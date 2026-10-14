extends SceneTree
## M2.4 per-actor per-phase Free Swap; accepted vs PRECHECK denial vs
## post-CardDiscarded POOL_CHANGED; exact ordered event stream.
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const Zones = preload("res://scripts/domain/m2/cards/card_zone_resolver.gd")
const Draw = preload("res://scripts/domain/m2/cards/draw_resolver.gd")
const Swap = preload("res://scripts/domain/m2/cards/free_swap_resolver.gd")
const Triggers = preload("res://scripts/domain/m2/cards/card_trigger_dispatcher.gd")
const SEED: int = 20261014
var passed: int = 0
var failed: int = 0

func _expect(case_id: String, ok: bool) -> void:
	if ok:
		passed += 1
		print("PASS ", case_id)
	else:
		failed += 1
		printerr("FAIL ", case_id)

func _start(seed: int = SEED) -> Dictionary:
	var loadouts: Dictionary = {}
	var contexts: Dictionary = {}
	var owned: Dictionary = {}
	for actor_id: String in ["A", "B", "C"]:
		var cards: Array = []
		for i: int in range(12):
			cards.append("burst")
		loadouts[actor_id] = cards
		contexts[actor_id] = {"actor_id": actor_id, "variant_id": "default", "tags": []}
		owned[actor_id] = {"burst": 12}
	return Draw.start_battle(loadouts, contexts,
		{"burst": {"id": "burst", "kind": "SP"}}, owned, seed)

func _zone(s: Dictionary, actor_id: String, zone: String) -> Array:
	return s["actors"][actor_id]["zones"][zone]

func _cmd(s: Dictionary, actor_id: String, card_id: String, command_id: String) -> Dictionary:
	return {"type": "FREE_SWAP", "actor_id": actor_id, "card_instance_id": card_id,
		"command_id": command_id, "expected_event_seq": int(s["event_seq"]),
		"expected_phase_index": int(s["player_phase_index"])}

func _swap(s: Dictionary, actor_id: String, card_id: String, command_id: String,
		rules: Array = [], can_act: bool = true) -> Dictionary:
	return Swap.apply(s, _cmd(s, actor_id, card_id, command_id), rules, can_act)

func _event_index(events: Array, name: String) -> int:
	for i: int in range(events.size()):
		if str(events[i]["kind"]) == name:
			return i
	return -1

func _kinds(events: Array) -> Array:
	var values: Array = []
	for event: Dictionary in events:
		values.append(str(event["kind"]))
	return values

func _move_all_but_one_draw_to_casting(start: Dictionary) -> Dictionary:
	var s: Dictionary = start
	for i: int in range(7):
		var id: String = str(_zone(s, "A", "draw")[0])
		var r: Dictionary = Zones.move(s, "A", id, "draw", "casting")
		if not r["accepted"]:
			return {}
		s = r["state"]
	return s

func _trigger(event_kind: String, target_id: String, effect_id: String = "fx-1") -> Dictionary:
	return {"effect_id": effect_id, "on": event_kind, "source_definition_id": "burst",
		"source_actor_id": "A", "operation": "MOVE_CARD", "actor_id": "A",
		"instance_id": target_id, "from_zone": "draw", "to_zone": "casting"}

func _init() -> void:
	var created: Dictionary = _start()
	if not created["accepted"]:
		printerr("FAIL M2_4_SETUP ", created.get("error", ""))
		quit(1)
		return
	var s: Dictionary = created["state"]
	_expect("M2_4_INITIAL_CONSERVATION", Zones.validate_state(s) and s["swap_used_by_actor"].size() == 3)
	var selected: String = str(_zone(s, "A", "hand")[0])
	var swapped: Dictionary = _swap(s, "A", selected, "swap-a-1")
	_expect("M26-SWAP-001", swapped["accepted"] and swapped["draw_succeeded"]
		and Zones.validate_state(swapped["state"])
		and swapped["state"]["swap_used_by_actor"]["A"]
		and not swapped["state"]["swap_used_by_actor"]["B"]
		and _zone(swapped["state"], "A", "hand").size() == 4
		and _zone(swapped["state"], "A", "discard").size() == 1
		and _zone(swapped["state"], "A", "draw").size() == 7)
	_expect("M27-SWAP-002", not _zone(swapped["state"], "A", "hand").has(selected)
		and _zone(swapped["state"], "A", "discard").has(selected)
		and _event_index(swapped["events"], "CardDiscarded") >= 0)
	_expect("M30-SWAP-004", _kinds(swapped["events"]) ==
		["CardZoneChanged", "CardDiscarded", "CardDrawn", "CardZoneChanged", "FreeSwapCompleted"])
	var no_cost: Dictionary = swapped["events"][-1]["details"]
	_expect("M26-SWAP-ZERO_COST", int(no_cost["ap_cost"]) == 0 and int(no_cost["mp_cost"]) == 0)
	_expect("M2_4_INPUT_UNCHANGED", not s["swap_used_by_actor"]["A"]
		and _zone(s, "A", "hand").has(selected))
	var repeat: Dictionary = _swap(swapped["state"], "A",
		str(_zone(swapped["state"], "A", "hand")[0]), "swap-a-2")
	_expect("M26-SWAP-ONLY_ONCE", not repeat["accepted"]
		and repeat["error"] == "SWAP_ALREADY_USED_THIS_PHASE"
		and Model.state_hash(repeat["state"]) == Model.state_hash(swapped["state"])
		and repeat["events"].is_empty())
	var duplicate: Dictionary = _swap(swapped["state"], "A",
		str(_zone(swapped["state"], "A", "hand")[0]), "swap-a-1")
	_expect("M26-SWAP-DUPLICATE_COMMAND", not duplicate["accepted"]
		and duplicate["error"] == "DUPLICATE_COMMAND"
		and Model.state_hash(duplicate["state"]) == Model.state_hash(swapped["state"]))
	var stale_cmd: Dictionary = _cmd(swapped["state"], "A",
		str(_zone(swapped["state"], "A", "hand")[0]), "swap-a-stale")
	stale_cmd["expected_event_seq"] = int(s["event_seq"])
	var stale: Dictionary = Swap.apply(swapped["state"], stale_cmd)
	_expect("M26-SWAP-STALE_ATOMIC", not stale["accepted"] and stale["error"] == "STALE_STATE"
		and Model.state_hash(stale["state"]) == Model.state_hash(swapped["state"]))
	var b_swap: Dictionary = _swap(swapped["state"], "B", str(_zone(swapped["state"], "B", "hand")[0]), "swap-b-1")
	_expect("M26-SWAP-PER_ACTOR", b_swap["accepted"] and b_swap["state"]["swap_used_by_actor"]["B"]
		and not b_swap["state"]["swap_used_by_actor"]["C"] and Zones.validate_state(b_swap["state"]))
	var reset: Dictionary = Swap.open_next_player_phase(b_swap["state"], 2)
	_expect("M26-SWAP-RESET_NEXT_PHASE", reset["accepted"]
		and int(reset["state"]["player_phase_index"]) == 2
		and not reset["state"]["swap_used_by_actor"]["A"]
		and not reset["state"]["swap_used_by_actor"]["B"])
	var reopened: Dictionary = _swap(reset["state"], "A", str(_zone(reset["state"], "A", "hand")[0]), "swap-a-next")
	_expect("M26-SWAP-SECOND_PHASE_ALLOWED", reopened["accepted"] and Zones.validate_state(reopened["state"]))
	var reset_duplicate: Dictionary = Swap.open_next_player_phase(reset["state"], 2)
	_expect("M26-SWAP-PHASE_MONOTONIC", not reset_duplicate["accepted"]
		and reset_duplicate["error"] == "INVALID_PHASE_SEQUENCE")
	var in_enemy: Dictionary = s.duplicate(true)
	in_enemy["phase"] = "ENEMY_PHASE"
	_expect("M26-SWAP-PHASE_REJECT", _swap(in_enemy, "A", selected, "enemy-swap")["error"] == "INVALID_PHASE")
	_expect("M26-SWAP-ACTOR_UNAVAILABLE", _swap(s, "A", selected, "incapacitated", [], false)["error"] == "ACTOR_UNAVAILABLE")

	var no_pool: Dictionary = s
	for i: int in range(8):
		var moved: Dictionary = Zones.move(no_pool, "A",
			str(_zone(no_pool, "A", "draw")[0]), "draw", "casting")
		no_pool = moved["state"]
	var orig_hash: String = Model.state_hash(no_pool)
	var rejected: Dictionary = _swap(no_pool, "A", str(_zone(no_pool, "A", "hand")[0]), "no-pool")
	_expect("M29-SWAP-003", not rejected["accepted"] and rejected["error"] == "NO_LEGAL_REPLACEMENT"
		and rejected["events"].is_empty() and not rejected["state"]["swap_used_by_actor"]["A"]
		and Model.state_hash(rejected["state"]) == orig_hash
		and Zones.validate_state(rejected["state"]))
	_expect("M29-SWAP-CAN_RETRY", Zones.replacement_ids(no_pool, "A").is_empty()
		and not no_pool["seen_swap_command_ids"].has("no-pool"))
	var restored: Dictionary = Zones.move(no_pool, "A",
		str(_zone(no_pool, "A", "casting")[0]), "casting", "discard")
	var retried: Dictionary = _swap(restored["state"], "A",
		str(_zone(restored["state"], "A", "hand")[0]), "no-pool")
	_expect("M29-SWAP-PRECHECK_RETRY", retried["accepted"] and retried["draw_succeeded"]
		and _event_index(retried["events"], "DiscardReshuffled") >= 0
		and Zones.validate_state(retried["state"]))
	_expect("M29-SWAP-NO_SELF_REDRAW", not _zone(retried["state"], "A", "hand").has(
		str(_zone(restored["state"], "A", "hand")[0])))

	# PRE3-R11: PRECHECK passes with one replacement; discard trigger
	# deliberately removes that card into Casting before Draw.
	var single: Dictionary = _move_all_but_one_draw_to_casting(s)
	var last: String = str(_zone(single, "A", "draw")[0])
	var chosen: String = str(_zone(single, "A", "hand")[0])
	_expect("PRE3-11-PRECHECK_VALID", Zones.replacement_ids(single, "A", chosen).size() == 1)
	var rules: Array = [_trigger("CardDiscarded", last)]
	var changed: Dictionary = _swap(single, "A", chosen, "pool-changed", rules)
	var events: Array = changed["events"]
	_expect("PRE3-11-POOL_CHANGED", changed["accepted"] and not changed["draw_succeeded"]
		and Zones.validate_state(changed["state"])
		and changed["state"]["swap_used_by_actor"]["A"]
		and _zone(changed["state"], "A", "casting").has(last)
		and _zone(changed["state"], "A", "discard").has(chosen)
		and _zone(changed["state"], "A", "hand").size() == 3)
	_expect("PRE3-11-EVENT_ORDER", _event_index(events, "CardDiscarded") <
		_event_index(events, "CardTriggerResolved")
		and _event_index(events, "CardTriggerResolved") < _event_index(events, "CardDrawFailed")
		and _event_index(events, "CardDrawFailed") < _event_index(events, "FreeSwapCompleted")
		and _event_index(events, "CardDrawn") == -1)
	var failed_event: Dictionary = events[_event_index(events, "CardDrawFailed")]
	_expect("PRE3-11-EXPLICIT_REASON", failed_event["details"]["reason"] == "POOL_CHANGED"
		and events[-1]["details"]["reason"] == "POOL_CHANGED"
		and changed["state"]["seen_swap_command_ids"].has("pool-changed"))
	_expect("PRE3-11-NO_RETRY", _swap(changed["state"], "A",
		str(_zone(changed["state"], "A", "hand")[0]), "pool-again")["error"] == "SWAP_ALREADY_USED_THIS_PHASE")
	_expect("PRE3-11-ORIGINAL_STATE_PURE", Zones.validate_state(single)
		and _zone(single, "A", "draw").has(last) and _zone(single, "A", "hand").has(chosen))

	# On successful draw, dispatch the new CardDrawn event and its effects.
	var on_draw_target: String = str(_zone(s, "A", "draw")[0])
	var on_draw: Dictionary = _swap(s, "A", selected, "on-draw",
		[_trigger("CardDrawn", on_draw_target)])
	_expect("M30-SWAP-DRAW_TRIGGERS", on_draw["accepted"] and on_draw["draw_succeeded"]
		and Zones.validate_state(on_draw["state"])
		and _zone(on_draw["state"], "A", "casting").has(on_draw_target))
	var d_events: Array = on_draw["events"]
	_expect("M28-SWAP-EVENT_TRIGGERS_ORDER", _event_index(d_events, "CardDiscarded") <
		_event_index(d_events, "CardDrawn") and _event_index(d_events, "CardDrawn") <
		_event_index(d_events, "CardTriggerResolved") and _event_index(d_events, "CardTriggerResolved") <
		_event_index(d_events, "FreeSwapCompleted"))
	_expect("M28-SWAP-UNMATCHED_NO_EFFECT", Triggers.dispatch(s,
		{"kind": "CardZoneChanged"}, [_trigger("CardDrawn", on_draw_target)])["events"].is_empty())
	var invalid_rules: Array = [_trigger("CardDiscarded", on_draw_target)]
	invalid_rules[0]["to_zone"] = "isolated"
	var invalid: Dictionary = _swap(s, "A", selected, "invalid-triggers", invalid_rules)
	_expect("M2_4-INVALID_TRIGGER_ATOMIC", not invalid["accepted"]
		and invalid["error"] == "PROTECTED_SWAP_ISOLATION"
		and Model.state_hash(invalid["state"]) == Model.state_hash(s))
	var duplicates_rules: Array = [
		_trigger("CardDiscarded", on_draw_target, "e1"),
		_trigger("CardDiscarded", on_draw_target, "e2")
	]
	var skipped: Dictionary = _swap(s, "A", selected, "conflicting-trigger", duplicates_rules)
	_expect("M28-SWAP-TRIGGER_SKIP_NO_ROLLBACK", skipped["accepted"]
		and _event_index(skipped["events"], "CardTriggerResolved") >= 0
		and _event_index(skipped["events"], "CardTriggerSkipped") >= 0
		and Zones.validate_state(skipped["state"]))

	var same_seed: Dictionary = _start()
	var again: Dictionary = _swap(same_seed["state"], "A",
		str(_zone(same_seed["state"], "A", "hand")[0]), "on-draw",
		[_trigger("CardDrawn", str(_zone(same_seed["state"], "A", "draw")[0]))])
	_expect("M2_4-SEEDED_REPLAY", again["accepted"]
		and Model.event_hash(again["events"]) == Model.event_hash(on_draw["events"])
		and Model.state_hash(again["state"]) == Model.state_hash(on_draw["state"]))
	_expect("M2_4-EVENT_SEQ_MONOTONIC", _events_monotonic(changed["state"])
		and _events_monotonic(on_draw["state"]))
	print("M2_4_REPLAY event_hash=", Model.event_hash(on_draw["events"]),
		" state_hash=", Model.state_hash(on_draw["state"]))
	print("M2_4_TEST_REPORT executed=", passed + failed, " passed=", passed, " failed=", failed,
		" seed=", SEED)
	if failed == 0:
		print("M2_4_FREE_SWAP_DOMAIN_VERIFIED")
	quit(0 if failed == 0 else 1)

func _events_monotonic(state: Dictionary) -> bool:
	if state["events"].size() != int(state["event_seq"]):
		return false
	for i: int in range(state["events"].size()):
		if int(state["events"][i]["event_seq"]) != i + 1:
			return false
	return true
