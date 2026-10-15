extends SceneTree
## M5.2: real paid status SP, stable ticks, Barrier+HP, DoT CORE-02,
## on-hit recipient, explicit Revive and deterministic replay.
const F = preload("res://tests/fixtures/m5_2_fixture.gd")
const M5 = preload("res://scripts/domain/m5/integration/m5_domain_resolver.gd")
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const Status = preload("res://scripts/domain/m5/status/status_resolver.gd")
const Damage = preload("res://scripts/domain/m5/damage/damage_pipeline_resolver.gd")
const Zones = preload("res://scripts/domain/m2/cards/card_zone_resolver.gd")
var passed: int = 0
var failed: int = 0
var cfg: Dictionary = {}
var tape: Array[Dictionary] = []
var no: int = 0

func check(id: String, success: bool) -> void:
	if success:
		passed += 1
		print("PASS ",id)
	else:
		failed += 1
		printerr("FAIL ",id)

func count(ev: Array, kind: String) -> int:
	var n: int = 0
	for e: Dictionary in ev:
		if str(e.get("kind","")) == kind:
			n += 1
	return n

func ix(ev: Array, kind: String) -> int:
	for i: int in range(ev.size()):
		if str(ev[i].get("kind","")) == kind:
			return i
	return -1

func cmd(s: Dictionary, kind: String, data: Dictionary = {},
		record: bool = false) -> Dictionary:
	no += 1
	var c: Dictionary = {"type":kind,"command_id":"m52-"+str(no)+":"+kind,
		"expected_event_seq":int(s["event_seq"])}
	for k: Variant in data:
		c[k] = data[k]
	var r: Dictionary = M5.apply(s,c,cfg)
	if r["accepted"] and record:
		tape.append(c.duplicate(true))
	return r

func card(s: Dictionary, actor: String) -> String:
	return str(s["core"]["cards"]["actors"][actor]["zones"]["hand"][0])

func paid(s: Dictionary, actor: String, target: String, record: bool = false) -> Dictionary:
	return cmd(s,"USE_EFFECT_SP_M5",{
		"actor_id":actor,"target_actor_id":target,
		"card_instance_id":card(s,actor)},record)

func cycle(s: Dictionary, record: bool = false, protect: bool = false) -> Dictionary:
	var a: Dictionary = cmd(s,"END_PLAYER_PHASE",{},record)
	if not a["accepted"]: return a
	a = cmd(a["state"],"DECLARE_NEXT_ENEMY_ACTION",{},record)
	if not a["accepted"]: return a
	a = cmd(a["state"],"OPEN_REACTION_WINDOW",{
		"enemy_action_id":str(a["state"]["active_enemy_action_id"])},record)
	if not a["accepted"]: return a
	if protect:
		var w: String = str(a["state"]["reaction_window"]["window_id"])
		a = cmd(a["state"],"QUEUE_REACTION",{"window_id":w,
			"entry":{"kind":"BASIC_PROTECT","actor_id":"C",
				"target_actor_id":"A"}},record)
		if not a["accepted"]: return a
		a = cmd(a["state"],"CONFIRM_REACTIONS",{
			"window_id":str(a["state"]["reaction_window"]["window_id"])},record)
	else:
		a = cmd(a["state"],"PASS_REACTION",{
			"window_id":str(a["state"]["reaction_window"]["window_id"])},record)
	if not a["accepted"]: return a
	a = cmd(a["state"],"RESOLVE_ENEMY_ATTACK_M5",{
		"enemy_action_id":str(a["state"]["active_enemy_action_id"])},record)
	if not a["accepted"]: return a
	a = cmd(a["state"],"END_ENEMY_PHASE",{},record)
	if not a["accepted"]: return a
	return cmd(a["state"],"START_PLAYER_PHASE",{},record)

func negative(s: Dictionary, kind: String, fields: Dictionary,
		reason: String) -> bool:
	var before: String = Model.state_hash(s)
	var r: Dictionary = cmd(s,kind,fields)
	return not r["accepted"] and str(r["error"]) == reason \
		and Model.state_hash(s) == before \
		and Model.state_hash(r["state"]) == before and r["events"].is_empty()

func _init() -> void:
	cfg = F.config()
	var origin: Dictionary = F.initial()
	if origin.is_empty():
		printerr("M52_INVALID_INITIAL")
		quit(1)
		return
	var init_hash: String = Model.state_hash(origin)
	check("M52-01-NO_UNPAID_STATUS_COMMAND",negative(origin,"USE_EFFECT_SP_M5",{
		"actor_id":"A","target_actor_id":"Boss",
		"card_instance_id":card(origin,"A"),"tick_amount":900},"M51_UNTRUSTED_DAMAGE_PAYLOAD"))
	check("M52-02-TARGET_TEAM_CHECKED",negative(origin,"USE_EFFECT_SP_M5",{
		"actor_id":"B","target_actor_id":"Boss",
		"card_instance_id":card(origin,"B")},"M52_WRONG_TEAM"))
	check("M52-03-CARD_IN_HAND_REQUIRED",negative(origin,"USE_EFFECT_SP_M5",{
		"actor_id":"A","target_actor_id":"Boss","card_instance_id":"FORGED"},"M52_CARD_NOT_IN_HAND"))
	var a: Dictionary = paid(origin,"A","Boss",true)
	if not a["accepted"]:
		printerr("M52_PRIMARY_POISON_FAIL ",a["error"]);quit(1);return
	var s: Dictionary = a["state"]
	check("M52-04-SP_COST_ONCE",s["core"]["battle"]["party_resources"]["current_ap"] == 5
		and s["core"]["battle"]["actors"]["A"]["mp"] == 9)
	check("M52-05-REGISTERED_STATUS_CREATED",s["core"]["battle"]["statuses"].size() == 1
		and s["core"]["battle"]["statuses"][0]["status_id"] == "burn"
		and s["core"]["battle"]["statuses"][0]["target_actor_id"] == "Boss")
	check("M52-06-STATUS_HAS_SOURCE_AND_VERSION",s["core"]["battle"]["statuses"][0]["source_actor_id"] == "A"
		and s["core"]["battle"]["statuses"][0]["definition_version"] == "m5.2-test-v1")
	check("M52-07-NO_PREMATURE_TICK",s["core"]["battle"]["actors"]["Boss"]["hp"] == 100)
	a = paid(s,"B","A",true)
	if not a["accepted"]:
		printerr("M52_WARD_FAIL ",a["error"]);quit(1);return
	s = a["state"]
	check("M52-08-AUTHORITATIVE_BARRIER_CAPACITY",s["core"]["battle"]["hp_barriers"]["A"] == 10.0)
	check("M52-09-WARD_SEPARATE_FROM_CASTING",not s["core"]["battle"].has("focus_ward")
		and s["core"]["battle"]["casting_instances"].is_empty())
	a = paid(s,"C","A",true)
	if not a["accepted"]:
		printerr("M52_REGEN_FAIL ",a["error"]);quit(1);return
	s = a["state"]
	check("M52-10-MULTIPLE_REAL_STATUS_INSTANCES",s["core"]["battle"]["statuses"].size() == 3
		and Status.validate(s["core"],cfg))
	check("M52-11-ONE_AP_PER_PAID_CARD",s["core"]["battle"]["party_resources"]["current_ap"] == 3
		and s["core"]["battle"]["paid_cost_command_ids"].size() == 3)
	var phase_two: Dictionary = cycle(s,true)
	if not phase_two["accepted"]:
		printerr("M52_FIRST_CYCLE_FAIL ",phase_two["error"]);quit(1);return
	s = phase_two["state"]
	check("M52-12-ACTUAL_ENEMY_HIT_SHIELD",s["core"]["battle"]["actors"]["A"]["hp"] == 87)
	check("M52-13-ENEMY_ON_HIT_STATUS_ATTACHED",count(s["events"],"StatusApplied") >= 4)
	check("M52-14-TICK_PRIORITY_DOT_BEFORE_HOT",ix(phase_two["events"],"StatusHPDamageApplied") <
		ix(phase_two["events"],"HPHealed"))
	check("M52-15-BOSS_DOT_REAL_HP",s["core"]["battle"]["actors"]["Boss"]["hp"] == 91)
	check("M52-16-FIRST_TICK_REMAINING_ONE",s["core"]["battle"]["statuses"].size() == 4
		and int(s["core"]["battle"]["statuses"][0]["remaining_ticks"]) == 1)
	check("M52-17-TICKS_BEFORE_PLAYER_AP_REFRESH",ix(phase_two["events"],"StatusTickStarted") <
		ix(phase_two["events"],"PlayerResourcesOpened"))
	check("M52-18-CARDS_CONSERVED",Zones.validate_state(s["core"]["cards"]))
	check("M52-19-HASH_INITIAL_UNCHANGED",Model.state_hash(origin) == init_hash)
	var replay: Dictionary = M5.replay(origin,tape,cfg)
	check("M52-20-DETERMINISTIC_EVENT_REPLAY",replay["accepted"] and
		replay["event_hash"] == Model.event_hash(s["events"]))
	check("M52-21-DETERMINISTIC_STATE_REPLAY",replay["accepted"] and
		replay["state_hash"] == Model.state_hash(s))
	check("M52-22-STABLE_RNG_NOT_FRAME_TIMER",s["core"]["battle"]["rng"]["algorithm"] == "park-miller-48271-v1")
	var bad_tape: Array[Dictionary] = tape.duplicate(true)
	bad_tape[3]["expected_event_seq"] = -1
	check("M52-23-STALE_TAPE_DENIED",not M5.replay(origin,bad_tape,cfg)["accepted"])
	var alt: Dictionary = cfg.duplicate(true)
	alt["m5_status_definitions"]["burn"]["tick_amount"] = 12
	check("M52-24-CONTENT_VERSION_ALTERS_EVENTS",M5.replay(origin,tape,alt)["event_hash"]
		!= replay["event_hash"])
	# Pure versioned stack, refresh, ignore, expiry and dispel.
	var base: Dictionary = F.initial()["core"]
	var burn1: Dictionary = Status.grant(base,"A","Boss","burn","grant-1",cfg)
	var burn2: Dictionary = Status.grant(burn1["core"],"A","Boss","burn","grant-2",cfg)
	var burn3: Dictionary = Status.grant(burn2["core"],"A","Boss","burn","grant-3",cfg)
	var burn4: Dictionary = Status.grant(burn3["core"],"A","Boss","burn","grant-4",cfg)
	check("M52-25-STACK_CAP_THREE",burn4["ok"]
		and burn4["core"]["battle"]["statuses"].size() == 1
		and burn4["core"]["battle"]["statuses"][0]["stacks"] == 3)
	var after: Dictionary = Status.tick(burn4["core"],2,cfg,"manual-round2")
	check("M52-26-STACKED_DOT_REAL_DAMAGE",after["ok"]
		and after["core"]["battle"]["actors"]["Boss"]["hp"] == 73)
	check("M52-27-STATUS_EXPIRES_AFTER_TWO_TICKS",after["ok"]
		and Status.tick(after["core"],3,cfg,"manual-round3")["core"]["battle"]["statuses"].is_empty())
	var frail1: Dictionary = Status.grant(base,"A","Boss","frail","f1",cfg)
	var frail2: Dictionary = Status.grant(frail1["core"],"A","Boss","frail","f2",cfg)
	check("M52-28-IGNORE_NO_RESET",frail2["ok"] and
		frail2["core"]["battle"]["statuses"] == frail1["core"]["battle"]["statuses"]
		and count(frail2["timeline"],"StatusGrantIgnored") == 1)
	var regen1: Dictionary = Status.grant(base,"C","A","regen","g1",cfg)
	var regen2: Dictionary = Status.grant(regen1["core"],"C","A","regen","g2",cfg)
	check("M52-29-REFRESH_RETAINS_INSTANCE_ID",regen2["ok"]
		and regen2["core"]["battle"]["statuses"][0]["status_instance_id"] ==
			regen1["core"]["battle"]["statuses"][0]["status_instance_id"])
	var shield1: Dictionary = Status.grant(base,"B","A","ward","w1",cfg)
	var shield2: Dictionary = Status.grant(shield1["core"],"B","A","ward","w2",cfg)
	check("M52-30-BARRIER_REPLACE_NOT_ACCUMULATE",shield2["ok"]
		and shield2["core"]["battle"]["hp_barriers"]["A"] == 10.0)
	var purified: Dictionary = Status.dispel(burn4["core"],"Boss","NEGATIVE",cfg)
	check("M52-31-DISPEL_TARGETED_BY_TAG",purified["ok"]
		and purified["core"]["battle"]["statuses"].is_empty()
		and count(purified["timeline"],"StatusDispelled") == 1)
	var barrier_tick: Dictionary = Status.tick(shield2["core"],2,cfg,"ward-r2")
	var expired: Dictionary = Status.tick(barrier_tick["core"],3,cfg,"ward-r3")
	check("M52-32-BARRIER_LIFETIME_EXPIRED",expired["ok"]
		and not expired["core"]["battle"]["hp_barriers"].has("A")
		and count(expired["timeline"],"HPBarrierExpired") == 1)
	var rage: Dictionary = Status.grant(base,"C","A","rage","r1",cfg)
	var d1: Dictionary = Damage.resolve(base,"A","Boss",
		F.config()["m5_basic_attack_profile"],{},cfg,"plain")
	var d2: Dictionary = Damage.resolve(rage["core"],"A","Boss",
		F.config()["m5_basic_attack_profile"],{},cfg,"buff")
	check("M52-33-BUFF_CHANGES_REAL_ATTACK",d1["ok"] and d2["ok"]
		and d2["core"]["battle"]["actors"]["Boss"]["hp"] <
			d1["core"]["battle"]["actors"]["Boss"]["hp"])
	var frail: Dictionary = Status.grant(base,"A","Boss","frail","debuff",cfg)
	var weak: Dictionary = Damage.resolve(frail["core"],"A","Boss",
		F.config()["m5_basic_attack_profile"],{},cfg,"weakened-defender")
	check("M52-34-DEBUFF_CHANGES_DEFENSE",weak["ok"] and
		weak["core"]["battle"]["actors"]["Boss"]["hp"] <
			d1["core"]["battle"]["actors"]["Boss"]["hp"])
	# Real payable revive and DoT->Last Spell CORE-02 use independent
	# scenario to preserve first Replay tape and all card conservation.
	var c2: Dictionary = cfg.duplicate(true)
	c2["m5_enemy_on_hit_status"]["boss_strike"]["status_id"] = "poison"
	var start: Dictionary = F.initial(F.SEED,{"A":"burn","B":"revive","C":"heal"})
	var begin: Dictionary = start.duplicate(true)
	var last: Dictionary = M5.apply(start,{
		"type":"ACTIVATE_LAST_SPELL_M4","command_id":"last-start",
		"expected_event_seq":0,"actor_id":"A","target_actor_id":"Boss",
		"confirmed":true,"casting_mode":"FULL"},c2)
	check("M52-35-LAST_LEGALLY_COMMITS",last["accepted"]
		and last["state"]["core"]["battle"]["last_spell_used_by_actor"]["A"] == 1)
	if not last["accepted"]:
		printerr("M52_LAST_SCENARIO ",last["error"]);quit(1);return
	start = last["state"]
	var in_phase: Dictionary = _phase_round(start,c2,false)
	if not in_phase["accepted"]:
		printerr("M52_LAST_CYCLE_FAILED ",in_phase["error"]);quit(1);return
	start = in_phase["state"]
	var e: Array = in_phase["events"]
	check("M52-36-DOT_HP0_IN_SAME_BOUNDARY",start["core"]["battle"]["actors"]["A"]["hp"] == 0
		and start["core"]["battle"]["actors"]["A"]["status"] == "INCAPACITATED")
	check("M52-37-CORE02_STRICT_ORDER",ix(e,"ActorIncapacitated") >= 0
		and ix(e,"ActorIncapacitated") < ix(e,"LastSpellInvalidated")
		and ix(e,"LastSpellInvalidated") < ix(e,"ScheduledEffectCancelled"))
	check("M52-38-NO_LAST_REFUND_OR_RESTORED_QUOTA",
		start["core"]["battle"]["last_spell_used_by_actor"]["A"] == 1
		and not start["core"]["battle"]["casting_instances"].has("last:last-start"))
	check("M52-39-INCAPACITATED_HAND_FROZEN",
		start["core"]["cards"]["actors"]["A"]["zones"]["hand"] ==
			begin["core"]["cards"]["actors"]["A"]["zones"]["hand"])
	var heal_bad: Dictionary = _paid_fixed(start,"C","A",c2,"heal-should-fail")
	check("M52-40-ORDINARY_HEAL_CANNOT_REVIVE",not heal_bad["accepted"]
		and heal_bad["error"] == "M52_TARGET_INCAPACITATED"
		and Model.state_hash(heal_bad["state"]) == Model.state_hash(start))
	var rev: Dictionary = _paid_fixed(start,"B","A",c2,"real-revive")
	check("M52-41-ACTUAL_PAID_REVIVE",rev["accepted"]
		and rev["state"]["core"]["battle"]["actors"]["A"]["hp"] == 35
		and ix(rev["events"],"ActorRevived") >= 0)
	if rev["accepted"]:
		check("M52-42-REVIVE_NEVER_RECREATES_LAST",
			rev["state"]["core"]["battle"]["last_spell_used_by_actor"]["A"] == 1
			and not rev["state"]["core"]["battle"]["casting_instances"].has("last:last-start"))
		check("M52-43-REVIVE_PAYMENT_ONLY_ONCE",
			rev["state"]["core"]["battle"]["paid_cost_command_ids"].size() == 2
			and Zones.validate_state(rev["state"]["core"]["cards"]))
	# Real Protect on-hit redirect: the redirected actual recipient C
	# receives the registered status, A does not.
	var prot: Dictionary = F.initial(F.SEED,{"A":"burn","B":"ward","C":"regen"})
	var pr: Dictionary = _phase_round(prot,cfg,true)
	check("M52-44-ON_HIT_PROTECT_REAL_RECIPIENT",pr["accepted"] and
		_has_status(pr["state"]["core"],"C","burn") and
		not _has_status(pr["state"]["core"],"A","burn"))
	var nofollow: Dictionary = cfg.duplicate(true)
	nofollow["m5_enemy_on_hit_status"]["boss_strike"]["follows_damage_recipient"] = false
	var nf: Dictionary = _phase_round(prot,nofollow,true)
	check("M52-45-ON_HIT_SUPPRESSED_UNLESS_TAGGED",nf["accepted"] and
		not _has_status(nf["state"]["core"],"A","burn") and
		not _has_status(nf["state"]["core"],"C","burn")
		and count(nf["state"]["events"],"StatusOnHitSuppressedByProtect") == 1)
	check("M52-46-ORIGIN_PRESERVED",Model.state_hash(origin) == init_hash)
	check("M52-47-REAL_STATUS_SP_CARD_CONSERVATION",Zones.validate_state(s["core"]["cards"]))
	check("M52-48-ENEMY_DIRECT_HP_UNTRUSTED_REJECTED",negative(origin,
		"RESOLVE_ENEMY_ATTACK_M5",{"hp_after":0},"M51_UNTRUSTED_DAMAGE_PAYLOAD"))
	print("M5_2_REPLAY seed=",F.SEED," commands=",tape.size(),
		" initial=",init_hash," events=",Model.event_hash(s["events"]),
		" final=",Model.state_hash(s))
	print("M5_2_TEST_REPORT executed=",passed+failed,
		" passed=",passed," failed=",failed)
	if failed == 0:
		print("M5_2_STATUS_DOMAIN_VERIFIED")
	quit(0 if failed == 0 else 1)

func _has_status(core: Dictionary, actor: String, status: String) -> bool:
	for item: Dictionary in core["battle"]["statuses"]:
		if str(item["target_actor_id"]) == actor and str(item["status_id"]) == status:
			return true
	return false

func _paid_fixed(s: Dictionary, actor: String, target: String,
		configuration: Dictionary, id: String) -> Dictionary:
	var c: Dictionary = {"type":"USE_EFFECT_SP_M5","command_id":id,
		"expected_event_seq":int(s["event_seq"]),
		"actor_id":actor,"target_actor_id":target,
		"card_instance_id":card(s,actor)}
	return M5.apply(s,c,configuration)

func _phase_round(initial: Dictionary, configuration: Dictionary, protect: bool) -> Dictionary:
	var state: Dictionary = initial.duplicate(true)
	var kinds: Array[String] = ["END_PLAYER_PHASE","DECLARE_NEXT_ENEMY_ACTION",
		"OPEN_REACTION_WINDOW","RESOLVE_ENEMY_ATTACK_M5","END_ENEMY_PHASE",
		"START_PLAYER_PHASE"]
	var events: Array = []
	var n: int = 0
	for kind: String in kinds:
		if kind == "RESOLVE_ENEMY_ATTACK_M5":
			var wid: String = str(state["reaction_window"]["window_id"])
			if protect:
				var queue: Dictionary = M5.apply(state,{
					"type":"QUEUE_REACTION","command_id":"p:queue",
					"expected_event_seq":int(state["event_seq"]),"window_id":wid,
					"entry":{"kind":"BASIC_PROTECT","actor_id":"C",
						"target_actor_id":"A"}},configuration)
				if not queue["accepted"]: return queue
				state = queue["state"]
				events.append_array(queue["events"])
			var window_end: Dictionary = M5.apply(state,{
				"type":"CONFIRM_REACTIONS" if protect else "PASS_REACTION",
				"command_id":"p:confirm",
				"expected_event_seq":int(state["event_seq"]),"window_id":wid
			},configuration)
			if not window_end["accepted"]: return window_end
			state = window_end["state"]
			events.append_array(window_end["events"])
		n += 1
		var args: Dictionary = {}
		if kind == "OPEN_REACTION_WINDOW" or kind == "RESOLVE_ENEMY_ATTACK_M5":
			args["enemy_action_id"] = str(state["active_enemy_action_id"])
		var c: Dictionary = {"type":kind,"command_id":"p:stage:"+str(n),
			"expected_event_seq":int(state["event_seq"])}
		for key: Variant in args: c[key] = args[key]
		var result: Dictionary = M5.apply(state,c,configuration)
		if not result["accepted"]: return result
		state = result["state"]
		events.append_array(result["events"])
	return {"accepted":true,"state":state,"events":events}
