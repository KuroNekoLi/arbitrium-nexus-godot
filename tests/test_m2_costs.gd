extends SceneTree
## M2.2 INTERNAL Cost/Overload cases; never treats a cost receipt as played SP.
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const Cost = preload("res://scripts/domain/m2/economy/cost_resolver.gd")
const Effect = preload("res://scripts/domain/m2/economy/cost_effect_resolver.gd")
const Ledger = preload("res://scripts/domain/m2/economy/resource_ledger.gd")
var config: Dictionary = {}
var passed: int = 0
var failed: int = 0

func _expect(id: String, good: bool, detail: String = "") -> void:
	if good:
		passed += 1
		print("PASS ", id)
	else:
		failed += 1
		printerr("FAIL ", id, " ", detail)

func _state() -> Dictionary:
	var s: Dictionary = Model.make_state(["A", "B", "C"], ["Boss"], 20261014)
	s["actors"]["A"]["max_mp"] = 10
	s["actors"]["A"]["mp"] = 8
	s["actors"]["B"]["max_mp"] = 8
	s["actors"]["B"]["mp"] = 5
	s["actors"]["C"]["max_mp"] = 12
	s["actors"]["C"]["mp"] = 1
	return s

func _card(ap: int, mp: int, overload: bool = false, borrow_limit: int = 0) -> Dictionary:
	return {"card_id": "fixture-sp", "ap_cost": ap, "mp_cost": mp,
		"overload_eligible": overload, "max_borrow_per_card": borrow_limit}

func _command(s: Dictionary, id: String, card: Dictionary, extra: Dictionary = {}) -> Dictionary:
	var cmd: Dictionary = {"type": "PAY_SP_COST_ONLY", "command_id": id,
		"expected_event_seq": int(s["event_seq"]), "actor_id": "A",
		"card": card, "casting_mode": "CHANTLESS"}
	for key: Variant in extra:
		cmd[key] = extra[key]
	return cmd

func _pay(s: Dictionary, id: String, card: Dictionary, extra: Dictionary = {}) -> Dictionary:
	return Cost.apply(s, _command(s, id, card, extra), config)

func _modifier(id: String, kind: String, value: int, priority: int, grant_seq: int, uses: int = 1) -> Dictionary:
	return {"instance_id": id, "kind": kind, "value": value,
		"priority": priority, "grant_seq": grant_seq, "remaining_uses": uses,
		"card_id": "*", "actor_id": "*"}

func _effect(s: Dictionary, kind: String, id: String, source: String, instance: String, amount: int) -> Dictionary:
	return Effect.apply(s, {"type": kind, "command_id": id,
		"expected_event_seq": int(s["event_seq"]),
		"source_cost_command_id": source, "effect_instance_id": instance,
		"amount": amount}, config)

func _resources(s: Dictionary, kind: String, id: String) -> Dictionary:
	return Ledger.apply(s, {"type": kind, "command_id": id,
		"expected_event_seq": int(s["event_seq"])}, config)

func _init() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://resources/combat/rulesets/m2_2_provisional_costs.json"))
	if not parsed is Dictionary:
		printerr("M2_2_SETUP_FAILURE invalid JSON fixture")
		quit(1)
		return
	config = parsed
	var s: Dictionary = _state()
	_expect("M2_2_CONFIG_AUTHORITY", config["authority"] == "BALANCE_PROVISIONAL"
		and config["ruleset_version"] == Model.RULESET_VERSION
		and Model.validate_shell(s))
	var initial_hash: String = Model.state_hash(s)
	var paid: Dictionary = _pay(s, "paid", _card(3, 2))
	_expect("M2_2_ATOMIC_AP_MP", paid["accepted"] and paid["state"]["party_resources"]["current_ap"] == 3
		and paid["state"]["actors"]["A"]["mp"] == 6
		and paid["state"]["actors"]["B"]["mp"] == 5 and paid["events"].size() == 1)
	_expect("M2_2_INPUT_IMMUTABLE", Model.state_hash(s) == initial_hash
		and s["rng"]["draw_index"] == 0 and s["events"].is_empty())
	_expect("M2_2_RECEIPT_NOT_CARD", paid["accepted"]
		and paid["events"][0]["kind"] == "SPCostReservedOnly"
		and paid["events"][0]["details"]["effect_execution"] == "DEFERRED_TO_M3_M4_M5"
		and paid["state"]["actors"]["Boss"]["hp"] == 100)
	var exhausted_mp: Dictionary = _state()
	exhausted_mp["actors"]["A"]["mp"] = 1
	var invalid_mp: Dictionary = _pay(exhausted_mp, "no-mp", _card(3, 2))
	_expect("M2_2_MP_INSUFFICIENT_ATOMIC", not invalid_mp["accepted"]
		and invalid_mp["error"] == "INSUFFICIENT_MP"
		and invalid_mp["state_hash"] == Model.state_hash(exhausted_mp))
	var no_ap: Dictionary = _pay(s, "no-ap", _card(7, 2))
	_expect("ECON-001-RESOURCE_ONLY", not no_ap["accepted"] and no_ap["error"] == "INSUFFICIENT_AP"
		and no_ap["state_hash"] == initial_hash)
	var not_actor: Dictionary = _pay(s, "bad-actor", _card(1, 1), {"actor_id": "Nobody"})
	_expect("M2_2_INVALID_ACTOR", not not_actor["accepted"] and not_actor["error"] == "ACTOR_NOT_FOUND")
	var damaged: Dictionary = _state()
	damaged["actors"]["A"]["hp"] = 0
	var down: Dictionary = _pay(damaged, "down", _card(1, 1))
	_expect("M2_2_UNAVAILABLE_ACTOR", not down["accepted"] and down["error"] == "ACTOR_UNAVAILABLE")
	var overload: Dictionary = _state()
	overload["party_resources"]["current_ap"] = 2
	var borrowed: Dictionary = _pay(overload, "borrowed", _card(9, 2, true, 7))
	_expect("M2_2_OVERLOAD_SHORTFALL", borrowed["accepted"]
		and borrowed["quote"]["ap_borrowed"] == 7
		and borrowed["state"]["party_resources"]["current_ap"] == 0
		and borrowed["state"]["party_resources"]["ap_debt"] == 7
		and borrowed["state"]["actors"]["A"]["mp"] == 6)
	var card_bound: Dictionary = _pay(overload, "card-limited", _card(10, 1, true, 7))
	_expect("M2_2_CARD_BORROW_LIMIT", not card_bound["accepted"]
		and card_bound["error"] == "CARD_BORROW_LIMIT"
		and card_bound["state_hash"] == Model.state_hash(overload))
	var team_bound: Dictionary = _state()
	team_bound["party_resources"]["current_ap"] = 1
	team_bound["party_resources"]["ap_debt"] = 7
	var team_denied: Dictionary = _pay(team_bound, "team-limited", _card(3, 1, true, 3))
	_expect("M2_2_TEAM_BORROW_LIMIT", not team_denied["accepted"]
		and team_denied["error"] == "TEAM_DEBT_LIMIT"
		and team_denied["state_hash"] == Model.state_hash(team_bound))
	var enough_ap: Dictionary = _pay(s, "enough", _card(5, 1, true, 5))
	_expect("M2_2_NO_VOLUNTARY_BORROW", enough_ap["accepted"]
		and enough_ap["state"]["party_resources"]["ap_debt"] == 0
		and enough_ap["state"]["party_resources"]["current_ap"] == 1)
	var only_short: Dictionary = _state()
	only_short["party_resources"]["current_ap"] = 5
	var exactly_one: Dictionary = _pay(only_short, "one-debt", _card(6, 0, true, 5))
	_expect("M2_2_BORROW_ONLY_GAP", exactly_one["accepted"]
		and exactly_one["quote"]["ap_borrowed"] == 1)
	var no_config: Dictionary = Cost.apply(s, _command(s, "missing-config", _card(8, 1, true, 8)), {})
	_expect("M2_2_NO_SILENT_DEBT_LIMIT", not no_config["accepted"]
		and no_config["error"] == "MISSING_PROVISIONAL_RULESET")
	var mutable: Dictionary = _state()
	mutable["cost_modifiers"] = [
		_modifier("d-high", "DISCOUNT", 2, 5, 3),
		_modifier("s1", "SET_COST", 7, 1, 1),
		_modifier("d-low", "DISCOUNT", 3, 2, 2)
	]
	var discounted: Dictionary = _pay(mutable, "discount", _card(10, 1))
	_expect("PRE3-10-RESOURCE_ONLY", discounted["accepted"]
		and discounted["quote"]["base_ap_after_set"] == 7
		and discounted["quote"]["ap_cost"] == 2
		and discounted["quote"]["modifiers_consumed"] == ["s1", "d-low", "d-high"])
	_expect("M2_2_DISCOUNT_CONSUMPTION", discounted["accepted"]
		and discounted["state"]["cost_modifiers"][0]["remaining_uses"] == 0
		and discounted["state"]["cost_modifiers"][1]["remaining_uses"] == 0
		and discounted["state"]["cost_modifiers"][2]["remaining_uses"] == 0
		and mutable["cost_modifiers"][0]["remaining_uses"] == 1)
	var variable: Dictionary = _card(1, 2)
	variable["variable_ap"] = true
	variable["min_investment"] = 1
	variable["max_investment"] = 5
	var var_state: Dictionary = _state()
	var_state["cost_modifiers"] = [_modifier("free-invest", "DISCOUNT", 4, 1, 1)]
	var var_result: Dictionary = _pay(var_state, "investment", variable, {"chosen_ap_investment": 4})
	_expect("M2_2_VARIABLE_INVESTMENT", var_result["accepted"]
		and var_result["quote"]["chosen_ap_investment"] == 4
		and var_result["quote"]["ap_cost"] == 0
		and var_result["state"]["party_resources"]["current_ap"] == 6
		and var_result["state"]["actors"]["A"]["mp"] == 6)
	var not_chosen: Dictionary = _pay(var_state, "no-investment", variable)
	_expect("M2_2_INVESTMENT_REQUIRED", not not_chosen["accepted"]
		and not_chosen["error"] == "MISSING_AP_INVESTMENT")
	var out_of_range: Dictionary = _pay(var_state, "over-range", variable, {"chosen_ap_investment": 6})
	_expect("M2_2_INVESTMENT_RANGE", not out_of_range["accepted"]
		and out_of_range["error"] == "INVESTMENT_OUT_OF_RANGE")
	var bogus_fixed: Dictionary = _pay(s, "fixed-extra", _card(2, 1), {"chosen_ap_investment": 4})
	_expect("M2_2_FIXED_CARD_NO_INVESTMENT", not bogus_fixed["accepted"]
		and bogus_fixed["error"] == "FIXED_COST_INVESTMENT_FORBIDDEN")
	var both_full: Dictionary = Cost.quote(s, _command(s, "full", _card(2, 3), {"casting_mode": "FULL"}), config)
	var both_quick: Dictionary = Cost.quote(s, _command(s, "chantless", _card(2, 3)), config)
	_expect("M2_2_DUAL_CAST_SAME_MP", both_full["ok"] and both_quick["ok"]
		and both_full["mp_cost"] == both_quick["mp_cost"]
		and both_full["mp_cost"] == 3)
	var min_state: Dictionary = _state()
	min_state["cost_modifiers"] = [
		_modifier("take-one", "DISCOUNT", 10, 0, 1),
		_modifier("unused", "DISCOUNT", 1, 1, 2)
	]
	var min_card: Dictionary = _card(3, 1)
	min_card["min_ap_cost"] = 2
	var limited: Dictionary = _pay(min_state, "min-pay", min_card)
	_expect("M2_2_MIN_AP_COST", limited["accepted"] and limited["quote"]["ap_cost"] == 2
		and limited["quote"]["eligible_discount_applied"] == 1
		and limited["state"]["cost_modifiers"][1]["remaining_uses"] == 1)
	var ineligible: Dictionary = _state()
	var other: Dictionary = _modifier("only-b", "DISCOUNT", 5, 1, 1)
	other["actor_id"] = "B"
	ineligible["cost_modifiers"] = [other]
	var filtered: Dictionary = _pay(ineligible, "not-for-a", _card(3, 1))
	_expect("M2_2_DISCOUNT_FILTER", filtered["accepted"] and filtered["quote"]["ap_cost"] == 3
		and filtered["state"]["cost_modifiers"][0]["remaining_uses"] == 1)
	var two_set: Dictionary = _state()
	two_set["cost_modifiers"] = [
		_modifier("s1", "SET_COST", 1, 1, 1),
		_modifier("s2", "SET_COST", 2, 2, 2)
	]
	var blocked_set: Dictionary = _pay(two_set, "two-set", _card(5, 1))
	_expect("M2_2_MULTIPLE_SET_COST_TBD", not blocked_set["accepted"]
		and blocked_set["error"] == "MULTIPLE_SET_COST_TBD")
	var same_mod_id: Dictionary = _state()
	same_mod_id["cost_modifiers"] = [
		_modifier("dup", "DISCOUNT", 1, 1, 1),
		_modifier("dup", "DISCOUNT", 2, 1, 2)
	]
	_expect("M2_2_DUPLICATE_MODIFIER_ID", not Model.validate_shell(same_mod_id))
	var stale: Dictionary = Cost.apply(paid["state"],
		_command(s, "stale-cost", _card(1, 1)), config)
	var repeated: Dictionary = _pay(paid["state"], "paid", _card(1, 1))
	_expect("M2_2_REPLAY_REJECTS_DUPLICATE", not repeated["accepted"]
		and repeated["error"] == "DUPLICATE_COMMAND"
		and not stale["accepted"] and stale["error"] == "STALE_STATE")
	var enemy_phase: Dictionary = _state()
	enemy_phase["phase"] = "ENEMY_PHASE"
	var wrong_phase: Dictionary = _pay(enemy_phase, "enemy", _card(1, 1))
	_expect("M2_2_COST_PLAYER_ONLY", not wrong_phase["accepted"] and wrong_phase["error"] == "INVALID_PHASE")

	# Effect fixtures require a paid source and unique single-use effect ID.
	var no_source: Dictionary = _effect(s, "AP_REFUND_EFFECT", "free", "nonexistent", "fx-free", 2)
	_expect("M2_2_NO_UNFUNDED_EFFECT", not no_source["accepted"]
		and no_source["error"] == "NO_PAID_SOURCE")
	var ap_refund: Dictionary = _effect(paid["state"], "AP_REFUND_EFFECT", "refund",
		"paid", "fx-ap", 2)
	_expect("M2_2_AP_REFUND_CURRENT_ONLY", ap_refund["accepted"]
		and ap_refund["state"]["party_resources"]["current_ap"] == 5
		and ap_refund["state"]["party_resources"]["ap_debt"] == 0)
	var twice_fx: Dictionary = _effect(ap_refund["state"], "AP_REFUND_EFFECT",
		"refund-again", "paid", "fx-ap", 2)
	_expect("M2_2_EFFECT_CONSUME_ONCE", not twice_fx["accepted"]
		and twice_fx["error"] == "EFFECT_ALREADY_CONSUMED")
	var debt_state: Dictionary = _state()
	debt_state["party_resources"]["current_ap"] = 1
	var debt_paid: Dictionary = _pay(debt_state, "paid-with-debt", _card(3, 1, true, 2))
	var refunded: Dictionary = _effect(debt_paid["state"], "AP_REFUND_EFFECT", "return-ap",
		"paid-with-debt", "fx-refund", 2)
	_expect("M2_2_REFUND_DOES_NOT_REPAY", refunded["accepted"]
		and refunded["state"]["party_resources"]["current_ap"] == 2
		and refunded["state"]["party_resources"]["ap_debt"] == 2)
	var reduce: Dictionary = _effect(refunded["state"], "REDUCE_AP_DEBT_EFFECT",
		"reduce-debt", "paid-with-debt", "fx-debt", 1)
	_expect("M2_2_REDUCE_DEBT_NO_AP", reduce["accepted"]
		and reduce["state"]["party_resources"]["current_ap"] == 2
		and reduce["state"]["party_resources"]["ap_debt"] == 1)
	var clear: Dictionary = _effect(reduce["state"], "REDUCE_AP_DEBT_EFFECT",
		"over-reduce", "paid-with-debt", "fx-debt-2", 50)
	_expect("M2_2_DEBT_CLAMP", clear["accepted"] and clear["state"]["party_resources"]["ap_debt"] == 0
		and clear["events"][0]["details"]["actual"] == 1)
	var future: Dictionary = _effect(paid["state"], "SCHEDULE_NEXT_PHASE_AP_BONUS",
		"future-ap", "paid", "fx-future", 3)
	_expect("M2_2_FUTURE_BONUS_NOT_IMMEDIATE", future["accepted"]
		and future["state"]["party_resources"]["current_ap"] == 3
		and future["state"]["party_resources"]["next_player_ap_bonus"] == 3)

	# M-D06 + provisional M-D04: debt paid before next-phase usable AP.
	var awaiting: Dictionary = _state()
	awaiting["phase"] = "AWAITING_PLAYER_START"
	awaiting["party_resources"]["current_ap"] = 0
	awaiting["party_resources"]["ap_debt"] = 8
	var opened: Dictionary = _resources(awaiting, "START_PLAYER_RESOURCES", "open-one")
	_expect("M2_2_DEBT_CROSS_PHASE", opened["accepted"]
		and opened["state"]["party_resources"]["current_ap"] == 0
		and opened["state"]["party_resources"]["ap_debt"] == 2
		and opened["events"][0]["details"]["old_debt_repaid"] == 6)
	var finish0: Dictionary = _resources(opened["state"], "CONVERT_AP_TO_RP", "end-one")
	var finish1: Dictionary = _resources(finish0["state"], "EXPIRE_RP", "enemy-end")
	var opened2: Dictionary = _resources(finish1["state"], "START_PLAYER_RESOURCES", "open-two")
	_expect("M2_2_DEBT_MULTI_PHASE", opened2["accepted"]
		and opened2["state"]["party_resources"]["current_ap"] == 4
		and opened2["state"]["party_resources"]["ap_debt"] == 0)
	var without_policy: Dictionary = Ledger.apply(awaiting,
		{"type": "START_PLAYER_RESOURCES", "command_id": "no-policy", "expected_event_seq": 0}, {})
	_expect("M2_2_DEBT_POLICY_EXPLICIT", not without_policy["accepted"]
		and without_policy["error"] == "DEFERRED_TO_M2_2_AP_DEBT")
	var boosted: Dictionary = _state()
	boosted["phase"] = "AWAITING_PLAYER_START"
	boosted["party_resources"]["ap_debt"] = 8
	boosted["party_resources"]["next_player_ap_bonus"] = 5
	var boosted_open: Dictionary = _resources(boosted, "START_PLAYER_RESOURCES", "bonus-pays-debt")
	_expect("M2_2_AP_BONUS_REPAYS_FIRST", boosted_open["accepted"]
		and boosted_open["state"]["party_resources"]["current_ap"] == 3
		and boosted_open["state"]["party_resources"]["ap_debt"] == 0
		and boosted_open["state"]["party_resources"]["next_player_ap_bonus"] == 0)
	var no_new_mp: Dictionary = _resources(future["state"], "CONVERT_AP_TO_RP", "end-phase")
	var no_new_mp2: Dictionary = _resources(no_new_mp["state"], "EXPIRE_RP", "enemy-end2")
	var bonus_start: Dictionary = _resources(no_new_mp2["state"], "START_PLAYER_RESOURCES", "round2")
	_expect("M2_2_NEXT_PHASE_AP_BONUS", bonus_start["accepted"]
		and bonus_start["state"]["party_resources"]["current_ap"] == 9
		and bonus_start["state"]["actors"]["A"]["mp"] == 6)

	var tape: Array[Dictionary] = [
		_command(s, "tape-1", _card(2, 1)),
		{"type": "PAY_SP_COST_ONLY", "command_id": "tape-2",
		 "expected_event_seq": 1, "actor_id": "A", "card": _card(3, 2), "casting_mode": "FULL"}
	]
	var first: Dictionary = Cost.replay(s, tape, config)
	var second: Dictionary = Cost.replay(s, tape, config)
	_expect("M2_2_REPLAY_DETERMINISTIC", first["accepted"] and second["accepted"]
		and first["state_hash"] == second["state_hash"]
		and first["event_hash"] == second["event_hash"]
		and first["state"]["rng"]["draw_index"] == 0
		and first["events"].size() == 2)
	var rejected_tape: Array[Dictionary] = [
		_command(s, "tx-1", _card(2, 1)),
		{"type": "PAY_SP_COST_ONLY", "command_id": "tx-2",
		 "expected_event_seq": 1, "actor_id": "A", "card": _card(6, 1)}
	]
	var partial: Dictionary = Cost.replay(s, rejected_tape, config)
	_expect("M2_2_REPLAY_FAILED_ATOMICALLY", not partial["accepted"]
		and partial["error"] == "INSUFFICIENT_AP"
		and partial["state"]["party_resources"]["current_ap"] == 4
		and partial["events"].size() == 1)
	var same_character: Dictionary = _pay(paid["state"], "second-a", _card(2, 1))
	_expect("M2_2_NO_GLOBAL_PLAY_LIMIT", same_character["accepted"]
		and same_character["state"]["paid_cost_command_ids"].size() == 2)
	var ledger_kind: Dictionary = Ledger.apply(s, {"type": "PLAY_SP",
		"command_id": "public", "expected_event_seq": 0}, config)
	_expect("M2_2_NO_PUBLIC_SP_EFFECT", not ledger_kind["accepted"]
		and ledger_kind["error"] == "UNKNOWN_RESOURCE_OPERATION")
	print("M2_2_REPLAY_PROOF seed=20261014 ruleset=", Model.RULESET_VERSION,
		" content=", Model.CONTENT_VERSION, " config=", config["schema_version"],
		" initial_hash=", initial_hash, " event_hash=", first["event_hash"],
		" final_state_hash=", first["state_hash"], " tape=", Model.canonical(tape))
	print("M2_2_TEST_REPORT executed=", passed + failed, " passed=", passed,
		" failed=", failed, " skipped=0")
	quit(1 if failed > 0 else 0)
