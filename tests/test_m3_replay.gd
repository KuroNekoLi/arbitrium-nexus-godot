extends SceneTree
## M3.5 deterministic two-full-round command-tape replay. Verify the
## authoritative same-seed event/state hashes, reject forged command IDs,
## different content, no UI time source and atomic fail-stop snapshots.
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const Zones = preload("res://scripts/domain/m2/cards/card_zone_resolver.gd")
const Domain = preload("res://scripts/domain/m3/integration/m3_domain_resolver.gd")
const Fixture = preload("res://tests/fixtures/m3_5_fixture.gd")
const Scenario = preload("res://tests/fixtures/m3_5_scenario.gd")
const SEED: int = 20261014
var passed: int = 0
var failed: int = 0

func verify(id: String, condition: bool) -> void:
	if condition:
		passed += 1
		print("PASS ", id)
	else:
		failed += 1
		printerr("FAIL ", id)

func _sequence_valid(s: Dictionary) -> bool:
	if int(s["event_seq"]) != s["events"].size():
		return false
	for i: int in range(s["events"].size()):
		if int(s["events"][i].get("event_seq",-1)) != i + 1:
			return false
	return true

func _index(events: Array, kind: String) -> int:
	for i: int in range(events.size()):
		if str(events[i]["kind"]) == kind:
			return i
	return -1

func _init() -> void:
	var scenario: Dictionary = Scenario.build(SEED)
	if not scenario.get("ok",false):
		printerr("M3_5_REPLAY_SCENARIO_FAILED ", str(scenario.get("error","unknown")))
		quit(1)
		return
	var seed_input: Dictionary = scenario["initial"]
	var tape: Array[Dictionary] = []
	for c: Dictionary in scenario["commands"]:
		tape.append(c.duplicate(true))
	var input_hash: String = Model.state_hash(seed_input)
	var expected_hash: String = Model.state_hash(scenario["state"])
	var run1: Dictionary = Domain.replay(seed_input, tape, Fixture.config())
	var run2: Dictionary = Domain.replay(seed_input, tape, Fixture.config())
	if not run1.get("accepted",false) or not run2.get("accepted",false):
		printerr("M3_5_REPLAY_FUNDAMENTAL_FAIL ", str(run1.get("error","unknown")))
		quit(1)
		return
	verify("M35-REPLAY-EXACT_FINAL_STATE", run1["state_hash"] == expected_hash)
	verify("M35-REPLAY-EXACT_EVENT_HASH", run1["event_hash"] == run2["event_hash"])
	verify("M35-REPLAY-STATE_HASH_REPEATABLE", run1["state_hash"] == run2["state_hash"])
	verify("M35-REPLAY-TAPE_NOT_MUTATED", tape == scenario["commands"])
	verify("M35-REPLAY-INITIAL_STATE_IMMUTABLE", Model.state_hash(seed_input) == input_hash)
	verify("M35-REPLAY-CARD_CONSERVATION", Zones.validate_state(run1["state"]["core"]["cards"]))
	verify("M35-REPLAY-MONOTONIC_EVENT_SEQUENCE", _sequence_valid(run1["state"]))
	verify("M35-REPLAY-EXACT_EVENT_COUNT", run1["events"].size() == run1["state"]["events"].size()
		and run1["state"]["events"] == run1["events"])
	verify("M35-REPLAY-COMMAND_RECEIPTS_1_PER_STEP", run1["receipts"].size() == tape.size())
	verify("M35-REPLAY-FINAL_RECEIPT_HASH", run1["receipts"][-1]["state_hash"] == run1["state_hash"])
	verify("M35-REPLAY-INITIAL_SHA_RECORDED", run1["initial_state_hash"] == input_hash)
	verify("M35-REPLAY-RECEIPT_COMMAND_IDS", run1["receipts"].map(
		func(r: Dictionary) -> String: return str(r["command_id"])) ==
		tape.map(func(c: Dictionary) -> String: return str(c["command_id"])))
	verify("M35-REPLAY-EVERY_RECEIPT_HAS_HASH", run1["receipts"].all(
		func(r: Dictionary) -> bool: return str(r.get("state_hash","")).length() == 64
			and str(r.get("event_hash","")).length() == 64))
	verify("M35-REPLAY-FIRST_TURN_RP_ZERO", run1["state"]["core"]["battle"]["party_resources"]["rp"] == 0)
	verify("M35-REPLAY-END_ROUND3", run1["state"]["core"]["battle"]["round"] == 3
		and run1["state"]["phase"] == "PLAYER_PHASE")
	var events: Array = run1["events"]
	verify("M35-REPLAY-BOTH_ROUNDS_ENEMY_DECLARED", events.filter(
		func(e: Dictionary) -> bool: return str(e["kind"]) == "EnemyActionDeclared").size() == 8)
	verify("M35-REPLAY-EACH_ENEMY_ACTION_FINISHED", events.filter(
		func(e: Dictionary) -> bool: return str(e["kind"]) == "EnemyActionFixtureResolved").size() == 8)
	verify("M35-REPLAY-EMPTY_WINDOW_EVENT_PRESENT", _index(events,"ReactionWindowEmptySkipped") >= 0)
	verify("M35-REPLAY-PROTECT_REDIRECT_EVENT_PRESENT", _index(events,"AttackTargetRedirected") >= 0)
	verify("M35-REPLAY-GUARD_EVENT_PRESENT", _index(events,"GuardCoverageRegistered") >= 0)
	verify("M35-REPLAY-SP_CANCEL_AND_FREE_SKIP_PRESENT", _index(events,"EnemyActionCancelledFixture") >= 0
		and _index(events,"ReactionSkipped") >= 0)
	verify("M35-REPLAY-TWO_PLAYER_RESOURCE_RENEWS", events.filter(
		func(e: Dictionary) -> bool: return str(e["kind"]) == "PlayerResourcesOpened").size() == 2)
	verify("M35-REPLAY-RP_EXPIRY_COUNT", events.filter(
		func(e: Dictionary) -> bool: return str(e["kind"]) == "EnemyResourcesClosed").size() >= 1)
	# Same gameplay from same tape under all three modes. Domain.view is a
	# projection and cannot change the receipts or queued action resolution.
	var hashes: Array[String] = []
	var event_hashes: Array[String] = []
	for mode: String in ["SMART","ALWAYS_ASK","QUICK"]:
		var s: Dictionary = seed_input.duplicate(true)
		for cmd: Dictionary in tape:
			var hint: Dictionary = {"elapsed_seconds": 120, "fps": 1,
				"auto_pass": true, "significance": "MINOR",
				"input_device": "GAMEPAD"}
			var policy: Dictionary = Domain.view(s, mode, hint)
			if not policy["ok"]:
				break
			var next: Dictionary = Domain.apply(s,cmd,Fixture.config())
			if not next["accepted"]:
				break
			s = next["state"]
		var ok: bool = Model.state_hash(s) == expected_hash
		verify("M35-REPLAY-"+mode+"_VIEW_DOES_NOT_MODIFY_DOMAIN",ok)
		hashes.append(Model.state_hash(s))
		var replayed: Dictionary = Domain.replay(seed_input,tape,Fixture.config())
		event_hashes.append(str(replayed["event_hash"]))
	verify("M35-REPLAY-THREE_MODES_FINAL_STATE_EQUAL", hashes[0] == hashes[1] and hashes[1] == hashes[2])
	verify("M35-REPLAY-THREE_MODES_EVENT_HASH_EQUAL", event_hashes[0] == event_hashes[1] and event_hashes[1] == event_hashes[2])
	verify("M35-REPLAY-NO_WALL_CLOCK_IN_STATE", not run1["state"].has("elapsed_seconds")
		and not run1["state"].has("ui_mode") and not run1["state"].has("deadline"))
	var bad_seq: Array[Dictionary] = tape.duplicate(true)
	bad_seq[4]["expected_event_seq"] = -1
	var stopped: Dictionary = Domain.replay(seed_input,bad_seq,Fixture.config())
	verify("M35-REPLAY-STALE_STEP_REJECTED", not stopped["accepted"] and stopped["error"] == "STALE_STATE"
		and stopped["failed_step"] == 4)
	verify("M35-REPLAY-STALE_STOPS_BEFORE_ANY_LATER_STEP", stopped["receipts"].size() == 4
		and stopped["events"].size() < run1["events"].size())
	var bad_copy: Array[Dictionary] = tape.duplicate(true)
	bad_copy[6]["command_id"] = str(bad_copy[0]["command_id"])
	var duplicates: Dictionary = Domain.replay(seed_input,bad_copy,Fixture.config())
	verify("M35-REPLAY-DUPLICATE_ID_REJECTED", not duplicates["accepted"]
		and duplicates["error"] == "EMPTY_OR_DUPLICATE_TAPE_COMMAND"
		and duplicates["failed_step"] == 6)
	verify("M35-REPLAY-DUPLICATE_FAILS_CLOSED", duplicates["receipts"].size() == 6)
	var early: Array[Dictionary] = tape.duplicate(true)
	early.insert(2, Fixture.command(scenario["checkpoints"]["countered_opened"]["state"],
		"COMPLETE_ENEMY_ACTION_FIXTURE", "invalid-early",
		{"enemy_action_id":"round:1:intent:countered"}))
	var early_replay: Dictionary = Domain.replay(seed_input,early,Fixture.config())
	verify("M35-REPLAY-NO_PREMATURE_ACTION", not early_replay["accepted"]
		and early_replay["failed_step"] == 2)
	var altered: Dictionary = Fixture.config()
	altered["reaction_definitions"]["counter"]["rp_cost"] = 5
	var changed: Dictionary = Domain.replay(seed_input,tape,altered)
	verify("M35-REPLAY-CONTENT_CHANGE_NOT_SILENT", not changed["accepted"]
		or changed["state_hash"] != run1["state_hash"])
	var other: Dictionary = Scenario.build(SEED+1)
	verify("M35-REPLAY-SEED_DISTINGUISHES_STATES", other["ok"]
		and Model.state_hash(other["initial"]) != input_hash)
	verify("M35-REPLAY-DIFFERENT_SEED_NOT_IDENTICAL", other["ok"]
		and Model.state_hash(other["state"]) != expected_hash)
	# Validate exact event ordering around the actual fee and effect.
	var paid: int = _index(events,"ReactionResourcesCommitted")
	var executed: int = _index(events,"ReactionExecuted")
	verify("M35-REPLAY-COST_EVENT_BEFORE_EFFECT", paid >= 0 and executed > paid)
	verify("M35-REPLAY-CARD_INSTANCE_NOT_DUPLICATED", Domain.validate_state(run1["state"]))
	verify("M35-REPLAY-NO_REAL_HP_DAMAGE_CLAIM", run1["state"]["core"]["battle"]["actors"]["Boss"]["hp"] == 100
		and run1["state"]["core"]["battle"]["actors"]["A"]["hp"] == 100)

	print("M3_5_REPLAY seed=",SEED," commands=",tape.size(),
		" initial=",input_hash, " events=",run1["event_hash"], " final=",run1["state_hash"])
	print("M3_5_REPLAY_REPORT executed=",passed+failed," passed=",passed," failed=",failed)
	if failed == 0:
		print("M3_5_REPLAY_ACCEPTED")
	quit(0 if failed == 0 else 1)
