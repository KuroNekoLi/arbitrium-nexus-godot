extends SceneTree
## M2.1 contract tests: resources ONLY; no actual attack damage, SP, Reaction or AI.
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const Resolver = preload("res://scripts/domain/m1/combat_resolver.gd")
const Ledger = preload("res://scripts/domain/m2/economy/resource_ledger.gd")
const BasicAttackMP = preload("res://scripts/domain/m2/economy/basic_attack_mp_policy.gd")
var passed: int = 0
var failed: int = 0
var provisional: Dictionary = {}
const SEED: int = 20261014

func _expect(case_id: String, ok: bool, note: String = "") -> void:
	if ok:
		passed += 1
		print("PASS ", case_id)
	else:
		failed += 1
		printerr("FAIL ", case_id, " ", note)

func _state() -> Dictionary:
	var s: Dictionary = Model.make_state(["A", "B", "C"], ["Boss"], SEED)
	if provisional.is_empty():
		return s
	var fixture: Dictionary = provisional["actor_mp_fixture"]
	for actor_id: String in ["A", "B", "C"]:
		var values: Dictionary = fixture[actor_id]
		s["actors"][actor_id]["mp"] = int(values["mp"])
		s["actors"][actor_id]["max_mp"] = int(values["max_mp"])
	return s

func _cmd(kind: String, id: String, seq: int, extra: Dictionary = {}) -> Dictionary:
	var command: Dictionary = {"type": kind, "command_id": id, "expected_event_seq": seq}
	for key: Variant in extra:
		command[key] = extra[key]
	return command

func _do(s: Dictionary, kind: String, id: String, extra: Dictionary = {}) -> Dictionary:
	return Ledger.apply(s, _cmd(kind, id, int(s["event_seq"]), extra), provisional)

func _init() -> void:
	var text_rules: String = FileAccess.get_file_as_string("res://resources/combat/rulesets/m2_1_provisional_resources.json")
	var parsed: Variant = JSON.parse_string(text_rules)
	if not parsed is Dictionary:
		printerr("FAIL M2_1_SETUP fixture JSON invalid")
		quit(1)
		return
	provisional = parsed
	var s: Dictionary = _state()
	_expect("M2_1_SETUP", Model.validate_shell(s) and provisional["authority"] == "BALANCE_PROVISIONAL"
		and Model.RULESET_VERSION == provisional["ruleset_version"])
	var quote: Dictionary = BasicAttackMP.quote(s, "A", provisional, Model.RULESET_VERSION)
	_expect("M2_1_JSON_INTEGRAL_FIXTURE", quote["accepted"] and quote["ap_cost"] == 1
		and quote["mp_restored"] == 2, str(quote.get("error", "")))
	var fractional: Dictionary = provisional.duplicate(true)
	fractional["basic_attack_ap_cost"] = 1.5
	var bad_cost: Dictionary = BasicAttackMP.quote(s, "A", fractional, Model.RULESET_VERSION)
	_expect("M2_1_FRACTIONAL_COST_REJECTED", not bad_cost["accepted"]
		and bad_cost["error"] == "INVALID_ATTACK_COST_CONFIG")

	# P1-D01: two attacks by same actor, MP gain only on the first accepted one.
	var a1: Dictionary = _do(s, "BASIC_ATTACK_RESOURCE_ONLY", "a-1", {"actor_id": "A"})
	if not a1["accepted"]:
		printerr("FAIL M2_1_PREREQUISITE: ", a1["error"])
		quit(1)
		return
	var a2: Dictionary = _do(a1["state"], "BASIC_ATTACK_RESOURCE_ONLY", "a-2", {"actor_id": "A"})
	_expect("P1-ECO-001", a1["accepted"] and a2["accepted"]
		and int(a1["state"]["actors"]["A"]["mp"]) == 3 and int(a2["state"]["actors"]["A"]["mp"]) == 3
		and a2["state"]["party_resources"]["current_ap"] == 4
		and a2["state"]["basic_attack_mp_restore_used_by_actor"]["A"]
		and not a2["state"]["basic_attack_mp_restore_used_by_actor"]["B"])
	var b1: Dictionary = _do(a2["state"], "BASIC_ATTACK_RESOURCE_ONLY", "b-1", {"actor_id": "B"})
	_expect("M2_1_ATTACK_INDEPENDENT", b1["accepted"] and b1["state"]["actors"]["B"]["mp"] == 7
		and b1["state"]["actors"]["A"]["mp"] == 3)
	_expect("M2_1_ATTACK_NO_DAMAGE", b1["events"][0]["kind"] == "BasicAttackResourceCommitted"
		and b1["events"][0]["details"]["attack_effect_status"] == "DEFERRED_TO_M5"
		and b1["state"]["actors"]["Boss"]["hp"] == 100)
	var no_cost: Dictionary = _state()
	no_cost["party_resources"]["current_ap"] = 0
	var refused: Dictionary = _do(no_cost, "BASIC_ATTACK_RESOURCE_ONLY", "fail-no-ap", {"actor_id": "A"})
	var topped: Dictionary = _do(no_cost, "GRANT_AP", "grant-after-fail", {"amount": 1})
	var first_after_reject: Dictionary = _do(topped["state"], "BASIC_ATTACK_RESOURCE_ONLY", "success-after-fail", {"actor_id": "A"})
	_expect("P1-ECO-002", not refused["accepted"] and refused["error"] == "INSUFFICIENT_AP"
		and refused["state_hash"] == Model.state_hash(no_cost) and not no_cost["basic_attack_mp_restore_used_by_actor"]["A"]
		and first_after_reject["accepted"] and first_after_reject["state"]["actors"]["A"]["mp"] == 3)
	var inter1: Dictionary = _do(s, "BASIC_ATTACK_RESOURCE_ONLY", "inter-a", {"actor_id": "A"})
	var inter2: Dictionary = _do(inter1["state"], "BASIC_ATTACK_RESOURCE_ONLY", "inter-b", {"actor_id": "B"})
	var inter3: Dictionary = _do(inter2["state"], "BASIC_ATTACK_RESOURCE_ONLY", "inter-a2", {"actor_id": "A"})
	var inter4: Dictionary = _do(inter3["state"], "BASIC_ATTACK_RESOURCE_ONLY", "inter-c", {"actor_id": "C"})
	_expect("P1-ECO-003", inter4["accepted"] and inter4["state"]["party_resources"]["current_ap"] == 2
		and inter4["state"]["actors"]["A"]["mp"] == 3 and inter4["state"]["actors"]["B"]["mp"] == 7
		and inter4["state"]["actors"]["C"]["mp"] == 12)

	# RP conversion always clamps at effective cap (default 6), all remaining AP is consumed.
	var close6: Dictionary = _do(s, "CONVERT_AP_TO_RP", "close-six")
	_expect("P1-ECO-004", close6["accepted"] and close6["state"]["party_resources"]["rp"] == 6
		and close6["state"]["party_resources"]["current_ap"] == 0 and close6["state"]["phase"] == "ENEMY_PHASE")
	var pay3: Dictionary = _do(s, "SPEND_AP", "ap-three", {"amount": 3})
	var close3: Dictionary = _do(pay3["state"], "CONVERT_AP_TO_RP", "close-three")
	_expect("P1-ECO-005", close3["accepted"] and close3["state"]["party_resources"]["rp"] == 3
		and close3["state"]["party_resources"]["current_ap"] == 0)
	var pay6: Dictionary = _do(s, "SPEND_AP", "ap-six", {"amount": 6})
	var close0: Dictionary = _do(pay6["state"], "CONVERT_AP_TO_RP", "close-zero")
	var refused_rp: Dictionary = _do(close0["state"], "SPEND_RP", "try-no-rp", {"amount": 1})
	_expect("P1-ECO-006", close0["state"]["party_resources"]["rp"] == 0
		and not refused_rp["accepted"] and refused_rp["error"] == "INSUFFICIENT_RP")
	var rp1: Dictionary = _do(close6["state"], "SPEND_RP", "spend-one-rp", {"amount": 1})
	var expire: Dictionary = _do(rp1["state"], "EXPIRE_RP", "expire-five")
	_expect("P1-ECO-007", rp1["state"]["party_resources"]["rp"] == 5
		and expire["accepted"] and expire["state"]["party_resources"]["rp"] == 0
		and expire["state"]["phase"] == "AWAITING_PLAYER_START")
	var rp2: Dictionary = _do(close6["state"], "SPEND_RP", "spend-two", {"amount": 2})
	var rp_next: Dictionary = _do(rp2["state"], "SPEND_RP", "spend-next", {"amount": 3})
	_expect("P1-ECO-008", rp2["state"]["party_resources"]["rp"] == 4
		and rp_next["state"]["party_resources"]["rp"] == 1)
	var huge_rp: Dictionary = _do(rp1["state"], "GRANT_RP", "grant-fifty", {"amount": 50})
	_expect("P1-ECO-009-UPDATED", huge_rp["accepted"] and huge_rp["state"]["party_resources"]["rp"] == 6
		and huge_rp["events"][0]["details"]["actual"] == 1)
	var increased_cap: Dictionary = _state()
	increased_cap["party_resources"]["rp_cap"] = 9 # effective cap fixture ONLY; skill policy is M2.2.
	var bonus: Dictionary = _do(increased_cap, "GRANT_AP", "extra-six", {"amount": 6})
	var close9: Dictionary = _do(bonus["state"], "CONVERT_AP_TO_RP", "close-cap-nine")
	_expect("M2_1_RP_CAP_OVERRIDE_FIXTURE", close9["accepted"] and close9["state"]["party_resources"]["rp"] == 9
		and close9["events"][0]["details"]["ap_overflow_lost"] == 3)

	# M-D18: CurrentAP isn't capped at BaseAP; only closing cap applies.
	var spend2: Dictionary = _do(s, "SPEND_AP", "spend-two", {"amount": 2})
	var grant8: Dictionary = _do(spend2["state"], "GRANT_AP", "gain-eight", {"amount": 8})
	_expect("M18-AP-001", grant8["accepted"] and grant8["state"]["party_resources"]["current_ap"] == 12)
	var spend3: Dictionary = _do(grant8["state"], "SPEND_AP", "spend-three", {"amount": 3})
	var cap6: Dictionary = _do(spend3["state"], "CONVERT_AP_TO_RP", "close-nine-ap")
	_expect("M18-RP-002", cap6["state"]["party_resources"]["rp"] == 6
		and cap6["events"][0]["details"]["ap_overflow_lost"] == 3)
	var start: Dictionary = _do(expire["state"], "START_PLAYER_RESOURCES", "round-two")
	_expect("M19-MP-001", start["accepted"] and start["state"]["actors"]["A"]["mp"] == 1
		and start["state"]["actors"]["B"]["mp"] == 5 and start["state"]["round"] == 2)
	var extra_gain: Dictionary = _do(s, "RECOVER_MP", "recover-c", {"actor_id": "C", "amount": 9})
	_expect("M20-MP-002", extra_gain["accepted"] and extra_gain["state"]["actors"]["C"]["mp"] == 12
		and extra_gain["events"][0]["details"]["actual"] == 2)
	_expect("M31-MP-001", s["actors"]["A"]["max_mp"] == 6 and s["actors"]["B"]["max_mp"] == 8
		and s["actors"]["C"]["max_mp"] == 12
		and extra_gain["state"]["actors"]["A"]["mp"] == 1)
	_expect("M2_1_NO_NATURAL_MP", start["state"]["actors"]["A"]["mp"] == 1
		and start["state"]["actors"]["B"]["mp"] == 5)
	var after_reset_attack: Dictionary = _do(start["state"], "BASIC_ATTACK_RESOURCE_ONLY", "round2-a", {"actor_id": "A"})
	_expect("M2_1_MP_CLAIM_RESETS", after_reset_attack["accepted"]
		and after_reset_attack["state"]["actors"]["A"]["mp"] == 3)

	# Fail-closed: no partial spend, duplicate effects, RNG changes or illegal transitions.
	var denied_mp: Dictionary = _do(s, "PAY_MP", "pay-too-much", {"actor_id": "A", "amount": 2})
	_expect("M2_1_MP_UNDERFLOW", not denied_mp["accepted"] and denied_mp["error"] == "INSUFFICIENT_MP"
		and denied_mp["state_hash"] == Model.state_hash(s))
	var good_mp: Dictionary = _do(s, "PAY_MP", "pay-one", {"actor_id": "A", "amount": 1})
	_expect("M2_1_MP_PAY", good_mp["accepted"] and good_mp["state"]["actors"]["A"]["mp"] == 0
		and good_mp["state"]["actors"]["B"]["mp"] == 5)
	var negative: Dictionary = _do(s, "GRANT_AP", "negative", {"amount": -1})
	var invalid_type: Dictionary = _do(s, "SPEND_AP", "float", {"amount": 1.5})
	_expect("M2_1_INVALID_AMOUNTS", not negative["accepted"] and not invalid_type["accepted"]
		and negative["state_hash"] == Model.state_hash(s) and invalid_type["state_hash"] == Model.state_hash(s))
	var duplicate: Dictionary = _do(a1["state"], "GRANT_AP", "a-1", {"amount": 2})
	var stale: Dictionary = Ledger.apply(a1["state"], _cmd("GRANT_AP", "stale", 0, {"amount": 2}), provisional)
	_expect("M2_1_IDEMPOTENCY", not duplicate["accepted"] and duplicate["error"] == "DUPLICATE_COMMAND"
		and not stale["accepted"] and stale["error"] == "STALE_STATE"
		and duplicate["state_hash"] == a1["state_hash"])
	var in_enemy: Dictionary = _do(close6["state"], "SPEND_AP", "no-player-ap", {"amount": 1})
	var bad_end: Dictionary = _do(close6["state"], "CONVERT_AP_TO_RP", "twice")
	_expect("M2_1_INVALID_PHASE", not in_enemy["accepted"] and not bad_end["accepted"])
	var no_actor: Dictionary = _do(s, "RECOVER_MP", "unknown-a", {"actor_id": "unknown", "amount": 1})
	var defeated: Dictionary = _state()
	defeated["actors"]["A"]["status"] = "EXHAUSTED"
	var rejected_attack: Dictionary = _do(defeated, "BASIC_ATTACK_RESOURCE_ONLY", "exh-a", {"actor_id": "A"})
	_expect("M2_1_ACTOR_GUARDS", not no_actor["accepted"] and no_actor["error"] == "ACTOR_NOT_FOUND"
		and not rejected_attack["accepted"] and rejected_attack["error"] == "ACTOR_UNAVAILABLE")
	var no_rules: Dictionary = Ledger.apply(s, _cmd("BASIC_ATTACK_RESOURCE_ONLY", "no-config", 0, {"actor_id": "A"}))
	_expect("M2_1_NO_SILENT_BALANCE", not no_rules["accepted"] and no_rules["error"] == "MISSING_PROVISIONAL_RULESET")
	var at_full: Dictionary = _state()
	at_full["actors"]["A"]["mp"] = at_full["actors"]["A"]["max_mp"]
	var full_attack: Dictionary = _do(at_full, "BASIC_ATTACK_RESOURCE_ONLY", "full-mp", {"actor_id": "A"})
	_expect("M2_1_FULL_MP_CLAIM", full_attack["accepted"]
		and full_attack["state"]["actors"]["A"]["mp"] == 6
		and full_attack["state"]["basic_attack_mp_restore_used_by_actor"]["A"]
		and full_attack["events"][0]["details"]["mp_restored"] == 0)
	var copy_hash: String = Model.state_hash(s)
	var rng_hash: String = Model.state_hash(s["rng"])
	_expect("M2_1_IMMUTABLE_INPUT", Model.state_hash(s) == copy_hash
		and Model.state_hash(s["rng"]) == rng_hash and s["events"].is_empty())
	var debt: Dictionary = _state()
	debt["party_resources"]["ap_debt"] = 2
	debt["phase"] = "AWAITING_PLAYER_START"
	var debt_start: Dictionary = _do(debt, "START_PLAYER_RESOURCES", "debt-round")
	_expect("M2_1_DEBT_DEFERRED", not debt_start["accepted"]
		and debt_start["error"] == "DEFERRED_TO_M2_2_AP_DEBT"
		and debt_start["state_hash"] == Model.state_hash(debt))
	var bad_mp_state: Dictionary = _state()
	bad_mp_state["actors"]["A"]["mp"] = 999
	var invalid_state_result: Dictionary = _do(bad_mp_state, "GRANT_AP", "should-refuse", {"amount": 1})
	_expect("M2_1_MP_STATE_INVARIANT", not invalid_state_result["accepted"]
		and invalid_state_result["error"] == "INVALID_STATE")
	var public_attack: Dictionary = Resolver.submit(s, {"type": "BASIC_ATTACK", "actor_id": "A"})
	_expect("M2_1_PUBLIC_ATTACK_NOT_READY", not public_attack["accepted"]
		and public_attack["error"] == "FEATURE_NOT_IMPLEMENTED"
		and public_attack["state_hash"] == Model.state_hash(s))
	var tape: Array[Dictionary] = [
		_cmd("GRANT_AP", "r-1", 0, {"amount": 8}),
		_cmd("BASIC_ATTACK_RESOURCE_ONLY", "r-2", 1, {"actor_id": "A"}),
		_cmd("BASIC_ATTACK_RESOURCE_ONLY", "r-3", 2, {"actor_id": "A"}),
		_cmd("CONVERT_AP_TO_RP", "r-4", 3),
		_cmd("SPEND_RP", "r-5", 4, {"amount": 2}),
		_cmd("EXPIRE_RP", "r-6", 5),
		_cmd("START_PLAYER_RESOURCES", "r-7", 6)
	]
	var replay1: Dictionary = Ledger.replay(s, tape, provisional)
	var replay2: Dictionary = Ledger.replay(s, tape, provisional)
	_expect("M2_1_REPLAY_IDENTICAL", replay1["accepted"] and replay2["accepted"]
		and replay1["state_hash"] == replay2["state_hash"]
		and replay1["event_hash"] == replay2["event_hash"]
		and replay1["events"].size() == tape.size())
	_expect("M2_1_RNG_PRESERVED", Model.state_hash(replay1["state"]["rng"]) == rng_hash
		and Model.state_hash(s["rng"]) == rng_hash)
	_expect("M2_1_EVENT_SEQUENCING", replay1["accepted"]
		and replay1["state"]["event_seq"] == 7 and replay1["state"]["round"] == 2
		and replay1["state"]["party_resources"]["current_ap"] == 6
		and replay1["state"]["party_resources"]["rp"] == 0)
	var error_tape: Array[Dictionary] = [
		_cmd("SPEND_AP", "et-1", 0, {"amount": 3}),
		_cmd("SPEND_AP", "et-2", 1, {"amount": 4})
	]
	var half: Dictionary = Ledger.replay(s, error_tape, provisional)
	_expect("M2_1_REPLAY_FAILURE", not half["accepted"] and half["error"] == "INSUFFICIENT_AP"
		and half["state"]["party_resources"]["current_ap"] == 3
		and half["events"].size() == 1)
	print("M2_1_REPLAY_PROOF seed=", SEED, " ruleset=", Model.RULESET_VERSION,
		" content=", Model.CONTENT_VERSION, " provisional=", provisional["schema_version"],
		" initial_hash=", Model.state_hash(s),
		" event_hash=", replay1["event_hash"], " final_state_hash=", replay1["state_hash"],
		" tape=", Model.canonical(tape))
	print("M2_1_TEST_REPORT executed=", passed + failed,
		" passed=", passed, " failed=", failed, " skipped=0")
	quit(1 if failed > 0 else 0)
