extends RefCounted
## Phase 3 M2.5 integration reducer: a transactionally committed envelope
## around ACTUAL M1/M2.1/M2.2 resource and M2.3/M2.4 zone resolvers.
## Scope: *domain fixture operations* only. Real SP damage, status, M3
## player-phase casting ticks and M4 releases remain unimplemented.
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const Cost = preload("res://scripts/domain/m2/economy/cost_resolver.gd")
const Ledger = preload("res://scripts/domain/m2/economy/resource_ledger.gd")
const Zones = preload("res://scripts/domain/m2/cards/card_zone_resolver.gd")
const Draw = preload("res://scripts/domain/m2/cards/draw_resolver.gd")
const Swap = preload("res://scripts/domain/m2/cards/free_swap_resolver.gd")
const SCHEMA: String = "m2.5-integrated-fixture-v1"

static func make_state(battle: Dictionary, cards: Dictionary) -> Dictionary:
	if not Model.validate_shell(battle) or not Zones.validate_state(cards):
		return {}
	if str(battle["phase"]) != str(cards["phase"]):
		return {}
	if str(battle["phase"]) != "PLAYER_PHASE":
		return {}
	if int(battle["round"]) != int(cards["player_phase_index"]):
		return {}
	if battle["allies"].size() != 3 or cards["actors"].size() != 3:
		return {}
	for actor_id: Variant in battle["allies"]:
		if not cards["actors"].has(actor_id):
			return {}
	if int(battle["seed"]) != int(cards["seed"]):
		return {}
	var state: Dictionary = {
		"schema_version": SCHEMA, "ruleset_version": str(battle["ruleset_version"]),
		"content_version": str(battle["content_version"]), "seed": int(battle["seed"]),
		"battle": battle.duplicate(true), "cards": cards.duplicate(true),
		"event_seq": 0, "events": [], "seen_command_ids": []
	}
	return state if validate_state(state) else {}

static func validate_state(state: Dictionary) -> bool:
	if str(state.get("schema_version", "")) != SCHEMA:
		return false
	if not state.get("battle", null) is Dictionary or not state.get("cards", null) is Dictionary:
		return false
	var battle: Dictionary = state["battle"]
	var cards: Dictionary = state["cards"]
	if not Model.validate_shell(battle) or not Zones.validate_state(cards):
		return false
	if str(battle["ruleset_version"]) != str(state.get("ruleset_version", "")):
		return false
	if str(battle["content_version"]) != str(state.get("content_version", "")):
		return false
	if not state.get("seed", null) is int or int(state["seed"]) != int(battle["seed"]):
		return false
	if int(cards["seed"]) != int(state["seed"]):
		return false
	if str(battle["phase"]) != str(cards["phase"]):
		return false
	if str(battle["phase"]) == "PLAYER_PHASE" and int(cards["player_phase_index"]) != int(battle["round"]):
		return false
	if cards["actors"].size() != battle["allies"].size():
		return false
	for actor_id: Variant in battle["allies"]:
		if not cards["actors"].has(actor_id):
			return false
	if not state.get("event_seq", null) is int or not state.get("events", null) is Array:
		return false
	if int(state["event_seq"]) != state["events"].size():
		return false
	if not state.get("seen_command_ids", null) is Array:
		return false
	var used: Dictionary = {}
	for command_id: Variant in state["seen_command_ids"]:
		if not command_id is String or str(command_id).is_empty() or used.has(command_id):
			return false
		used[command_id] = true
	for i: int in range(state["events"].size()):
		if not state["events"][i] is Dictionary:
			return false
		var entry: Dictionary = state["events"][i]
		if int(entry.get("event_seq", -1)) != i + 1:
			return false
		if not ["resources", "cards"].has(str(entry.get("source", ""))):
			return false
	return true

static func _rejected(original: Dictionary, reason: String) -> Dictionary:
	var state: Dictionary = original.duplicate(true)
	return {"accepted": false, "error": reason, "state": state,
		"events": [], "state_hash": Model.state_hash(state),
		"event_hash": Model.event_hash([])}

static func _actor_available(battle: Dictionary, actor_id: String) -> bool:
	if not battle["allies"].has(actor_id) or not battle["actors"].has(actor_id):
		return false
	var actor: Dictionary = battle["actors"][actor_id]
	return str(actor.get("status", "")) == "ACTIVE" and int(actor.get("hp", 0)) > 0

static func _command(state: Dictionary, instruction: Dictionary) -> String:
	if not validate_state(state):
		return "INVALID_INTEGRATED_STATE"
	var command_id: String = str(instruction.get("command_id", ""))
	if command_id.strip_edges().is_empty():
		return "INVALID_COMMAND_ID"
	if state["seen_command_ids"].has(command_id):
		return "DUPLICATE_COMMAND"
	if not instruction.get("expected_event_seq", null) is int:
		return "INVALID_EXPECTED_EVENT_SEQ"
	if int(instruction["expected_event_seq"]) != int(state["event_seq"]):
		return "STALE_STATE"
	return ""

static func _log(next: Dictionary, origin: String, source_events: Array, result_events: Array) -> void:
	for event: Dictionary in source_events:
		next["event_seq"] = int(next["event_seq"]) + 1
		var wrapped: Dictionary = {
			"event_seq": int(next["event_seq"]),
			"source": origin, "source_event_seq": int(event["event_seq"]),
			"event": event.duplicate(true)
		}
		next["events"].append(wrapped)
		result_events.append(wrapped)

static func _success(next: Dictionary, command_id: String, new_events: Array) -> Dictionary:
	next["seen_command_ids"].append(command_id)
	return {"accepted": true, "error": "", "state": next, "events": new_events,
		"state_hash": Model.state_hash(next), "event_hash": Model.event_hash(new_events)}

static func apply(state: Dictionary, instruction: Dictionary, config: Dictionary) -> Dictionary:
	var problem: String = _command(state, instruction)
	if not problem.is_empty():
		return _rejected(state, problem)
	var kind: String = str(instruction.get("type", ""))
	var actor_id: String = str(instruction.get("actor_id", ""))
	var command_id: String = str(instruction["command_id"])
	var battle: Dictionary = state["battle"]
	var cards: Dictionary = state["cards"]
	var next: Dictionary = state.duplicate(true)
	var produced: Array = []
	match kind:
		"COMMIT_SP_CARD_FIXTURE":
			# This is NOT real damage/effect/casting resolution. Its cost
			# MUST be from an externally fixed card-definition cost catalogue,
			# never a cost Dictionary supplied by the action/UI.
			if battle["phase"] != "PLAYER_PHASE" or not _actor_available(battle, actor_id):
				return _rejected(state, "ACTOR_UNAVAILABLE_OR_PHASE")
			if not config.get("costs", null) is Dictionary or not config.get("definitions", null) is Dictionary:
				return _rejected(state, "MISSING_INTEGRATION_CONFIGURATION")
			var instance_id: String = str(instruction.get("card_instance_id", ""))
			if Zones.location(cards, actor_id, instance_id) != "hand":
				return _rejected(state, "CARD_NOT_IN_OWN_HAND")
			var definition_id: String = str(cards["actors"][actor_id]["instances"][instance_id]["definition_id"])
			if not config["definitions"].has(definition_id) or not config["definitions"][definition_id] is Dictionary:
				return _rejected(state, "NO_VERSIONED_CARD_COST")
			var cost_card: Dictionary = config["definitions"][definition_id].duplicate(true)
			if str(cost_card.get("card_id", "")) != definition_id:
				return _rejected(state, "COST_DEFINITION_MISMATCH")
			var mode: String = str(instruction.get("casting_mode", "CHANTLESS"))
			var payment: Dictionary = {
				"type": "PAY_SP_COST_ONLY", "command_id": command_id,
				"expected_event_seq": int(battle["event_seq"]), "actor_id": actor_id,
				"card": cost_card, "casting_mode": mode
			}
			if instruction.has("chosen_ap_investment"):
				payment["chosen_ap_investment"] = instruction["chosen_ap_investment"]
			var paid: Dictionary = Cost.apply(battle, payment, config["costs"])
			if not paid["accepted"]:
				return _rejected(state, str(paid["error"]))
			var destination: String = "casting" if mode == "FULL" else "discard"
			var moved: Dictionary = Zones.move(cards, actor_id, instance_id, "hand", destination)
			if not moved["accepted"]:
				return _rejected(state, str(moved["error"]))
			next["battle"] = paid["state"]
			next["cards"] = moved["state"]
			_log(next, "resources", paid["events"], produced)
			_log(next, "cards", moved["events"], produced)
		"BASIC_ATTACK_RESOURCE_ONLY":
			# M3.1 entry-point to the EXISTING per-actor M2.1 cost/MP policy.
			# The enemy hit and damage remain M5, not a second combat engine.
			if battle["phase"] != "PLAYER_PHASE" or not _actor_available(battle, actor_id):
				return _rejected(state, "ACTOR_UNAVAILABLE_OR_PHASE")
			var basic: Dictionary = Ledger.apply(battle, {
				"type": "BASIC_ATTACK_RESOURCE_ONLY",
				"command_id": command_id,
				"actor_id": actor_id,
				"expected_event_seq": int(battle["event_seq"])
			}, config.get("resources", {}))
			if not basic["accepted"]:
				return _rejected(state, str(basic["error"]))
			next["battle"] = basic["state"]
			_log(next, "resources", basic["events"], produced)
		"FREE_SWAP":
			if battle["phase"] != "PLAYER_PHASE":
				return _rejected(state, "INVALID_PHASE")
			var request: Dictionary = {
				"type": "FREE_SWAP", "actor_id": actor_id, "command_id": command_id,
				"card_instance_id": str(instruction.get("card_instance_id", "")),
				"expected_event_seq": int(cards["event_seq"]),
				"expected_phase_index": int(cards["player_phase_index"])
			}
			var rules: Variant = config.get("trigger_rules", [])
			if not rules is Array:
				return _rejected(state, "INVALID_TRIGGER_RULES")
			var swapped: Dictionary = Swap.apply(cards, request, rules, _actor_available(battle, actor_id))
			if not swapped["accepted"]:
				return _rejected(state, str(swapped["error"]))
			next["cards"] = swapped["state"]
			_log(next, "cards", swapped["events"], produced)
		"EXTRA_DRAW_FIXTURE":
			if battle["phase"] != "PLAYER_PHASE" or not _actor_available(battle, actor_id):
				return _rejected(state, "ACTOR_UNAVAILABLE_OR_PHASE")
			if not instruction.get("count", null) is int or int(instruction["count"]) < 0:
				return _rejected(state, "INVALID_DRAW_COUNT")
			var drawn: Dictionary = Draw.draw_cards(cards, actor_id, int(instruction["count"]))
			if not drawn["accepted"]:
				return _rejected(state, str(drawn["error"]))
			next["cards"] = drawn["state"]
			_log(next, "cards", drawn["events"], produced)
		"RESOLVE_CAST_ZONE_FIXTURE":
			var cast_id: String = str(instruction.get("card_instance_id", ""))
			var moved: Dictionary = Zones.move(cards, actor_id, cast_id, "casting", "discard")
			if not moved["accepted"]:
				return _rejected(state, str(moved["error"]))
			next["cards"] = moved["state"]
			_log(next, "cards", moved["events"], produced)
		"CONVERT_AP_TO_RP", "EXPIRE_RP", "START_PLAYER_RESOURCES":
			# M2 resource-ledger phase boundary. M3 must insert scheduled
			# Casting/status ticks before START_PLAYER_RESOURCES in gameplay.
			var req: Dictionary = {"type": kind, "command_id": command_id,
				"expected_event_seq": int(battle["event_seq"])}
			var phase_result: Dictionary = Ledger.apply(battle, req, config.get("resources", {}))
			if not phase_result["accepted"]:
				return _rejected(state, str(phase_result["error"]))
			next["battle"] = phase_result["state"]
			_log(next, "resources", phase_result["events"], produced)
			if kind == "START_PLAYER_RESOURCES":
				var new_phase: Dictionary = Swap.open_next_player_phase(cards,
					int(phase_result["state"]["round"]))
				if not new_phase["accepted"]:
					return _rejected(state, str(new_phase["error"]))
				var updated_cards: Dictionary = new_phase["state"]
				var phase_events: Array = new_phase["events"].duplicate()
				var actor_ids: Array = updated_cards["actors"].keys()
				actor_ids.sort()
				for ally: Variant in actor_ids:
					if not _actor_available(phase_result["state"], str(ally)):
						continue
					var replenished: Dictionary = Draw.draw_to_four(updated_cards, str(ally))
					if not replenished["accepted"]:
						return _rejected(state, str(replenished["error"]))
					updated_cards = replenished["state"]
					phase_events.append_array(replenished["events"])
				next["cards"] = updated_cards
				_log(next, "cards", phase_events, produced)
			else:
				next["cards"]["phase"] = str(phase_result["state"]["phase"])
		_:
			return _rejected(state, "UNKNOWN_M2_INTEGRATION_COMMAND")
	if not validate_state(next):
		return _rejected(state, "INTEGRATED_INVARIANT_BROKEN")
	return _success(next, command_id, produced)

static func replay(initial: Dictionary, commands: Array[Dictionary], config: Dictionary) -> Dictionary:
	if not validate_state(initial):
		return _rejected(initial, "INVALID_INITIAL_STATE")
	var current: Dictionary = initial.duplicate(true)
	var events: Array = []
	for command: Dictionary in commands:
		var executed: Dictionary = apply(current, command, config)
		if not executed["accepted"]:
			return {"accepted": false, "error": executed["error"], "state": current,
				"events": events, "state_hash": Model.state_hash(current),
				"event_hash": Model.event_hash(events)}
		current = executed["state"]
		events.append_array(executed["events"])
	return {"accepted": true, "error": "", "state": current,
		"events": events, "state_hash": Model.state_hash(current),
		"event_hash": Model.event_hash(events)}
