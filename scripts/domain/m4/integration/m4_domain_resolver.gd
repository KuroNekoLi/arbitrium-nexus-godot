extends RefCounted
## M4.1: same authoritative M3 Phase state, same M2 atomic cost+zones.
## Only CAST_SPELL_M4 is new. Other commands delegate unchanged to M3.
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const Phase = preload("res://scripts/domain/m3/phase/phase_engine.gd")
const M2 = preload("res://scripts/domain/m2/integration/m2_domain_resolver.gd")
const Boundary = preload("res://scripts/domain/m3/phase/phase_boundary_resolver.gd")
const Profile = preload("res://scripts/domain/m4/casting/casting_profile_resolver.gd")
const Instance = preload("res://scripts/domain/m4/casting/casting_instance_resolver.gd")

static func validate_state(state: Dictionary) -> bool:
	return Phase.validate_state(state) and Instance.valid(state["core"])

static func _reject(state: Dictionary, reason: String) -> Dictionary:
	var copy: Dictionary = state.duplicate(true)
	return {"accepted": false, "error": reason, "state": copy, "events": [],
		"state_hash": Model.state_hash(copy), "event_hash": Model.event_hash([])}

static func _event(state: Dictionary, out: Array, kind: String,
		command_id: String, details: Dictionary, origin: String = "m4") -> void:
	state["event_seq"] = int(state["event_seq"]) + 1
	var event: Dictionary = {
		"event_seq": int(state["event_seq"]), "kind": kind,
		"command_id": command_id, "source": origin,
		"details": details.duplicate(true), "phase": str(state["phase"]),
		"round": int(state["core"]["battle"]["round"])
	}
	state["events"].append(event)
	out.append(event)

static func apply(original: Dictionary, command: Dictionary,
		config: Dictionary) -> Dictionary:
	if not validate_state(original):
		return _reject(original, "INVALID_M4_PHASE_STATE")
	var kind: String = str(command.get("type", ""))
	if kind != "CAST_SPELL_M4":
		return Phase.apply(original, command, config)
	var id: String = str(command.get("command_id", ""))
	if id.strip_edges().is_empty():
		return _reject(original, "INVALID_COMMAND_ID")
	if original["seen_command_ids"].has(id):
		return _reject(original, "DUPLICATE_COMMAND")
	if not command.get("expected_event_seq", null) is int:
		return _reject(original, "INVALID_EXPECTED_EVENT_SEQ")
	if int(command["expected_event_seq"]) != int(original["event_seq"]):
		return _reject(original, "STALE_STATE")
	if original["phase"] != "PLAYER_PHASE" or original["core"]["battle"]["outcome"] != "ONGOING":
		return _reject(original, "INVALID_PHASE")
	var resolved: Dictionary = Profile.resolve(original["core"], command, config)
	if not resolved["ok"]:
		return _reject(original, str(resolved["error"]))
	var next: Dictionary = original.duplicate(true)
	var spent: Dictionary = {
		"type": "COMMIT_SP_CARD_FIXTURE", "command_id": id,
		"actor_id": resolved["actor_id"],
		"card_instance_id": resolved["card_instance_id"],
		"casting_mode": resolved["mode"],
		"expected_event_seq": int(next["core"]["event_seq"])
	}
	if command.has("chosen_ap_investment"):
		spent["chosen_ap_investment"] = command["chosen_ap_investment"]
	var committed: Dictionary = M2.apply(next["core"], spent, config)
	if not committed["accepted"]:
		return _reject(original, str(committed["error"]))
	next["core"] = committed["state"]
	var output: Array = []
	for source_event: Dictionary in committed["events"]:
		_event(next, output, str(source_event["event"]["kind"]), id,
			{"core_event": source_event}, "m2")
	if resolved["mode"] == "FULL":
		var created: Dictionary = Instance.build(next["core"], resolved, id)
		if not created["ok"]:
			return _reject(original, str(created["error"]))
		var cast: Dictionary = created["instance"]
		next["core"]["battle"]["casting_instances"][cast["casting_id"]] = cast
		next["core"]["battle"]["actors"][resolved["actor_id"]]["status"] = "CONCENTRATING"
		_event(next, output, "CastingStarted", id,
			{"casting_id": cast["casting_id"], "caster_id": cast["caster_id"],
			"card_instance_id": cast["card_instance_id"],
			"planned_resolve_round": cast["planned_resolve_round"],
			"concentrating": true, "base_stability_authority": "BALANCE_PROVISIONAL"})
	else:
		_event(next, output, "SpellEffectDeferredToM5", id,
			{"spell_id": resolved["definition_id"], "mode": "CHANTLESS",
			"target_snapshot": {"actor_id": resolved["target_actor_id"]},
			"effect_execution": "NOT_IMPLEMENTED_M5", "hp_delta": 0})
	_event(next, output, "PlayerActionSettled", id,
		{"actor_id": resolved["actor_id"], "action_type": "CAST_SPELL_M4",
			"mode": resolved["mode"], "charged_once": true,
			"effects": "IMMEDIATE_CONTRACT_OR_SCHEDULED_ONLY"})
	var outcome: Dictionary = Boundary.check_action_outcome(next["core"])
	if not outcome["ok"]:
		return _reject(original, str(outcome["error"]))
	next["core"] = outcome["core"]
	_event(next, output, "BattleOutcomeEvaluated", id, outcome["event"], "boundary")
	if not validate_state(next):
		return _reject(original, "M4_INVARIANT_BROKEN")
	next["seen_command_ids"].append(id)
	return {"accepted": true, "error": "", "state": next,
		"events": output, "state_hash": Model.state_hash(next),
		"event_hash": Model.event_hash(output)}

static func replay(initial: Dictionary, tape: Array[Dictionary],
		config: Dictionary) -> Dictionary:
	if not validate_state(initial):
		return _reject(initial, "INVALID_INITIAL_STATE")
	var s: Dictionary = initial.duplicate(true)
	var events: Array = []
	for command: Dictionary in tape:
		var result: Dictionary = apply(s, command, config)
		if not result["accepted"]:
			return {"accepted": false, "error": result["error"],
				"state": s, "events": events,
				"state_hash": Model.state_hash(s),
				"event_hash": Model.event_hash(events)}
		s = result["state"]
		events.append_array(result["events"])
	return {"accepted": true, "error": "", "state": s,
		"events": events, "state_hash": Model.state_hash(s),
		"event_hash": Model.event_hash(events)}
