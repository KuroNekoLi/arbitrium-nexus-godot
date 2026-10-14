extends SceneTree
## PH3-M1: runnable tests for the *new* Domain scaffold (not the legacy BattleState).
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const Resolver = preload("res://scripts/domain/m1/combat_resolver.gd")
const Rng = preload("res://scripts/domain/m1/combat_rng.gd")
const SEED: int = 12345
var passed: int = 0
var failed: int = 0

func _expect(case_id: String, condition: bool, details: String = "") -> void:
	if condition:
		passed += 1
		print("PASS ", case_id)
	else:
		failed += 1
		printerr("FAIL ", case_id, " ", details)

func _cmd(id: String, actor: String, seq: int) -> Dictionary:
	return {"type": "SELECT_ACTOR", "command_id": id,
		"actor_id": actor, "expected_event_seq": seq}

func _init() -> void:
	var state: Dictionary = Model.make_state(["A", "B", "C"], ["Boss"], SEED)
	var init_hash: String = Model.state_hash(state)
	var init_rng_hash: String = Model.state_hash(state["rng"])
	_expect("PH3-M1-STATE-001", not state.is_empty() and state["party_resources"]["base_ap"] == 6
		and state["allies"].size() == 3 and state["actors"]["A"]["card_zones"]["hand"].is_empty()
		and state["round"] == 1 and state["phase"] == "PLAYER_PHASE")
	_expect("PH3-M1-STATE-002", Model.make_state(["A", "A", "C"], ["Boss"], SEED).is_empty()
		and Model.make_state(["A", "B", "C"], ["C"], SEED).is_empty()
		and Model.make_state(["A", "B"], ["Boss"], SEED).is_empty())
	_expect("PH3-M1-STATE-003", Model.validate_shell(state))
	var selected: Dictionary = Resolver.submit(state, _cmd("select-1", "A", 0))
	_expect("PH3-M1-CMD-001", selected["accepted"] and selected["state"]["selected_actor_id"] == "A"
		and selected["events"].size() == 1 and selected["error"] == "")
	_expect("PH3-M1-CMD-002", Model.state_hash(state) == init_hash
		and Model.state_hash(state["rng"]) == init_rng_hash
		and state["events"].is_empty() and state["seen_command_ids"].is_empty(),
		"Accepted command must not mutate caller input.")
	var missing: Dictionary = Resolver.submit(state, _cmd("missing", "Nobody", 0))
	_expect("PH3-M1-CMD-003", not missing["accepted"] and missing["error"] == "ACTOR_NOT_FOUND"
		and missing["state_hash"] == init_hash and missing["events"].is_empty())
	var wrong_phase: Dictionary = Model.snapshot(state)
	wrong_phase["phase"] = "ENEMY_PHASE"
	var wrong: Dictionary = Resolver.submit(wrong_phase, _cmd("wrong-phase", "A", 0))
	_expect("PH3-M1-CMD-004", not wrong["accepted"] and wrong["error"] == "INVALID_PHASE"
		and wrong["events"].is_empty())
	var knocked: Dictionary = Model.snapshot(state)
	knocked["actors"]["A"]["hp"] = 0
	var denied: Dictionary = Resolver.submit(knocked, _cmd("knocked", "A", 0))
	_expect("PH3-M1-CMD-005", not denied["accepted"] and denied["error"] == "ACTOR_UNAVAILABLE")
	var unsupported: Dictionary = Resolver.submit(state, {"type": "BASIC_ATTACK", "actor_id": "A"})
	_expect("PH3-M1-CMD-006", not unsupported["accepted"] and unsupported["error"] == "FEATURE_NOT_IMPLEMENTED"
		and unsupported["state_hash"] == init_hash)
	var unknown: Dictionary = Resolver.submit(state, {"type": "MOVE", "actor_id": "A"})
	_expect("PH3-M1-CMD-007", not unknown["accepted"] and unknown["error"] == "UNKNOWN_COMMAND"
		and unknown["state_hash"] == init_hash)
	var next: Dictionary = Resolver.submit(selected["state"], _cmd("select-2", "C", 1))
	_expect("PH3-M1-EVT-001", next["accepted"] and next["events"][0]["event_seq"] == 2
		and next["events"][0]["action_id"] == 2 and next["events"][0]["command_id"] == "select-2"
		and next["state"]["events"].size() == 2 and next["state"]["seen_command_ids"].size() == 2)
	var empty_id: Dictionary = Resolver.submit(state, _cmd("", "A", 0))
	_expect("PH3-M1-CMD-008", not empty_id["accepted"] and empty_id["error"] == "INVALID_COMMAND_ID"
		and empty_id["state_hash"] == init_hash)
	var no_seq: Dictionary = Resolver.submit(state, {"type": "SELECT_ACTOR", "actor_id": "A", "command_id": "no-seq"})
	_expect("PH3-M1-CMD-009", not no_seq["accepted"] and no_seq["error"] == "MISSING_EXPECTED_EVENT_SEQ")
	var duplicate: Dictionary = Resolver.submit(selected["state"], _cmd("select-1", "B", 1))
	_expect("PH3-M1-CMD-010", not duplicate["accepted"] and duplicate["error"] == "DUPLICATE_COMMAND"
		and duplicate["state_hash"] == selected["state_hash"])
	var stale: Dictionary = Resolver.submit(selected["state"], _cmd("select-fresh", "B", 0))
	_expect("PH3-M1-CMD-011", not stale["accepted"] and stale["error"] == "STALE_STATE"
		and stale["state_hash"] == selected["state_hash"])
	var exhausted: Dictionary = Model.snapshot(state)
	exhausted["actors"]["A"]["status"] = "EXHAUSTED"
	var exhausted_result: Dictionary = Resolver.submit(exhausted, _cmd("exh", "A", 0))
	_expect("PH3-M1-CMD-012", not exhausted_result["accepted"] and exhausted_result["error"] == "ACTOR_UNAVAILABLE")
	var invalid_model: Dictionary = Model.snapshot(state)
	invalid_model["ruleset_version"] = "legacy-v1"
	var invalid_result: Dictionary = Resolver.submit(invalid_model, _cmd("invalid-model", "A", 0))
	_expect("PH3-M1-CMD-013", not invalid_result["accepted"] and invalid_result["error"] == "INVALID_STATE")
	var second_same: Dictionary = Resolver.submit(selected["state"], _cmd("select-again", "A", 1))
	_expect("PH3-M1-CMD-014", second_same["accepted"] and second_same["state"]["action_seq"] == 2,
		"M1 selection does not introduce per-actor action count caps.")
	var tape: Array[Dictionary] = [
		_cmd("tape-1", "A", 0), _cmd("tape-2", "B", 1), _cmd("tape-3", "A", 2)
	]
	var playback_a: Dictionary = Resolver.replay(state, tape)
	var playback_b: Dictionary = Resolver.replay(state, tape)
	_expect("PH3-M1-REPLAY-001", playback_a["accepted"] and playback_b["accepted"]
		and playback_a["state_hash"] == playback_b["state_hash"]
		and playback_a["event_hash"] == playback_b["event_hash"])
	_expect("PH3-M1-REPLAY-002", playback_a["events"].size() == 3
		and playback_a["state"]["event_seq"] == 3 and playback_a["state"]["action_seq"] == 3
		and playback_a["state"]["selected_actor_id"] == "A")
	var failing_tape: Array[Dictionary] = [_cmd("ok", "A", 0), _cmd("bad", "Nobody", 1)]
	var fail_replay: Dictionary = Resolver.replay(state, failing_tape)
	_expect("PH3-M1-REPLAY-003", not fail_replay["accepted"]
		and fail_replay["error"] == "ACTOR_NOT_FOUND" and fail_replay["state"]["event_seq"] == 1
		and fail_replay["events"].size() == 1)
	var different_seed: Dictionary = Model.make_state(["A", "B", "C"], ["Boss"], SEED + 1)
	_expect("PH3-M1-REPLAY-004", Model.state_hash(different_seed) != init_hash)
	var first_roll: Dictionary = Rng.next_int(Rng.initial_state(1))
	var second_roll: Dictionary = Rng.next_int(first_roll["rng"])
	_expect("PH3-M1-RNG-001", first_roll["value"] == 48271
		and second_roll["value"] == 182605794
		and first_roll["rng"]["draw_index"] == 1 and second_roll["rng"]["draw_index"] == 2)
	var original_rng: Dictionary = Rng.initial_state(1)
	Rng.next_int(original_rng)
	_expect("PH3-M1-RNG-002", original_rng["draw_index"] == 0 and original_rng["state"] == 1,
		"RNG must never mutate caller state.")
	_expect("PH3-M1-RNG-003", Model.state_hash(playback_a["state"]["rng"]) == init_rng_hash
		and Model.state_hash(playback_a["state"]) == playback_a["state_hash"],
		"SELECT_ACTOR must not consume RNG.")
	var wrong_rng: Dictionary = Rng.initial_state(1)
	wrong_rng["algorithm"] = "unsupported-algorithm"
	var rejected_rng: Dictionary = Rng.next_int(wrong_rng)
	_expect("PH3-M1-RNG-004", not rejected_rng["accepted"] and rejected_rng["error"] == "UNSUPPORTED_RNG_VERSION")
	var snap: Dictionary = Model.snapshot(state)
	snap["actors"]["A"]["hp"] = 0
	snap["party_resources"]["current_ap"] = 0
	_expect("PH3-M1-SNAP-001", int(state["actors"]["A"]["hp"]) == 100
		and int(state["party_resources"]["current_ap"]) == 6)
	var dict_a: Dictionary = {"b": 2, "a": {"y": 0, "x": 1}}
	var dict_b: Dictionary = {"a": {"x": 1, "y": 0}, "b": 2}
	_expect("PH3-M1-SNAP-002", Model.state_hash(dict_a) == Model.state_hash(dict_b))
	var bad_resources: Dictionary = Model.snapshot(state)
	bad_resources["party_resources"]["ap_debt"] = -1
	_expect("PH3-M1-STATE-004", not Model.validate_shell(bad_resources))
	_expect("PH3-M1-EVT-002", selected["events"][0]["rng_draw_index"] == 0
		and selected["events"][0]["phase"] == "PLAYER_PHASE"
		and selected["state"]["events"][0]["command_id"] == "select-1")
	print("M1_REPLAY_PROOF seed=", SEED, " ruleset=", Model.RULESET_VERSION,
		" content=", Model.CONTENT_VERSION, " initial_hash=", init_hash,
		" event_hash=", playback_a["event_hash"],
		" final_state_hash=", playback_a["state_hash"],
		" command_tape=", Model.canonical(tape))
	print("M1_TEST_REPORT executed=", passed + failed, " passed=", passed,
		" failed=", failed, " skipped=0")
	quit(1 if failed > 0 else 0)
