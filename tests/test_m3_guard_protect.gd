extends SceneTree
## M3.3 PRE3-R01/R02/R03/R04/R17, P1-D11/D12/D13/D14:
## SP-free basic Guard=1RP, Protect=2RP, first redirect wins,
## one Window/EnemyAction including multi-hit, no HP math at this stage.
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const Draw = preload("res://scripts/domain/m2/cards/draw_resolver.gd")
const Zones = preload("res://scripts/domain/m2/cards/card_zone_resolver.gd")
const M2 = preload("res://scripts/domain/m2/integration/m2_domain_resolver.gd")
const Phase = preload("res://scripts/domain/m3/phase/phase_engine.gd")
const Eligibility = preload("res://scripts/domain/m3/reaction/reaction_eligibility.gd")
const Queue = preload("res://scripts/domain/m3/reaction/reaction_queue_resolver.gd")
const SEED: int = 20261014
var passed: int = 0
var failed: int = 0
var cfg: Dictionary = {
	"reaction_definitions": {
		"counter": {"kind":"REACTION_SP","reaction_trigger":"ENEMY_ACTION",
			"rp_cost":1,"mp_cost":2,"fixture_effect":"CANCEL_ACTION_FIXTURE",
			"target_scope":"ANY","requires_active_enemy_action":true}
	}
}

func _ok(id: String, condition: bool) -> void:
	if condition:
		passed += 1
		print("PASS ", id)
	else:
		failed += 1
		printerr("FAIL ", id)

func _intent(id: String, scope: String, targets: Array, hits: int = 1,
		damage: String = "PHYSICAL", extras: Dictionary = {}) -> Dictionary:
	var d: Dictionary = {"intent_id":id,"enemy_id":"Boss",
		"action_order": 1, "created_seq": 1,
		"publicly_declared":true,"target_scope":scope,
		"target_ids":targets, "hit_count":hits,
		"damage_type":damage,"requires_reaction_window":true}
	for k: Variant in extras:
		d[k] = extras[k]
	return d

func _state(intents: Array, use_counter: bool = false) -> Dictionary:
	var loadouts: Dictionary = {}
	var contexts: Dictionary = {}
	var owned: Dictionary = {}
	var definitions: Dictionary = {}
	for actor: String in ["A","B","C"]:
		var name: String = "counter" if use_counter and actor == "A" else "ordinary"
		var loadout: Array = []
		for i: int in range(12):
			loadout.append(name)
		loadouts[actor] = loadout
		contexts[actor] = {"actor_id":actor,"variant_id":"default","tags":[]}
		owned[actor] = {name:12}
		definitions[name] = {"id":name,"kind":"SP"}
	var cards: Dictionary = Draw.start_battle(loadouts, contexts, definitions, owned, SEED)
	if not cards["accepted"]:
		return {}
	var battle: Dictionary = Model.make_state(["A","B","C"], ["Boss"], SEED)
	for actor: String in ["A","B","C"]:
		battle["actors"][actor]["mp"] = 8
		battle["actors"][actor]["max_mp"] = 10
	var core: Dictionary = M2.make_state(battle,cards["state"])
	return Phase.make_state(core,intents)

func _cmd(state: Dictionary, kind: String, id: String, args: Dictionary = {}) -> Dictionary:
	var request: Dictionary = {"type":kind, "command_id":id,
		"expected_event_seq":int(state["event_seq"])}
	for k: Variant in args:
		request[k] = args[k]
	return request

func _apply(state: Dictionary, kind: String, id: String, args: Dictionary = {}) -> Dictionary:
	return Phase.apply(state, _cmd(state,kind,id,args),cfg)

func _reaction(state: Dictionary, kind: String, id: String, args: Dictionary = {}) -> Dictionary:
	var values: Dictionary = {"window_id":str(state["reaction_window"]["window_id"])}
	values.merge(args,true)
	return _apply(state,kind,id,values)

func _guard(actor: String) -> Dictionary:
	return {"kind":"BASIC_GUARD","actor_id":actor,
		"target_actor_id":actor}

func _protect(actor: String, target: String) -> Dictionary:
	return {"kind":"BASIC_PROTECT","actor_id":actor,"target_actor_id":target}

func _card(s: Dictionary, actor: String) -> String:
	return str(s["core"]["cards"]["actors"][actor]["zones"]["hand"][0])

func _sp(s: Dictionary, actor: String, target: String) -> Dictionary:
	return {"kind":"REACTION_SP_FIXTURE","actor_id":actor,
		"card_instance_id":_card(s,actor),"target_actor_id":target}

func _setup(state: Dictionary) -> Dictionary:
	var e: Dictionary = _apply(state,"END_PLAYER_PHASE","setup-end")
	if not e["accepted"]:
		return {}
	var d: Dictionary = _apply(e["state"],"DECLARE_NEXT_ENEMY_ACTION","setup-declare")
	if not d["accepted"]:
		return {}
	return d["state"]

func _open(state: Dictionary) -> Dictionary:
	var action_id: String = str(state["active_enemy_action_id"])
	return _apply(state,"OPEN_REACTION_WINDOW","setup-open:" + action_id,
		{"enemy_action_id":action_id})

func _event_index(events: Array, name: String) -> int:
	for i: int in range(events.size()):
		if str(events[i]["kind"]) == name:
			return i
	return -1

func _not_changed(rejected: Dictionary, before: Dictionary, reason: String) -> bool:
	return (not rejected["accepted"] and str(rejected["error"]) == reason
		and rejected["events"].is_empty()
		and Model.state_hash(rejected["state"]) == Model.state_hash(before))

func _assert_core_unchanged(before: Dictionary, after: Dictionary) -> bool:
	return Model.state_hash(before["core"]) == Model.state_hash(after["core"])

func _init() -> void:
	var multi_initial: Dictionary = _state([_intent("multi","MULTI",["A","B"],3)])
	var multi: Dictionary = _setup(multi_initial)
	var opened: Dictionary = _open(multi)
	if not opened["accepted"]:
		printerr("M3_3_SETUP_FAILED ",opened["error"])
		quit(1)
		return
	var s: Dictionary = opened["state"]
	var baseline_core: String = Model.state_hash(s["core"])
	var baseline_cards: String = Model.state_hash(s["core"]["cards"])
	var original_rp: int = int(s["core"]["battle"]["party_resources"]["rp"])
	_ok("M3_3_SP_FREE_GUARD_AVAILABLE", opened["events"][0]["kind"] == "ReactionWindowOpened"
		and s["reaction_window"]["status"] == "DRAFTING")
	_ok("M3_3_MULTHIT_SINGLE_WINDOW", s["enemy_actions"][0]["public_intent"]["hit_count"] == 3
		and s["reaction_window"]["window_id"] == "round:1:intent:multi:window:0")
	var gq: Dictionary = _reaction(s,"QUEUE_REACTION","gq",{"entry":_guard("A")})
	_ok("M3_3_QUEUE_GUARD_NO_HAND", gq["accepted"]
		and gq["state"]["reaction_window"]["draft"].size() == 1
		and _assert_core_unchanged(s,gq["state"]))
	var pure: Dictionary = Queue.preview(gq["state"], cfg["reaction_definitions"])
	_ok("M3_3_GUARD_PREVIEW_PURE", pure["ok"] and pure["estimated_rp"] == 1
		and _assert_core_unchanged(s,gq["state"]))
	var confirmed: Dictionary = _reaction(gq["state"],"CONFIRM_REACTIONS","gconfirm")
	var defended: Dictionary = confirmed["state"]
	_ok("M3_3_GUARD_EXACTLY_ONE_RP", confirmed["accepted"]
		and int(defended["core"]["battle"]["party_resources"]["rp"]) == original_rp - 1)
	_ok("M3_3_GUARD_NO_MP_OR_CARD", defended["core"]["battle"]["actors"]["A"]["mp"] == 8
		and Model.state_hash(defended["core"]["cards"]) == baseline_cards)
	_ok("M3_3_GUARD_THREE_HIT_COVERAGE", defended["reaction_window"]["guard_actor_ids"] == ["A"]
		and _event_index(confirmed["events"],"GuardCoverageRegistered") >= 0
		and confirmed["events"][_event_index(confirmed["events"],"GuardCoverageRegistered")]["details"]["hit_count"] == 3)
	_ok("M3_3_GUARD_NO_DAMAGE_HARDCODE", not confirmed["events"][_event_index(confirmed["events"],"GuardCoverageRegistered")]["details"].has("reduction_percent")
		and str(confirmed["events"][_event_index(confirmed["events"],"GuardCoverageRegistered")]["details"]["damage_coefficient"]).begins_with("DEFERRED_M5"))
	_ok("M3_3_GUARD_EVENTS_ORDER", _event_index(confirmed["events"],"ReactionResourcesCommitted") <
		_event_index(confirmed["events"],"GuardCoverageRegistered")
		and _event_index(confirmed["events"],"GuardCoverageRegistered") <
		_event_index(confirmed["events"],"ReactionExecuted"))
	_ok("M3_3_GUARD_EXECUTE_ONCE", defended["reaction_window"]["executed_actor_ids"] == ["A"]
		and _not_changed(_reaction(defended,"CONFIRM_REACTIONS","double-guard"),
			defended,"REACTION_WINDOW_CLOSED"))
	var finalized: Dictionary = _apply(defended,"COMPLETE_ENEMY_ACTION_FIXTURE","finish-multi",
		{"enemy_action_id":str(defended["active_enemy_action_id"])})
	_ok("M3_3_GUARD_HANDOFF_SNAPSHOT", finalized["accepted"]
		and finalized["events"][-1]["details"]["defense_snapshot"]["guard_actor_ids"] == ["A"]
		and finalized["events"][-1]["details"]["defense_snapshot"]["hit_count"] == 3
		and finalized["events"][-1]["details"]["defense_snapshot"]["hit_and_damage_status"] == "DEFERRED_TO_M5")
	_ok("M3_3_GUARD_NOT_GLOBAL_PERSISTENT", finalized["state"]["reaction_window"].is_empty()
		and Zones.validate_state(finalized["state"]["core"]["cards"]))

	# Single-target three-hit Protect, first successful claim wins. C has
	# enough RP, but second Protect must SKIP without fee or executing.
	var si: Dictionary = _state([_intent("single","SINGLE",["A"],3)])
	var single: Dictionary = _open(_setup(si))["state"]
	var p1: Dictionary = _reaction(single,"QUEUE_REACTION","protect-b",{"entry":_protect("B","A")})
	var p2: Dictionary = _reaction(p1["state"],"QUEUE_REACTION","protect-c",{"entry":_protect("C","A")})
	_ok("M3_3_DOUBLE_PROTECT_DRAFT_IS_PURE", p2["accepted"]
		and _assert_core_unchanged(single,p2["state"])
		and Queue.preview(p2["state"],cfg["reaction_definitions"])["estimated_rp"] == 4)
	var pc: Dictionary = _reaction(p2["state"],"CONFIRM_REACTIONS","protect-confirm")
	var w: Dictionary = pc["state"]["reaction_window"]
	_ok("M3_3_PROTECT_ONE_REDIRECT", pc["accepted"]
		and w["protected_by_actor_id"] == "B"
		and w["original_target_actor_id"] == "A"
		and w["damage_recipient_actor_id"] == "B")
	_ok("M3_3_PROTECT_THREE_HITS_SINGLE_REDIRECT", w["guard_actor_ids"].is_empty()
		and pc["events"][_event_index(pc["events"],"AttackTargetRedirected")]["details"]["hit_count"] == 3)
	_ok("M3_3_PROTECT_ONLY_TWO_RP", pc["state"]["core"]["battle"]["party_resources"]["rp"] == 4
		and pc["state"]["core"]["battle"]["actors"]["B"]["mp"] == 8
		and pc["state"]["core"]["battle"]["actors"]["C"]["mp"] == 8)
	_ok("M3_3_SECOND_PROTECT_SKIPPED_NO_CHAIN", _event_index(pc["events"],"ReactionSkipped") >= 0
		and pc["events"][_event_index(pc["events"],"ReactionSkipped")]["details"]["actor_id"] == "C"
		and pc["events"][_event_index(pc["events"],"ReactionSkipped")]["details"]["reason"] == "PROTECT_ALREADY_REDIRECTED"
		and w["executed_actor_ids"] == ["B"])
	_ok("M3_3_PROTECT_NO_CARD_USED", Model.state_hash(pc["state"]["core"]["cards"]) ==
		Model.state_hash(single["core"]["cards"]))
	var pc_finish: Dictionary = _apply(pc["state"],"COMPLETE_ENEMY_ACTION_FIXTURE","single-finish",
		{"enemy_action_id":str(pc["state"]["active_enemy_action_id"])})
	_ok("M3_3_REDIRECT_BEFORE_HIT_OR_DEFENSE", pc_finish["accepted"]
		and pc_finish["events"][-1]["details"]["defense_snapshot"]["damage_recipient_actor_id"] == "B"
		and pc_finish["events"][-1]["details"]["defense_snapshot"]["follows_damage_recipient"] == "EXPLICIT_TAG_ONLY"
		and pc_finish["state"]["core"]["battle"]["actors"]["A"]["hp"] == 100)
	_ok("M3_3_REDIRECT_NOT_DAMAGE", str(pc_finish["events"][-1]["details"]["damage_status"]) == "DEFERRED_TO_M5")

	# Guard before Protect remains paid even if redirect means Guard never
	# ends up affecting that attack, no retroactive refund.
	var gp1: Dictionary = _reaction(single,"QUEUE_REACTION","guard-a",{"entry":_guard("A")})
	var gp2: Dictionary = _reaction(gp1["state"],"QUEUE_REACTION","protect-b",
		{"entry":_protect("B","A")})
	var gp_done: Dictionary = _reaction(gp2["state"],"CONFIRM_REACTIONS","guard-protect")
	_ok("M3_3_GUARD_THEN_PROTECT_PAID", gp_done["accepted"]
		and gp_done["state"]["core"]["battle"]["party_resources"]["rp"] == 3
		and gp_done["state"]["reaction_window"]["guard_actor_ids"] == ["A"]
		and gp_done["state"]["reaction_window"]["damage_recipient_actor_id"] == "B")
	_ok("M3_3_GUARD_NOT_FREELY_REFUNDED", gp_done["state"]["reaction_window"]["executed_actor_ids"] == ["A","B"])
	var pg1: Dictionary = _reaction(single,"QUEUE_REACTION","pg-protect",
		{"entry":_protect("B","A")})
	var pg2: Dictionary = _reaction(pg1["state"],"QUEUE_REACTION","pg-guard",
		{"entry":_guard("A")})
	var pg_done: Dictionary = _reaction(pg2["state"],"CONFIRM_REACTIONS","pg-confirm")
	_ok("M3_3_GUARD_AFTER_REDIRECT_SKIPS", pg_done["accepted"]
		and pg_done["state"]["core"]["battle"]["party_resources"]["rp"] == 4
		and pg_done["events"][_event_index(pg_done["events"],"ReactionSkipped")]["details"]["reason"] == "NOT_CURRENT_DAMAGE_RECIPIENT"
		and pg_done["state"]["reaction_window"]["executed_actor_ids"] == ["B"])

	# Strict refusals: AoE and MULTI may Guard but cannot Protect; direct
	# casting disruption / unprotectable attacks cannot Protect; illegal
	# owner/target cannot consume RP even at draft time.
	var multi_action: Dictionary = multi["enemy_actions"][0]
	var scope_check: Dictionary = Eligibility.check(multi["core"],multi_action,
		_protect("C","A"),cfg["reaction_definitions"],true,multi["reaction_window"])
	_ok("M3_3_MULTITARGET_PROTECT_REJECTED", scope_check["error"] == "PROTECT_REQUIRES_SINGLE_TARGET")
	var aoe_intent: Array = [_intent("aoe","AOE",["A","B","C"],2)]
	var aoe: Dictionary = _open(_setup(_state(aoe_intent)))["state"]
	var aoe_check: Dictionary = Eligibility.check(aoe["core"],aoe["enemy_actions"][0],
		_protect("C","A"),cfg["reaction_definitions"],true,aoe["reaction_window"])
	_ok("M3_3_AOE_PROTECT_REJECTED", aoe_check["error"] == "PROTECT_REQUIRES_SINGLE_TARGET"
		and Eligibility.check(aoe["core"],aoe["enemy_actions"][0],_guard("A"),
			cfg["reaction_definitions"],true,aoe["reaction_window"])["ok"])
	var disruption: Dictionary = _open(_setup(_state([
		_intent("disrupt","SINGLE",["A"],1,"MAGICAL",
			{"direct_casting_disruption":true})])))
	_ok("M3_3_DIRECT_CASTING_NOT_BASIC_REACTION", disruption["accepted"]
		and disruption["state"]["reaction_window"]["status"] == "CLOSED"
		and disruption["events"][0]["kind"] == "ReactionWindowEmptySkipped")
	var unprotectable: Dictionary = _open(_setup(_state([
		_intent("unprotectable","SINGLE",["A"],1,"PHYSICAL",
			{"unprotectable":true})])))["state"]
	_ok("M3_3_UNPROTECTABLE_REJECTED", Eligibility.check(unprotectable["core"],
		unprotectable["enemy_actions"][0],_protect("B","A"),cfg["reaction_definitions"],
		true,unprotectable["reaction_window"])["error"] == "UNPROTECTABLE_ATTACK")
	_ok("M3_3_CAN_GUARD_UNPROTECTABLE_HP", Eligibility.check(unprotectable["core"],
		unprotectable["enemy_actions"][0],_guard("A"),cfg["reaction_definitions"],
		true,unprotectable["reaction_window"])["ok"])
	_ok("M3_3_CANNOT_PROTECT_SELF", Eligibility.check(single["core"],single["enemy_actions"][0],
		_protect("A","A"),cfg["reaction_definitions"],true,single["reaction_window"])["error"] == "CANNOT_PROTECT_SELF")
	_ok("M3_3_WRONG_PROTECT_TARGET", Eligibility.check(single["core"],single["enemy_actions"][0],
		_protect("B","C"),cfg["reaction_definitions"],true,single["reaction_window"])["error"] == "PROTECT_TARGET_MISMATCH")
	_ok("M3_3_GUARD_NONTARGET_REJECTED", Eligibility.check(single["core"],single["enemy_actions"][0],
		_guard("C"),cfg["reaction_definitions"],true,single["reaction_window"])["error"] == "NOT_CURRENT_DAMAGE_RECIPIENT")
	var hp0: Dictionary = single.duplicate(true)
	hp0["core"]["battle"]["actors"]["B"]["hp"] = 0
	hp0["core"]["battle"]["actors"]["B"]["status"] = "INCAPACITATED"
	_ok("M3_3_INCAPACITATED_CANNOT_PROTECT", Eligibility.check(hp0["core"],hp0["enemy_actions"][0],
		_protect("B","A"),cfg["reaction_definitions"],true,hp0["reaction_window"])["error"] == "ACTOR_UNAVAILABLE")
	var exhausted: Dictionary = single.duplicate(true)
	exhausted["core"]["battle"]["actors"]["B"]["status"] = "EXHAUSTED"
	_ok("M3_3_EXHAUSTED_CANNOT_PROTECT", Eligibility.check(exhausted["core"],exhausted["enemy_actions"][0],
		_protect("B","A"),cfg["reaction_definitions"],true,exhausted["reaction_window"])["error"] == "ACTOR_UNAVAILABLE")
	var concentrated: Dictionary = single.duplicate(true)
	concentrated["core"]["battle"]["actors"]["B"]["status"] = "CONCENTRATING"
	_ok("M3_3_CONCENTRATING_BASIC_DISALLOWED", Eligibility.check(concentrated["core"],
		concentrated["enemy_actions"][0],_protect("B","A"),
		cfg["reaction_definitions"],true,concentrated["reaction_window"])["error"] == "CONCENTRATING_UNSUPPORTED_M4")
	var ally_exhausted: Dictionary = single.duplicate(true)
	ally_exhausted["core"]["battle"]["actors"]["A"]["status"] = "EXHAUSTED"
	_ok("M3_3_CAN_PROTECT_EXHAUSTED_TARGET", Eligibility.check(ally_exhausted["core"],
		ally_exhausted["enemy_actions"][0],_protect("B","A"),
		cfg["reaction_definitions"],true,ally_exhausted["reaction_window"])["ok"])
	var dead_target: Dictionary = single.duplicate(true)
	dead_target["core"]["battle"]["actors"]["A"]["hp"] = 0
	_ok("M3_3_HP0_TARGET_REJECTED", Eligibility.check(dead_target["core"],
		dead_target["enemy_actions"][0],_protect("B","A"),
		cfg["reaction_definitions"],true,dead_target["reaction_window"])["error"] == "TARGET_INCAPACITATED")
	var no_rp: Dictionary = single.duplicate(true)
	no_rp["core"]["battle"]["party_resources"]["rp"] = 1
	_ok("M3_3_PROTECT_NEEDS_2_RP", Eligibility.check(no_rp["core"],
		no_rp["enemy_actions"][0],_protect("B","A"),
		cfg["reaction_definitions"],true,no_rp["reaction_window"])["error"] == "INSUFFICIENT_RP")
	_ok("M3_3_GUARD_WITH_1_RP", Eligibility.check(no_rp["core"],
		no_rp["enemy_actions"][0],_guard("A"),
		cfg["reaction_definitions"],true,no_rp["reaction_window"])["ok"])
	var empty_rp: Dictionary = single.duplicate(true)
	empty_rp["core"]["battle"]["party_resources"]["rp"] = 0
	_ok("M3_3_NO_RP_NO_BASIC", not Eligibility.check(empty_rp["core"],
		empty_rp["enemy_actions"][0],_guard("A"),
		cfg["reaction_definitions"],true,empty_rp["reaction_window"])["ok"]
		and not Eligibility.check(empty_rp["core"],
		empty_rp["enemy_actions"][0],_protect("B","A"),
		cfg["reaction_definitions"],true,empty_rp["reaction_window"])["ok"])
	_ok("M3_3_NO_CARD_COST_FROM_BASIC", _not_changed(_reaction(no_rp,"QUEUE_REACTION",
		"cannot-buy-protect",{"entry":_protect("B","A")}),
		no_rp,"INSUFFICIENT_RP"))
	var rp1_guard: Dictionary = _reaction(no_rp,"QUEUE_REACTION",
		"one-rp-guard",{"entry":_guard("A")})
	var rp1_confirm: Dictionary = _reaction(rp1_guard["state"],"CONFIRM_REACTIONS","one-rp-confirm")
	_ok("M3_3_BASIC_GUARD_ZERO_RP_AFTER_PAY", rp1_confirm["accepted"]
		and rp1_confirm["state"]["core"]["battle"]["party_resources"]["rp"] == 0)
	var forged_draft: Dictionary = _reaction(single,"QUEUE_REACTION",
		"forged-cost",{"entry":{"kind":"BASIC_PROTECT",
			"actor_id":"C","target_actor_id":"A","rp_cost":-500}})
	_ok("M3_3_DRAFT_IGNORES_CLIENT_COST_FIELDS", forged_draft["accepted"]
		and _assert_core_unchanged(single,forged_draft["state"])
		and Queue.preview(forged_draft["state"],cfg["reaction_definitions"])["estimated_rp"] == 2)
	# This contract is stronger than mere input validation: any injected
	# rp_cost is IGNORED; domain-approved cost always controls payment.
	var injection: Dictionary = _reaction(single,"QUEUE_REACTION","injection",
		{"entry":{"kind":"BASIC_PROTECT","actor_id":"B",
		"target_actor_id":"A","rp_cost":0,"mp_cost":-999}})
	var injection_paid: Dictionary = _reaction(injection["state"],"CONFIRM_REACTIONS","injection-confirm")
	_ok("M3_3_COST_SOURCE_IS_FIXED_DOMAIN", injection_paid["accepted"]
		and injection_paid["state"]["core"]["battle"]["party_resources"]["rp"] == 4
		and injection_paid["state"]["core"]["battle"]["actors"]["B"]["mp"] == 8)

	# Counter SP cancels source BEFORE a pending Protect: PRE3-R04 says
	# skip Protect with NO RP charge, no card use and no execution quota.
	var counter_init: Dictionary = _state([_intent("counteraction","SINGLE",["A"],1)],true)
	var counter_s: Dictionary = _open(_setup(counter_init))["state"]
	var ca: Dictionary = _reaction(counter_s,"QUEUE_REACTION","counter-a",
		{"entry":_sp(counter_s,"A","A")})
	var cb: Dictionary = _reaction(ca["state"],"QUEUE_REACTION","counter-protect",
		{"entry":_protect("B","A")})
	var counter_done: Dictionary = _reaction(cb["state"],"CONFIRM_REACTIONS","counter-confirm")
	_ok("M3_3_PRE3_R04_PROTECT_TRIGGER_GONE", counter_done["accepted"]
		and counter_done["events"][_event_index(counter_done["events"],"ReactionSkipped")]["details"]["reason"] == "TRIGGER_GONE"
		and counter_done["state"]["reaction_window"]["executed_actor_ids"] == ["A"])
	_ok("M3_3_PRE3_R04_NO_PROTECT_CHARGE", counter_done["state"]["core"]["battle"]["party_resources"]["rp"] == 5
		and counter_done["state"]["reaction_window"]["protected_by_actor_id"] == ""
		and counter_done["state"]["core"]["cards"]["actors"]["B"]["zones"]["discard"].is_empty())
	_ok("M3_3_PRE3_R04_REAL_SP_CARD_USED", counter_done["state"]["core"]["cards"]["actors"]["A"]["zones"]["discard"].size() == 1
		and Zones.validate_state(counter_done["state"]["core"]["cards"]))

	# Multiple windows: guard does not silently apply beyond its source
	# action, RP persists across windows then expires at EnemyPhase end.
	var twice: Dictionary = _state([
		_intent("one","SINGLE",["A"],3),
		_intent("two","SINGLE",["A"],2,
			"MAGICAL",{"action_order":2,"created_seq":2})
	])
	var first_w: Dictionary = _open(_setup(twice))["state"]
	var first_q: Dictionary = _reaction(first_w,"QUEUE_REACTION","first-guard",
		{"entry":_guard("A")})
	var first_c: Dictionary = _reaction(first_q["state"],"CONFIRM_REACTIONS","first-confirm")
	var first_f: Dictionary = _apply(first_c["state"],"COMPLETE_ENEMY_ACTION_FIXTURE","first-finish",
		{"enemy_action_id":str(first_c["state"]["active_enemy_action_id"])})
	var second_d: Dictionary = _apply(first_f["state"],"DECLARE_NEXT_ENEMY_ACTION","second-declare")
	var second_w: Dictionary = _open(second_d["state"])
	_ok("M3_3_SECOND_WINDOW_GUARD_RESETS", second_w["accepted"]
		and second_w["state"]["reaction_window"]["guard_actor_ids"].is_empty()
		and second_w["state"]["reaction_window"]["executed_actor_ids"].is_empty())
	_ok("M3_3_RP_SHARED_BETWEEN_ACTIONS", second_w["state"]["core"]["battle"]["party_resources"]["rp"] == 5)
	var second_q: Dictionary = _reaction(second_w["state"],"QUEUE_REACTION","second-guard",
		{"entry":_guard("A")})
	var second_c: Dictionary = _reaction(second_q["state"],"CONFIRM_REACTIONS","second-confirm")
	_ok("M3_3_GUARD_COST_PER_DISTINCT_ACTION", second_c["accepted"]
		and second_c["state"]["core"]["battle"]["party_resources"]["rp"] == 4
		and second_c["state"]["reaction_window"]["guard_actor_ids"] == ["A"])
	var second_f: Dictionary = _apply(second_c["state"],"COMPLETE_ENEMY_ACTION_FIXTURE","second-finish",
		{"enemy_action_id":str(second_c["state"]["active_enemy_action_id"])})
	var final_end: Dictionary = _apply(second_f["state"],"END_ENEMY_PHASE","enemy-end")
	_ok("M3_3_RP_EXPIRES_AFTER_ACTIONS", final_end["accepted"]
		and final_end["state"]["core"]["battle"]["party_resources"]["rp"] == 0)

	# Deterministic replay for Guard+Protect JIT chain with exactly-once
	# RP and no phantom card; pure commands, same seed and fixed catalogue.
	var tape: Array[Dictionary] = []
	var replay_state: Dictionary = si
	for step: String in ["END_PLAYER_PHASE","DECLARE_NEXT_ENEMY_ACTION","OPEN_REACTION_WINDOW",
			"QUEUE_REACTION","QUEUE_REACTION","CONFIRM_REACTIONS",
			"COMPLETE_ENEMY_ACTION_FIXTURE","END_ENEMY_PHASE"]:
		var extras: Dictionary = {}
		if step == "OPEN_REACTION_WINDOW" or step == "COMPLETE_ENEMY_ACTION_FIXTURE":
			extras["enemy_action_id"] = str(replay_state["active_enemy_action_id"])
		if step == "QUEUE_REACTION":
			extras["window_id"] = str(replay_state["reaction_window"]["window_id"])
			extras["entry"] = _protect("B","A") if tape.size() == 3 else _protect("C","A")
		if step == "CONFIRM_REACTIONS":
			extras["window_id"] = str(replay_state["reaction_window"]["window_id"])
		var cmd: Dictionary = _cmd(replay_state,step,"tape-" + str(tape.size()),extras)
		tape.append(cmd)
		var executed: Dictionary = Phase.apply(replay_state,cmd,cfg)
		if not executed["accepted"]:
			printerr("FAIL M3_3_TAPE_BUILD ",step," ",executed["error"])
			quit(1)
			return
		replay_state = executed["state"]
	var replayed: Dictionary = Phase.replay(si,tape,cfg)
	var again: Dictionary = Phase.replay(si,tape,cfg)
	_ok("M3_3_SEEDED_GUARD_PROTECT_REPLAY", replayed["accepted"] and again["accepted"]
		and replayed["event_hash"] == again["event_hash"]
		and replayed["state_hash"] == again["state_hash"]
		and replayed["state_hash"] == Model.state_hash(replay_state))
	_ok("M3_3_EVENT_SEQUENCE_MONOTONIC", _event_sequence(replay_state)
		and replay_state["event_seq"] == replayed["events"].size())
	_ok("M3_3_REPLAY_CARD_CONSERVATION", Zones.validate_state(replay_state["core"]["cards"]))
	var poisoned: Array[Dictionary] = tape.duplicate(true)
	poisoned.append(tape[0].duplicate(true))
	var reject_tape: Dictionary = Phase.replay(si,poisoned,cfg)
	_ok("M3_3_REPLAY_DUPLICATE_ATOMIC", not reject_tape["accepted"]
		and reject_tape["error"] == "DUPLICATE_COMMAND"
		and reject_tape["state_hash"] == replayed["state_hash"])
	print("M3_3_REPLAY seed=",SEED," initial=",Model.state_hash(si),
		" events=",replayed["event_hash"]," final=",replayed["state_hash"])
	print("M3_3_TEST_REPORT executed=",passed + failed," passed=",passed," failed=",failed)
	if failed == 0:
		print("M3_3_BASIC_DEFENSE_DOMAIN_VERIFIED")
	quit(0 if failed == 0 else 1)

func _event_sequence(s: Dictionary) -> bool:
	if int(s["event_seq"]) != s["events"].size():
		return false
	for i: int in range(s["events"].size()):
		if int(s["events"][i]["event_seq"]) != i+1:
			return false
	return true
