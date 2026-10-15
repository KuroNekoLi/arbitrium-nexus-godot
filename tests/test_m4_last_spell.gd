extends SceneTree
## M4.3 actual Godot Last Spell domain test, no M5 damage/HP0 simulation.
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

func _init() -> void:
	config = settings()
	var seed: Dictionary = initial()
	if seed.is_empty() or config.is_empty():
		printerr("M4_3_BAD_FIXTURE")
		quit(1)
		return
	var initial_hash: String = Model.state_hash(seed)
	var quote: Dictionary = Last.inspect(seed["core"],"A",config)
	check("LAST-001-PRECONFIRM_QUOTE",quote["ok"] and quote["requires_confirmation"]
		and quote["irreversible"] and quote["quote"]["mp_cost"] == 3
		and quote["success_consequence"] == "EXHAUSTED_FOR_REMAINDER_OF_BATTLE")
	check("LAST-001-LOCKED_VARIANT_REJECTED",Last.inspect(seed["core"],"B",config)["error"] == "LAST_SPELL_LOCKED")
	check("LAST-001-WRONG_ACTOR_REJECTED",Last.inspect(seed["core"],"Boss",config)["error"] == "ACTOR_NOT_FOUND")
	check("LAST-001-CONFIRM_MANDATORY",wrong(seed,"ACTIVATE_LAST_SPELL_M4","no-confirm",
		{"actor_id":"A","target_actor_id":"Boss"},"LAST_SPELL_CONFIRMATION_REQUIRED"))
	var instant: Dictionary = last_command()
	instant["casting_mode"] = "CHANTLESS"
	check("LAST-001-CHANTLESS_FORBIDDEN",wrong(seed,"ACTIVATE_LAST_SPELL_M4",
		"no-instant",instant,"LAST_SPELL_FULL_CHANT_ONLY"))
	check("LAST-001-MISSING_TARGET",wrong(seed,"ACTIVATE_LAST_SPELL_M4",
		"no-target",{"actor_id":"A","confirmed":true},"INVALID_LAST_SPELL_TARGET"))
	var empty_mp: Dictionary = seed.duplicate(true)
	empty_mp["core"]["battle"]["actors"]["A"]["mp"] = 0
	check("LAST-001-MP_FAILED_ATOMIC",wrong(empty_mp,"ACTIVATE_LAST_SPELL_M4",
		"poor",last_command(),"INSUFFICIENT_MP"))
	var no_slot: Dictionary = config.duplicate(true)
	no_slot["last_spell_slots"]["A"]["unlocked"] = false
	check("LAST-001-UNLOCK_ENFORCED",wrong(seed,"ACTIVATE_LAST_SPELL_M4",
		"locked",last_command(),"LAST_SPELL_LOCKED",no_slot))
	var broken: Dictionary = config.duplicate(true)
	broken["last_spell_slots"]["A"]["planned_delay_rounds"] = 0
	check("LAST-001-TIMELINE_MUST_BE_AUTHORIZED",wrong(seed,"ACTIVATE_LAST_SPELL_M4",
		"missing-delay",last_command(),"MISSING_LAST_SPELL_TIMELINE_FIXTURE",broken))
	var tape: Array[Dictionary] = []
	var submit: Dictionary = perform(seed,tape,"ACTIVATE_LAST_SPELL_M4","start-nova",last_command())
	if not submit["accepted"]:
		printerr("M4_3_START_FAILURE ",submit["error"])
		quit(1)
		return
	var s: Dictionary = submit["state"]
	check("LAST-001-SUBMIT_ACCEPTED",submit["accepted"] and M4.validate_state(s))
	check("LAST-001-ONCE_USED_COMMITTED",s["core"]["battle"]["last_spell_used_by_actor"]["A"] == 1)
	check("LAST-001-NO_CARD_ZONE_MOVEMENT",Zones.validate_state(s["core"]["cards"])
		and s["core"]["cards"] == seed["core"]["cards"])
	check("LAST-001-AP_MP_ONCE",s["core"]["battle"]["party_resources"]["current_ap"] == 4
		and s["core"]["battle"]["actors"]["A"]["mp"] == 5
		and s["core"]["battle"]["paid_cost_command_ids"].size() == 1)
	check("LAST-001-BASE_AP_UNCHANGED",s["core"]["battle"]["party_resources"]["base_ap"] == 6)
	check("LAST-001-FULL_ONLY_CONCENTRATING",s["core"]["battle"]["actors"]["A"]["status"] == "CONCENTRATING")
	var x: Dictionary = s["core"]["battle"]["casting_instances"]["last:start-nova"]
	check("LAST-001-UNIQUE_SLOT_NOT_HAND",x["card_instance_id"] == "" and x["kind"] == "LAST_SPELL"
		and x["planned_resolve_round"] == 3 and x["paid_ap"] == 2 and x["paid_mp"] == 3)
	check("LAST-001-CANNOT_CANCEL",wrong(s,"CANCEL_CAST","cancel-ls",
		{"casting_id":"last:start-nova"},"FEATURE_NOT_IMPLEMENTED_M3_1"))
	check("LAST-001-NO_SECOND_ACTIVATION",wrong(s,"ACTIVATE_LAST_SPELL_M4",
		"second-nova",last_command(),"LAST_SPELL_ALREADY_USED"))
	check("LAST-001-CANNOT_BASIC_ATTACK_WHILE_CONCENTRATING",wrong(s,
		"BASIC_ATTACK_RESOURCE_ONLY","attack-cast",{"actor_id":"A"},"ACTOR_UNAVAILABLE_OR_PHASE"))
	check("LAST-001-STALE_REJECTED",not M4.apply(s,cmd(seed,"ACTIVATE_LAST_SPELL_M4",
		"stale",last_command()),config)["accepted"])
	check("LAST-001-DUPLICATE_COMMAND_REJECTED",wrong(s,"ACTIVATE_LAST_SPELL_M4",
		"start-nova",last_command(),"DUPLICATE_COMMAND"))
	check("LAST-001-RNG_IMMUTABLE",Model.state_hash(s["core"]["battle"]["rng"])
		== Model.state_hash(seed["core"]["battle"]["rng"]))
	check("LAST-002-NOT_EARLY_EFFECT",index_of(submit["events"],"LastSpellEffectDeferredToM5") == -1)
	var enemy: Dictionary = advance_enemy(s,tape,"r1")
	if not enemy["accepted"]:
		printerr("M4_3_ENEMY_SETUP_FAILED ",enemy["error"])
		quit(1)
		return
	s = enemy["state"]
	check("LAST-003-DIRECT_REQUIRES_TARGET_INSTANCE",wrong(s,
		"APPLY_CASTING_DISRUPTION_M4_FIXTURE","wrong-id",{
			"source_enemy_action_id":str(s["active_enemy_action_id"]),
			"casting_id":"last:start-nova","target_casting_id":"last:wrong",
			"effect_id":"destab1"},"DIRECT_TARGET_CASTING_ID_REQUIRED"))
	for n: int in range(3):
		var effect: String = "destab"+str(n+1)
		var snap: Dictionary = s
		var hit: Dictionary = perform(s,tape,"APPLY_CASTING_DISRUPTION_M4_FIXTURE",
			"destabilize-"+str(n+1),{
				"source_enemy_action_id":str(s["active_enemy_action_id"]),
				"casting_id":"last:start-nova","target_casting_id":"last:start-nova",
				"effect_id":effect})
		if not hit["accepted"]:
			printerr("M4_3_DESTABILIZATION_FAILED ",effect," ",hit["error"])
			quit(1)
			return
		s = hit["state"]
		var active: Dictionary = s["core"]["battle"]["casting_instances"]["last:start-nova"]
		check("LAST-003-DISRUPTION-"+str(n+1)+"-DOES_NOT_CANCEL",
			M4.validate_state(s) and active["kind"] == "LAST_SPELL"
			and s["core"]["battle"]["actors"]["A"]["status"] == "CONCENTRATING"
			and index_of(hit["events"],"CastingInterrupted") == -1)
		check("LAST-003-DISRUPTION-"+str(n+1)+"-NO_REFUND",
			s["core"]["battle"]["actors"]["A"]["mp"] == 5
			and s["core"]["battle"]["party_resources"]["current_ap"] == 0
			and index_of(hit["events"],"MPRestored") == -1)
		check("LAST-003-DISRUPTION-"+str(n+1)+"-NO_CARD_ZONE",
			s["core"]["cards"] == snap["core"]["cards"])
		if n == 0:
			check("LAST-003-ONE_DELAY_USED",active["delay_used"]
				and active["planned_resolve_round"] == 4
				and active["disrupted_count"] == 1
				and index_of(hit["events"],"LastSpellDestabilizedDelayed") >= 0)
		elif n == 1:
			check("LAST-004-SECOND_DISRUPTION_WEAKENS",active["delay_used"]
				and active["planned_resolve_round"] == 4
				and active["outcome_modifier_numerator"] == 3
				and active["outcome_modifier_denominator"] == 4
				and index_of(hit["events"],"LastSpellDestabilizedWeakened") >= 0)
		else:
			check("LAST-004-NO_INFINITE_DELAY_OR_STACKING",active["planned_resolve_round"] == 4
				and active["outcome_modifier_numerator"] == 3
				and active["outcome_modifier_denominator"] == 4 and active["disrupted_count"] == 3)
	check("LAST-004-REJECT_REPLAYED_SOURCE",wrong(s,"APPLY_CASTING_DISRUPTION_M4_FIXTURE",
		"replay-destab1",{
			"source_enemy_action_id":str(s["active_enemy_action_id"]),
			"casting_id":"last:start-nova","target_casting_id":"last:start-nova",
			"effect_id":"destab1"},"DUPLICATE_DISRUPTION_EFFECT"))
	var closed: Dictionary = end_enemy(s,tape,"r1")
	if not closed["accepted"]:
		printerr("M4_3_CLOSE_R1_FAILED ",closed["error"]);quit(1);return
	s = closed["state"]
	var open_r2: Dictionary = perform(s,tape,"START_PLAYER_PHASE","enter-r2")
	if not open_r2["accepted"]:
		printerr("M4_3_OPEN_R2_FAILED ",open_r2["error"]);quit(1);return
	s = open_r2["state"]
	check("LAST-003-NO_RELEASE_IN_ROUND2",s["core"]["battle"]["casting_instances"].has("last:start-nova")
		and index_of(open_r2["events"],"LastSpellReleased") == -1)
	var enemy2: Dictionary = advance_enemy(s,tape,"r2")
	if not enemy2["accepted"]:
		printerr("M4_3_ENEMY_R2_FAILED ",enemy2["error"]);quit(1);return
	var closed2: Dictionary = end_enemy(enemy2["state"],tape,"r2")
	if not closed2["accepted"]:
		printerr("M4_3_CLOSE_R2_FAILED ",closed2["error"]);quit(1);return
	var open_r3: Dictionary = perform(closed2["state"],tape,"START_PLAYER_PHASE","enter-r3")
	if not open_r3["accepted"]:
		printerr("M4_3_OPEN_R3_FAILED ",open_r3["error"]);quit(1);return
	s = open_r3["state"]
	check("LAST-003-DELAY_PREVENTS_ROUND3_RELEASE",s["core"]["battle"]["casting_instances"].has("last:start-nova")
		and index_of(open_r3["events"],"LastSpellReleased") == -1)
	var enemy3: Dictionary = advance_enemy(s,tape,"r3")
	if not enemy3["accepted"]:
		printerr("M4_3_ENEMY_R3_FAILED ",enemy3["error"]);quit(1);return
	var closed3: Dictionary = end_enemy(enemy3["state"],tape,"r3")
	if not closed3["accepted"]:
		printerr("M4_3_CLOSE_R3_FAILED ",closed3["error"]);quit(1);return
	var open_r4: Dictionary = perform(closed3["state"],tape,"START_PLAYER_PHASE","enter-r4")
	if not open_r4["accepted"]:
		printerr("M4_3_OPEN_R4_FAILED ",open_r4["error"]);quit(1);return
	s = open_r4["state"]
	check("LAST-005-RELEASE_ONCE_AT_ROUND4",index_of(open_r4["events"],"LastSpellReleased") >= 0
		and index_of(open_r4["events"],"LastSpellEffectDeferredToM5") >= 0)
	check("LAST-005-RELEASE_BEFORE_PLAYER_RESOURCES",
		index_of(open_r4["events"],"LastSpellReleased") < index_of(open_r4["events"],"PlayerResourcesOpened"))
	check("LAST-005-ACTOR_EXHAUSTED",s["core"]["battle"]["actors"]["A"]["status"] == "EXHAUSTED"
		and not s["core"]["battle"]["casting_instances"].has("last:start-nova"))
	check("LAST-005-BASE_AP_STILL_SIX",s["core"]["battle"]["party_resources"]["base_ap"] == 6
		and s["core"]["battle"]["party_resources"]["current_ap"] == 6)
	check("LAST-005-ONCE_USED_PERSISTS",s["core"]["battle"]["last_spell_used_by_actor"]["A"] == 1)
	check("LAST-005-EXHAUSTED_CANNOT_ATTACK",wrong(s,"BASIC_ATTACK_RESOURCE_ONLY","ex-attack",
		{"actor_id":"A"},"ACTOR_UNAVAILABLE"))
	check("LAST-005-EXHAUSTED_CANNOT_CAST",wrong(s,"ACTIVATE_LAST_SPELL_M4",
		"ex-recast",last_command(),"LAST_SPELL_ALREADY_USED"))
	check("LAST-005-EXHAUSTED_TARGETABLE_ALIVE",s["core"]["battle"]["actors"]["A"]["hp"] == 100
		and s["core"]["battle"]["actors"]["A"]["status"] != "INCAPACITATED")
	check("LAST-005-HP_UNCHANGED_M5_ONLY",s["core"]["battle"]["actors"]["Boss"]["hp"] == 100
		and s["core"]["battle"]["actors"]["A"]["hp"] == 100)
	check("LAST-005-NO_CARD_INSTANCE_CREATED",Zones.validate_state(s["core"]["cards"])
		and s["core"]["cards"]["actors"]["A"]["instances"].size() == 12)
	check("LAST-005-NO_MP_PAYMENT_ON_RELEASE",s["core"]["battle"]["paid_cost_command_ids"].size() == 1
		and s["core"]["battle"]["actors"]["A"]["mp"] == 5)
	check("LAST-005-ACTOR_B_CAN_STILL_ACT",M4.apply(s,cmd(s,"BASIC_ATTACK_RESOURCE_ONLY",
		"b-can-act",{"actor_id":"B"}),config)["accepted"])
	var re: Dictionary = M4.replay(seed,tape,config)
	check("LAST-REPLAY-SAME_SEED_FINAL",re["accepted"]
		and re["state_hash"] == Model.state_hash(s))
	check("LAST-REPLAY-SAME_SEED_EVENTS",re["accepted"]
		and re["event_hash"] == Model.event_hash(s["events"]))
	check("LAST-REPLAY-INITIAL_INPUT_UNTOUCHED",Model.state_hash(seed) == initial_hash)
	var stale_tape: Array[Dictionary] = tape.duplicate(true)
	stale_tape[3]["expected_event_seq"] = -1
	check("LAST-REPLAY-STALE_FAIL_CLOSED",not M4.replay(seed,stale_tape,config)["accepted"])
	print("M4_3_REPLAY seed=",SEED," commands=",tape.size(),
		" initial=",initial_hash," events=",Model.event_hash(s["events"]),
		" final=",Model.state_hash(s))
	print("M4_3_TEST_REPORT executed=",pass_count+fail_count," passed=",pass_count," failed=",fail_count)
	if fail_count == 0:
		print("M4_3_LAST_SPELL_DOMAIN_VERIFIED")
	quit(0 if fail_count == 0 else 1)
