extends SceneTree
## M5.5 mandatory 100 fixed seeds, each from ACTUAL initial encounter
## through authentic terminal Outcome, then same-tape deterministic replay.
const F = preload("res://tests/fixtures/m5_full_battle_fixture.gd")
const Driver = preload("res://tests/fixtures/m5_full_battle_driver.gd")
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const Zones = preload("res://scripts/domain/m2/cards/card_zone_resolver.gd")
const N: int = 100
var passed: int = 0
var failed: int = 0
func check(id: String, ok: bool) -> void:
	if ok:
		passed += 1
		print("PASS ",id)
	else:
		failed += 1
		printerr("FAIL ",id)

func _init() -> void:
	var distinct_tapes: Dictionary = {}
	var distinct_events: Dictionary = {}
	var total_commands: int = 0
	var total_rejected: int = 0
	var maximum_rounds: int = 0
	var max_events: int = 0
	var victories: int = 0
	var defeats: int = 0
	var replay_ok: bool = true
	var status_ok: bool = true
	var resource_ok: bool = true
	var policy_ok: bool = true
	var first_hp0_count: int = 0
	var fallback_count: int = 0
	var start_ms: int = Time.get_ticks_msec()
	for i: int in range(N):
		var seed: int = F.SEED + i
		var report: Dictionary = Driver.run(seed)
		if not report.get("ok",false):
			printerr("M5_5_SEED_FAILURE seed=",seed," reason=",
				report.get("error","?")," commands=",report.get("accepted",0))
			check("M55-SEED-"+str(seed),false)
			replay_ok = false
			status_ok = false
			resource_ok = false
			policy_ok = false
			continue
		var replay: Dictionary = Driver.replay(report)
		var valid: bool = replay.get("ok",false)
		check("M55-SEED-"+str(seed),valid and \
			["VICTORY","DEFEAT"].has(str(report["outcome"])) and \
			int(report["rejected"]) == 0 and \
			int(report["accepted"]) > 0 and \
			int(report["events"]) <= Driver.MAX_EVENTS)
		replay_ok = replay_ok and valid
		if not Zones.validate_state(report["final"]["core"]["cards"]):
			resource_ok = false
		if not ["VICTORY","DEFEAT"].has(str(report["outcome"])):
			status_ok = false
		if int(report["rejected"]) != 0 or \
				int(report["accepted"]) > Driver.MAX_COMMANDS:
			policy_ok = false
		if int(report["first_hp0_event_seq"]) >= 0:
			first_hp0_count += 1
		fallback_count += int(report["fallback_count"])
		total_commands += int(report["accepted"])
		total_rejected += int(report["rejected"])
		maximum_rounds = maxi(maximum_rounds,int(report["rounds"]))
		max_events = maxi(max_events,int(report["events"]))
		if report["outcome"] == "VICTORY":
			victories += 1
		elif report["outcome"] == "DEFEAT":
			defeats += 1
		distinct_tapes[str(report["tape_hash"])] = true
		distinct_events[str(report["event_hash"])] = true
		print("M5_5_SEED_REPORT seed=",seed,
			" ruleset=",report["ruleset_version"],
			" content=",report["content_version"],
			" prng=",report["prng_version"],
			" accepted=",report["accepted"]," rejected=",report["rejected"],
			" rounds=",report["rounds"]," events=",report["events"],
			" first_hp0=",report["first_hp0_event_seq"],
			" fallback=",report["fallback_count"],
			" outcome=",report["outcome"],
			" init=",report["initial_hash"]," tape=",report["tape_hash"],
			" event=",report["event_hash"]," final=",report["final_hash"],
			" elapsed_ms=",report["elapsed_ms"])
	check("M55-100-01-EXACTLY_100_SEEDS",victories+defeats == N)
	check("M55-100-02-EVERY_TAPE_REPLAY",replay_ok)
	check("M55-100-03-TERMINAL_OUTCOMES",status_ok)
	check("M55-100-04-NO_INVALID_RESOURCE_OR_ZONES",resource_ok)
	check("M55-100-05-NO_REJECTED_POLICY_COMMANDS",policy_ok and total_rejected == 0)
	check("M55-100-06-MULTIPLE_SEEDED_COMMAND_TAPES",distinct_tapes.size() >= 2)
	check("M55-100-07-DISTINCT_EVENT_HASHES",distinct_events.size() == N)
	check("M55-100-08-OBSERVED_HP_ZERO_BOUNDARIES",first_hp0_count >= 1)
	check("M55-100-09-FALLBACK_GENUINELY_USED",fallback_count >= 1)
	check("M55-100-10-FINITE_ALL_ENCOUNTERS",
		maximum_rounds <= F.MAX_ROUNDS and max_events <= Driver.MAX_EVENTS and \
		total_commands <= Driver.MAX_COMMANDS*N)
	print("M5_5_100_SEEDS_REPORT executed=",passed+failed,
		" passed=",passed," failed=",failed," runs=",N,
		" victories=",victories," defeats=",defeats,
		" commands=",total_commands," rejected=",total_rejected,
		" max_rounds=",maximum_rounds," max_events=",max_events,
		" distinct_tapes=",distinct_tapes.size(),
		" elapsed_ms=",Time.get_ticks_msec()-start_ms)
	if failed == 0 and passed == 110:
		print("M5_5_100_SEEDED_FULL_BATTLES_VERIFIED")
	quit(0 if failed == 0 and passed == 110 else 1)
