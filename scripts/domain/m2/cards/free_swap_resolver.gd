extends RefCounted
## M2.4 one FREE_SWAP per actor per player phase, cost 0 AP / 0 MP.
## Only called with the M3 action-eligibility decision (can_act), not
## inferred from a UI timeout. Phase transitions belong to M3.
const Zones = preload("res://scripts/domain/m2/cards/card_zone_resolver.gd")
const Draw = preload("res://scripts/domain/m2/cards/draw_resolver.gd")
const Triggers = preload("res://scripts/domain/m2/cards/card_trigger_dispatcher.gd")

static func _reject(state: Dictionary, reason: String) -> Dictionary:
	var result: Dictionary = Zones.rejected(state, reason)
	result["draw_succeeded"] = false
	return result

static func _valid_command(state: Dictionary, command: Dictionary, can_act: bool) -> String:
	if not Zones.validate_state(state):
		return "INVALID_ZONE_STATE"
	if str(state["phase"]) != "PLAYER_PHASE":
		return "INVALID_PHASE"
	if not can_act:
		return "ACTOR_UNAVAILABLE"
	if str(command.get("type", "")) != "FREE_SWAP":
		return "INVALID_COMMAND_TYPE"
	var actor: String = str(command.get("actor_id", ""))
	if not state["actors"].has(actor):
		return "ACTOR_NOT_FOUND"
	if not command.get("expected_event_seq", null) is int:
		return "INVALID_EXPECTED_EVENT_SEQ"
	if int(command["expected_event_seq"]) != int(state["event_seq"]):
		return "STALE_STATE"
	if not command.get("expected_phase_index", null) is int:
		return "INVALID_EXPECTED_PHASE"
	if int(command["expected_phase_index"]) != int(state["player_phase_index"]):
		return "STALE_PHASE"
	var command_id: String = str(command.get("command_id", ""))
	if command_id.strip_edges().is_empty():
		return "INVALID_COMMAND_ID"
	if state["seen_swap_command_ids"].has(command_id):
		return "DUPLICATE_COMMAND"
	if bool(state["swap_used_by_actor"][actor]):
		return "SWAP_ALREADY_USED_THIS_PHASE"
	var card_id: String = str(command.get("card_instance_id", ""))
	if not state["actors"][actor]["instances"].has(card_id):
		return "INSTANCE_NOT_OWNED"
	if Zones.location(state, actor, card_id) != "hand":
		return "INSTANCE_NOT_IN_HAND"
	return ""

static func apply(state: Dictionary, command: Dictionary, trigger_rules: Array = [],
		can_act: bool = true) -> Dictionary:
	var error: String = _valid_command(state, command, can_act)
	if not error.is_empty():
		return _reject(state, error)
	var trigger_validation: Dictionary = Triggers.validate_rules(trigger_rules)
	if not trigger_validation["ok"]:
		return _reject(state, str(trigger_validation["error"]))
	var actor_id: String = str(command["actor_id"])
	var selected: String = str(command["card_instance_id"])
	# M-D29: no legal alternative at PRECHECK -> no events, no quota spent.
	if Zones.replacement_ids(state, actor_id, selected).is_empty():
		return _reject(state, "NO_LEGAL_REPLACEMENT")
	var snapshot: Dictionary = state.duplicate(true)
	var starting_events: int = state["events"].size()
	var isolated: Dictionary = Zones.move(snapshot, actor_id, selected, "hand", "isolated")
	if not isolated["accepted"]:
		return _reject(state, str(isolated["error"]))
	snapshot = isolated["state"]
	# M-D30: formal discard event while original remains isolated.
	var discard_event: Dictionary = Zones.emit(snapshot, "CardDiscarded", actor_id,
		{"instance_id": selected, "from_zone": "hand", "to_zone": "isolated",
		"command_id": str(command["command_id"])})
	var discard_effects: Dictionary = Triggers.dispatch(snapshot, discard_event, trigger_rules)
	if not discard_effects["accepted"]:
		return _reject(state, str(discard_effects["error"]))
	snapshot = discard_effects["state"]
	# A discard effect may have consumed all replacements (PRE3-R11).
	# The physical original is still isolated and cannot be recycled.
	var drawn: Dictionary = Draw.draw_cards(snapshot, actor_id, 1)
	if not drawn["accepted"]:
		return _reject(state, str(drawn["error"]))
	snapshot = drawn["state"]
	var drawn_event: Dictionary = {}
	for event: Dictionary in drawn["events"]:
		if event["kind"] == "CardDrawn":
			drawn_event = event
			break
	var successful: bool = not drawn_event.is_empty()
	if successful:
		var draw_effects: Dictionary = Triggers.dispatch(snapshot, drawn_event, trigger_rules)
		if not draw_effects["accepted"]:
			return _reject(state, str(draw_effects["error"]))
		snapshot = draw_effects["state"]
	else:
		Zones.emit(snapshot, "CardDrawFailed", actor_id,
			{"reason": "POOL_CHANGED", "instance_id": selected,
			"command_id": str(command["command_id"])})
	# Restore discarded original only AFTER the replacement draw attempt.
	var finished: Dictionary = Zones.move(snapshot, actor_id, selected, "isolated", "discard")
	if not finished["accepted"]:
		return _reject(state, str(finished["error"]))
	snapshot = finished["state"]
	snapshot["swap_used_by_actor"][actor_id] = true
	snapshot["seen_swap_command_ids"].append(str(command["command_id"]))
	Zones.emit(snapshot, "FreeSwapCompleted", actor_id,
		{"command_id": str(command["command_id"]), "selected_instance_id": selected,
		"draw_succeeded": successful,
		"drawn_instance_id": str(drawn_event.get("details", {}).get("instance_id", "")),
		"reason": "" if successful else "POOL_CHANGED", "ap_cost": 0, "mp_cost": 0,
		"player_phase_index": int(snapshot["player_phase_index"])})
	if not Zones.validate_state(snapshot):
		return _reject(state, "SWAP_CONSERVATION_VIOLATION")
	var emitted: Array = snapshot["events"].slice(starting_events)
	return {"accepted": true, "error": "", "draw_succeeded": successful,
		"state": snapshot, "events": emitted}

## M3-only boundary. This is not a player command. A newly opened phase
## resets all three independent allowances; repeated/stale IDs reject atomically.
static func open_next_player_phase(state: Dictionary, expected_phase_index: int) -> Dictionary:
	if not Zones.validate_state(state):
		return _reject(state, "INVALID_ZONE_STATE")
	if expected_phase_index != int(state["player_phase_index"]) + 1:
		return _reject(state, "INVALID_PHASE_SEQUENCE")
	for actor_key: Variant in state["actors"]:
		if not state["actors"][actor_key]["zones"]["isolated"].is_empty():
			return _reject(state, "SWAP_OPERATION_PENDING")
	var updated: Dictionary = state.duplicate(true)
	updated["player_phase_index"] = expected_phase_index
	updated["phase"] = "PLAYER_PHASE"
	for actor_key: Variant in updated["swap_used_by_actor"]:
		updated["swap_used_by_actor"][actor_key] = false
	var event: Dictionary = Zones.emit(updated, "FreeSwapQuotaRefreshed", "",
		{"player_phase_index": expected_phase_index})
	return Zones.accepted(updated, [event])
