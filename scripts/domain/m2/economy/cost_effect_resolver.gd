extends RefCounted
## M2.2 INTERNAL fixture effects. Only pre-paid fixture SP cost can grant effects.
## Events do not implement SP execution, targets or card ownership.
## M-D01/16: AP refund enters current AP; M-D17: debt reduction NEVER adds AP.
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const TYPES: Array[String] = ["AP_REFUND_EFFECT", "REDUCE_AP_DEBT_EFFECT", "SCHEDULE_NEXT_PHASE_AP_BONUS"]

static func _rejected(state: Dictionary, why: String) -> Dictionary:
	var copy: Dictionary = Model.snapshot(state)
	return {"accepted": false, "error": why, "state": copy, "events": [],
		"state_hash": Model.state_hash(copy), "event_hash": Model.event_hash([])}

static func apply(state: Dictionary, command: Dictionary, config: Dictionary) -> Dictionary:
	if not Model.validate_shell(state):
		return _rejected(state, "INVALID_STATE")
	if state.get("phase", "") != "PLAYER_PHASE":
		return _rejected(state, "INVALID_PHASE")
	if config.get("authority", "") != "BALANCE_PROVISIONAL" or config.get("ruleset_version", "") != Model.RULESET_VERSION:
		return _rejected(state, "MISSING_PROVISIONAL_RULESET")
	var kind: String = str(command.get("type", ""))
	if not TYPES.has(kind):
		return _rejected(state, "UNKNOWN_FIXTURE_EFFECT")
	var id: String = str(command.get("command_id", ""))
	if id.strip_edges().is_empty():
		return _rejected(state, "INVALID_COMMAND_ID")
	if state["seen_command_ids"].has(id):
		return _rejected(state, "DUPLICATE_COMMAND")
	if not command.get("expected_event_seq", null) is int or int(command["expected_event_seq"]) != int(state["event_seq"]):
		return _rejected(state, "STALE_STATE")
	var source: String = str(command.get("source_cost_command_id", ""))
	if not state["paid_cost_command_ids"].has(source):
		return _rejected(state, "NO_PAID_SOURCE")
	var effect_id: String = str(command.get("effect_instance_id", ""))
	if effect_id.strip_edges().is_empty():
		return _rejected(state, "INVALID_EFFECT_ID")
	if state["consumed_effect_instance_ids"].has(effect_id):
		return _rejected(state, "EFFECT_ALREADY_CONSUMED")
	if not command.get("amount", null) is int or int(command["amount"]) <= 0:
		return _rejected(state, "INVALID_AMOUNT")
	var amount: int = int(command["amount"])
	var resources: Dictionary = state["party_resources"]
	var before: int = 0
	var actual: int = 0
	var next_state: Dictionary = Model.snapshot(state)
	var pool: Dictionary = next_state["party_resources"]
	match kind:
		"AP_REFUND_EFFECT":
			before = int(resources["current_ap"])
			if amount > 9223372036854775807 - before:
				return _rejected(state, "AP_OVERFLOW")
			actual = amount
			pool["current_ap"] = before + actual
		"REDUCE_AP_DEBT_EFFECT":
			before = int(resources["ap_debt"])
			actual = min(amount, before)
			pool["ap_debt"] = before - actual
		"SCHEDULE_NEXT_PHASE_AP_BONUS":
			before = int(resources["next_player_ap_bonus"])
			if amount > 9223372036854775807 - before:
				return _rejected(state, "AP_OVERFLOW")
			actual = amount
			pool["next_player_ap_bonus"] = before + actual
	next_state["seen_command_ids"].append(id)
	next_state["consumed_effect_instance_ids"].append(effect_id)
	next_state["action_seq"] += 1
	next_state["event_seq"] += 1
	var event: Dictionary = {"kind": kind, "action_id": next_state["action_seq"],
		"event_seq": next_state["event_seq"], "command_id": id,
		"rng_draw_index": next_state["rng"]["draw_index"],
		"details": {"effect_instance_id": effect_id, "source_cost_command_id": source,
			"requested": amount, "actual": actual, "before": before,
			"balance_authority": "BALANCE_PROVISIONAL"}}
	next_state["events"].append(event)
	return {"accepted": true, "error": "", "state": next_state, "events": [event],
		"state_hash": Model.state_hash(next_state), "event_hash": Model.event_hash([event])}
