extends SceneTree
## M2.5 partial invariant coverage: real M2.1/M2.2 components ONLY.
## This script must NEVER be used to certify the missing M2.3/M2.4 card invariants.
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const Cost = preload("res://scripts/domain/m2/economy/cost_resolver.gd")
const Effect = preload("res://scripts/domain/m2/economy/cost_effect_resolver.gd")
const Ledger = preload("res://scripts/domain/m2/economy/resource_ledger.gd")
const SEED: int = 20261014
var passed: int = 0
var failed: int = 0

func _expect(case_id: String, condition: bool) -> void:
	if condition:
		passed += 1
		print("PASS ", case_id)
	else:
		failed += 1
		printerr("FAIL ", case_id)

func _state() -> Dictionary:
	var state: Dictionary = Model.make_state(["A", "B", "C"], ["Boss"], SEED)
	state["actors"]["A"]["mp"] = 8
	state["actors"]["A"]["max_mp"] = 10
	return state

func _command(state: Dictionary, kind: String, id: String, extra: Dictionary = {}) -> Dictionary:
	var command: Dictionary = {"type": kind, "command_id": id,
		"expected_event_seq": int(state["event_seq"])}
	for key: Variant in extra:
		command[key] = extra[key]
	return command

func _card(ap: int, mp: int, overload: bool = false, cap: int = 0) -> Dictionary:
	return {"card_id": "M2_5_FIXTURE_ONLY", "ap_cost": ap, "mp_cost": mp,
		"overload_eligible": overload, "max_borrow_per_card": cap}

func _legal(state: Dictionary) -> bool:
	if not Model.validate_shell(state):
		return false
	for key: String in ["current_ap", "ap_debt", "rp", "rp_cap"]:
		if int(state["party_resources"][key]) < 0:
			return false
	for actor_id: String in state["allies"]:
		var actor: Dictionary = state["actors"][actor_id]
		if int(actor["mp"]) < 0 or int(actor["mp"]) > int(actor["max_mp"]):
			return false
	return true

func _init() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(
		"res://resources/combat/rulesets/m2_2_provisional_costs.json"))
	if not parsed is Dictionary:
		printerr("FAIL M2_5_INVARIANTS_SETUP invalid configuration")
		quit(1)
		return
	var config: Dictionary = parsed
	var start: Dictionary = _state()
	var original_hash: String = Model.state_hash(start)
	_expect("M2_5_RESOURCE_INITIAL_VALID", _legal(start))
	var paid: Dictionary = Cost.apply(start, _command(start, "PAY_SP_COST_ONLY", "cost-1",
		{"actor_id": "A", "card": _card(8, 2, true, 2)}), config)
	_expect("M2_5_OVERLOAD_RESOURCE_INVARIANT", paid["accepted"] and _legal(paid["state"])
		and paid["state"]["party_resources"]["current_ap"] == 0
		and paid["state"]["party_resources"]["ap_debt"] == 2
		and paid["state"]["actors"]["A"]["mp"] == 6)
	_expect("M2_5_COST_INPUT_PURE", Model.state_hash(start) == original_hash
		and start["rng"]["draw_index"] == 0)
	var duplicate: Dictionary = Cost.apply(paid["state"],
		_command(paid["state"], "PAY_SP_COST_ONLY", "cost-1",
			{"actor_id": "A", "card": _card(1, 1)}), config)
	_expect("M2_5_DUPLICATE_COST_ATOMIC", not duplicate["accepted"]
		and duplicate["error"] == "DUPLICATE_COMMAND"
		and duplicate["state_hash"] == Model.state_hash(paid["state"])
		and duplicate["events"].is_empty()
		and duplicate["state"]["rng"] == paid["state"]["rng"])
	var no_mp: Dictionary = Cost.apply(paid["state"],
		_command(paid["state"], "PAY_SP_COST_ONLY", "no-mp",
			{"actor_id": "A", "card": _card(1, 7)}), config)
	_expect("M2_5_INSUFFICIENT_MP_ATOMIC", not no_mp["accepted"]
		and no_mp["error"] == "INSUFFICIENT_MP"
		and no_mp["state_hash"] == Model.state_hash(paid["state"]))
	var refund: Dictionary = Effect.apply(paid["state"],
		_command(paid["state"], "AP_REFUND_EFFECT", "refund-1",
			{"source_cost_command_id": "cost-1", "effect_instance_id": "fx-refund",
			 "amount": 3}), config)
	_expect("M2_5_REFUND_DEBT_SEPARATE", refund["accepted"] and _legal(refund["state"])
		and refund["state"]["party_resources"]["current_ap"] == 3
		and refund["state"]["party_resources"]["ap_debt"] == 2)
	var refund_again: Dictionary = Effect.apply(refund["state"],
		_command(refund["state"], "AP_REFUND_EFFECT", "refund-2",
			{"source_cost_command_id": "cost-1", "effect_instance_id": "fx-refund",
			 "amount": 3}), config)
	_expect("M2_5_REFUND_NO_REPEAT", not refund_again["accepted"]
		and refund_again["error"] == "EFFECT_ALREADY_CONSUMED"
		and refund_again["state_hash"] == Model.state_hash(refund["state"]))
	var reduce: Dictionary = Effect.apply(refund["state"],
		_command(refund["state"], "REDUCE_AP_DEBT_EFFECT", "reduce-1",
			{"source_cost_command_id": "cost-1", "effect_instance_id": "fx-reduce",
			 "amount": 1}), config)
	_expect("M2_5_REDUCE_DEBT_NOT_AP", reduce["accepted"] and _legal(reduce["state"])
		and reduce["state"]["party_resources"]["current_ap"] == 3
		and reduce["state"]["party_resources"]["ap_debt"] == 1)
	var closed: Dictionary = Ledger.apply(reduce["state"],
		_command(reduce["state"], "CONVERT_AP_TO_RP", "end-1"), config)
	_expect("M2_5_RP_FROM_REMAINING", closed["accepted"] and _legal(closed["state"])
		and closed["state"]["party_resources"]["rp"] == 3)
	var expired: Dictionary = Ledger.apply(closed["state"],
		_command(closed["state"], "EXPIRE_RP", "enemy-close"), config)
	_expect("M2_5_RP_DOES_NOT_CARRY", expired["accepted"] and _legal(expired["state"])
		and expired["state"]["party_resources"]["rp"] == 0)
	var reopened: Dictionary = Ledger.apply(expired["state"],
		_command(expired["state"], "START_PLAYER_RESOURCES", "open-2"), config)
	_expect("M2_5_AP_DEBT_REPAID_BEFORE_REFRESH", reopened["accepted"]
		and _legal(reopened["state"])
		and reopened["state"]["party_resources"]["ap_debt"] == 0
		and reopened["state"]["party_resources"]["current_ap"] == 5)
	var huge_ap: Dictionary = Ledger.apply(start,
		_command(start, "GRANT_AP", "grant-10", {"amount": 10}), config)
	var capped: Dictionary = Ledger.apply(huge_ap["state"],
		_command(huge_ap["state"], "CONVERT_AP_TO_RP", "cap-rp"), config)
	_expect("M2_5_AP_UNCAPPED_RP_CAPPED", huge_ap["accepted"] and capped["accepted"]
		and huge_ap["state"]["party_resources"]["current_ap"] == 16
		and capped["state"]["party_resources"]["rp"] == 6 and _legal(capped["state"]))
	var zero_phase: Dictionary = _state()
	zero_phase["phase"] = "AWAITING_PLAYER_START"
	zero_phase["party_resources"]["current_ap"] = 0
	zero_phase["party_resources"]["ap_debt"] = 8
	var zero_open: Dictionary = Ledger.apply(zero_phase,
		_command(zero_phase, "START_PLAYER_RESOURCES", "debt-zero"), config)
	_expect("M2_5_PROVISIONAL_ZERO_AP_PHASE", zero_open["accepted"]
		and zero_open["state"]["party_resources"]["current_ap"] == 0
		and zero_open["state"]["party_resources"]["ap_debt"] == 2
		and _legal(zero_open["state"]))
	var late: Dictionary = Cost.apply(paid["state"], _command(start,
		"PAY_SP_COST_ONLY", "stale", {"actor_id": "A", "card": _card(1, 1)}), config)
	_expect("M2_5_STALE_COMMAND_ATOMIC", not late["accepted"]
		and late["error"] == "STALE_STATE"
		and late["state_hash"] == Model.state_hash(paid["state"]))
	print("M2_5_RESOURCE_ONLY_INVARIANTS_REPORT executed=", passed + failed,
		" passed=", passed, " failed=", failed, " skipped=0", " card_instance_and_swap=BLOCKED_M2_3_M2_4")
	quit(1 if failed > 0 else 0)
