extends RefCounted
## Deterministic TEST DRIVER (not Boss AI and not a Domain rule).
## Choices are explicit, finite, reproducible policy commands submitted
## one-by-one to the exact M5 reducer. No scene nodes, clock, auto-pass.
const F = preload("res://tests/fixtures/m5_full_battle_fixture.gd")
const M5 = preload("res://scripts/domain/m5/integration/m5_domain_resolver.gd")
const M4 = preload("res://scripts/domain/m4/integration/m4_domain_resolver.gd")
const M2 = preload("res://scripts/domain/m2/integration/m2_domain_resolver.gd")
const Zones = preload("res://scripts/domain/m2/cards/card_zone_resolver.gd")
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const MAX_COMMANDS: int = 480
const MAX_EVENTS: int = 4500

static func _available(ctx: Dictionary, actor: String) -> bool:
	var b: Dictionary = ctx["state"]["core"]["battle"]
	return str(b["actors"][actor]["status"]) == "ACTIVE" and int(b["actors"][actor]["hp"]) > 0

static func _hand(ctx: Dictionary, actor: String, definition: String) -> String:
	var own: Dictionary = ctx["state"]["core"]["cards"]["actors"][actor]
	for inst: Variant in own["zones"]["hand"]:
		var instance_id: String = str(inst)
		if str(own["instances"][instance_id]["definition_id"]) == definition:
			return instance_id
	return ""

static func _receipt(ctx: Dictionary, kind: String,
		arguments: Dictionary = {}) -> bool:
	var state: Dictionary = ctx["state"]
	if ctx["tape"].size() >= MAX_COMMANDS or state["events"].size() > MAX_EVENTS:
		ctx["error"] = "M55_DRIVER_GUARD_COMMAND_OR_EVENT_CAP"
		return false
	var command_id: String = "m55:"+str(ctx["seed"])+":"+str(ctx["tape"].size())+":"+kind
	var command: Dictionary = {"type":kind,"command_id":command_id,
		"expected_event_seq":int(state["event_seq"])}
	for key: Variant in arguments:
		command[key] = arguments[key]
	var before: String = Model.state_hash(state)
	var applied: Dictionary = M5.apply(state,command,ctx["config"])
	if not applied["accepted"]:
		ctx["rejected"] = int(ctx["rejected"])+1
		if Model.state_hash(applied["state"]) != before or \
				not applied["events"].is_empty():
			ctx["error"] = "M55_NONATOMIC_REJECTION:"+kind
		else:
			ctx["error"] = "M55_POLICY_REJECTED:"+kind+":"+str(applied["error"])
		return false
	ctx["state"] = applied["state"]
	ctx["tape"].append(command)
	if not M2.validate_state(ctx["state"]["core"]) or \
			not M4.validate_state(ctx["state"]) or \
			not Zones.validate_state(ctx["state"]["core"]["cards"]):
		ctx["error"] = "M55_POST_COMMAND_INVARIANT:"+kind
		return false
	var b: Dictionary = ctx["state"]["core"]["battle"]
	for actor: Variant in b["actors"]:
		var unit: Dictionary = b["actors"][actor]
		if int(unit["hp"]) < 0 or int(unit["hp"]) > int(unit["max_hp"]) or \
				int(unit["mp"]) < 0 or int(unit["mp"]) > int(unit["max_mp"]):
			ctx["error"] = "M55_NEGATIVE_OR_EXCESS_RESOURCE:"+str(actor)
			return false
	for field: String in ["current_ap","rp","ap_debt"]:
		if int(b["party_resources"][field]) < 0:
			ctx["error"] = "M55_NEGATIVE_RESOURCE:"+field
			return false
	if ctx["state"]["events"].size() > MAX_EVENTS:
		ctx["error"] = "M55_EVENT_LIMIT"
		return false
	for wrapped: Dictionary in applied["events"]:
		var kind_event: String = str(wrapped.get("kind",""))
		ctx["coverage"][kind_event] = int(ctx["coverage"].get(kind_event,0))+1
		if int(ctx["first_hp0_event_seq"]) == -1 and \
				kind_event == "ActorIncapacitated":
			ctx["first_hp0_event_seq"] = int(wrapped["event_seq"])
	return true

static func _try_sp(ctx: Dictionary, actor: String, definition: String,
		mode: String = "NORMAL") -> bool:
	if not _available(ctx,actor):
		return true
	var b: Dictionary = ctx["state"]["core"]["battle"]
	if int(b["party_resources"]["current_ap"]) < 2:
		return true
	var card: String = _hand(ctx,actor,definition)
	if card.is_empty():
		return true
	var costs: Dictionary = ctx["config"]["definitions"][definition]
	if int(b["actors"][actor]["mp"]) < int(costs["mp_cost"]):
		return true
	var kind: String = "PLAY_TACTICAL_SP_M53"
	var fields: Dictionary = {"actor_id":actor,"target_actor_id":"Boss",
		"card_instance_id":card,"combo_mode":mode}
	if ["burn","ward","regen"].has(definition):
		kind = "USE_EFFECT_SP_M5"
		fields.erase("combo_mode")
		if definition == "ward" or definition == "regen":
			fields["target_actor_id"] = "A" if \
				int(b["actors"]["A"]["hp"]) > 0 else actor
	elif definition == "regular":
		kind = "CAST_SPELL_M4"
		fields.erase("combo_mode")
		fields["casting_mode"] = "CHANTLESS"
	return _receipt(ctx,kind,fields)

static func _try_full(ctx: Dictionary) -> bool:
	if not _available(ctx,"C"):
		return true
	var card: String = _hand(ctx,"C","regular")
	var b: Dictionary = ctx["state"]["core"]["battle"]
	if card.is_empty() or int(b["party_resources"]["current_ap"]) < 2 or \
			int(b["actors"]["C"]["mp"]) < 2:
		return true
	return _receipt(ctx,"CAST_SPELL_M4",{"actor_id":"C",
		"card_instance_id":card,"target_actor_id":"Boss","casting_mode":"FULL"})

static func _try_last(ctx: Dictionary) -> bool:
	if not _available(ctx,"A"):
		return true
	var b: Dictionary = ctx["state"]["core"]["battle"]
	if int(b["party_resources"]["current_ap"]) < 3 or \
			int(b["actors"]["A"]["mp"]) < 3:
		return true
	return _receipt(ctx,"ACTIVATE_LAST_SPELL_M4",{"actor_id":"A",
		"target_actor_id":"Boss","confirmed":true,"casting_mode":"FULL"})

static func _try_basic(ctx: Dictionary, actor: String) -> bool:
	if not _available(ctx,actor):
		return true
	var b: Dictionary = ctx["state"]["core"]["battle"]
	if int(b["party_resources"]["current_ap"]) < 2:
		return true
	return _receipt(ctx,"BASIC_ATTACK_RESOURCE_ONLY",
		{"actor_id":actor,"target_actor_id":"Boss"})

static func _player(ctx: Dictionary) -> bool:
	var round_id: int = int(ctx["state"]["core"]["battle"]["round"])
	# A deterministic, explicitly chosen test policy. Always leaves
	# ≥1 AP convertible to RP, so legal Reaction can be tested.
	if round_id == 1:
		if not _try_sp(ctx,"A","setup"): return false
		# Combo requires a different B actor, its own M2 payment.
		if not _try_sp(ctx,"B","finish","COMBO"): return false
		if not _try_full(ctx): return false
		if not _try_sp(ctx,"A","burn"): return false
		if not _try_sp(ctx,"B","ward"): return false
		if not _try_sp(ctx,"C","regen"): return false
	elif round_id == 2:
		if not _try_last(ctx): return false
		if not _try_sp(ctx,"B","ward"): return false
		if not _try_sp(ctx,"C","regen"): return false
		if not _try_basic(ctx,"C"): return false
	else:
		if not _try_sp(ctx,"B","finish"): return false
		if not _try_sp(ctx,"C","regen"): return false
		if not _try_sp(ctx,"B","ward"): return false
		if not _try_sp(ctx,"C","regular"): return false
		if not _try_basic(ctx,"B"): return false
		if not _try_basic(ctx,"C"): return false
	# When a phase cannot submit a legal SP due to hand resources,
	# EndPhase is a lawful explicit driver choice (not a Reaction auto-pass).
	return true

static func _enemy_round(ctx: Dictionary) -> bool:
	if not _receipt(ctx,"END_PLAYER_PHASE"): return false
	if not _receipt(ctx,"DECLARE_NEXT_ENEMY_ACTION"): return false
	var enemy_action_id: String = str(ctx["state"]["active_enemy_action_id"])
	if not _receipt(ctx,"OPEN_REACTION_WINDOW",{"enemy_action_id":enemy_action_id}):
		return false
	var window: Dictionary = ctx["state"]["reaction_window"]
	if str(window.get("status","")) == "DRAFTING":
		var original_target: String = str(window.get("original_target_actor_id",""))
		var rp: int = int(ctx["state"]["core"]["battle"]["party_resources"]["rp"])
		var guardian: String = ""
		# Guard is only a legal explicit Reaction for ACTIVE living target.
		if rp >= 1 and F.ACTORS.has(original_target) and _available(ctx,original_target):
			guardian = original_target
		if not guardian.is_empty():
			var window_id: String = str(window["window_id"])
			if not _receipt(ctx,"QUEUE_REACTION",{"window_id":window_id,
					"entry":{"kind":"BASIC_GUARD","actor_id":guardian,
						"target_actor_id":guardian}}):
				return false
			if not _receipt(ctx,"CONFIRM_REACTIONS",{"window_id":window_id}):
				return false
		else:
			# Explicit policy PASS only; no timer/FPS-based auto reaction.
			if not _receipt(ctx,"PASS_REACTION",{"window_id":str(window["window_id"])}):
				return false
	if not _receipt(ctx,"RESOLVE_ENEMY_ATTACK_M5",{
			"enemy_action_id":enemy_action_id}):
		return false
	if str(ctx["state"]["core"]["battle"]["outcome"]) != "ONGOING":
		return true
	if not _receipt(ctx,"END_ENEMY_PHASE"): return false
	if not _receipt(ctx,"START_PLAYER_PHASE"): return false
	return true

static func run(seed: int) -> Dictionary:
	var start_ms: int = Time.get_ticks_msec()
	var original: Dictionary = F.initial(seed)
	if original.is_empty():
		return {"ok":false,"error":"M55_INITIAL_ENCOUNTER_FAILED","seed":seed}
	var ctx: Dictionary = {"seed":seed,"config":F.config(),
		"initial":original.duplicate(true),"state":original,
		"tape":[],"coverage":{},"rejected":0,"first_hp0_event_seq":-1,"error":""}
	for _round: int in range(F.MAX_ROUNDS):
		if str(ctx["state"]["core"]["battle"]["outcome"]) != "ONGOING":
			break
		if str(ctx["state"]["phase"]) != "PLAYER_PHASE":
			ctx["error"] = "M55_UNEXPECTED_PHASE_START"
			break
		if not _player(ctx):
			break
		if str(ctx["state"]["core"]["battle"]["outcome"]) != "ONGOING":
			break
		if not _enemy_round(ctx):
			break
	var final: Dictionary = ctx["state"]
	var battle: Dictionary = final["core"]["battle"]
	var outcome: String = str(battle["outcome"])
	if ctx["error"].is_empty() and not ["VICTORY","DEFEAT"].has(outcome):
		ctx["error"] = "M55_NO_TERMINAL_OUTCOME_WITHIN_LIMIT"
	var report: Dictionary = {"ok":ctx["error"].is_empty(),"error":ctx["error"],
		"seed":seed,"content_version":str(ctx["config"]["m5_5_content_version"]),
		"ruleset_version":str(battle["ruleset_version"]),
		"prng_version":str(battle["rng"]["algorithm"]),
		"accepted":ctx["tape"].size(),"rejected":ctx["rejected"],
		"rounds":int(battle["round"]),"events":final["events"].size(),
		"first_hp0_event_seq":ctx["first_hp0_event_seq"],
		"fallback_count":int(ctx["coverage"].get("BossBreakRecovered",0)),
		"outcome":outcome,"coverage":ctx["coverage"],
		"initial_hash":Model.state_hash(ctx["initial"]),
		"event_hash":Model.event_hash(final["events"]),
		"final_hash":Model.state_hash(final),
		"tape_hash":Model.event_hash(ctx["tape"]),
		"elapsed_ms":Time.get_ticks_msec()-start_ms,
		"initial":ctx["initial"],"final":final,"tape":ctx["tape"],
		"config":ctx["config"]}
	return report

static func replay(report: Dictionary) -> Dictionary:
	if not report.get("ok",false):
		return {"ok":false,"error":"M55_INVALID_BATTLE_REPORT"}
	var result: Dictionary = M5.replay(report["initial"],report["tape"],report["config"])
	if not result["accepted"]:
		return {"ok":false,"error":"M55_REPLAY_COMMAND_REJECTED:"+str(result["error"])}
	if result["event_hash"] != report["event_hash"] or \
			result["state_hash"] != report["final_hash"] or \
			Model.event_hash(result["events"]) != report["event_hash"] or \
			Model.state_hash(result["state"]) != report["final_hash"]:
		return {"ok":false,"error":"M55_REPLAY_HASH_MISMATCH"}
	return {"ok":true,"error":"","state_hash":result["state_hash"],
		"event_hash":result["event_hash"]}
