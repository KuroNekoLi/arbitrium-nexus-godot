extends SceneTree
## M2.5 actual cross-module state/replay tests. Fixture-only spell effects,
## but real M2.2 payments + M2.3 instance moves + M2.4 FreeSwap.
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const Zones = preload("res://scripts/domain/m2/cards/card_zone_resolver.gd")
const Draw = preload("res://scripts/domain/m2/cards/draw_resolver.gd")
const Integrated = preload("res://scripts/domain/m2/integration/m2_domain_resolver.gd")
const SEED: int = 20261014
var passed: int = 0
var failed: int = 0
var config: Dictionary = {}

func _expect(id: String, good: bool, note: String = "") -> void:
	if good:
		passed += 1
		print("PASS ", id)
	else:
		failed += 1
		printerr("FAIL ", id, " ", note)

func _fixture(seed: int = SEED, definition: String = "burst") -> Dictionary:
	var loadouts: Dictionary = {}
	var contexts: Dictionary = {}
	var owned: Dictionary = {}
	for actor_id: String in ["A", "B", "C"]:
		var ids: Array = []
		for i: int in range(12):
			ids.append(definition)
		loadouts[actor_id] = ids
		contexts[actor_id] = {"actor_id": actor_id, "variant_id": "default", "tags": []}
		owned[actor_id] = {definition: 12}
	var card_definitions: Dictionary = {definition: {"id": definition, "kind": "SP"}}
	var started: Dictionary = Draw.start_battle(loadouts, contexts, card_definitions, owned, seed)
	if not started["accepted"]:
		return {}
	var battle: Dictionary = Model.make_state(["A", "B", "C"], ["Boss"], seed)
	battle["actors"]["A"]["mp"] = 8
	battle["actors"]["A"]["max_mp"] = 10
	battle["actors"]["B"]["mp"] = 6
	battle["actors"]["B"]["max_mp"] = 8
	battle["actors"]["C"]["mp"] = 5
	battle["actors"]["C"]["max_mp"] = 12
	return Integrated.make_state(battle, started["state"])

func _hand(state: Dictionary, actor: String) -> Array:
	return state["cards"]["actors"][actor]["zones"]["hand"]

func _zone(state: Dictionary, actor: String, zone: String) -> Array:
	return state["cards"]["actors"][actor]["zones"][zone]

func _cmd(state: Dictionary, kind: String, id: String, extra: Dictionary = {}) -> Dictionary:
	var command: Dictionary = {"type": kind, "command_id": id,
		"expected_event_seq": int(state["event_seq"])}
	for key: Variant in extra:
		command[key] = extra[key]
	return command

func _do(state: Dictionary, kind: String, id: String, extra: Dictionary = {},
		options: Dictionary = {}) -> Dictionary:
	return Integrated.apply(state, _cmd(state, kind, id, extra), config if options.is_empty() else options)

func _cost(actor: String, card: String, mode: String = "CHANTLESS") -> Dictionary:
	return {"actor_id": actor, "card_instance_id": card, "casting_mode": mode}

func _swap(actor: String, card: String) -> Dictionary:
	return {"actor_id": actor, "card_instance_id": card}

func _source_kinds(events: Array) -> Array:
	var kinds: Array = []
	for item: Dictionary in events:
		kinds.append(str(item["event"]["kind"]))
	return kinds

func _index(events: Array, kind: String) -> int:
	for i: int in range(events.size()):
		if str(events[i]["event"]["kind"]) == kind:
			return i
	return -1

func _snapshot_result(result: Dictionary, original: Dictionary, reason: String) -> bool:
	return (not result["accepted"] and str(result["error"]) == reason
		and result["events"].is_empty()
		and Model.state_hash(result["state"]) == Model.state_hash(original))

func _init() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(
		"res://resources/combat/rulesets/m2_2_provisional_costs.json"))
	if not parsed is Dictionary:
		printerr("M2_5_INTEGRATION_SETUP_CONFIG_FAILED")
		quit(1)
		return
	config = {"costs": parsed, "resources": parsed, "definitions": {
		"burst": {"card_id": "burst", "ap_cost": 3, "mp_cost": 2},
		"over": {"card_id": "over", "ap_cost": 8, "mp_cost": 2,
			"overload_eligible": true, "max_borrow_per_card": 2}
	}, "trigger_rules": []}
	var initial: Dictionary = _fixture()
	if not Integrated.validate_state(initial):
		printerr("M2_5_INTEGRATION_SETUP_STATE_FAILED")
		quit(1)
		return
	_expect("M2_5_INT_INITIAL_36_CARDS", Zones.validate_state(initial["cards"])
		and initial["cards"]["actors"].size() == 3
		and _hand(initial, "A").size() == 4 and _zone(initial, "B", "draw").size() == 8
		and initial["battle"]["party_resources"]["current_ap"] == 6)
	var initial_hash: String = Model.state_hash(initial)
	var selected: String = str(_hand(initial, "A")[0])
	var committed: Dictionary = _do(initial, "COMMIT_SP_CARD_FIXTURE", "paid-a", _cost("A", selected))
	_expect("M2_5_INT_COST_ZONE_ATOMIC", committed["accepted"]
		and Integrated.validate_state(committed["state"])
		and committed["state"]["battle"]["party_resources"]["current_ap"] == 3
		and committed["state"]["battle"]["actors"]["A"]["mp"] == 6
		and _zone(committed["state"], "A", "discard").has(selected)
		and _hand(committed["state"], "A").size() == 3)
	_expect("M2_5_INT_COST_BEFORE_ZONE", _source_kinds(committed["events"]) ==
		["SPCostReservedOnly", "CardZoneChanged"]
		and committed["events"][0]["source"] == "resources"
		and committed["events"][1]["source"] == "cards")
	_expect("M2_5_INT_INPUT_NOT_MUTATED", Model.state_hash(initial) == initial_hash)
	var again_same: Dictionary = _do(committed["state"], "COMMIT_SP_CARD_FIXTURE",
		"double-card", _cost("A", selected))
	_expect("M2_5_INT_DOUBLE_SP_REJECT", _snapshot_result(again_same,
		committed["state"], "CARD_NOT_IN_OWN_HAND"))
	var other_actor: Dictionary = _do(committed["state"], "COMMIT_SP_CARD_FIXTURE",
		"wrong-owner", _cost("B", str(_hand(committed["state"], "A")[0])))
	_expect("M2_5_INT_OWNER_REJECT", _snapshot_result(other_actor,
		committed["state"], "CARD_NOT_IN_OWN_HAND"))
	var missing_definition: Dictionary = config.duplicate(true)
	missing_definition["definitions"].erase("burst")
	var cost_config_denied: Dictionary = _do(initial, "COMMIT_SP_CARD_FIXTURE", "no-definition",
		_cost("A", selected), missing_definition)
	_expect("M2_5_INT_COST_CATALOG_REJECT", _snapshot_result(cost_config_denied,
		initial, "NO_VERSIONED_CARD_COST"))
	var low_mp: Dictionary = initial.duplicate(true)
	low_mp["battle"]["actors"]["A"]["mp"] = 0
	var not_paid: Dictionary = _do(low_mp, "COMMIT_SP_CARD_FIXTURE", "no-mp", _cost("A", selected))
	_expect("M2_5_INT_MP_NO_CARD_LOSS", _snapshot_result(not_paid, low_mp, "INSUFFICIENT_MP")
		and _hand(not_paid["state"], "A").has(selected))
	var no_ap: Dictionary = initial.duplicate(true)
	no_ap["battle"]["party_resources"]["current_ap"] = 0
	var not_enough: Dictionary = _do(no_ap, "COMMIT_SP_CARD_FIXTURE", "no-ap", _cost("A", selected))
	_expect("M2_5_INT_AP_NO_CARD_LOSS", _snapshot_result(not_enough, no_ap, "INSUFFICIENT_AP")
		and _hand(not_enough["state"], "A").has(selected))
	var swapped_zero: Dictionary = _do(no_ap, "FREE_SWAP", "zero-ap-swap", _swap("A", selected))
	_expect("M2_5_INT_ZERO_AP_SWAP", swapped_zero["accepted"]
		and Integrated.validate_state(swapped_zero["state"])
		and swapped_zero["state"]["battle"]["party_resources"] == no_ap["battle"]["party_resources"]
		and swapped_zero["state"]["battle"]["actors"]["A"]["mp"] == no_ap["battle"]["actors"]["A"]["mp"])
	var double_swap: Dictionary = _do(swapped_zero["state"], "FREE_SWAP", "swap-again",
		_swap("A", str(_hand(swapped_zero["state"], "A")[0])))
	_expect("M2_5_INT_SWAP_ONCE", _snapshot_result(double_swap,
		swapped_zero["state"], "SWAP_ALREADY_USED_THIS_PHASE"))
	var source_conflict: Dictionary = _do(swapped_zero["state"], "COMMIT_SP_CARD_FIXTURE",
		"zero-ap-swap", _cost("A", str(_hand(swapped_zero["state"], "A")[0])))
	_expect("M2_5_INT_GLOBAL_DUPLICATE_COMMAND", _snapshot_result(source_conflict,
		swapped_zero["state"], "DUPLICATE_COMMAND"))
	var stale: Dictionary = _cmd(swapped_zero["state"], "FREE_SWAP", "stale-1",
		_swap("B", str(_hand(swapped_zero["state"], "B")[0])))
	stale["expected_event_seq"] = int(initial["event_seq"])
	_expect("M2_5_INT_GLOBAL_STALE_COMMAND", _snapshot_result(
		Integrated.apply(swapped_zero["state"], stale, config), swapped_zero["state"], "STALE_STATE"))
	var full: Dictionary = _do(initial, "COMMIT_SP_CARD_FIXTURE", "full-1",
		_cost("A", selected, "FULL"))
	_expect("M2_5_INT_CASTING_ZONE_EXCLUSIVE", full["accepted"]
		and _zone(full["state"], "A", "casting").has(selected)
		and not _zone(full["state"], "A", "discard").has(selected)
		and full["state"]["battle"]["actors"]["A"]["mp"] == 6)
	var complete: Dictionary = _do(full["state"], "RESOLVE_CAST_ZONE_FIXTURE", "finish-full",
		{"actor_id": "A", "card_instance_id": selected})
	_expect("M2_5_INT_CASTING_TO_DISCARD", complete["accepted"]
		and _zone(complete["state"], "A", "casting").is_empty()
		and _zone(complete["state"], "A", "discard").has(selected)
		and Integrated.validate_state(complete["state"]))
	# Same instance cannot be readied for a second SP while casting.
	_expect("M2_5_INT_CASTING_NOT_DRAWABLE", _snapshot_result(
		_do(full["state"], "COMMIT_SP_CARD_FIXTURE", "full-illegal",
			_cost("A", selected)), full["state"], "CARD_NOT_IN_OWN_HAND"))

	# The provisional Overload fixture *really* pays cost and moves card.
	var overload: Dictionary = _fixture(SEED, "over")
	var over_id: String = str(_hand(overload, "A")[0])
	var borrowed: Dictionary = _do(overload, "COMMIT_SP_CARD_FIXTURE", "overload-pay",
		_cost("A", over_id))
	_expect("M2_5_INT_OVERLOAD_LINKED_CARD", borrowed["accepted"]
		and borrowed["state"]["battle"]["party_resources"]["current_ap"] == 0
		and borrowed["state"]["battle"]["party_resources"]["ap_debt"] == 2
		and _zone(borrowed["state"], "A", "discard").has(over_id)
		and borrowed["state"]["battle"]["actors"]["A"]["mp"] == 6)
	var zero_cost: Dictionary = borrowed["state"]
	var after_debt: Dictionary = _do(zero_cost, "FREE_SWAP", "overload-free",
		_swap("A", str(_hand(zero_cost, "A")[0])))
	_expect("M2_5_INT_AP_DEBT_SWAP_FREE", after_debt["accepted"]
		and after_debt["state"]["battle"]["party_resources"]["ap_debt"] == 2
		and after_debt["state"]["battle"]["party_resources"]["current_ap"] == 0)

	# PRECHECK no alternative: keep immutable resources/cards/quota/events.
	var blocked: Dictionary = initial.duplicate(true)
	for i: int in range(8):
		var move: Dictionary = Zones.move(blocked["cards"], "A",
			str(blocked["cards"]["actors"]["A"]["zones"]["draw"][0]),
			"draw", "casting")
		blocked["cards"] = move["state"]
	_expect("M2_5_INT_NO_POOL_FIXTURE_VALID", Integrated.validate_state(blocked))
	var no_pool_swap: Dictionary = _do(blocked, "FREE_SWAP", "no-legal-alternative",
		_swap("A", str(_hand(blocked, "A")[0])))
	_expect("M2_5_INT_PRECHECK_ATOMIC", _snapshot_result(
		no_pool_swap, blocked, "NO_LEGAL_REPLACEMENT")
		and not no_pool_swap["state"]["cards"]["swap_used_by_actor"]["A"])

	# PRE3-R11: last legal replacement is moved to Casting by CardDiscarded.
	var one: Dictionary = initial.duplicate(true)
	for i: int in range(7):
		var moved: Dictionary = Zones.move(one["cards"], "A",
			str(one["cards"]["actors"]["A"]["zones"]["draw"][0]), "draw", "casting")
		one["cards"] = moved["state"]
	var last_id: String = str(_zone(one, "A", "draw")[0])
	var trigger: Dictionary = {"effect_id": "move-last", "on": "CardDiscarded",
		"source_definition_id": "burst", "source_actor_id": "A",
		"operation": "MOVE_CARD", "actor_id": "A", "instance_id": last_id,
		"from_zone": "draw", "to_zone": "casting"}
	var with_trigger: Dictionary = config.duplicate(true)
	with_trigger["trigger_rules"] = [trigger]
	var original: String = str(_hand(one, "A")[0])
	var pool_changed: Dictionary = _do(one, "FREE_SWAP", "pool-changed",
		_swap("A", original), with_trigger)
	_expect("M2_5_INT_PRE3_R11_NOT_ROLLED_BACK", pool_changed["accepted"]
		and _zone(pool_changed["state"], "A", "casting").has(last_id)
		and _zone(pool_changed["state"], "A", "discard").has(original)
		and pool_changed["state"]["cards"]["swap_used_by_actor"]["A"]
		and Integrated.validate_state(pool_changed["state"]))
	_expect("M2_5_INT_PRE3_R11_ORDER", _index(pool_changed["events"], "CardDiscarded") <
		_index(pool_changed["events"], "CardTriggerResolved")
		and _index(pool_changed["events"], "CardTriggerResolved") <
		_index(pool_changed["events"], "CardDrawFailed")
		and _index(pool_changed["events"], "CardDrawn") == -1
		and pool_changed["events"][_index(pool_changed["events"], "CardDrawFailed")]["event"]["details"]["reason"] == "POOL_CHANGED")
	_expect("M2_5_INT_PRE3_R11_NO_RESOURCE_CHANGE", pool_changed["state"]["battle"] ==
		one["battle"] and Model.state_hash(one["battle"]) ==
		Model.state_hash(initial["battle"]))

	# Hand 8 cap is enforced IN COMPOSITE; no card or RNG is invented.
	var draw8: Dictionary = _do(initial, "EXTRA_DRAW_FIXTURE", "fill-8",
		{"actor_id": "A", "count": 20})
	_expect("M2_5_INT_HAND_CAP8", draw8["accepted"]
		and _hand(draw8["state"], "A").size() == 8
		and _zone(draw8["state"], "A", "draw").size() == 4)
	var no_more: Dictionary = _do(draw8["state"], "EXTRA_DRAW_FIXTURE", "extra-ninth",
		{"actor_id": "A", "count": 3})
	_expect("M2_5_INT_HAND_CAP8_NO_PHANTOM", no_more["accepted"]
		and no_more["events"].is_empty()
		and _zone(no_more["state"], "A", "draw").size() == 4
		and Integrated.validate_state(no_more["state"]))
	var invalid_actor: Dictionary = initial.duplicate(true)
	invalid_actor["battle"]["actors"]["A"]["status"] = "INCAPACITATED"
	var not_act: Dictionary = _do(invalid_actor, "FREE_SWAP", "unavailable",
		_swap("A", str(_hand(invalid_actor, "A")[0])))
	_expect("M2_5_INT_INCAPACITATED_DENIED", _snapshot_result(
		not_act, invalid_actor, "ACTOR_UNAVAILABLE"))

	# A true mixed command tape, with quoted AP/MP, actual SP movement,
	# M2.4 events, AP->RP/expiry, debt-phase refill, and a second swap.
	var tape: Array[Dictionary] = []
	var current: Dictionary = initial
	var first_cmd: Dictionary = _cmd(current, "COMMIT_SP_CARD_FIXTURE", "tape-sp-a",
		_cost("A", str(_hand(current, "A")[0])))
	tape.append(first_cmd)
	var op: Dictionary = Integrated.apply(current, first_cmd, config)
	if not op["accepted"]:
		_expect("M2_5_INT_TAPE_BUILD", false, str(op["error"]))
		quit(1)
		return
	current = op["state"]
	var second_cmd: Dictionary = _cmd(current, "FREE_SWAP", "tape-swap-a",
		_swap("A", str(_hand(current, "A")[0])))
	tape.append(second_cmd)
	op = Integrated.apply(current, second_cmd, config)
	if not op["accepted"]:
		_expect("M2_5_INT_TAPE_BUILD", false, str(op["error"]))
		quit(1)
		return
	current = op["state"]
	var third_cmd: Dictionary = _cmd(current, "COMMIT_SP_CARD_FIXTURE", "tape-sp-b",
		_cost("B", str(_hand(current, "B")[0])))
	tape.append(third_cmd)
	op = Integrated.apply(current, third_cmd, config)
	if not op["accepted"]:
		_expect("M2_5_INT_TAPE_BUILD", false, str(op["error"]))
		quit(1)
		return
	current = op["state"]
	for phase_step: String in ["CONVERT_AP_TO_RP", "EXPIRE_RP", "START_PLAYER_RESOURCES"]:
		var cmd: Dictionary = _cmd(current, phase_step, "tape-" + phase_step)
		tape.append(cmd)
		op = Integrated.apply(current, cmd, config)
		if not op["accepted"]:
			_expect("M2_5_INT_TAPE_BUILD", false, str(op["error"]))
			quit(1)
			return
		current = op["state"]
	_expect("M2_5_INT_NEXT_PHASE_REFILL", int(current["battle"]["round"]) == 2
		and int(current["cards"]["player_phase_index"]) == 2
		and _hand(current, "A").size() == 4
		and not current["cards"]["swap_used_by_actor"]["A"]
		and current["battle"]["party_resources"]["current_ap"] == 6
		and current["battle"]["party_resources"]["rp"] == 0)
	var last_cmd: Dictionary = _cmd(current, "FREE_SWAP", "tape-swap-a-again",
		_swap("A", str(_hand(current, "A")[0])))
	tape.append(last_cmd)
	op = Integrated.apply(current, last_cmd, config)
	if not op["accepted"]:
		_expect("M2_5_INT_TAPE_BUILD", false, str(op["error"]))
		quit(1)
		return
	current = op["state"]
	var first_run: Dictionary = Integrated.replay(initial, tape, config)
	var second_run: Dictionary = Integrated.replay(initial, tape, config)
	_expect("M2_5_INT_FULL_CROSS_MODULE_REPLAY", first_run["accepted"] and second_run["accepted"]
		and first_run["state_hash"] == second_run["state_hash"]
		and first_run["event_hash"] == second_run["event_hash"]
		and first_run["state_hash"] == Model.state_hash(current)
		and Integrated.validate_state(first_run["state"]))
	_expect("M2_5_INT_REPLAY_EVENT_ORDER", _index(first_run["events"], "SPCostReservedOnly") >= 0
		and _index(first_run["events"], "CardDiscarded") > _index(first_run["events"], "SPCostReservedOnly")
		and _index(first_run["events"], "PlayerResourcesOpened") > _index(first_run["events"], "CardDiscarded")
		and _index(first_run["events"], "FreeSwapQuotaRefreshed") > _index(first_run["events"], "PlayerResourcesOpened"))
	_expect("M2_5_INT_REPLAY_RNG_EQUAL", first_run["state"]["cards"]["rng_state"] ==
		second_run["state"]["cards"]["rng_state"]
		and first_run["state"]["battle"]["rng"] == second_run["state"]["battle"]["rng"])
	_expect("M2_5_INT_REPLAY_QUOTA_RESET_REUSED", first_run["state"]["cards"]["swap_used_by_actor"]["A"]
		and first_run["state"]["cards"]["seen_swap_command_ids"].size() == 2)
	_expect("M2_5_INT_REPLAY_ZERO_RP", first_run["state"]["battle"]["party_resources"]["rp"] == 0)
	var different_seed: Dictionary = _fixture(SEED + 1)
	var distinct: Dictionary = Integrated.replay(different_seed, tape, config)
	_expect("M2_5_INT_REPLAY_DISTINCT_INITIAL_SEED", not distinct["accepted"]
		or distinct["state_hash"] != first_run["state_hash"])
	var poisoned: Array[Dictionary] = tape.duplicate(true)
	poisoned.append(tape[0].duplicate(true))
	var declined: Dictionary = Integrated.replay(initial, poisoned, config)
	_expect("M2_5_INT_REPLAY_FAILURE_ATOMIC", not declined["accepted"]
		and declined["error"] == "DUPLICATE_COMMAND"
		and declined["state_hash"] == first_run["state_hash"]
		and declined["event_hash"] == first_run["event_hash"])
	_expect("M2_5_INT_EVENT_SEQUENCE_MONOTONIC", _sequence_ok(first_run["state"])
		and _sequence_ok(pool_changed["state"]) and _sequence_ok(borrowed["state"]))
	_expect("M2_5_INT_REPLAY_INITIAL_UNTOUCHED", Model.state_hash(initial) == initial_hash)
	print("M2_5_INTEGRATION_HASH seed=", SEED,
		" initial=", initial_hash, " events=", first_run["event_hash"],
		" final=", first_run["state_hash"])
	print("M2_5_INTEGRATION_REPORT executed=", passed + failed,
		" passed=", passed, " failed=", failed)
	if failed == 0:
		print("M2_5_CROSS_MODULE_DOMAIN_VERIFIED")
	quit(0 if failed == 0 else 1)

func _sequence_ok(state: Dictionary) -> bool:
	if int(state["event_seq"]) != state["events"].size():
		return false
	for i: int in range(state["events"].size()):
		if int(state["events"][i]["event_seq"]) != i + 1:
			return false
	return true
