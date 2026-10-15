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
const LastSpell = preload("res://scripts/domain/m4/last_spell/last_spell_resolver.gd")
const LastInstability = preload("res://scripts/domain/m4/last_spell/last_spell_instability_resolver.gd")
const Invalidation = preload("res://scripts/domain/m4/casting/casting_invalidation_resolver.gd")
const Damage = preload("res://scripts/domain/m5/damage/damage_pipeline_resolver.gd")

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
	if bool(applied["interrupted"]) and str(spell.get("kind","")) == "LAST_SPELL":
		var special: Dictionary = LastInstability.handle(applied["instance"],
			config.get("last_spell_instability",{}))
		if not special["ok"]:
			return _reject(original,str(special["error"]))
		next["core"]["battle"]["casting_instances"][casting_id] = special["instance"]
		_event(next,out,str(special["event"]["kind"]),id,special["event"])
		if not validate_state(next):
			return _reject(original,"LAST_SPELL_INVARIANT_BROKEN")
		next["seen_command_ids"].append(id)
		return {"accepted":true,"error":"","state":next,"events":out,
			"state_hash":Model.state_hash(next),"event_hash":Model.event_hash(out)}
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


## M4.4 trusted encounter-bound TEST-ONLY bridge until M5 supplies actual hits
## and revive tagged skills. Never expose these as generic player HP commands.
static func _life_fixture(original: Dictionary, command: Dictionary,
		config: Dictionary, revive: bool) -> Dictionary:
	var id: String = str(command.get("command_id",""))
	if id.strip_edges().is_empty():
		return _reject(original,"INVALID_COMMAND_ID")
	if original["seen_command_ids"].has(id):
		return _reject(original,"DUPLICATE_COMMAND")
	if not command.get("expected_event_seq",null) is int:
		return _reject(original,"INVALID_EXPECTED_EVENT_SEQ")
	if int(command["expected_event_seq"]) != int(original["event_seq"]):
		return _reject(original,"STALE_STATE")
	if config.get("m4_4_trusted_life_fixture",false) != true:
		return _reject(original,"M5_HP_ENGINE_NOT_AVAILABLE")
	# No caller-specified final HP, damage, resource or execution outcome.
	for field: String in ["hp_after","damage","mp_refund","ap_refund","once_used","effect_power"]:
		if command.has(field):
			return _reject(original,"UNTRUSTED_LIFE_PAYLOAD")
	var catalogue: Variant = config.get("m4_4_life_effects",null)
	var effect_id: String = str(command.get("effect_id",""))
	if not catalogue is Dictionary or not catalogue.has(effect_id) or \
			not catalogue[effect_id] is Dictionary:
		return _reject(original,"UNKNOWN_LIFE_FIXTURE")
	var effect: Dictionary = catalogue[effect_id]
	if str(effect.get("authority","")) != "M4_4_TRUSTED_FIXTURE_ONLY":
		return _reject(original,"UNTRUSTED_LIFE_FIXTURE")
	var target: String = str(effect.get("target_actor_id",""))
	if target.is_empty() or not original["core"]["battle"]["allies"].has(target):
		return _reject(original,"INVALID_LIFE_FIXTURE_TARGET")
	var next: Dictionary = original.duplicate(true)
	var events: Array = []
	if revive:
		if str(effect.get("operation","")) != "REVIVE" or \
				not effect.get("revive_tag",false) == true or \
				not effect.get("hp_after",null) is int:
			return _reject(original,"REVIVE_TAG_REQUIRED")
		if original["phase"] != "PLAYER_PHASE" or original["core"]["battle"]["outcome"] != "ONGOING":
			return _reject(original,"INVALID_REVIVE_PHASE")
		var revived: Dictionary = Invalidation.revive(next["core"],target,int(effect["hp_after"]))
		if not revived["ok"]:
			return _reject(original,str(revived["error"]))
		next["core"] = revived["core"]
		_event(next,events,"ActorRevivedFixture",id,revived["event"],"m4_fixture")
	else:
		if str(effect.get("operation","")) != "HP_ZERO" or \
				not effect.get("hp_after",null) is int or int(effect["hp_after"]) != 0:
			return _reject(original,"INVALID_HP0_EFFECT_FIXTURE")
		if original["phase"] != "ENEMY_PHASE" or str(original["active_enemy_action_id"]).is_empty():
			return _reject(original,"NO_DECLARED_ENEMY_ACTION")
		if original["reaction_window"].is_empty() or \
				str(original["reaction_window"].get("status","")) != "CLOSED":
			return _reject(original,"REACTION_WINDOW_NOT_RESOLVED")
		if str(command.get("source_enemy_action_id","")) != str(original["active_enemy_action_id"]):
			return _reject(original,"HP0_ACTION_ID_MISMATCH")
		if command.get("verified_hit_fixture",false) != true or \
				config.get("m4_4_verified_hit_fixture",false) != true:
			return _reject(original,"M5_VERIFIED_HIT_REQUIRED")
		var action: Dictionary = original["enemy_actions"][int(original["enemy_cursor"])]
		var intent: Dictionary = action["public_intent"]
		if str(intent.get("target_scope","")) != "SINGLE" or \
				not intent.get("target_ids",null) is Array or intent["target_ids"].size() != 1:
			return _reject(original,"HP0_FIXTURE_SCOPE_UNSUPPORTED")
		var recipient: String = str(intent["target_ids"][0])
		if not str(original["reaction_window"].get("damage_recipient_actor_id","")).is_empty():
			recipient = str(original["reaction_window"]["damage_recipient_actor_id"])
		if recipient != target:
			return _reject(original,"HP0_PROTECT_RECIPIENT_MISMATCH")
		if int(next["core"]["battle"]["actors"][target]["hp"]) <= 0:
			return _reject(original,"ACTOR_ALREADY_AT_ZERO_HP")
		next["core"]["battle"]["actors"][target]["hp"] = 0
		var forced: Dictionary = Invalidation.incapacitate(next["core"],target,id,config)
		if not forced["ok"]:
			return _reject(original,str(forced["error"]))
		next["core"] = forced["core"]
		# Publish forced chain at the SAME action boundary, never on next tick.
		for record: Dictionary in forced["timeline"]:
			if str(record["kind"]) == "core_event":
				_event(next,events,str(record["raw"]["event"]["kind"]),id,
					{"core_event":record["raw"]},"m2")
			else:
				_event(next,events,str(record["kind"]),id,record,"m4_invalidation")
	# Outcome is computed after all required effects, preserving CORE-01
	# victory priority and the original M3 battle outcome contract.
	var judged: Dictionary = Boundary.check_action_outcome(next["core"])
	if not judged["ok"]:
		return _reject(original,str(judged["error"]))
	next["core"] = judged["core"]
	_event(next,events,"BattleOutcomeEvaluated",id,judged["event"],"boundary")
	if not validate_state(next):
		return _reject(original,"M4_4_INVARIANT_BROKEN")
	next["seen_command_ids"].append(id)
	return {"accepted":true,"error":"","state":next,"events":events,
		"state_hash":Model.state_hash(next),"event_hash":Model.event_hash(events)}

static func apply(original: Dictionary, command: Dictionary,
		config: Dictionary) -> Dictionary:
	if not validate_state(original):
		return _reject(original, "INVALID_M4_PHASE_STATE")
	var kind: String = str(command.get("type", ""))
	if kind == "APPLY_INCAPACITATION_M4_FIXTURE":
		return _life_fixture(original,command,config,false)
	if kind == "APPLY_REVIVE_M4_FIXTURE":
		return _life_fixture(original,command,config,true)
	if kind == "APPLY_CASTING_DISRUPTION_M4_FIXTURE":
		return _disrupt(original,command,config)
	if kind == "ACTIVATE_LAST_SPELL_M4":
		var id: String = str(command.get("command_id",""))
		if id.strip_edges().is_empty():
			return _reject(original,"INVALID_COMMAND_ID")
		if original["seen_command_ids"].has(id):
			return _reject(original,"DUPLICATE_COMMAND")
		if not command.get("expected_event_seq",null) is int:
			return _reject(original,"INVALID_EXPECTED_EVENT_SEQ")
		if int(command["expected_event_seq"]) != int(original["event_seq"]):
			return _reject(original,"STALE_STATE")
		if original["phase"] != "PLAYER_PHASE" or original["core"]["battle"]["outcome"] != "ONGOING":
			return _reject(original,"INVALID_PHASE")
		if command.get("confirmed",false) != true:
			return _reject(original,"LAST_SPELL_CONFIRMATION_REQUIRED")
		if str(command.get("casting_mode","FULL")) != "FULL":
			return _reject(original,"LAST_SPELL_FULL_CHANT_ONLY")
		var actor: String = str(command.get("actor_id",""))
		var submitted: Dictionary = LastSpell.commit(original["core"],actor,
			str(command.get("target_actor_id","")),id,config)
		if not submitted["ok"]:
			return _reject(original,str(submitted["error"]))
		var next: Dictionary = original.duplicate(true)
		next["core"] = submitted["core"]
		var output: Array = []
		for wrapped: Dictionary in submitted["events"]:
			_event(next,output,str(wrapped["event"]["kind"]),id,
				{"core_event":wrapped},"m2")
		_event(next,output,"LastSpellCommitted",id,{
			"casting_id":submitted["instance"]["casting_id"],"caster_id":actor,
			"spell_id":submitted["instance"]["spell_id"],
			"planned_resolve_round":submitted["instance"]["planned_resolve_round"],
			"once_used":true,"mode":"FULL","cannot_cancel":true,
			"no_card_instance":true,"cost_paid_once":true})
		var result: Dictionary = Boundary.check_action_outcome(next["core"])
		if not result["ok"]:
			return _reject(original,str(result["error"]))
		next["core"] = result["core"]
		_event(next,output,"BattleOutcomeEvaluated",id,result["event"],"boundary")
		if not validate_state(next):
			return _reject(original,"LAST_SPELL_INVARIANT_BROKEN")
		next["seen_command_ids"].append(id)
		return {"accepted":true,"error":"","state":next,"events":output,
			"state_hash":Model.state_hash(next),"event_hash":Model.event_hash(output)}

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
		# Actual M2 cost transaction receipt is the sole refund base.
		# No client-supplied MP quote is ever trusted.
		var saw_authoritative_payment: bool = false
		for paid_event: Dictionary in committed["events"]:
			if str(paid_event["event"]["kind"]) == "SPCostReservedOnly":
				cast["paid_mp"] = int(paid_event["event"]["details"]["mp_cost"])
				cast["paid_ap"] = int(paid_event["event"]["details"]["ap_cost"])
				saw_authoritative_payment = true
		if not saw_authoritative_payment:
			return _reject(original, "MISSING_AUTHORITATIVE_PAYMENT_RECEIPT")
		next["core"]["battle"]["casting_instances"][cast["casting_id"]] = cast
		next["core"]["battle"]["actors"][resolved["actor_id"]]["status"] = "CONCENTRATING"
		_event(next, output, "CastingStarted", id,
			{"casting_id": cast["casting_id"], "caster_id": cast["caster_id"],
			"card_instance_id": cast["card_instance_id"],
			"planned_resolve_round": cast["planned_resolve_round"],
			"concentrating": true, "base_stability_authority": "BALANCE_PROVISIONAL"})
	else:
		if config.get("m5_damage_enabled",false) == true:
			var magic: Variant = config.get("m5_spell_profiles",{}).get(str(resolved["definition_id"]),null)
			if not magic is Dictionary:
				return _reject(original,"M51_MISSING_SPELL_EFFECT")
			var hit: Dictionary = Damage.resolve(next["core"],str(resolved["actor_id"]),
				str(resolved["target_actor_id"]),magic,{},config,id)
			if not hit["ok"]:
				return _reject(original,str(hit["error"]))
			next["core"] = hit["core"]
			for record: Dictionary in hit["timeline"]:
				if str(record["kind"]) == "core_event":
					_event(next,output,str(record["raw"]["event"]["kind"]),id,{"core_event":record["raw"]},"m2")
				else:
					_event(next,output,str(record["kind"]),id,record,"m5_damage")
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
