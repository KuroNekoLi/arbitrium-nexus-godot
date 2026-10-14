extends RefCounted
## M4.1: same authoritative M3 Phase state, same M2 atomic cost+zones.
## Only CAST_SPELL_M4 is new. Other commands delegate unchanged to M3.
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const Phase = preload("res://scripts/domain/m3/phase/phase_engine.gd")
const M2 = preload("res://scripts/domain/m2/integration/m2_domain_resolver.gd")
const Boundary = preload("res://scripts/domain/m3/phase/phase_boundary_resolver.gd")
const Profile = preload("res://scripts/domain/m4/casting/casting_profile_resolver.gd")
const Instance = preload("res://scripts/domain/m4/casting/casting_instance_resolver.gd")
const Disruption = preload("res://scripts/domain/m4/casting/casting_disruption_resolver.gd")
const Refund = preload("res://scripts/domain/m4/casting/casting_refund_policy.gd")

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


## Strictly INTERNAL M4.2 encounter event bridge, NOT a free user action.
## Only a versioned source effect can supply power, and ON_HIT requires a
## separately authorized M5-style verified-hit FIXTURE gate.
static func _disrupt(original: Dictionary, command: Dictionary, config: Dictionary) -> Dictionary:
	var id: String = str(command.get("command_id",""))
	if id.strip_edges().is_empty():
		return _reject(original,"INVALID_COMMAND_ID")
	if original["seen_command_ids"].has(id):
		return _reject(original,"DUPLICATE_COMMAND")
	if not command.get("expected_event_seq",null) is int:
		return _reject(original,"INVALID_EXPECTED_EVENT_SEQ")
	if int(command["expected_event_seq"]) != int(original["event_seq"]):
		return _reject(original,"STALE_STATE")
	if config.get("m4_2_fixture_authorized",false) != true:
		return _reject(original,"M4_2_FIXTURE_NOT_AUTHORIZED")
	if str(original["phase"]) != "ENEMY_PHASE" or str(original["active_enemy_action_id"]).is_empty():
		return _reject(original,"NO_DECLARED_ENEMY_ACTION")
	var current_action: Dictionary = original["enemy_actions"][int(original["enemy_cursor"])]
	var action_id: String = str(original["active_enemy_action_id"])
	if str(command.get("source_enemy_action_id","")) != action_id:
		return _reject(original,"DISRUPTION_ACTION_ID_MISMATCH")
	if original["reaction_window"].is_empty() or str(original["reaction_window"].get("status","")) != "CLOSED":
		return _reject(original,"REACTION_WINDOW_NOT_RESOLVED")
	var casting_id: String = str(command.get("casting_id",""))
	if not original["core"]["battle"]["casting_instances"].has(casting_id):
		return _reject(original,"CASTING_INSTANCE_NOT_FOUND")
	var spell: Dictionary = original["core"]["battle"]["casting_instances"][casting_id]
	var catalogue: Variant = config.get("disruption_effects",null)
	var effect_id: String = str(command.get("effect_id",""))
	if not catalogue is Dictionary or not catalogue.has(effect_id) or not catalogue[effect_id] is Dictionary:
		return _reject(original,"DISRUPTION_EFFECT_NOT_REGISTERED")
	var effect: Dictionary = catalogue[effect_id]
	var channel: String = str(effect.get("channel",""))
	if not ["DIRECT_CASTING_INSTANCE","ON_HIT_CASTING"].has(channel):
		return _reject(original,"INVALID_DISRUPTION_EFFECT_CHANNEL")
	var hit_index: int = int(command.get("hit_index",0))
	if hit_index < 0:
		return _reject(original,"INVALID_HIT_INDEX")
	var key: String = action_id + ":" + effect_id + ":" + str(hit_index)
	for seen: Variant in spell["disruption_events"]:
		if str(seen.get("source_enemy_action_id","")) + ":" + str(seen.get("effect_id","")) + ":" + str(seen.get("hit_index",0)) == key:
			return _reject(original,"DUPLICATE_DISRUPTION_EFFECT")
	var next: Dictionary = original.duplicate(true)
	var out: Array = []
	if channel == "ON_HIT_CASTING":
		if config.get("m4_2_verified_hit_fixture",false) != true or command.get("hit_fixture_confirmed",false) != true:
			return _reject(original,"M5_HIT_RESOLUTION_NOT_AVAILABLE")
		var intent: Dictionary = current_action["public_intent"]
		if str(intent.get("target_scope","")) != "SINGLE" or not intent.get("target_ids",null) is Array:
			return _reject(original,"ON_HIT_SCOPE_UNSUPPORTED")
		if hit_index >= int(intent.get("hit_count",0)):
			return _reject(original,"HIT_INDEX_OUT_OF_RANGE")
		var original_target: String = str(intent["target_ids"][0])
		var recipient: String = original_target
		var window: Dictionary = original["reaction_window"]
		if not str(window.get("damage_recipient_actor_id","")).is_empty():
			recipient = str(window["damage_recipient_actor_id"])
		if original_target != str(spell["caster_id"]):
			return _reject(original,"CASTER_NOT_ORIGINAL_HIT_TARGET")
		if recipient != str(spell["caster_id"]):
			_event(next,out,"CastingDisruptionSuppressedByProtect",id,{
				"casting_id":casting_id,"source_enemy_action_id":action_id,
				"original_target_actor_id":original_target,
				"actual_damage_recipient_actor_id":recipient,
				"effect_id":effect_id,"no_stability_loss":true,
				"hit_proof":"M5_VERIFIED_HIT_FIXTURE_ONLY"})
			next["seen_command_ids"].append(id)
			return {"accepted":true,"error":"","state":next,"events":out,
				"state_hash":Model.state_hash(next),"event_hash":Model.event_hash(out)}
	if channel == "DIRECT_CASTING_INSTANCE" and str(command.get("target_casting_id","")) != casting_id:
		return _reject(original,"DIRECT_TARGET_CASTING_ID_REQUIRED")
	var context: Dictionary = {"channel":channel,"source_enemy_action_id":action_id,
		"effect_id":effect_id,"hit_index":hit_index}
	var applied: Dictionary = Disruption.resolve(spell,effect,context)
	if not applied["ok"]:
		return _reject(original,str(applied["error"]))
	var trace: Dictionary = applied["trace"]
	next["core"]["battle"]["casting_instances"][casting_id] = applied["instance"]
	_event(next,out,"CastingDisruptionEvaluated",id,trace)
	if int(trace["ward_absorbed"]) > 0:
		_event(next,out,"FocusWardAbsorbed",id,{
			"casting_id":casting_id,"absorbed":int(trace["ward_absorbed"]),
			"before":int(trace["ward_before"]),"after":int(trace["ward_after"]),
			"hp_barrier_affected":false})
	_event(next,out,"CastingStabilityChanged",id,{
		"casting_id":casting_id,"before":int(trace["stability_before"]),
		"after":int(trace["stability_after"]),"stability_lost":int(trace["stability_lost"])})
	if bool(applied["interrupted"]):
		var caster: String = str(spell["caster_id"])
		# Quoted from the M2-authoritative paid_mp receipt, never from
		# command input. Not applicable to HP0, Last Spell or cancellation.
		var quote: Dictionary = Refund.quote(spell,next["core"]["battle"]["actors"][caster],
			config.get("casting_interrupt_refund",{}))
		if not quote["ok"]:
			return _reject(original,str(quote["error"]))
		_event(next,out,"CastingInterrupted",id,{
			"casting_id":casting_id,"caster_id":caster,
			"reason":"STABILITY_REACHED_ZERO","mp_refund_requested":int(quote["requested"]),
			"ap_refund":0,"overload_debt_repaid":0})
		_event(next,out,"ScheduledEffectCancelled",id,{
			"casting_id":casting_id,"reason":"CASTING_INTERRUPTED","effect_applied":false})
		# REAL M2 ledger MPRestored capped by current MaxMP.
		var refunded: Dictionary = M2.apply(next["core"],{
			"type":"RECOVER_CASTING_INTERRUPT_MP_M4",
			"command_id":id+":m4refund","expected_event_seq":int(next["core"]["event_seq"]),
			"actor_id":caster,"amount":int(quote["requested"])
		},config)
		if not refunded["accepted"]:
			return _reject(original,str(refunded["error"]))
		next["core"] = refunded["state"]
		for item: Dictionary in refunded["events"]:
			_event(next,out,str(item["event"]["kind"]),id,{"core_event":item},"m2")
		var moved: Dictionary = M2.apply(next["core"],{
			"type":"SETTLE_CASTING_CARD_M4","command_id":id+":m4discard",
			"expected_event_seq":int(next["core"]["event_seq"]),
			"actor_id":caster,"card_instance_id":str(spell["card_instance_id"])
		},config)
		if not moved["accepted"]:
			return _reject(original,str(moved["error"]))
		next["core"] = moved["state"]
		for item: Dictionary in moved["events"]:
			_event(next,out,str(item["event"]["kind"]),id,{"core_event":item},"m2")
		next["core"]["battle"]["casting_instances"].erase(casting_id)
		next["core"]["battle"]["actors"][caster]["status"] = "ACTIVE"
		_event(next,out,"ConcentrationEnded",id,{
			"casting_id":casting_id,"caster_id":caster,
			"reason":"CASTING_INTERRUPTED","refunded_mp":int(quote["actual"])})
	if not validate_state(next):
		return _reject(original,"M4_2_INVARIANT_BROKEN")
	next["seen_command_ids"].append(id)
	return {"accepted":true,"error":"","state":next,"events":out,
		"state_hash":Model.state_hash(next),"event_hash":Model.event_hash(out)}

static func apply(original: Dictionary, command: Dictionary,
		config: Dictionary) -> Dictionary:
	if not validate_state(original):
		return _reject(original, "INVALID_M4_PHASE_STATE")
	var kind: String = str(command.get("type", ""))
	if kind == "APPLY_CASTING_DISRUPTION_M4_FIXTURE":
		return _disrupt(original,command,config)
	if kind != "CAST_SPELL_M4":
		var delegated: Dictionary = Phase.apply(original,command,config)
		if delegated["accepted"] and not validate_state(delegated["state"]):
			return _reject(original,"M4_DELEGATED_INVARIANT_BROKEN")
		return delegated
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
