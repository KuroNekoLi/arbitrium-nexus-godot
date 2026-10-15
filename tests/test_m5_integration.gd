extends SceneTree
## M5.5 golden authentic battle—not just a final-state injection.
const F = preload("res://tests/fixtures/m5_full_battle_fixture.gd")
const Driver = preload("res://tests/fixtures/m5_full_battle_driver.gd")
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const Zones = preload("res://scripts/domain/m2/cards/card_zone_resolver.gd")
var passed: int = 0
var failed: int = 0

func check(id: String, condition: bool) -> void:
	if condition:
		passed += 1
		print("PASS ",id)
	else:
		failed += 1
		printerr("FAIL ",id)

func _init() -> void:
	var start: Dictionary = F.initial(F.SEED)
	if start.is_empty():
		printerr("M55_EMPTY_GOLDEN_ENCOUNTER"); quit(1); return
	var b: Dictionary = start["core"]["battle"]
	check("M55-INT-01-INITIAL_ROUND_ONE",int(b["round"]) == 1 and b["phase"] == "PLAYER_PHASE")
	check("M55-INT-02-ALL_THREE_ACTIVE",F.ACTORS.size() == 3 and
		b["actors"]["A"]["status"] == "ACTIVE" and
		b["actors"]["B"]["status"] == "ACTIVE" and
		b["actors"]["C"]["status"] == "ACTIVE")
	check("M55-INT-03-REAL_FULL_HP_BOSS",int(b["actors"]["Boss"]["hp"]) == 290 and
		int(b["actors"]["Boss"]["max_hp"]) == 290)
	check("M55-INT-04-THREE_DISTINCT_DECK_ROLES",
		F.LOADOUTS["A"] != F.LOADOUTS["B"] and
		F.LOADOUTS["B"] != F.LOADOUTS["C"])
	var intact: bool = true
	for actor: String in F.ACTORS:
		var zone: Dictionary = start["core"]["cards"]["actors"][actor]["zones"]
		if zone["hand"].size() != 4 or zone["draw"].size() != 8 or
				start["core"]["cards"]["actors"][actor]["instances"].size() != 12:
			intact = false
	check("M55-INT-05-ALL_DECKS_12_UNIQUE_INSTANCES",intact and
		Zones.validate_state(start["core"]["cards"]))
	check("M55-INT-06-SHARED_AP6_INDEPENDENT_MP",
		int(b["party_resources"]["current_ap"]) == 6 and
		int(b["actors"]["A"]["mp"]) == 10 and
		int(b["actors"]["C"]["mp"]) == 10)
	var report: Dictionary = Driver.run(F.SEED)
	if not report.get("ok",false):
		printerr("M55_GOLDEN_BATTLE_FAILURE: ",report.get("error","?"),
			" seed=",F.SEED," accepted=",report.get("accepted",0),
			" rounds=",report.get("rounds",0)," coverage=",report.get("coverage",{}))
		quit(1); return
	var c: Dictionary = report["coverage"]
	check("M55-INT-07-REAL_TERMINAL_OUTCOME",["VICTORY","DEFEAT"].has(report["outcome"]))
	check("M55-INT-08-NOT_PRECOOKED_ONE_STEP",int(report["accepted"]) >= 20
		and int(report["rounds"]) >= 4)
	check("M55-INT-09-ONE_LIVE_BOSS_ENCOUNTER",int(report["rounds"]) <= F.MAX_ROUNDS)
	check("M55-INT-10-BOSS_INTENT_PUBLIC",int(c.get("BossIntentCommitted",0)) >= 1)
	check("M55-INT-11-ACTUAL_BOSS_DAMAGE_TRACES",int(c.get("DamageTrace",0)) >= 3)
	check("M55-INT-12-ACTUAL_PLAYER_HP_DAMAGE",int(c.get("HPDamageApplied",0)) >= 2)
	check("M55-INT-13-BREAK_ACTUALLY_TRIGGERED",int(c.get("BreakTriggered",0)) >= 1)
	check("M55-INT-14-BOSS_FALLBACK_ACTUALLY_RESOLVED",int(c.get("BossBreakRecovered",0)) >= 1)
	check("M55-INT-15-EXPOSED_CREATED",int(c.get("ExposedApplied",0)) >= 1)
	check("M55-INT-16-EXPOSED_LATER_CONSUMED",int(c.get("ExposedConsumed",0)) >= 1)
	check("M55-INT-17-TWO_PAID_ACTOR_COMBO",int(c.get("ComboExecuted",0)) >= 1)
	check("M55-INT-18-REAL_FULL_CHANT_RELEASED",int(c.get("CastingReleased",0)) >= 1)
	check("M55-INT-19-LAST_SPELL_REAL_RELEASED",int(c.get("LastSpellReleased",0)) == 1)
	check("M55-INT-20-LAST_SPELL_EXHAUSTED",int(c.get("ActorExhausted",0)) >= 1)
	check("M55-INT-21-EXPLICIT_REACTION",int(c.get("ReactionsConfirmed",0)) >= 1 or
		int(c.get("ReactionsPassed",0)) >= 1 or int(c.get("ReactionPassed",0)) >= 1)
	check("M55-INT-22-REAL_STATUS_GRANTED",int(c.get("StatusApplied",0)) >= 1)
	check("M55-INT-23-REAL_STATUS_TICK",int(c.get("StatusTickStarted",0)) >= 1)
	check("M55-INT-24-CHARGED_AND_DRAWN",
		int(report["final"]["core"]["battle"]["paid_cost_command_ids"].size()) >= 3 and
		int(c.get("CardDrawn",0)) >= 1)
	check("M55-INT-25-NO_NEGATIVE_HP_OR_ZONE_DUPLICATION",
		Zones.validate_state(report["final"]["core"]["cards"]))
	check("M55-INT-26-NO_REJECTED_POLICY_COMMAND",int(report["rejected"]) == 0)
	check("M55-INT-27-REAL_ROUND_PHASE_CHANGE",int(c.get("PlayerPhaseOpened",0)) >= 2)
	check("M55-INT-28-FINISHED_BATTLE_LOCKED",
		str(report["final"]["core"]["battle"]["outcome"]) == report["outcome"])
	var replay: Dictionary = Driver.replay(report)
	check("M55-INT-29-ENTIRE_TAPE_REPLAY_IDENTICAL",replay.get("ok",false))
	check("M55-INT-30-CANONICAL_SHA256",
		str(report["event_hash"]).length() == 64 and
		str(report["final_hash"]).length() == 64 and
		str(report["tape_hash"]).length() == 64)
	check("M55-INT-31-DOMAIN_NEVER_USES_FRAME_CLOCK",
		str(report["prng_version"]) == "park-miller-48271-v1")
	check("M55-INT-32-CONTENT_EXPLICITLY_VERSIONED",
		report["content_version"] == F.CONTENT_VERSION and
		report["config"]["m5_balance_authority"] == "BALANCE_PROVISIONAL")
	print("M5_5_INTEGRATION_REPORT executed=",passed+failed,
		" passed=",passed," failed=",failed)
	if failed == 0 and passed == 32:
		print("M5_5_GOLDEN_FULL_BATTLE_VERIFIED")
		print("M5_5_GOLDEN seed=",F.SEED," commands=",report["accepted"],
			" rounds=",report["rounds"]," outcome=",report["outcome"],
			" tape=",report["tape_hash"]," initial=",report["initial_hash"],
			" events=",report["event_hash"]," final=",report["final_hash"])
	quit(0 if failed == 0 and passed == 32 else 1)
