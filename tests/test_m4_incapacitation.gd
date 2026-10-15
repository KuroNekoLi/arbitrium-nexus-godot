extends SceneTree
## M4.4 CORE-02 HP0 and Revive exact event boundary; fixture ONLY, no M5 hit engine.
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const Draw = preload("res://scripts/domain/m2/cards/draw_resolver.gd")
const Zones = preload("res://scripts/domain/m2/cards/card_zone_resolver.gd")
const M2 = preload("res://scripts/domain/m2/integration/m2_domain_resolver.gd")
const Phase = preload("res://scripts/domain/m3/phase/phase_engine.gd")
const M4 = preload("res://scripts/domain/m4/integration/m4_domain_resolver.gd")
const Last = preload("res://scripts/domain/m4/last_spell/last_spell_resolver.gd")
const Instance = preload("res://scripts/domain/m4/casting/casting_instance_resolver.gd")
const SEED: int = 20261014
var pass_count: int = 0
var fail_count: int = 0
var config: Dictionary = {}
func check(id: String, value: bool) -> void:
	if value:
		pass_count += 1
		print("PASS ",id)
	else:
		fail_count += 1
		printerr("FAIL ",id)

func settings() -> Dictionary:
	var costs: Variant = JSON.parse_string(FileAccess.get_file_as_string(
		"res://resources/combat/rulesets/m2_2_provisional_costs.json"))
	var r: Variant = JSON.parse_string(FileAccess.get_file_as_string(
		"res://resources/combat/rulesets/m2_1_provisional_resources.json"))
	if not costs is Dictionary or not r is Dictionary:
		return {}
	var resources: Dictionary = costs.duplicate(true)
	resources["basic_attack_ap_cost"] = int(r["basic_attack_ap_cost"])
	resources["basic_attack_mp_gain"] = int(r["basic_attack_mp_gain"])
	return {"costs":costs,"resources":resources,
		"definitions":{"regular":{"card_id":"regular","ap_cost":1,"mp_cost":2}},
		"casting_profiles":{"regular":{"spell_id":"regular","allowed_modes":["CHANTLESS","FULL"],"base_stability":10}},
		"last_spell_slots":{
			"A":{"spell_id":"nova","unlocked":true,"planned_delay_rounds":2,"base_stability":10},
			"B":{"spell_id":"b_nova","unlocked":false,"planned_delay_rounds":2,"base_stability":10},
			"C":{"spell_id":"c_nova","unlocked":true,"planned_delay_rounds":2,"base_stability":10}},
		"last_spell_cost_definitions":{
			"nova":{"card_id":"nova","ap_cost":2,"mp_cost":3},
			"b_nova":{"card_id":"b_nova","ap_cost":2,"mp_cost":2},
			"c_nova":{"card_id":"c_nova","ap_cost":2,"mp_cost":3}},
		"last_spell_instability":{"authority":"BALANCE_PROVISIONAL",
			"stability_reset":10,"weaken_numerator":3,"weaken_denominator":4},
		"reaction_definitions":{},
		"disruption_effects":{
			"destab1":{"channel":"DIRECT_CASTING_INSTANCE","disruption_power":12,"authority":"BALANCE_PROVISIONAL"},
			"destab2":{"channel":"DIRECT_CASTING_INSTANCE","disruption_power":12,"authority":"BALANCE_PROVISIONAL"},
			"destab3":{"channel":"DIRECT_CASTING_INSTANCE","disruption_power":12,"authority":"BALANCE_PROVISIONAL"}},
		"m4_4_trusted_life_fixture":true,"m4_4_verified_hit_fixture":true,
		"m4_4_life_effects":{
			"hp0_A":{"authority":"M4_4_TRUSTED_FIXTURE_ONLY","operation":"HP_ZERO",
				"target_actor_id":"A","hp_after":0},
			"hp0_B":{"authority":"M4_4_TRUSTED_FIXTURE_ONLY","operation":"HP_ZERO",
				"target_actor_id":"B","hp_after":0},
			"revive_A":{"authority":"M4_4_TRUSTED_FIXTURE_ONLY","operation":"REVIVE",
				"target_actor_id":"A","hp_after":35,"revive_tag":true},
			"normal_heal":{"authority":"M4_4_TRUSTED_FIXTURE_ONLY","operation":"HEAL",
				"target_actor_id":"A","hp_after":35,"revive_tag":false}
		},
		"m4_2_fixture_authorized":true,"m4_dual_cast_enabled":true,
		"m4_2_verified_hit_fixture":false,"m4_2_internal_refund":true,
		"trigger_rules":[]}

func initial() -> Dictionary:
	var loadouts: Dictionary = {}
	var contexts: Dictionary = {}
	var owned: Dictionary = {}
	for id: String in ["A","B","C"]:
		var cards: Array = []
		for i: int in range(12):
			cards.append("regular")
		loadouts[id] = cards
		contexts[id] = {"actor_id":id,"variant_id":"default","tags":[]}
		owned[id] = {"regular":12}
	var started: Dictionary = Draw.start_battle(loadouts,contexts,
		{"regular":{"id":"regular","kind":"SP"}},owned,SEED)
	if not started["accepted"]:
		return {}
	var battle: Dictionary = Model.make_state(["A","B","C"],["Boss"],SEED)
	for id: String in ["A","B","C"]:
		battle["actors"][id]["mp"] = 8
		battle["actors"][id]["max_mp"] = 10
	return Phase.make_state(M2.make_state(battle,started["state"]),[
		{"intent_id":"lastspell-test","enemy_id":"Boss","action_order":1,
			"created_seq":0,"publicly_declared":true,"target_scope":"SINGLE",
			"target_ids":["A"],"hit_count":1,"damage_type":"MAGICAL",
			"requires_reaction_window":true}])

func cmd(s: Dictionary, kind: String, id: String, args: Dictionary = {}) -> Dictionary:
	var req: Dictionary = {"type":kind,"command_id":id,"expected_event_seq":int(s["event_seq"])}
	for key: Variant in args:
		req[key] = args[key]
	return req

func perform(s: Dictionary, tape: Array[Dictionary], kind: String, id: String,
		args: Dictionary = {}) -> Dictionary:
	var instruction: Dictionary = cmd(s,kind,id,args)
	var result: Dictionary = M4.apply(s,instruction,config)
	if result["accepted"]:
		tape.append(instruction)
	return result

func wrong(s: Dictionary, kind: String, id: String, args: Dictionary, error: String,
		cfg: Dictionary = {}) -> bool:
	var result: Dictionary = M4.apply(s,cmd(s,kind,id,args),
		config if cfg.is_empty() else cfg)
	return not result["accepted"] and str(result["error"]) == error \
		and Model.state_hash(result["state"]) == Model.state_hash(s) \
		and result["events"].is_empty()

func last_command(actor: String = "A") -> Dictionary:
	return {"actor_id":actor,"target_actor_id":"Boss","casting_mode":"FULL","confirmed":true}

func index_of(events: Array, kind: String) -> int:
	for i: int in range(events.size()):
		if str(events[i]["kind"]) == kind:
			return i
	return -1

func advance_enemy(s: Dictionary, tape: Array[Dictionary], tag: String) -> Dictionary:
	var ending: Dictionary = perform(s,tape,"END_PLAYER_PHASE",tag+"-end")
	if not ending["accepted"]:
		return ending
	var declared: Dictionary = perform(ending["state"],tape,"DECLARE_NEXT_ENEMY_ACTION",tag+"-declare")
	if not declared["accepted"]:
		return declared
	var opened: Dictionary = perform(declared["state"],tape,"OPEN_REACTION_WINDOW",tag+"-open",
		{"enemy_action_id":str(declared["state"]["active_enemy_action_id"])})
	if not opened["accepted"]:
		return opened
	return perform(opened["state"],tape,"PASS_REACTION",tag+"-pass",
		{"window_id":str(opened["state"]["reaction_window"]["window_id"])})

func end_enemy(s: Dictionary, tape: Array[Dictionary], tag: String) -> Dictionary:
	var completed: Dictionary = perform(s,tape,"COMPLETE_ENEMY_ACTION_FIXTURE",tag+"-complete",
		{"enemy_action_id":str(s["active_enemy_action_id"])})
	if not completed["accepted"]:
		return completed
	return perform(completed["state"],tape,"END_ENEMY_PHASE",tag+"-enemy-end")


func hit(s: Dictionary, tape: Array[Dictionary], id: String, effect: String = "hp0_A") -> Dictionary:
	return perform(s,tape,"APPLY_INCAPACITATION_M4_FIXTURE",id,{
		"effect_id":effect,
		"source_enemy_action_id":str(s["active_enemy_action_id"]),
		"verified_hit_fixture":true})

func _init() -> void:
	config = settings()
	var seed: Dictionary = initial()
	if seed.is_empty() or config.is_empty():
		printerr("M4_4_BAD_SETUP"); quit(1); return
	var initial_hash: String = Model.state_hash(seed)
	var tape: Array[Dictionary] = []
	var submitted: Dictionary = perform(seed,tape,"ACTIVATE_LAST_SPELL_M4","last-start",last_command())
	if not submitted["accepted"]:
		printerr("M4_4_SUBMIT_FAILED ",submitted["error"]);quit(1);return
	var s: Dictionary = submitted["state"]
	var card_snapshot: Dictionary = s["core"]["cards"].duplicate(true)
	var payment_snapshot: Array = s["core"]["battle"]["paid_cost_command_ids"].duplicate(true)
	var mp_paid: int = int(s["core"]["battle"]["actors"]["A"]["mp"])
	var ap_paid: int = int(s["core"]["battle"]["party_resources"]["current_ap"])
	var cost_count: int = payment_snapshot.size()
	check("P2-LAST-01-COMMITTED_ONCE",int(s["core"]["battle"]["last_spell_used_by_actor"]["A"]) == 1)
	check("P2-LAST-01-T3_RELEASE_SCHEDULED",int(s["core"]["battle"]["casting_instances"]["last:last-start"]["planned_resolve_round"]) == 3)
	check("P2-LAST-01-COST_PAID_AT_START",ap_paid == 4 and mp_paid == 5 and cost_count == 1)
	check("P2-LAST-01-NO_CARD_ZONE_FOR_LAST",s["core"]["cards"] == card_snapshot
		and s["core"]["battle"]["casting_instances"]["last:last-start"]["card_instance_id"] == "")
	# Round1 no HP0, run through genuine M3 reaction and phase boundary.
	var e1: Dictionary = advance_enemy(s,tape,"r1")
	if not e1["accepted"]:
		printerr("M4_4_R1_SETUP_FAILED ",e1["error"]);quit(1);return
	var closed1: Dictionary = end_enemy(e1["state"],tape,"r1")
	if not closed1["accepted"]:
		printerr("M4_4_R1_END_FAILED ",closed1["error"]);quit(1);return
	var opened2: Dictionary = perform(closed1["state"],tape,"START_PLAYER_PHASE","enter-r2")
	if not opened2["accepted"]:
		printerr("M4_4_R2_START_FAILED ",opened2["error"]);quit(1);return
	s = opened2["state"]
	check("P2-LAST-01-T2_NO_PREMATURE_RELEASE",s["core"]["battle"]["casting_instances"].has("last:last-start")
		and index_of(opened2["events"],"LastSpellReleased") == -1)
	var e2: Dictionary = advance_enemy(s,tape,"r2")
	if not e2["accepted"]:
		printerr("M4_4_R2_ENEMY_FAILED ",e2["error"]);quit(1);return
	s = e2["state"]
	check("PRE3-13-HP0_NOT_CLIENT_COMMAND",wrong(s,"APPLY_INCAPACITATION_M4_FIXTURE",
		"inject-hp",{"source_enemy_action_id":str(s["active_enemy_action_id"]),
			"effect_id":"hp0_A","verified_hit_fixture":true,"hp_after":0},
		"UNTRUSTED_LIFE_PAYLOAD"))
	check("PRE3-13-HIT_REQUIRES_PROOF",wrong(s,"APPLY_INCAPACITATION_M4_FIXTURE",
		"no-hit",{"source_enemy_action_id":str(s["active_enemy_action_id"]),
			"effect_id":"hp0_A"},"M5_VERIFIED_HIT_REQUIRED"))
	check("PRE3-13-HIT_SOURCE_MUST_MATCH",wrong(s,"APPLY_INCAPACITATION_M4_FIXTURE",
		"wrong-action",{"source_enemy_action_id":"wrong",
			"effect_id":"hp0_A","verified_hit_fixture":true},"HP0_ACTION_ID_MISMATCH"))
	check("PRE3-13-UNRELATED_ACTOR_CANNOT_BE_KILLED",wrong(s,"APPLY_INCAPACITATION_M4_FIXTURE",
		"wrong-recipient",{"source_enemy_action_id":str(s["active_enemy_action_id"]),
			"effect_id":"hp0_B","verified_hit_fixture":true},"HP0_PROTECT_RECIPIENT_MISMATCH"))
	check("PRE3-13-UNKNOWN_EFFECT_REJECTED",wrong(s,"APPLY_INCAPACITATION_M4_FIXTURE",
		"unknown",{"source_enemy_action_id":str(s["active_enemy_action_id"]),
			"effect_id":"arbitrary","verified_hit_fixture":true},"UNKNOWN_LIFE_FIXTURE"))
	var off: Dictionary = config.duplicate(true)
	off["m4_4_trusted_life_fixture"] = false
	check("PRE3-13-GATED_FIXTURE_NOT_PUBLIC",wrong(s,"APPLY_INCAPACITATION_M4_FIXTURE",
		"not-trusted",{"source_enemy_action_id":str(s["active_enemy_action_id"]),
			"effect_id":"hp0_A","verified_hit_fixture":true},"M5_HP_ENGINE_NOT_AVAILABLE",off))
	check("PRE3-13-ACTIVE_CAST_BEFORE_HIT",s["core"]["battle"]["actors"]["A"]["status"] == "CONCENTRATING"
		and s["core"]["battle"]["casting_instances"].has("last:last-start"))
	var before_hit_rng: String = Model.state_hash(s["core"]["battle"]["rng"])
	var before_hit_card: String = Model.state_hash(s["core"]["cards"])
	var killed: Dictionary = hit(s,tape,"t2-lethal")
	if not killed["accepted"]:
		printerr("M4_4_HP0_REJECTED ",killed["error"]);quit(1);return
	s = killed["state"]
	check("P2-LAST-02-INSTANT_HP0",s["core"]["battle"]["actors"]["A"]["hp"] == 0
		and s["core"]["battle"]["actors"]["A"]["status"] == "INCAPACITATED")
	check("P2-LAST-02-HIT_EVENT_CHAIN",
		index_of(killed["events"],"ActorIncapacitated") >= 0
		and index_of(killed["events"],"ActorIncapacitated") <
			index_of(killed["events"],"LastSpellInvalidated")
		and index_of(killed["events"],"LastSpellInvalidated") <
			index_of(killed["events"],"ScheduledEffectCancelled")
		and index_of(killed["events"],"ScheduledEffectCancelled") <
			index_of(killed["events"],"BattleOutcomeEvaluated"))
	check("CORE-02-INVALIDATE_CAUSE",killed["events"][index_of(killed["events"],"LastSpellInvalidated")]["details"]["reason"] == "CASTER_INCAPACITATED")
	check("CORE-02-PENDING_INSTANCE_ERASED_NOW",not s["core"]["battle"]["casting_instances"].has("last:last-start"))
	check("CORE-02-SCHEDULE_CANCELED_NOW",index_of(killed["events"],"ScheduledEffectCancelled") >= 0
		and index_of(killed["events"],"LastSpellReleased") == -1
		and index_of(killed["events"],"LastSpellEffectDeferredToM5") == -1)
	check("P2-LAST-02-CANONICAL_INVALIDATED_HISTORY",
		s["core"]["battle"]["last_spell_invalidated_by_actor"]["A"]["casting_id"] == "last:last-start"
		and s["core"]["battle"]["last_spell_invalidated_by_actor"]["A"]["once_used"])
	check("P2-LAST-03-ONCE_PER_BATTLE_NOT_REFUNDED",s["core"]["battle"]["last_spell_used_by_actor"]["A"] == 1)
	check("P2-LAST-03-NO_MP_REFUND",s["core"]["battle"]["actors"]["A"]["mp"] == mp_paid
		and index_of(killed["events"],"MPRestored") == -1)
	check("P2-LAST-03-NO_AP_REFUND",s["core"]["battle"]["party_resources"]["current_ap"] == 0
		and s["core"]["battle"]["paid_cost_command_ids"] == payment_snapshot)
	check("PRE3-14-DEBT_NOT_REFUNDED",s["core"]["battle"]["party_resources"]["ap_debt"] == 0)
	check("PRE3-13-CARD_ZONES_FROZEN",Model.state_hash(s["core"]["cards"]) == before_hit_card
		and Zones.validate_state(s["core"]["cards"]))
	check("PRE3-13-RNG_UNCHANGED_ON_HP0",Model.state_hash(s["core"]["battle"]["rng"]) == before_hit_rng)
	check("P2-LAST-02-M5_DAMAGE_NOT_INVENTED",s["core"]["battle"]["actors"]["Boss"]["hp"] == 100)
	check("P2-LAST-02-OUTCOME_STILL_ONGOING",s["core"]["battle"]["outcome"] == "ONGOING")
	check("P2-LAST-02-A_CANNOT_REACT_OR_ATTACK",wrong(s,"BASIC_ATTACK_RESOURCE_ONLY",
		"attack-while-zero",{"actor_id":"A"},"ACTOR_UNAVAILABLE_OR_PHASE"))
	check("P2-LAST-02-CANT_REPEAT_HP_ZERO",wrong(s,"APPLY_INCAPACITATION_M4_FIXTURE",
		"second-kill",{"source_enemy_action_id":str(s["active_enemy_action_id"]),
			"effect_id":"hp0_A","verified_hit_fixture":true},"ACTOR_ALREADY_AT_ZERO_HP"))
	check("P2-LAST-02-STALE_SEQUENCE_REJECTED",not M4.apply(s,cmd(seed,
		"APPLY_INCAPACITATION_M4_FIXTURE","stale",{}),config)["accepted"])
	check("P2-LAST-02-DUPLICATE_COMMAND_REJECTED",wrong(s,"APPLY_INCAPACITATION_M4_FIXTURE",
		"t2-lethal",{"effect_id":"hp0_A"},"DUPLICATE_COMMAND"))
	var closed2: Dictionary = end_enemy(s,tape,"r2")
	if not closed2["accepted"]:
		printerr("M4_4_CLOSE_R2_FAILED ",closed2["error"]);quit(1);return
	var opened3: Dictionary = perform(closed2["state"],tape,"START_PLAYER_PHASE","enter-r3")
	if not opened3["accepted"]:
		printerr("M4_4_OPEN_R3_FAILED ",opened3["error"]);quit(1);return
	s = opened3["state"]
	check("P2-LAST-01-NO_RELEASE_T3",index_of(opened3["events"],"LastSpellReleased") == -1
		and index_of(opened3["events"],"LastSpellEffectDeferredToM5") == -1
		and not s["core"]["battle"]["casting_instances"].has("last:last-start"))
	check("P2-LAST-02-HAND_FROZEN_AFTER_ROUND",s["core"]["cards"]["actors"]["A"]["zones"]["hand"] ==
		card_snapshot["actors"]["A"]["zones"]["hand"])
	check("PRE3-13-ORDINARY_HEAL_CANNOT_REVIVE",wrong(s,"APPLY_REVIVE_M4_FIXTURE",
		"heal-not-revive",{"effect_id":"normal_heal"},"REVIVE_TAG_REQUIRED"))
	check("P2-LAST-03-REVIVE_REQUIRES_PROVISIONED_FIXTURE",wrong(s,"APPLY_REVIVE_M4_FIXTURE",
		"untrusted-revive",{"effect_id":"arbitrary"},"UNKNOWN_LIFE_FIXTURE"))
	var revived: Dictionary = perform(s,tape,"APPLY_REVIVE_M4_FIXTURE","revive-once",{
		"effect_id":"revive_A"})
	if not revived["accepted"]:
		printerr("M4_4_REVIVE_FAILED ",revived["error"]);quit(1);return
	s = revived["state"]
	check("P2-LAST-04-REVIVE_HP_RESTORED",s["core"]["battle"]["actors"]["A"]["hp"] == 35
		and s["core"]["battle"]["actors"]["A"]["status"] == "ACTIVE")
	check("P2-LAST-04-CANNOT_REVIVE_OLD_SPELL",not s["core"]["battle"]["casting_instances"].has("last:last-start"))
	check("P2-LAST-04-ONCE_USED_STAYS_USED",s["core"]["battle"]["last_spell_used_by_actor"]["A"] == 1)
	check("P2-LAST-04-INVALIDATED_HISTORY_PERSISTS",s["core"]["battle"]["last_spell_invalidated_by_actor"].has("A"))
	check("P2-LAST-04-STILL_NO_MP_REFUND",s["core"]["battle"]["actors"]["A"]["mp"] == mp_paid)
	check("P2-LAST-04-LAST_CANNOT_START_AGAIN",wrong(s,"ACTIVATE_LAST_SPELL_M4",
		"recast-after-revive",last_command(),"LAST_SPELL_ALREADY_USED"))
	check("P2-LAST-04-CANCEL_NEVER_ACCEPTED",wrong(s,"CANCEL_CAST","cancel-old",
		{"casting_id":"last:last-start"},"FEATURE_NOT_IMPLEMENTED_M3_1"))
	check("P2-LAST-04-DUPLICATE_REVIVE_REJECTED",wrong(s,"APPLY_REVIVE_M4_FIXTURE",
		"revive-twice",{"effect_id":"revive_A"},"REVIVE_REQUIRES_INCAPACITATED"))
	var replay: Dictionary = M4.replay(seed,tape,config)
	check("P2-LAST-05-REPLAY_ACCEPTED",replay["accepted"])
	check("P2-LAST-05-REPLAY_IDENTICAL_FINAL",replay["accepted"]
		and replay["state_hash"] == Model.state_hash(s))
	check("P2-LAST-05-REPLAY_IDENTICAL_EVENTS",replay["accepted"]
		and replay["event_hash"] == Model.event_hash(s["events"]))
	check("P2-LAST-05-INITIAL_SNAPSHOT_UNCHANGED",Model.state_hash(seed) == initial_hash)
	var tape_bad: Array[Dictionary] = tape.duplicate(true)
	tape_bad[4]["expected_event_seq"] = -1
	check("P2-LAST-05-STALE_TAPE_FAIL_CLOSED",not M4.replay(seed,tape_bad,config)["accepted"])
	# Ordinary Full Chant HP0 is NOT a CastingInterrupt: its physical card
	# moves Casting→Discard without an M-D22 refund.
	var normal_seed: Dictionary = initial()
	var card: String = str(normal_seed["core"]["cards"]["actors"]["A"]["zones"]["hand"][0])
	var normal_cast: Dictionary = M4.apply(normal_seed,cmd(normal_seed,"CAST_SPELL_M4",
		"normal-cast",{"actor_id":"A","casting_mode":"FULL",
			"card_instance_id":card,"target_actor_id":"Boss"}),config)
	if not normal_cast["accepted"]:
		printerr("M4_4_NORMAL_SETUP_FAILED ",normal_cast["error"]);quit(1);return
	var n_tape: Array[Dictionary] = []
	var normal_enemy: Dictionary = advance_enemy(normal_cast["state"],n_tape,"normal-enemy")
	if not normal_enemy["accepted"]:
		printerr("M4_4_NORMAL_ENEMY_FAILED ",normal_enemy["error"]);quit(1);return
	var normal_hp: int = int(normal_enemy["state"]["core"]["battle"]["actors"]["A"]["mp"])
	var normal_kill: Dictionary = hit(normal_enemy["state"],n_tape,"normal-hp0")
	check("PRE3-13-ORDINARY_FULL_HP0_ACCEPTED",normal_kill["accepted"])
	if normal_kill["accepted"]:
		var n: Dictionary = normal_kill["state"]
		check("PRE3-13-ORDINARY_FULL_INVALIDATED",n["core"]["battle"]["casting_instances"].is_empty()
			and n["core"]["battle"]["actors"]["A"]["status"] == "INCAPACITATED")
		check("PRE3-13-ORDINARY_CARD_MOVED",Zones.location(n["core"]["cards"],"A",card) == "discard"
			and Zones.validate_state(n["core"]["cards"]))
		check("PRE3-13-ORDINARY_NO_MP_REFUND",n["core"]["battle"]["actors"]["A"]["mp"] == normal_hp
			and index_of(normal_kill["events"],"CastingInterrupted") == -1
			and index_of(normal_kill["events"],"MPRestored") == -1)
		check("PRE3-13-ORDINARY_EXACT_INVALIDATION",index_of(normal_kill["events"],"CastingInvalidated") > 0
			and index_of(normal_kill["events"],"ScheduledEffectCancelled") >= 0)
	# After a SUCCESSFUL released Last Spell, HP0 cannot retroactively
	# erase already emitted legal release/effect contract. Revive stays EXHAUSTED.
	var success_seed: Dictionary = initial()
	var done_tape: Array[Dictionary] = []
	var success_cast: Dictionary = perform(success_seed,done_tape,"ACTIVATE_LAST_SPELL_M4",
		"success-last",last_command())
	var active: Dictionary = success_cast["state"]
	for round_n: int in [1,2]:
		var e: Dictionary = advance_enemy(active,done_tape,"success-r"+str(round_n))
		if not e["accepted"]:
			printerr("M4_4_SUCCESS_ENEMY_FAILED ",e["error"]);quit(1);return
		var closed: Dictionary = end_enemy(e["state"],done_tape,"success-r"+str(round_n))
		if not closed["accepted"]:
			printerr("M4_4_SUCCESS_CLOSE_FAILED ",closed["error"]);quit(1);return
		var opened: Dictionary = perform(closed["state"],done_tape,"START_PLAYER_PHASE",
			"success-enter-r"+str(round_n+1))
		if not opened["accepted"]:
			printerr("M4_4_SUCCESS_OPEN_FAILED ",opened["error"]);quit(1);return
		active = opened["state"]
	check("P2-LAST-06-SUCCESS_FIRST",active["core"]["battle"]["actors"]["A"]["status"] == "EXHAUSTED"
		and active["core"]["battle"]["last_spell_resolved_by_actor"]["A"])
	check("P2-LAST-06-SUCCESS_EFFECT_ALREADY_PUBLISHED",index_of(active["events"],
		"LastSpellEffectDeferredToM5") >= 0)
	var success_enemy: Dictionary = advance_enemy(active,done_tape,"success-r3")
	if not success_enemy["accepted"]:
		printerr("M4_4_SUCCESS_R3_ENEMY_FAILED ",success_enemy["error"]);quit(1);return
	var after_success_kill: Dictionary = hit(success_enemy["state"],done_tape,"post-release-hp0")
	check("P2-LAST-06-EXHAUSTED_CAN_BE_HIT",after_success_kill["accepted"]
		and after_success_kill["state"]["core"]["battle"]["actors"]["A"]["status"] == "INCAPACITATED")
	check("P2-LAST-06-NO_RETROACTIVE_INVALIDATION",after_success_kill["accepted"]
		and index_of(after_success_kill["events"],"LastSpellInvalidated") == -1
		and after_success_kill["state"]["core"]["battle"]["last_spell_resolved_by_actor"]["A"])
	if after_success_kill["accepted"]:
		var post_kill_end: Dictionary = end_enemy(after_success_kill["state"],done_tape,"success-r3")
		var post_kill_round: Dictionary = perform(post_kill_end["state"],done_tape,
			"START_PLAYER_PHASE","success-enter-r4")
		var post_revival: Dictionary = perform(post_kill_round["state"],done_tape,
			"APPLY_REVIVE_M4_FIXTURE","post-release-revive",{"effect_id":"revive_A"})
		check("PRE3-14-EXHAUSTED_PERSISTS_AFTER_REVIVE",post_revival["accepted"]
			and post_revival["state"]["core"]["battle"]["actors"]["A"]["status"] == "EXHAUSTED")
		check("P2-LAST-06-RELEASE_HISTORY_UNCHANGED",post_revival["accepted"]
			and post_revival["state"]["core"]["battle"]["last_spell_resolved_by_actor"]["A"]
			and not post_revival["state"]["core"]["battle"].get("last_spell_invalidated_by_actor",{}).has("A"))
		check("PRE3-14-EXHAUSTED_CANNOT_ATTACK_AFTER_REVIVE",wrong(
			post_revival["state"],"BASIC_ATTACK_RESOURCE_ONLY","post-release-attack",
			{"actor_id":"A"},"ACTOR_UNAVAILABLE_OR_PHASE"))
	print("M4_4_REPLAY seed=",SEED," commands=",tape.size(),
		" initial=",initial_hash," events=",Model.event_hash(s["events"]),
		" final=",Model.state_hash(s))
	print("M4_4_TEST_REPORT executed=",pass_count+fail_count,
		" passed=",pass_count," failed=",fail_count)
	if fail_count == 0:
		print("M4_4_INVALIDATION_DOMAIN_VERIFIED")
	quit(0 if fail_count == 0 else 1)
