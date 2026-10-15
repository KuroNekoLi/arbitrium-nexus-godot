extends SceneTree
## M5.1 actual HP-hit Godot Domain assertions + same-seed M2/M3/M4 Replay.
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const RNG = preload("res://scripts/domain/m1/combat_rng.gd")
const Hit = preload("res://scripts/domain/m5/damage/hit_resolver.gd")
const Crit = preload("res://scripts/domain/m5/damage/critical_resolver.gd")
const Damage = preload("res://scripts/domain/m5/damage/damage_pipeline_resolver.gd")
const M5 = preload("res://scripts/domain/m5/integration/m5_domain_resolver.gd")
const Zones = preload("res://scripts/domain/m2/cards/card_zone_resolver.gd")
const Fixture = preload("res://tests/fixtures/m5_1_fixture.gd")
var passed: int = 0
var failed: int = 0
var tape: Array[Dictionary] = []
var config: Dictionary = {}

func check(id: String, yes: bool) -> void:
	if yes:
		passed += 1
		print("PASS ",id)
	else:
		failed += 1
		printerr("FAIL ",id)

func record(s: Dictionary, name: String, fields: Dictionary = {}) -> Dictionary:
	var request: Dictionary = {"type":name,"command_id":"m51-"+str(tape.size())+"-"+name,
		"expected_event_seq":int(s["event_seq"])}
	for key: Variant in fields:
		request[key] = fields[key]
	var result: Dictionary = M5.apply(s,request,config)
	if result["accepted"]:
		tape.append(request.duplicate(true))
	return result

func index_of(events: Array, name: String) -> int:
	for i: int in range(events.size()):
		if str(events[i].get("kind","")) == name:
			return i
	return -1

func count(events: Array, name: String) -> int:
	var result: int = 0
	for e: Dictionary in events:
		if str(e.get("kind","")) == name:
			result += 1
	return result

func negative(s: Dictionary, command: Dictionary, expected: String) -> bool:
	var h: String = Model.state_hash(s)
	var r: Dictionary = M5.apply(s,command,config)
	return not r["accepted"] and str(r["error"]) == expected \
		and Model.state_hash(s) == h and Model.state_hash(r["state"]) == h \
		and r["events"].is_empty()

func _init() -> void:
	config = Fixture.config()
	var initial: Dictionary = Fixture.initial()
	if initial.is_empty() or config.is_empty():
		printerr("M51_BAD_FIXTURE")
		quit(1)
		return
	check("M51-01-AUTHORITY_ENFORCED",negative(initial,{"type":"BASIC_ATTACK_RESOURCE_ONLY",
		"command_id":"m51-forge","expected_event_seq":0,"actor_id":"A",
		"target_actor_id":"Boss","final_damage":999},"M51_UNTRUSTED_DAMAGE_PAYLOAD"))
	check("M51-02-FIXTURE_HP0_NOT_PLAYER_COMMAND",negative(initial,{
		"type":"APPLY_INCAPACITATION_M4_FIXTURE","command_id":"m51-hp0",
		"expected_event_seq":0},"M51_INTERNAL_FIXTURE_NOT_PUBLIC"))
	var offline: Dictionary = config.duplicate(true)
	offline["m5_damage_enabled"] = false
	check("M51-03-M5_DISABLED_FAIL_CLOSED",not M5.apply(initial,{
		"type":"BASIC_ATTACK_RESOURCE_ONLY","command_id":"no-m5",
		"expected_event_seq":0,"actor_id":"A"},offline)["accepted"])
	var rng: Dictionary = RNG.initial_state(Fixture.SEED)
	var a: Dictionary = config["m5_actor_stats"]["A"]
	var boss: Dictionary = config["m5_actor_stats"]["Boss"]
	var sure: Dictionary = Hit.resolve(rng,Fixture.profile(),a,boss,config["m5_balance"])
	check("M51-04-GUARANTEED_NO_RNG",sure["ok"] and sure["hit"]
		and sure["rng"] == rng and sure["chance_bp"] == 10000)
	var random: Dictionary = Hit.resolve(rng,Fixture.profile("PHYSICAL","RANDOM_PERCENT"),
		a,boss,config["m5_balance"])
	check("M51-05-CHANCE_PERCENT_RNG_ONCE",random["ok"] and random["chance_bp"] == 8500
		and random["rng"]["draw_index"] == 1 and random["roll_bp"] >= 0)
	var hi: Dictionary = a.duplicate(true)
	hi["accuracy"] = 10000
	var lo: Dictionary = a.duplicate(true)
	lo["accuracy"] = 0
	var evasive: Dictionary = boss.duplicate(true)
	evasive["evasion"] = 10000
	check("M51-06-HIT_CLAMP_95",Hit.resolve(rng,Fixture.profile("PHYSICAL",
		"RANDOM_PERCENT"),hi,boss,config["m5_balance"])["chance_bp"] == 9500)
	check("M51-07-HIT_CLAMP_05",Hit.resolve(rng,Fixture.profile("PHYSICAL",
		"RANDOM_PERCENT"),lo,evasive,config["m5_balance"])["chance_bp"] == 500)
	var condition: Dictionary = Fixture.profile("MAGICAL","CONDITIONAL")
	condition["condition_met"] = false
	var conditional: Dictionary = Hit.resolve(rng,condition,a,boss,config["m5_balance"])
	check("M51-08-CONDITIONAL_MISS_NO_RNG",conditional["ok"]
		and not conditional["hit"] and conditional["rng"] == rng)
	var missing_condition: Dictionary = Fixture.profile("MAGICAL","CONDITIONAL")
	check("M51-09-CONDITIONAL_MUST_BE_DEFINED",not Hit.resolve(rng,
		missing_condition,a,boss,config["m5_balance"])["ok"])
	var ineligible: Dictionary = Crit.resolve(rng,false,a)
	check("M51-10-INELIGIBLE_CRIT_NO_RNG",ineligible["ok"]
		and not ineligible["critical"] and ineligible["rng"] == rng)
	var allcrit: Dictionary = a.duplicate(true)
	allcrit["crit_rate_bp"] = 10000
	var critical: Dictionary = Crit.resolve(rng,true,allcrit)
	check("M51-11-ELIGIBLE_CRIT_100_PERCENT",critical["ok"] and critical["critical"]
		and critical["rng"]["draw_index"] == 1)
	var damage: Dictionary = Damage.resolve(initial["core"],"A","Boss",
		Fixture.profile(),{},config,"pure-damage")
	check("M51-12-REAL_HP_DEDUCTED",damage["ok"]
		and damage["core"]["battle"]["actors"]["Boss"]["hp"] == 84)
	check("M51-13-ONE_TRACE_ONE_HP_EVENT",damage["timeline"].size() == 2
		and damage["timeline"][0]["kind"] == "DamageTrace"
		and damage["timeline"][1]["kind"] == "HPDamageApplied")
	check("M51-14-DAMAGE_SOURCE_IMMUTABLE",initial["core"]["battle"]["actors"]["Boss"]["hp"] == 100)
	check("M51-15-MISS_HAS_ZERO_DAMAGE_AND_NO_CRIT_ROLL",_miss_is_atomic(initial))
	var flame: Dictionary = Damage.resolve(initial["core"],"A","Boss",
		Fixture.profile("MAGICAL","GUARANTEED",1,false,"FIRE"),{},config,"fire")
	check("M51-16-ELEMENT_BY_ENEMY",flame["ok"] and
		flame["core"]["battle"]["actors"]["Boss"]["hp"] < damage["core"]["battle"]["actors"]["Boss"]["hp"])
	var protected: Dictionary = Damage.resolve(initial["core"],"Boss","A",
		Fixture.profile(),{"damage_recipient_actor_id":"C","protect_confirmed":true},config,"protect")
	check("M51-17-PROTECT_USES_RECIPIENT_DEFENSE",protected["ok"]
		and protected["core"]["battle"]["actors"]["A"]["hp"] == 100
		and protected["core"]["battle"]["actors"]["C"]["hp"] == 92
		and protected["timeline"][0]["recipient_id"] == "C")
	check("M51-18-UNAUTHORIZED_REDIRECT_REJECTED",not Damage.resolve(initial["core"],
		"Boss","A",Fixture.profile(),{"damage_recipient_actor_id":"C"},config,"fake")["ok"])
	var shielded: Dictionary = initial["core"].duplicate(true)
	shielded["battle"]["hp_barriers"] = {"A":4.0}
	var warded: Dictionary = Damage.resolve(shielded,"Boss","A",Fixture.profile(),
		{"guard_actor_ids":["A"]},config,"guard-barrier")
	check("M51-19-GUARD_THEN_BARRIER",warded["ok"]
		and warded["timeline"][0]["guard_applied"]
		and warded["timeline"][0]["barrier_absorbed"] == 4.0
		and warded["core"]["battle"]["actors"]["A"]["hp"] == 98)
	check("M51-20-FOCUS_WARD_NOT_HP_BARRIER",warded["ok"]
		and not warded["core"]["battle"].has("casting_focus_ward"))
	var small: Dictionary = config.duplicate(true)
	small["m5_actor_stats"]["A"]["patk"] = 0
	var zero: Dictionary = Damage.resolve(initial["core"],"A","Boss",Fixture.profile(),{},small,"zero")
	check("M51-21-ZERO_DAMAGE_NOT_CHIP_ONE",zero["ok"]
		and zero["core"]["battle"]["actors"]["Boss"]["hp"] == 100)
	var multi: Dictionary = Damage.resolve(initial["core"],"Boss","A",
		Fixture.profile("PHYSICAL","GUARANTEED",2),{},config,"two-hit")
	check("M51-22-MULTIHIT_TWO_REAL_DAMAGE_EVENTS",multi["ok"]
		and count(multi["timeline"],"HPDamageApplied") == 2
		and multi["core"]["battle"]["actors"]["A"]["hp"] == 80)
	var missing: Dictionary = config.duplicate(true)
	missing["m5_element_resistance"]["Boss"].erase("NEUTRAL")
	check("M51-23-UNKNOWN_ELEMENT_FAILS_CLOSED",not Damage.resolve(initial["core"],
		"A","Boss",Fixture.profile(),{},missing,"invalid")["ok"])
	var doomed: Dictionary = initial["core"].duplicate(true)
	doomed["battle"]["actors"]["A"]["hp"] = 4
	var killed: Dictionary = Damage.resolve(doomed,"Boss","A",Fixture.profile(),{},config,"hp0")
	check("M51-24-REAL_HP0_CALLS_M4_INVALIDATOR",killed["ok"]
		and killed["core"]["battle"]["actors"]["A"]["hp"] == 0
		and killed["core"]["battle"]["actors"]["A"]["status"] == "INCAPACITATED"
		and count(killed["timeline"],"ActorIncapacitated") == 1)
	var begin_hash: String = Model.state_hash(initial)
	var hand: String = str(initial["core"]["cards"]["actors"]["A"]["zones"]["hand"][0])
	var chantless: Dictionary = record(initial,"CAST_SPELL_M4",{
		"actor_id":"A","target_actor_id":"Boss","card_instance_id":hand,
		"casting_mode":"CHANTLESS"})
	if not chantless["accepted"]:
		printerr("M51_CHANTLESS_FAILURE ",chantless["error"]);quit(1);return
	var s: Dictionary = chantless["state"]
	check("M51-25-CHANTLESS_REAL_DAMAGE_BEFORE_OUTCOME",index_of(chantless["events"],"DamageTrace") >= 0
		and index_of(chantless["events"],"DamageTrace") <
		index_of(chantless["events"],"BattleOutcomeEvaluated"))
	check("M51-26-CHANTLESS_AP_MP_ONCE",s["core"]["battle"]["party_resources"]["current_ap"] == 5
		and s["core"]["battle"]["actors"]["A"]["mp"] == 6
		and s["core"]["battle"]["paid_cost_command_ids"].size() == 1)
	check("M51-27-CHANTLESS_NOT_DEFERRED",index_of(chantless["events"],"SpellEffectDeferredToM5") == -1
		and s["core"]["battle"]["actors"]["Boss"]["hp"] == 84)
	var c: String = str(s["core"]["cards"]["actors"]["B"]["zones"]["hand"][0])
	var full: Dictionary = record(s,"CAST_SPELL_M4",{"actor_id":"B",
		"card_instance_id":c,"target_actor_id":"Boss","casting_mode":"FULL"})
	if not full["accepted"]:
		printerr("M51_FULL_FAILURE ",full["error"]);quit(1);return
	s = full["state"]
	check("M51-28-FULL_NO_EARLY_DAMAGE",s["core"]["battle"]["actors"]["Boss"]["hp"] == 84
		and s["core"]["battle"]["actors"]["B"]["status"] == "CONCENTRATING")
	var basic: Dictionary = record(s,"BASIC_ATTACK_RESOURCE_ONLY",{
		"actor_id":"C","target_actor_id":"Boss"})
	if not basic["accepted"]:
		printerr("M51_BASIC_FAILURE ",basic["error"]);quit(1);return
	s = basic["state"]
	check("M51-29-BASIC_ATTACK_REAL_DAMAGE",s["core"]["battle"]["actors"]["Boss"]["hp"] == 68
		and index_of(basic["events"],"DamageTrace") >= 0)
	check("M51-30-BASIC_STILL_ONLY_ONE_M2_RESOURCE_TRANSACTION",
		s["core"]["battle"]["actors"]["C"]["mp"] == 10
		and s["core"]["battle"]["party_resources"]["current_ap"] == 3)
	var ended: Dictionary = record(s,"END_PLAYER_PHASE")
	if not ended["accepted"]:
		printerr("M51_END_PLAYER_FAIL ",ended["error"]);quit(1);return
	var declared: Dictionary = record(ended["state"],"DECLARE_NEXT_ENEMY_ACTION")
	if not declared["accepted"]:
		printerr("M51_DECLARE_FAIL ",declared["error"]);quit(1);return
	var opened: Dictionary = record(declared["state"],"OPEN_REACTION_WINDOW",{
		"enemy_action_id":str(declared["state"]["active_enemy_action_id"])})
	if not opened["accepted"]:
		printerr("M51_OPEN_FAIL ",opened["error"]);quit(1);return
	var passed_window: Dictionary = record(opened["state"],"PASS_REACTION",{
		"window_id":str(opened["state"]["reaction_window"]["window_id"])})
	if not passed_window["accepted"]:
		printerr("M51_PASS_FAIL ",passed_window["error"]);quit(1);return
	check("M51-31-REACTION_EXPLICIT_PASS_REQUIRED",
		str(passed_window["state"]["reaction_window"]["status"]) == "CLOSED")
	var attacked: Dictionary = record(passed_window["state"],"RESOLVE_ENEMY_ATTACK_M5",{
		"enemy_action_id":str(passed_window["state"]["active_enemy_action_id"])})
	if not attacked["accepted"]:
		printerr("M51_ENEMY_ATTACK_FAIL ",attacked["error"]);quit(1);return
	s = attacked["state"]
	check("M51-32-ENEMY_ACTION_REAL_TWO_HITS",s["core"]["battle"]["actors"]["A"]["hp"] == 80
		and count(attacked["events"],"DamageTrace") == 2)
	check("M51-33-ENEMY_DAMAGE_BEFORE_OUTCOME",index_of(attacked["events"],"DamageTrace")
		< index_of(attacked["events"],"BattleOutcomeEvaluated"))
	check("M51-34-ENEMY_INTENT_NOT_REPLACED",index_of(attacked["events"],"EnemyActionResolved") >= 0
		and s["core"]["battle"]["actors"]["Boss"]["hp"] == 68)
	var enemy_end: Dictionary = record(s,"END_ENEMY_PHASE")
	if not enemy_end["accepted"]:
		printerr("M51_ENEMY_END_FAIL ",enemy_end["error"]);quit(1);return
	var new_player: Dictionary = record(enemy_end["state"],"START_PLAYER_PHASE")
	if not new_player["accepted"]:
		printerr("M51_PHASE_START_FAIL ",new_player["error"]);quit(1);return
	s = new_player["state"]
	check("M51-35-FULL_RELEASE_DOES_REAL_HP",s["core"]["battle"]["actors"]["Boss"]["hp"] == 52
		and s["core"]["battle"]["actors"]["B"]["status"] == "ACTIVE")
	check("M51-36-FULL_RELEASE_BEFORE_AP_DRAW",index_of(new_player["events"],"DamageTrace") >= 0
		and index_of(new_player["events"],"DamageTrace") <
		index_of(new_player["events"],"PlayerResourcesOpened"))
	check("M51-37-FULL_CARD_UNIQUE_DISCARD",Zones.validate_state(s["core"]["cards"])
		and s["core"]["cards"]["actors"]["B"]["zones"]["casting"].is_empty())
	check("M51-38-FULL_NO_SECOND_PAYMENT",
		s["core"]["battle"]["paid_cost_command_ids"].size() == 2)
	check("M51-39-INITIAL_IMMUTABLE",Model.state_hash(initial) == begin_hash)
	var replay: Dictionary = M5.replay(initial,tape,config)
	check("M51-40-SAME_TAPE_EVENT_HASH",replay["accepted"]
		and replay["event_hash"] == Model.event_hash(s["events"]))
	check("M51-41-SAME_TAPE_FINAL_HASH",replay["accepted"]
		and replay["state_hash"] == Model.state_hash(s))
	var stale: Array[Dictionary] = tape.duplicate(true)
	stale[2]["expected_event_seq"] = -5
	check("M51-42-STALE_REPLAY_REFUSED",not M5.replay(initial,stale,config)["accepted"])
	var changed: Dictionary = config.duplicate(true)
	changed["m5_element_resistance"]["Boss"]["NEUTRAL"] = 8000
	var rerun: Dictionary = M5.replay(initial,tape,changed)
	check("M51-43-CONTENT_CHANGE_ALTERS_HASH",rerun["accepted"]
		and rerun["event_hash"] != replay["event_hash"])
	check("M51-44-REAL_DAMAGE_NOT_FREE_FIXTURE",count(s["events"],"HPDamageApplied") >= 4
		and not s["core"]["battle"].has("fake_hp_delta"))
	print("M5_1_REPLAY seed=",Fixture.SEED," commands=",tape.size(),
		" initial=",begin_hash," events=",Model.event_hash(s["events"]),
		" final=",Model.state_hash(s))
	print("M5_1_TEST_REPORT executed=",passed+failed,
		" passed=",passed," failed=",failed)
	if failed == 0:
		print("M5_1_DAMAGE_DOMAIN_VERIFIED")
	quit(0 if failed == 0 else 1)

func _miss_is_atomic(initial: Dictionary) -> bool:
	var c: Dictionary = config.duplicate(true)
	c["m5_actor_stats"]["A"]["accuracy"] = 0
	c["m5_actor_stats"]["Boss"]["evasion"] = 10000
	var p: Dictionary = Fixture.profile("PHYSICAL","CONDITIONAL",1,true)
	p["condition_met"] = false
	var result: Dictionary = Damage.resolve(initial["core"],"A","Boss",p,{},c,"miss")
	return result["ok"] and result["core"]["battle"]["actors"]["Boss"]["hp"] == 100 \
		and result["core"]["battle"]["rng"] == initial["core"]["battle"]["rng"] \
		and result["timeline"].size() == 1 \
		and not result["timeline"][0]["hit"] \
		and int(result["timeline"][0]["crit_roll_bp"]) == -1
