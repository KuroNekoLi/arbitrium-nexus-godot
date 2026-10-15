extends SceneTree
## Complete accepted CommandTape, replay receipts, RNG and presentation isolation.
const F = preload("res://tests/fixtures/m5_full_battle_fixture.gd")
const Driver = preload("res://tests/fixtures/m5_full_battle_driver.gd")
const M5 = preload("res://scripts/domain/m5/integration/m5_domain_resolver.gd")
const Model = preload("res://scripts/domain/m1/combat_model.gd")
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
	var a: Dictionary = Driver.run(F.SEED)
	if not a.get("ok",false):
		printerr("M55_REPLAY_FULL_BATTLE_FAILED: ",a.get("error",""))
		quit(1);return
	var second: Dictionary = Driver.run(F.SEED)
	var receipts: Dictionary = M5.replay(a["initial"],a["tape"],a["config"])
	var replay: Dictionary = Driver.replay(a)
	check("M55-REP-01-REAL_BATTLE_TERMINAL",a["ok"] and
		["VICTORY","DEFEAT"].has(a["outcome"]))
	check("M55-REP-02-SAME_SEED_IDENTICAL_CARD_SHUFFLE",second["ok"] and
		Model.state_hash(second["initial"]) == a["initial_hash"])
	check("M55-REP-03-SAME_SEED_IDENTICAL_TAPE",second["ok"] and
		second["tape_hash"] == a["tape_hash"])
	check("M55-REP-04-SAME_SEED_IDENTICAL_EVENTS",second["ok"] and
		second["event_hash"] == a["event_hash"])
	check("M55-REP-05-SAME_SEED_IDENTICAL_FINAL_STATE",second["ok"] and
		second["final_hash"] == a["final_hash"])
	check("M55-REP-06-M5_REDUCER_REPLAY_ACCEPTED",receipts["accepted"])
	check("M55-REP-07-REPLAY_EVENT_HASH",replay.get("ok",false) and
		receipts["event_hash"] == a["event_hash"])
	check("M55-REP-08-REPLAY_FINAL_HASH",replay.get("ok",false) and
		receipts["state_hash"] == a["final_hash"])
	check("M55-REP-09-ALL_ACTUAL_COMMANDS_RETAIN_SEQ",
		a["tape"].size() == int(a["accepted"]) and
		int(a["tape"][0]["expected_event_seq"]) == 0)
	var original_hash: String = Model.state_hash(a["initial"])
	check("M55-REP-10-REPLAY_PRESERVES_INITIAL",
		Model.state_hash(a["initial"]) == original_hash)
	var tampered: Array[Dictionary] = a["tape"].duplicate(true)
	tampered[0]["expected_event_seq"] = -1
	var refused: Dictionary = M5.replay(a["initial"],tampered,a["config"])
	check("M55-REP-11-STALE_TAPE_FAIL_CLOSED",not refused["accepted"] and
		refused["events"].is_empty() and
		Model.state_hash(refused["state"]) == original_hash)
	var appended: Array[Dictionary] = a["tape"].duplicate(true)
	appended.append({"type":"END_PLAYER_PHASE","command_id":"post-win-forged",
		"expected_event_seq":int(a["final"]["event_seq"])})
	var terminal: Dictionary = M5.replay(a["initial"],appended,a["config"])
	check("M55-REP-12-POST_TERMINAL_TAPE_FAIL_CLOSED",
		not terminal["accepted"] and terminal["error"] == "BATTLE_ENDED" and
		Model.state_hash(terminal["state"]) == a["final_hash"])
	# Presentation options are explicitly *not* part of the Domain command
	# tape. Reuse the same tape in three viewport policy configurations:
	# Godot emits exactly the same hashes with no frame/time dependency.
	for _mode: String in ["ALWAYS_ASK","SMART","QUICK"]:
		var presentation: Dictionary = a["config"].duplicate(true)
		presentation["presentation_only_mode"] = _mode
		var ui_replay: Dictionary = M5.replay(a["initial"],a["tape"],presentation)
		check("M55-REP-13-PRESENTATION_"+_mode,
			ui_replay["accepted"] and
			ui_replay["event_hash"] == a["event_hash"] and
			ui_replay["state_hash"] == a["final_hash"])
	print("M5_5_REPLAY_REPORT executed=",passed+failed,
		" passed=",passed," failed=",failed)
	if failed == 0 and passed == 15:
		print("M5_5_FULL_TAPE_REPLAY_VERIFIED")
		print("M5_5_REPLAY seed=",F.SEED," commands=",a["accepted"],
			" tape=",a["tape_hash"]," events=",a["event_hash"],
			" final=",a["final_hash"])
	quit(0 if passed == 15 and failed == 0 else 1)
