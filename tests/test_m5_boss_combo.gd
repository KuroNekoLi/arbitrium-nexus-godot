extends SceneTree
## M5.3 — accepted M2 SP, Boss public intent, whole-SP Break/Exposed/Combo.
const F = preload("res://tests/fixtures/m5_3_fixture.gd")
const M5 = preload("res://scripts/domain/m5/integration/m5_domain_resolver.gd")
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const Zones = preload("res://scripts/domain/m2/cards/card_zone_resolver.gd")
var passed: int = 0
var failed: int = 0
var seq: int = 0
var cfg: Dictionary = {}
var tape: Array[Dictionary] = []

func check(id: String, condition: bool) -> void:
	if condition:
		passed += 1
		print("PASS ",id)
	else:
		failed += 1
		printerr("FAIL ",id)

func count(events: Array, kind: String) -> int:
	var sum: int = 0
	for e: Dictionary in events:
		if str(e.get("kind","")) == kind:
			sum += 1
	return sum

func index(events: Array, kind: String) -> int:
	for i: int in range(events.size()):
		if str(events[i].get("kind","")) == kind:
			return i
	return -1

func command(state: Dictionary, kind: String, options: Dictionary = {},
		record: bool = false) -> Dictionary:
	seq += 1
	var c: Dictionary = {"type":kind,"command_id":"m53-"+str(seq),
		"expected_event_seq":int(state["event_seq"])}
	for k: Variant in options:
		c[k] = options[k]
	var result: Dictionary = M5.apply(state,c,cfg)
	if record and result["accepted"]:
		tape.append(c.duplicate(true))
	return result

func card(state: Dictionary, actor: String) -> String:
	return str(state["core"]["cards"]["actors"][actor]["zones"]["hand"][0])

func play(state: Dictionary, actor: String, mode: String = "NORMAL",
		record: bool = false) -> Dictionary:
	return command(state,"PLAY_TACTICAL_SP_M53",{"actor_id":actor,
		"target_actor_id":"Boss","card_instance_id":card(state,actor),
		"combo_mode":mode},record)

func denied(state: Dictionary, kind: String, options: Dictionary,
		error: String) -> bool:
	var before: String = Model.state_hash(state)
	var result: Dictionary = command(state,kind,options)
	return not result["accepted"] and str(result["error"]) == error and 		result["events"].is_empty() and Model.state_hash(state) == before 		and Model.state_hash(result["state"]) == before

func phase_cycle(state: Dictionary, record: bool = false) -> Dictionary:
	var result: Dictionary = command(state,"END_PLAYER_PHASE",{},record)
	if not result["accepted"]:
		return result
	result = command(result["state"],"DECLARE_NEXT_ENEMY_ACTION",{},record)
	if not result["accepted"]:
		return result
	var action_id: String = str(result["state"]["active_enemy_action_id"])
	result = command(result["state"],"OPEN_REACTION_WINDOW",{
		"enemy_action_id":action_id},record)
	if not result["accepted"]:
		return result
	result = command(result["state"],"PASS_REACTION",{
		"window_id":str(result["state"]["reaction_window"]["window_id"])},record)
	if not result["accepted"]:
		return result
	result = command(result["state"],"RESOLVE_ENEMY_ATTACK_M5",{
		"enemy_action_id":action_id},record)
	if not result["accepted"]:
		return result
	result = command(result["state"],"END_ENEMY_PHASE",{},record)
	if not result["accepted"]:
		return result
	return command(result["state"],"START_PLAYER_PHASE",{},record)

func _init() -> void:
	cfg = F.config()
	var original: Dictionary = F.initial()
	if original.is_empty():
		printerr("M53_FIXTURE_UNAVAILABLE")
		quit(1)
		return
	var initial_hash: String = Model.state_hash(original)
	check("M53-01-SINGLE_M5_BASELINE",not original["core"]["battle"].has("m53"))
	check("M53-02-UNTRUSTED_BREAK_DENIED",denied(original,"PLAY_TACTICAL_SP_M53",{
		"actor_id":"A","target_actor_id":"Boss","card_instance_id":card(original,"A"),
		"break_damage":999},"M51_UNTRUSTED_DAMAGE_PAYLOAD"))
	check("M53-03-CANNOT_STEAL_CARD",denied(original,"PLAY_TACTICAL_SP_M53",{
		"actor_id":"B","target_actor_id":"Boss","card_instance_id":card(original,"A")
		},"M53_CARD_NOT_OWNED_IN_HAND"))
	check("M53-04-INVALID_COMBO_MODE_DENIED",denied(original,"PLAY_TACTICAL_SP_M53",{
		"actor_id":"A","target_actor_id":"Boss","card_instance_id":card(original,"A"),
		"combo_mode":"AUTO"},"M53_INVALID_COMBO_MODE"))
	var done: Dictionary = play(original,"A","NORMAL",true)
	if not done["accepted"]:
		printerr("M53_SETUP_FAILED ",done["error"])
		quit(1)
		return
	var state: Dictionary = done["state"]
	var boss: Dictionary = state["core"]["battle"]["m53"]
	check("M53-05-M2_AP_PAID_ONCE",
		int(state["core"]["battle"]["party_resources"]["current_ap"]) == 5)
	check("M53-06-M2_MP_PAID_ONCE",
		int(state["core"]["battle"]["actors"]["A"]["mp"]) == 9)
	check("M53-07-CARD_HAND_TO_DISCARD",Zones.validate_state(state["core"]["cards"])
		and state["core"]["cards"]["actors"]["A"]["zones"]["discard"].size() == 1)
	check("M53-08-MULTI_HIT_BEFORE_BREAK",count(done["events"],"DamageTrace") == 2
		and index(done["events"],"BreakTriggered") >
		index(done["events"],"DamageTrace"))
	check("M53-09-BREAK_LOCKED_ON_WHOLE_SP",bool(boss["break_locked"])
		and int(boss["break_gauge"]) == 0)
	check("M53-10-BREAK_DISTINCT_FROM_CASTING",
		state["core"]["battle"]["casting_instances"].is_empty()
		and count(done["events"],"CastingInterrupted") == 0)
	check("M53-11-EXPOSED_SINGLE_OPPORTUNITY",
		str(boss["exposed"]["target_id"]) == "Boss"
		and int(boss["exposed"]["expires_round"]) == 2)
	check("M53-12-COMBO_OFFER_WITH_SOURCE",
		str(boss["combo"]["source_actor_id"]) == "A")
	check("M53-13-SOURCE_CANNOT_SELF_COMBO",denied(state,"PLAY_TACTICAL_SP_M53",{
		"actor_id":"A","target_actor_id":"Boss","card_instance_id":card(state,"A"),
		"combo_mode":"COMBO"},"M53_COMBO_OPPORTUNITY_NOT_ELIGIBLE"))
	check("M53-14-STILL_ORIGINAL_IMMUTABLE",Model.state_hash(original) == initial_hash)
	var finish: Dictionary = play(state,"B","COMBO",true)
	if not finish["accepted"]:
		printerr("M53_FINISHER_FAILED ",finish["error"])
		quit(1)
		return
	var fstate: Dictionary = finish["state"]
	var after: Dictionary = fstate["core"]["battle"]["m53"]
	check("M53-15-TWO_DIFFERENT_ACTORS_PAID",
		fstate["core"]["battle"]["paid_cost_command_ids"].size() == 2
		and int(fstate["core"]["battle"]["party_resources"]["current_ap"]) == 4
		and int(fstate["core"]["battle"]["actors"]["B"]["mp"]) == 9)
	check("M53-16-EXTRA_COMBO_AP_ZERO",count(finish["events"],"ComboExecuted") == 1
		and int(finish["events"][index(finish["events"],"ComboExecuted")]["details"]["extra_ap"]) == 0)
	check("M53-17-EXPOSED_CONSUMED_BY_NEXT_SP",after["exposed"].is_empty()
		and count(finish["events"],"ExposedConsumed") == 1)
	check("M53-18-COMBO_CONSUMED_ONCE",after["combo"].is_empty()
		and count(finish["events"],"ComboExecuted") == 1)
	check("M53-19-COMBO_DAMAGE_THROUGH_M51",
		count(finish["events"],"DamageTrace") == 2)
	check("M53-20-BREAK_LOCK_NO_STOCKPILE",int(after["break_gauge"]) == 0
		and count(finish["events"],"BreakDamageIgnoredLocked") == 1)
	check("M53-21-DOUBLE_COMBO_DENIED",denied(fstate,"PLAY_TACTICAL_SP_M53",{
		"actor_id":"C","target_actor_id":"Boss","card_instance_id":card(fstate,"C"),
		"combo_mode":"COMBO"},"M53_COMBO_OPPORTUNITY_NOT_ELIGIBLE"))
	var phase: Dictionary = command(fstate,"END_PLAYER_PHASE",{},true)
	if not phase["accepted"]:
		printerr("M53_BOSS_PUBLISH_FAILED ",phase["error"]);quit(1);return
	var ep: Dictionary = phase["state"]
	check("M53-22-BOSS_INTENT_COMMITTED",count(phase["events"],"BossIntentCommitted") == 1
		and ep["enemy_actions"].size() == 1)
	check("M53-23-BREAK_FALLBACK_PUBLIC",
		str(ep["enemy_actions"][0]["public_intent"]["skill_id"]) == "boss_fallback"
		and bool(ep["enemy_actions"][0]["public_intent"]["break_fallback"]))
	check("M53-24-BOSS_COMMITTED_TARGET",ep["enemy_actions"][0]["public_intent"]["target_ids"] == ["A"])
	var declared: Dictionary = command(ep,"DECLARE_NEXT_ENEMY_ACTION",{},true)
	if not declared["accepted"]:
		printerr("M53_DECLARATION_FAILED ",declared["error"]);quit(1);return
	check("M53-25-DECLARED_INTENT_LOCKED",declared["state"]["enemy_actions"][0]["public_intent"]
		== ep["enemy_actions"][0]["public_intent"])
	var window: Dictionary = command(declared["state"],"OPEN_REACTION_WINDOW",{
		"enemy_action_id":str(declared["state"]["active_enemy_action_id"])},true)
	if not window["accepted"]:
		printerr("M53_WINDOW_FAILED ",window["error"]);quit(1);return
	var pass: Dictionary = command(window["state"],"PASS_REACTION",{
		"window_id":str(window["state"]["reaction_window"]["window_id"])},true)
	if not pass["accepted"]:
		printerr("M53_PASS_FAILED ",pass["error"]);quit(1);return
	var resolve: Dictionary = command(pass["state"],"RESOLVE_ENEMY_ATTACK_M5",{
		"enemy_action_id":str(pass["state"]["active_enemy_action_id"])},true)
	if not resolve["accepted"]:
		printerr("M53_FALLBACK_FAILED ",resolve["error"]);quit(1);return
	check("M53-26-FALLBACK_START_AND_SETTLE",count(resolve["events"],"EnemyActionResolved") == 1
		and count(resolve["events"],"BossBreakRecovered") == 1)
	check("M53-27-BREAK_GAUGE_RESTORED",
		int(resolve["state"]["core"]["battle"]["m53"]["break_gauge"]) == 9
		and not bool(resolve["state"]["core"]["battle"]["m53"]["break_locked"]))
	check("M53-28-FALLBACK_LOWER_HITS",count(resolve["events"],"DamageTrace") == 1)
	var end: Dictionary = command(resolve["state"],"END_ENEMY_PHASE",{},true)
	var start: Dictionary = command(end["state"],"START_PLAYER_PHASE",{},true) if end["accepted"] else end
	check("M53-29-PHASE_ADVANCED",start["accepted"] and
		int(start["state"]["core"]["battle"]["round"]) == 2)
	if start["accepted"]:
		var ordinary: Dictionary = command(start["state"],"END_PLAYER_PHASE",{})
		check("M53-30-NEXT_INTENT_NO_FALLBACK",ordinary["accepted"] and
			str(ordinary["state"]["enemy_actions"][0]["public_intent"]["skill_id"]) == "boss_strike")
	var replay: Dictionary = M5.replay(original,tape,cfg)
	check("M53-31-SEED_TAPE_REPLAY",replay["accepted"])
	check("M53-32-EVENT_HASH_REPLAY",replay["accepted"] and
		replay["event_hash"] == Model.event_hash(start["state"]["events"]))
	check("M53-33-STATE_HASH_REPLAY",replay["accepted"] and
		replay["state_hash"] == Model.state_hash(start["state"]))
	# Alternate scenarios test rejection atomicity and whole-SP boundaries.
	var same: Dictionary = play(F.initial(),"A")
	var again: Dictionary = play(same["state"],"A") if same["accepted"] else same
	check("M53-34-BREAK_DAMAGE_LOCK_IGNORES",again["accepted"] and
		count(again["events"],"BreakDamageIgnoredLocked") == 1)
	check("M53-35-EXPOSED_NOT_REFRESHED",again["accepted"] and
		count(again["events"],"ExposedRefreshIgnored") == 1 and
		int(again["state"]["core"]["battle"]["m53"]["exposed"]["expires_round"]) == 2)
	var alt_cfg: Dictionary = cfg.duplicate(true)
	alt_cfg["m5_3_sp_effects"]["finish"]["damage_profile"]["hit_mode"] = "CONDITIONAL"
	alt_cfg["m5_3_sp_effects"]["finish"]["damage_profile"]["condition_met"] = false
	cfg = alt_cfg
	var missed: Dictionary = play(same["state"],"B","COMBO") if same["accepted"] else same
	check("M53-36-FINISHER_MISS_PAYS",missed["accepted"] and
		int(missed["state"]["core"]["battle"]["party_resources"]["current_ap"]) == 4)
	check("M53-37-MISS_PRESERVES_EXPOSED",missed["accepted"] and
		not missed["state"]["core"]["battle"]["m53"]["exposed"].is_empty())
	check("M53-38-MISS_PRESERVES_COMBO",missed["accepted"] and
		not missed["state"]["core"]["battle"]["m53"]["combo"].is_empty())
	cfg = F.config()
	var original2: Dictionary = F.initial()
	var solo_cfg: Dictionary = cfg.duplicate(true)
	solo_cfg["m5_3_sp_effects"]["setup"]["consume_exposed"] = true
	cfg = solo_cfg
	var self_attempt: Dictionary = play(original2,"A")
	check("M53-39-SELF_CREATED_EXPOSED_NOT_CONSUMED",self_attempt["accepted"] and
		not self_attempt["state"]["core"]["battle"]["m53"]["exposed"].is_empty()
		and count(self_attempt["events"],"ExposedConsumed") == 0)
	cfg = F.config()
	var exp: Dictionary = play(F.initial(),"A")
	var round2: Dictionary = phase_cycle(exp["state"]) if exp["accepted"] else exp
	check("M53-40-NEW_PLAYER_PHASE_KEEP_EXPOSED",round2["accepted"] and
		not round2["state"]["core"]["battle"]["m53"]["exposed"].is_empty())
	var expire: Dictionary = command(round2["state"],"END_PLAYER_PHASE",{}) if round2["accepted"] else round2
	check("M53-41-EXPOSED_EXPIRES_AFTER_NEXT_PLAYER_PHASE",expire["accepted"] and
		expire["state"]["core"]["battle"]["m53"]["exposed"].is_empty()
		and count(expire["events"],"ExposedExpired") == 1)
	var wrong: Dictionary = cfg.duplicate(true)
	wrong["m5_3_boss"]["fallback_skill_id"] = "unknown_skill"
	cfg = wrong
	check("M53-42-INVALID_FALLBACK_FAIL_CLOSED",denied(exp["state"],
		"END_PLAYER_PHASE",{},"M53_FALLBACK_NOT_REGISTERED"))
	cfg = F.config()
	var bad_seed: Array[Dictionary] = tape.duplicate(true)
	bad_seed[0]["expected_event_seq"] = -10
	check("M53-43-REPLAY_BAD_TAPE_STOPS",not M5.replay(original,bad_seed,cfg)["accepted"])
	check("M53-44-NO_CARD_DUPLICATION",Zones.validate_state(fstate["core"]["cards"]))
	print("M5_3_TEST_REPORT executed=",passed+failed," passed=",passed," failed=",failed)
	if failed == 0 and passed == 44:
		print("M5_3_BOSS_BREAK_EXPOSED_COMBO_DOMAIN_VERIFIED")
		print("M5_3_REPLAY seed=",F.SEED," commands=",tape.size(),
			" initial=",initial_hash," events=",Model.event_hash(start["state"]["events"]),
			" final=",Model.state_hash(start["state"]))
	quit(1 if failed > 0 or passed != 44 else 0)
