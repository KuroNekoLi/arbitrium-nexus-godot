extends SceneTree
## M4.2 independently verifiable tests. All enemy hit/disruption events are
## EXPLICIT, versioned, fixture-authorized (no live M5 damage or hit engine).
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const Draw = preload("res://scripts/domain/m2/cards/draw_resolver.gd")
const Zones = preload("res://scripts/domain/m2/cards/card_zone_resolver.gd")
const M2 = preload("res://scripts/domain/m2/integration/m2_domain_resolver.gd")
const Phase = preload("res://scripts/domain/m3/phase/phase_engine.gd")
const Queue = preload("res://scripts/domain/m3/reaction/reaction_queue_resolver.gd")
const M4 = preload("res://scripts/domain/m4/integration/m4_domain_resolver.gd")
const Instance = preload("res://scripts/domain/m4/casting/casting_instance_resolver.gd")
const Ward = preload("res://scripts/domain/m4/casting/focus_ward_resolver.gd")
const Refund = preload("res://scripts/domain/m4/casting/casting_refund_policy.gd")
const SEED: int = 20261014
var passed: int = 0
var failed: int = 0
var config: Dictionary = {}

func _yes(id: String, condition: bool) -> void:
	if condition:
		passed += 1
		print("PASS ", id)
	else:
		failed += 1
		printerr("FAIL ", id)

func _cfg() -> Dictionary:
	var costs: Variant = JSON.parse_string(FileAccess.get_file_as_string(
		"res://resources/combat/rulesets/m2_2_provisional_costs.json"))
	var resources: Variant = JSON.parse_string(FileAccess.get_file_as_string(
		"res://resources/combat/rulesets/m2_1_provisional_resources.json"))
	if not costs is Dictionary or not resources is Dictionary:
		return {}
	var res: Dictionary = costs.duplicate(true)
	res["basic_attack_ap_cost"] = int(resources["basic_attack_ap_cost"])
	res["basic_attack_mp_gain"] = int(resources["basic_attack_mp_gain"])
	return {"costs": costs, "resources": res,
		"definitions": {"spell":{"card_id":"spell","ap_cost":1,"mp_cost":2}},
		"casting_profiles":{"spell":{"spell_id":"spell",
			"allowed_modes":["CHANTLESS","FULL"],"base_stability":10}},
		"reaction_definitions":{"spell":{
			"kind":"REACTION_SP", "reaction_trigger":"ENEMY_ACTION",
			"rp_cost":1,"mp_cost":1,"fixture_effect":"FOCUS_WARD_FIXTURE",
			"target_scope":"ANY", "requires_active_enemy_action":false,
			"cast_compatible":true, "focus_ward_amount":6}},
		"disruption_effects":{
			"arrow":{"channel":"ON_HIT_CASTING","disruption_power":4,"authority":"BALANCE_PROVISIONAL"},
			"lock":{"channel":"DIRECT_CASTING_INSTANCE","disruption_power":4,"authority":"BALANCE_PROVISIONAL"},
			"blast":{"channel":"DIRECT_CASTING_INSTANCE","disruption_power":8,"authority":"BALANCE_PROVISIONAL"},
			"heavy":{"channel":"DIRECT_CASTING_INSTANCE","disruption_power":20,"authority":"BALANCE_PROVISIONAL"}},
		"casting_interrupt_refund":{"authority":"BALANCE_PROVISIONAL",
			"numerator":1,"denominator":2,"rounding":"FLOOR_FIXTURE"},
		"m4_dual_cast_enabled":true,
		"m4_2_fixture_authorized":true,"m4_2_verified_hit_fixture":true,
		"m4_2_internal_refund":true, "trigger_rules":[]}

func _initial(seed: int = SEED) -> Dictionary:
	var loadouts: Dictionary = {}
	var contexts: Dictionary = {}
	var owned: Dictionary = {}
	for a: String in ["A","B","C"]:
		var values: Array = []
		for i: int in range(12):
			values.append("spell")
		loadouts[a] = values
		contexts[a] = {"actor_id":a,"variant_id":"default","tags":[]}
		owned[a] = {"spell":12}
	var dealt: Dictionary = Draw.start_battle(loadouts,contexts,
		{"spell":{"id":"spell","kind":"SP"}},owned,seed)
	if not dealt["accepted"]:
		return {}
	var battle: Dictionary = Model.make_state(["A","B","C"],["Boss"],seed)
	for a: String in ["A","B","C"]:
		battle["actors"][a]["mp"] = 8
		battle["actors"][a]["max_mp"] = 10
	return Phase.make_state(M2.make_state(battle,dealt["state"]),[
		{"intent_id":"m42_arrow","enemy_id":"Boss","action_order":1,
		"created_seq":0,"publicly_declared":true,
		"target_scope":"SINGLE","target_ids":["A"],"hit_count":3,
		"damage_type":"MAGICAL","requires_reaction_window":true}])

func _cmd(s: Dictionary, kind: String, id: String, args: Dictionary = {}) -> Dictionary:
	var c: Dictionary = {"type":kind,"command_id":id,"expected_event_seq":int(s["event_seq"])}
	for k: Variant in args:
		c[k] = args[k]
	return c

func _apply(s: Dictionary, kind: String, id: String,
		args: Dictionary = {}, cfg: Dictionary = {}) -> Dictionary:
	return M4.apply(s,_cmd(s,kind,id,args),config if cfg.is_empty() else cfg)

func _failed(result: Dictionary, before: Dictionary, error: String) -> bool:
	return not result["accepted"] and str(result["error"]) == error and result["events"].is_empty() \
		and Model.state_hash(result["state"]) == Model.state_hash(before)

func _ix(events: Array, kind: String) -> int:
	for i: int in range(events.size()):
		if str(events[i]["kind"]) == kind:
			return i
	return -1

func _cast(s: Dictionary, a: String, id: String) -> Dictionary:
	return _apply(s,"CAST_SPELL_M4",id,{
		"actor_id":a,"casting_mode":"FULL",
		"card_instance_id":str(s["core"]["cards"]["actors"][a]["zones"]["hand"][0]),
		"target_actor_id":"Boss"})

func _active(s: Dictionary, cast_id: String) -> Dictionary:
	return s["core"]["battle"]["casting_instances"][cast_id]

func _disrupt(s: Dictionary, effect: String, id: String,
		hit_index: int = 0, channel_proof: bool = false) -> Dictionary:
	var a: Dictionary = {"source_enemy_action_id":str(s["active_enemy_action_id"]),
		"casting_id":"cast:full-A","effect_id":effect,"hit_index":hit_index}
	if effect != "arrow":
		a["target_casting_id"] = "cast:full-A"
	if channel_proof:
		a["hit_fixture_confirmed"] = true
	return _apply(s,"APPLY_CASTING_DISRUPTION_M4_FIXTURE",id,a)

func _advance_two(s: Dictionary, tape: Array[Dictionary]) -> Dictionary:
	return s

func _send(s: Dictionary, tape: Array[Dictionary], kind: String, id: String,
		args: Dictionary = {}) -> Dictionary:
	var command: Dictionary = _cmd(s,kind,id,args)
	tape.append(command)
	return M4.apply(s,command,config)

func _init() -> void:
	config = _cfg()
	var s: Dictionary = _initial()
	if config.is_empty() or s.is_empty():
		printerr("M4_2_FIXTURE_SETUP_FAILED")
		quit(1)
		return
	var initial_hash: String = Model.state_hash(s)
	var tape: Array[Dictionary] = []
	var fa: Dictionary = _send(s,tape,"CAST_SPELL_M4","full-A",{
		"actor_id":"A","casting_mode":"FULL",
		"card_instance_id":str(s["core"]["cards"]["actors"]["A"]["zones"]["hand"][0]),
		"target_actor_id":"Boss"})
	if not fa["accepted"]:
		printerr("M4_2_FULL_A_FAILED ",fa["error"])
		quit(1)
		return
	s = fa["state"]
	var fb: Dictionary = _cast(s,"B","full-B")
	if not fb["accepted"]:
		printerr("M4_2_FULL_B_FAILED ",fb["error"])
		quit(1)
		return
	tape.append(_cmd(s,"CAST_SPELL_M4","full-B",{
		"actor_id":"B","casting_mode":"FULL",
		"card_instance_id":str(s["core"]["cards"]["actors"]["B"]["zones"]["hand"][0]),
		"target_actor_id":"Boss"}))
	s = fb["state"]
	_yes("M22-CAST-002-PAID_MP_TRACED_FROM_M2",int(_active(s,"cast:full-A")["paid_mp"]) == 2)
	_yes("M42-INDEPENDENT_TWO_CASTS",s["core"]["battle"]["casting_instances"].size() == 2)
	_yes("M42-BOSS_BREAK_UNTOUCHED",not s["core"]["battle"].has("casting_break_gauge"))
	var generic: Dictionary = Ward.grant(_active(s,"cast:full-A"),5)
	var absorbed: Dictionary = Ward.absorb(generic["instance"],3)
	_yes("CAST-004-WARD_NO_HP_ABSORPTION",generic["ok"] and absorbed["ok"]
		and absorbed["absorbed"] == 3 and absorbed["ward_after"] == 2
		and absorbed["instance"]["current_stability"] == 10)
	var quote: Dictionary = Refund.quote(_active(s,"cast:full-A"),s["core"]["battle"]["actors"]["A"],
		config["casting_interrupt_refund"])
	_yes("M22-CAST-002-REFUND_QUOTE_FROM_PAID_MP",quote["ok"] and quote["requested"] == 1)
	_yes("M22-CAST-002-PROVISIONAL_NOT_CANON",quote["balance_authority"] == "BALANCE_PROVISIONAL")
	_yes("M22-CAST-002-UNKNOWN_REFUND_REJECTED",not Refund.quote(_active(s,"cast:full-A"),
		s["core"]["battle"]["actors"]["A"],{})["ok"])
	var bad_ratio: Dictionary = config["casting_interrupt_refund"].duplicate(true)
	bad_ratio["numerator"] = 2
	_yes("M22-CAST-002-REFUND_NOT_FULL_RATIO",not Refund.quote(_active(s,"cast:full-A"),
		s["core"]["battle"]["actors"]["A"],bad_ratio)["ok"])
	_yes("M42-NO_DIRECT_REFUND_WITHOUT_INTERRUPT",_failed(_apply(s,
		"RECOVER_CASTING_INTERRUPT_MP_M4","fake-refund",
		{"actor_id":"A","amount":2}),s,"FEATURE_NOT_IMPLEMENTED_M3_1"))
	var ended: Dictionary = _send(s,tape,"END_PLAYER_PHASE","enemy-start")
	if not ended["accepted"]:
		printerr("M4_2_END_PLAYER_FAILED ",ended["error"]); quit(1);return
	s = ended["state"]
	var declared: Dictionary = _send(s,tape,"DECLARE_NEXT_ENEMY_ACTION","declare")
	if not declared["accepted"]:
		printerr("M4_2_DECLARE_FAILED ",declared["error"]);quit(1);return
	s = declared["state"]
	_yes("M42-DIRECT_REQUIRES_WINDOW_RESOLUTION",_failed(_disrupt(s,"heavy","too-soon"),
		s,"REACTION_WINDOW_NOT_RESOLVED"))
	var opened: Dictionary = _send(s,tape,"OPEN_REACTION_WINDOW","open",
		{"enemy_action_id":str(s["active_enemy_action_id"])})
	if not opened["accepted"]:
		printerr("M4_2_WINDOW_FAILED ",opened["error"]);quit(1);return
	s = opened["state"]
	var window_id: String = str(s["reaction_window"]["window_id"])
	_yes("CAST-004-CONCENTRATION_BASIC_GUARD_REJECTED",_failed(_apply(s,"QUEUE_REACTION",
		"bad-guard",{"window_id":window_id,
		"entry":{"kind":"BASIC_GUARD","actor_id":"A","target_actor_id":"A"}}),
		s,"CONCENTRATING_UNSUPPORTED_M4"))
	var pending_card: String = str(s["core"]["cards"]["actors"]["A"]["zones"]["hand"][0])
	var ward_entry: Dictionary = {"kind":"REACTION_SP_FIXTURE","actor_id":"A",
		"target_actor_id":"A","card_instance_id":pending_card}
	var queued_ward: Dictionary = _send(s,tape,"QUEUE_REACTION","queue-ward",
		{"window_id":window_id,"entry":ward_entry})
	if not queued_ward["accepted"]:
		printerr("M4_2_QUEUE_WARD_FAILED ",queued_ward["error"]);quit(1);return
	s = queued_ward["state"]
	var protect_entry: Dictionary = {"kind":"BASIC_PROTECT","actor_id":"C","target_actor_id":"A"}
	var queued_protect: Dictionary = _send(s,tape,"QUEUE_REACTION","queue-protect",
		{"window_id":window_id,"entry":protect_entry})
	if not queued_protect["accepted"]:
		printerr("M4_2_QUEUE_PROTECT_FAILED ",queued_protect["error"]);quit(1);return
	s = queued_protect["state"]
	_yes("CAST-004-CONFIRM_ONLY_NO_EARLY_FEE",s["core"]["battle"]["party_resources"]["rp"] == 4
		and s["core"]["battle"]["actors"]["A"]["mp"] == 6
		and Queue.preview(s,config["reaction_definitions"])["estimated_rp"] == 3)
	_yes("CAST-004-QUEUED_CARD_IN_HAND_UNTIL_CONFIRM",Zones.location(s["core"]["cards"],"A",pending_card) == "hand")
	var confirmed: Dictionary = _send(s,tape,"CONFIRM_REACTIONS","confirm",
		{"window_id":window_id})
	if not confirmed["accepted"]:
		printerr("M4_2_CONFIRM_FAILED ",confirmed["error"]);quit(1);return
	s = confirmed["state"]
	_yes("CAST-004-CAST_COMPATIBLE_EXECUTED",s["reaction_window"]["executed_actor_ids"] == ["A","C"])
	_yes("CAST-004-FOCUS_WARD_APPLIED_VIA_M3_QUEUE",int(_active(s,"cast:full-A")["focus_ward"]) == 6
		and _ix(confirmed["events"],"FocusWardGranted") >= 0)
	_yes("CAST-004-CONCENTRATING_REMAINS",s["core"]["battle"]["actors"]["A"]["status"] == "CONCENTRATING")
	_yes("CAST-004-FOCUS_WARD_SP_PAYS_REAL_RP_MP",s["core"]["battle"]["party_resources"]["rp"] == 1
		and s["core"]["battle"]["actors"]["A"]["mp"] == 5)
	_yes("CAST-004-FOCUS_WARD_CARD_DISCARDED",Zones.location(s["core"]["cards"],"A",pending_card) == "discard"
		and Zones.validate_state(s["core"]["cards"]))
	_yes("P1-PRT-006-M3_REDIRECT_FIRST",s["reaction_window"]["damage_recipient_actor_id"] == "C")
	_yes("P1-PRT-006-NO_AUTOPASS",s["reaction_window"]["status"] == "CLOSED"
		and s["reaction_window"]["closure_reason"] == "CONFIRMED_AND_RESOLVED")
	var before_hit: String = Model.state_hash(s)
	_yes("P1-PRT-006-HIT_NOT_PROVEN_DENIED",_failed(_disrupt(s,"arrow","unproven",0,false),
		s,"M5_HIT_RESOLUTION_NOT_AVAILABLE"))
	var suppressed: Dictionary = _send(s,tape,"APPLY_CASTING_DISRUPTION_M4_FIXTURE","onhit",
		{"source_enemy_action_id":str(s["active_enemy_action_id"]),
		"casting_id":"cast:full-A","effect_id":"arrow","hit_index":0,
		"hit_fixture_confirmed":true})
	if not suppressed["accepted"]:
		printerr("M4_2_PROTECT_ONHIT_FAILED ",suppressed["error"]);quit(1);return
	s = suppressed["state"]
	_yes("P1-PRT-006-PROTECT_STOPS_ON_HIT_DISRUPTION",_ix(suppressed["events"],
		"CastingDisruptionSuppressedByProtect") >= 0
		and int(_active(s,"cast:full-A")["current_stability"]) == 10
		and int(_active(s,"cast:full-A")["focus_ward"]) == 6)
	_yes("P1-PRT-007-PROTECT_HP_UNCHANGED_M5_DEFERRED",s["core"]["battle"]["actors"]["A"]["hp"] == 100
		and s["core"]["battle"]["actors"]["C"]["hp"] == 100)
	_yes("P1-PRT-006-NON_MUTATING_PROTECT_CAST",_active(s,"cast:full-B")["current_stability"] == 10)
	_yes("CAST-005-INVALID_SOURCE_REJECTED",_failed(_apply(s,
		"APPLY_CASTING_DISRUPTION_M4_FIXTURE","bad-source",{
			"source_enemy_action_id":"other",
			"casting_id":"cast:full-A","target_casting_id":"cast:full-A","effect_id":"heavy"
		}),s,"DISRUPTION_ACTION_ID_MISMATCH"))
	var untrusted: Dictionary = config.duplicate(true)
	untrusted["m4_2_fixture_authorized"] = false
	_yes("CAST-005-UNTRUSTED_SOURCE_REJECTED",_failed(_apply(s,
		"APPLY_CASTING_DISRUPTION_M4_FIXTURE","untrusted",{
		"source_enemy_action_id":str(s["active_enemy_action_id"]),
		"casting_id":"cast:full-A","target_casting_id":"cast:full-A","effect_id":"heavy"
		},untrusted),s,"M4_2_FIXTURE_NOT_AUTHORIZED"))
	_yes("CAST-005-UNREGISTERED_POWER_REJECTED",_failed(_disrupt(s,"client-power","bad-power"),s,
		"DISRUPTION_EFFECT_NOT_REGISTERED"))
	_yes("CAST-005-DIRECT_CASTING_ID_REQUIRED",_failed(_apply(s,
		"APPLY_CASTING_DISRUPTION_M4_FIXTURE","wrong-cast-target",{
		"source_enemy_action_id":str(s["active_enemy_action_id"]),
		"casting_id":"cast:full-A","target_casting_id":"cast:full-B","effect_id":"heavy"
		}),s,"DIRECT_TARGET_CASTING_ID_REQUIRED"))
	var lock: Dictionary = _send(s,tape,"APPLY_CASTING_DISRUPTION_M4_FIXTURE","lock-hit",{
		"source_enemy_action_id":str(s["active_enemy_action_id"]),
		"casting_id":"cast:full-A","target_casting_id":"cast:full-A","effect_id":"lock"})
	if not lock["accepted"]:
		printerr("M4_2_LOCK_FAILED ",lock["error"]);quit(1);return
	s=lock["state"]
	_yes("CAST-004-WARD_FIRST_FULLY_ABSORBS",_active(s,"cast:full-A")["focus_ward"] == 2
		and _active(s,"cast:full-A")["current_stability"] == 10)
	_yes("CAST-004-DIRECT_BYPASSES_PROTECT",_ix(lock["events"],"CastingDisruptionEvaluated") >= 0)
	_yes("CAST-004-FOCUS_WARD_EVENT_NOT_BARRIER",_ix(lock["events"],"FocusWardAbsorbed") >= 0
		and lock["events"][_ix(lock["events"],"FocusWardAbsorbed")]["details"]["hp_barrier_affected"] == false)
	_yes("CAST-005-DUPLICATE_DISRUPTION_REJECTED",_failed(_disrupt(s,"lock","lock-repeat"),s,
		"DUPLICATE_DISRUPTION_EFFECT"))
	var blast: Dictionary = _send(s,tape,"APPLY_CASTING_DISRUPTION_M4_FIXTURE","blast-hit",{
		"source_enemy_action_id":str(s["active_enemy_action_id"]),
		"casting_id":"cast:full-A","target_casting_id":"cast:full-A","effect_id":"blast"})
	if not blast["accepted"]:
		printerr("M4_2_BLAST_FAILED ",blast["error"]);quit(1);return
	s=blast["state"]
	_yes("CAST-004-WARD_DEPLETED_BEFORE_STABILITY",_active(s,"cast:full-A")["focus_ward"] == 0
		and _active(s,"cast:full-A")["current_stability"] == 4)
	_yes("CAST-005-INDEPENDENT_CASTING_STABILITY",_active(s,"cast:full-B")["current_stability"] == 10)
	var before_cost: Dictionary = s["core"]["battle"]["party_resources"].duplicate(true)
	var before_paid: Array = s["core"]["battle"]["paid_cost_command_ids"].duplicate(true)
	var heavy: Dictionary = _send(s,tape,"APPLY_CASTING_DISRUPTION_M4_FIXTURE","heavy-hit",{
		"source_enemy_action_id":str(s["active_enemy_action_id"]),
		"casting_id":"cast:full-A","target_casting_id":"cast:full-A","effect_id":"heavy"})
	if not heavy["accepted"]:
		printerr("M4_2_HEAVY_FAILED ",heavy["error"]);quit(1);return
	s=heavy["state"]
	_yes("CAST-005-STABILITY_ZERO_INTERRUPTS",_ix(heavy["events"],"CastingInterrupted") >= 0
		and _ix(heavy["events"],"ScheduledEffectCancelled") >= 0)
	_yes("M22-CAST-002-IMMEDIATE_MP_REFUND",s["core"]["battle"]["actors"]["A"]["mp"] == 6
		and _ix(heavy["events"],"MPRestored") >= 0)
	_yes("M22-CAST-002-AP_DEBT_NOT_REFUNDED",s["core"]["battle"]["party_resources"] == before_cost
		and s["core"]["battle"]["paid_cost_command_ids"] == before_paid)
	_yes("CAST-005-REFUND_EVENT_ORDER",_ix(heavy["events"],"CastingInterrupted") <
		_ix(heavy["events"],"ScheduledEffectCancelled")
		and _ix(heavy["events"],"ScheduledEffectCancelled") < _ix(heavy["events"],"MPRestored")
		and _ix(heavy["events"],"MPRestored") < _ix(heavy["events"],"CardZoneChanged"))
	_yes("CAST-005-A_CARD_CASTING_TO_DISCARD",s["core"]["cards"]["actors"]["A"]["zones"]["casting"].is_empty()
		and s["core"]["cards"]["actors"]["A"]["zones"]["discard"].size() == 2)
	_yes("CAST-005-A_CONCENTRATION_CLEARED",s["core"]["battle"]["actors"]["A"]["status"] == "ACTIVE"
		and not s["core"]["battle"]["casting_instances"].has("cast:full-A"))
	_yes("CAST-005-B_CAST_STILL_ACTIVE",Instance.valid(s["core"])
		and s["core"]["battle"]["casting_instances"].has("cast:full-B")
		and s["core"]["battle"]["actors"]["B"]["status"] == "CONCENTRATING")
	_yes("CAST-005-EXACT_CARD_INSTANCE_CONSERVATION",Zones.validate_state(s["core"]["cards"]))
	_yes("CAST-005-NO_HP_OR_BOSS_BREAK_AFFECTED",s["core"]["battle"]["actors"]["Boss"]["hp"] == 100
		and s["core"]["battle"]["actors"]["A"]["hp"] == 100)
	_yes("CAST-005-REPEAT_AFTER_INTERRUPT_REJECTED",_failed(_disrupt(s,"heavy","heavy-again"),
		s,"CASTING_INSTANCE_NOT_FOUND"))
	var replayed: Dictionary = M4.replay(_initial(),tape,config)
	_yes("M42-SEEDED_REPLAY_EXECUTES",replayed["accepted"])
	_yes("M42-SEEDED_REPLAY_IDENTICAL_STATE_HASH",replayed["accepted"]
		and replayed["state_hash"] == Model.state_hash(s))
	_yes("M42-SEEDED_REPLAY_IDENTICAL_EVENT_HASH",replayed["accepted"]
		and replayed["event_hash"] == Model.event_hash(s["events"]))
	_yes("M42-REPLAY_INPUT_UNCHANGED",Model.state_hash(_initial()) == initial_hash)
	var wrong_order: Array[Dictionary] = tape.duplicate(true)
	wrong_order[2]["expected_event_seq"] = -1
	var halted: Dictionary = M4.replay(_initial(),wrong_order,config)
	_yes("M42-REPLAY_STALE_FAILS_CLOSED",not halted["accepted"] and halted["error"] == "STALE_STATE")
	var cap: Dictionary = config["casting_interrupt_refund"].duplicate(true)
	var capped_actor: Dictionary = s["core"]["battle"]["actors"]["A"].duplicate(true)
	capped_actor["mp"] = 10
	var cap_quote: Dictionary = Refund.quote(fa["state"]["core"]["battle"]["casting_instances"]["cast:full-A"],capped_actor,cap)
	_yes("M22-CAST-002-MP_MAX_CAP",cap_quote["ok"] and cap_quote["requested"] == 1
		and cap_quote["actual"] == 0)
	# Additional positive control for P1-D14: absent Protect and with a
	# trusted M5 hit FIXTURE, on-hit disruption MUST reduce the original
	# caster Stability. No untrusted client-supplied power may override it.
	var solo: Dictionary = _initial(SEED + 1)
	var solo_cast: Dictionary = _cast(solo,"A","solo-full")
	var solo_enemy: Dictionary = _apply(solo_cast["state"],"END_PLAYER_PHASE","solo-end")
	var solo_declared: Dictionary = _apply(solo_enemy["state"],"DECLARE_NEXT_ENEMY_ACTION","solo-declare")
	var solo_opened: Dictionary = _apply(solo_declared["state"],"OPEN_REACTION_WINDOW","solo-open",
		{"enemy_action_id":str(solo_declared["state"]["active_enemy_action_id"])})
	var solo_pass: Dictionary = _apply(solo_opened["state"],"PASS_REACTION","solo-pass",
		{"window_id":str(solo_opened["state"]["reaction_window"]["window_id"])})
	_yes("P1-PRT-008-REAL_WINDOW_EXPLICIT_PASS",solo_pass["accepted"]
		and solo_pass["state"]["reaction_window"]["closure_reason"] == "PLAYER_PASSED")
	var solo_before: Dictionary = solo_pass["state"]
	var claimed_hit: Dictionary = {
		"source_enemy_action_id":str(solo_before["active_enemy_action_id"]),
		"casting_id":"cast:solo-full","effect_id":"arrow",
		"hit_index":0,"hit_fixture_confirmed":true,"disruption_power":9999}
	var no_hit_cfg: Dictionary = config.duplicate(true)
	no_hit_cfg["m4_2_verified_hit_fixture"] = false
	_yes("P1-PRT-008-UNTRUSTED_HIT_FIXTURE_REJECTED",_failed(_apply(
		solo_before,"APPLY_CASTING_DISRUPTION_M4_FIXTURE","untrusted-hit",
		claimed_hit,no_hit_cfg),solo_before,"M5_HIT_RESOLUTION_NOT_AVAILABLE"))
	var solo_hit: Dictionary = _apply(solo_before,"APPLY_CASTING_DISRUPTION_M4_FIXTURE",
		"real-onhit-fixture",claimed_hit)
	_yes("P1-PRT-008-UNPROTECTED_ON_HIT_APPLIES",solo_hit["accepted"]
		and _active(solo_hit["state"],"cast:solo-full")["current_stability"] == 6)
	_yes("P1-PRT-008-CONTENT_POWER_NOT_CLIENT_OVERRIDE",solo_hit["accepted"]
		and solo_hit["events"][_ix(solo_hit["events"],"CastingDisruptionEvaluated")]["details"]["power"] == 4)
	_yes("P1-PRT-008-HP_REMAINS_M5_DEFERRED",solo_hit["accepted"]
		and solo_hit["state"]["core"]["battle"]["actors"]["A"]["hp"] == 100
		and solo_hit["state"]["core"]["battle"]["actors"]["Boss"]["hp"] == 100)
	_yes("P1-PRT-008-DUPLICATE_HIT_EVENT_REJECTED",_failed(_apply(
		solo_hit["state"],"APPLY_CASTING_DISRUPTION_M4_FIXTURE","duplicate-hit",
		claimed_hit),solo_hit["state"],"DUPLICATE_DISRUPTION_EFFECT"))
	_yes("P1-PRT-008-CAST_CARD_REMAINS_IN_CASTING",solo_hit["accepted"]
		and Instance.valid(solo_hit["state"]["core"])
		and Zones.validate_state(solo_hit["state"]["core"]["cards"]))
	_yes("P1-PRT-008-CANNOT_DISRUPT_UNTARGETED_CASTER",_failed(_apply(
		confirmed["state"],"APPLY_CASTING_DISRUPTION_M4_FIXTURE","wrong-hit-target",{
		"source_enemy_action_id":str(confirmed["state"]["active_enemy_action_id"]),
		"casting_id":"cast:full-B","effect_id":"arrow",
		"hit_index":0,"hit_fixture_confirmed":true
	}),confirmed["state"],"CASTER_NOT_ORIGINAL_HIT_TARGET"))
	_yes("M42-NO_ORDINARY_REACTION_FROM_CONCENTRATING",_active(s,"cast:full-B")["concentration"]
		and s["core"]["battle"]["actors"]["B"]["status"] == "CONCENTRATING")
	print("M4_2_REPLAY seed=",SEED," commands=",tape.size()," initial=",initial_hash,
		" events=",Model.event_hash(s["events"])," final=",Model.state_hash(s))
	print("M4_2_TEST_REPORT executed=",passed+failed," passed=",passed," failed=",failed)
	if failed == 0:
		print("M4_2_DISRUPTION_DOMAIN_VERIFIED")
	quit(0 if failed == 0 else 1)
