extends SceneTree
## M2.5 deterministic cross-resolver replay of M2.1/M2.2 ONLY.
## M2.3 card shuffle/zones and M2.4 free-swap remain an explicit gate blocker.
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const Cost = preload("res://scripts/domain/m2/economy/cost_resolver.gd")
const Effect = preload("res://scripts/domain/m2/economy/cost_effect_resolver.gd")
const Ledger = preload("res://scripts/domain/m2/economy/resource_ledger.gd")
const SEED: int = 20261014
var passed: int = 0
var failed: int = 0

func _expect(id: String, yes: bool) -> void:
	if yes:
		passed += 1
		print("PASS ", id)
	else:
		failed += 1
		printerr("FAIL ", id)

func _initial() -> Dictionary:
	var s: Dictionary = Model.make_state(["A", "B", "C"], ["Boss"], SEED)
	s["actors"]["A"]["max_mp"] = 10
	s["actors"]["A"]["mp"] = 8
	return s

func _tape() -> Array[Dictionary]:
	return [
		{"type": "PAY_SP_COST_ONLY", "command_id": "c1", "expected_event_seq": 0,
		 "actor_id": "A", "casting_mode": "CHANTLESS",
		 "card": {"card_id": "fixture-sp", "ap_cost": 8, "mp_cost": 2,
			"overload_eligible": true, "max_borrow_per_card": 2}},
		{"type": "AP_REFUND_EFFECT", "command_id": "e1", "expected_event_seq": 1,
		 "source_cost_command_id": "c1", "effect_instance_id": "fx1", "amount": 3},
		{"type": "REDUCE_AP_DEBT_EFFECT", "command_id": "e2", "expected_event_seq": 2,
		 "source_cost_command_id": "c1", "effect_instance_id": "fx2", "amount": 1},
		{"type": "GRANT_AP", "command_id": "r1", "expected_event_seq": 3, "amount": 2},
		{"type": "CONVERT_AP_TO_RP", "command_id": "r2", "expected_event_seq": 4},
		{"type": "SPEND_RP", "command_id": "r3", "expected_event_seq": 5, "amount": 2},
		{"type": "EXPIRE_RP", "command_id": "r4", "expected_event_seq": 6},
		{"type": "START_PLAYER_RESOURCES", "command_id": "r5", "expected_event_seq": 7}
	]

func _replay(start: Dictionary, tape: Array[Dictionary], config: Dictionary) -> Dictionary:
	var current: Dictionary = Model.snapshot(start)
	var collected: Array = []
	for command: Dictionary in tape:
		var result: Dictionary
		var kind: String = str(command["type"])
		if kind == "PAY_SP_COST_ONLY":
			result = Cost.apply(current, command, config)
		elif ["AP_REFUND_EFFECT", "REDUCE_AP_DEBT_EFFECT", "SCHEDULE_NEXT_PHASE_AP_BONUS"].has(kind):
			result = Effect.apply(current, command, config)
		else:
			result = Ledger.apply(current, command, config)
		if not result["accepted"]:
			return {"accepted": false, "error": result["error"], "state": current,
				"events": collected, "state_hash": Model.state_hash(current),
				"event_hash": Model.event_hash(collected)}
		current = result["state"]
		collected.append_array(result["events"])
	return {"accepted": true, "error": "", "state": current,
		"events": collected, "state_hash": Model.state_hash(current),
		"event_hash": Model.event_hash(collected)}

func _ordered(events: Array) -> bool:
	var seq: int = 0
	for event: Variant in events:
		if not event is Dictionary or int(event.get("event_seq", -1)) != seq + 1:
			return false
		seq += 1
	return true

func _init() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(
		"res://resources/combat/rulesets/m2_2_provisional_costs.json"))
	if not parsed is Dictionary:
		printerr("FAIL M2_5_REPLAY_SETUP invalid ruleset")
		quit(1)
		return
	var config: Dictionary = parsed
	var initial: Dictionary = _initial()
	var initial_hash: String = Model.state_hash(initial)
	var tape: Array[Dictionary] = _tape()
	var a: Dictionary = _replay(initial, tape, config)
	var b: Dictionary = _replay(initial, tape, config)
	_expect("M2_5_CROSS_RESOLVER_REPLAY_EQUAL", a["accepted"] and b["accepted"]
		and a["event_hash"] == b["event_hash"]
		and a["state_hash"] == b["state_hash"])
	_expect("M2_5_REPLAY_EVENTS_MONOTONIC", a["accepted"] and a["events"].size() == tape.size()
		and _ordered(a["events"]))
	_expect("M2_5_REPLAY_RNG_UNCHANGED", a["accepted"]
		and a["state"]["rng"]["draw_index"] == 0
		and Model.state_hash(initial) == initial_hash)
	_expect("M2_5_REPLAY_AP_RP_DEBT", a["accepted"]
		and a["state"]["party_resources"]["current_ap"] == 5
		and a["state"]["party_resources"]["ap_debt"] == 0
		and a["state"]["party_resources"]["rp"] == 0
		and a["state"]["actors"]["A"]["mp"] == 6)
	var change: Array[Dictionary] = _tape()
	change[1]["amount"] = 4
	var changed: Dictionary = _replay(initial, change, config)
	_expect("M2_5_REPLAY_DISTINCT_TAPE_HASH", changed["accepted"]
		and changed["event_hash"] != a["event_hash"]
		and changed["state_hash"] == a["state_hash"])
	var bad: Array[Dictionary] = _tape()
	bad[2]["expected_event_seq"] = 0
	var stopped: Dictionary = _replay(initial, bad, config)
	_expect("M2_5_REPLAY_FAILURE_ATOMIC", not stopped["accepted"]
		and stopped["error"] == "STALE_STATE"
		and stopped["events"].size() == 2
		and stopped["state"]["event_seq"] == 2
		and stopped["state"]["rng"]["draw_index"] == 0)
	print("M2_5_PARTIAL_REPLAY_PROOF seed=", SEED, " ruleset=", Model.RULESET_VERSION,
		" content=", Model.CONTENT_VERSION, " config=", config["schema_version"],
		" initial_hash=", initial_hash, " event_hash=", a["event_hash"],
		" final_state_hash=", a["state_hash"], " tape=", Model.canonical(tape),
		" coverage=M2_1_M2_2_ONLY")
	print("M2_5_RESOURCE_ONLY_REPLAY_REPORT executed=", passed + failed,
		" passed=", passed, " failed=", failed, " skipped=0"
		" card_instance_and_swap=BLOCKED_M2_3_M2_4")
	quit(1 if failed > 0 else 0)
