extends SceneTree
## M3.2: window identity, draft purity, multi-actor reorder, Confirm JIT,
## PRE3-R04 cancelled-trigger skips (no fee/card/quota), pass and replay.
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const Draw = preload("res://scripts/domain/m2/cards/draw_resolver.gd")
const Zones = preload("res://scripts/domain/m2/cards/card_zone_resolver.gd")
const M2 = preload("res://scripts/domain/m2/integration/m2_domain_resolver.gd")
const Phase = preload("res://scripts/domain/m3/phase/phase_engine.gd")
const Queue = preload("res://scripts/domain/m3/reaction/reaction_queue_resolver.gd")
const Eligibility = preload("res://scripts/domain/m3/reaction/reaction_eligibility.gd")
const SEED: int = 20261014
var pass_count: int = 0
var fail_count: int = 0
var config: Dictionary = {}

func _expect(id: String, yes: bool) -> void:
	if yes:
		pass_count += 1
		print("PASS ", id)
	else:
		fail_count += 1
		printerr("FAIL ", id)

func _fixture() -> Dictionary:
	var loadouts: Dictionary = {}
	var contexts: Dictionary = {}
	var owned: Dictionary = {}
	var defs: Dictionary = {}
	var actor_def: Dictionary = {"A": "counter", "B": "shield", "C": "support"}
	for actor: String in ["A", "B", "C"]:
		var d: String = str(actor_def[actor])
		var cards: Array = []
		for i: int in range(12):
			cards.append(d)
		loadouts[actor] = cards
		contexts[actor] = {"actor_id": actor, "variant_id": "default", "tags": []}
		owned[actor] = {d: 12}
		defs[d] = {"id": d, "kind": "SP"}
	var drawn: Dictionary = Draw.start_battle(loadouts, contexts, defs, owned, SEED)
	if not drawn["accepted"]:
		return {}
	var battle: Dictionary = Model.make_state(["A", "B", "C"], ["Boss"], SEED)
	for actor: String in ["A", "B", "C"]:
		battle["actors"][actor]["mp"] = 8
		battle["actors"][actor]["max_mp"] = 10
	var core: Dictionary = M2.make_state(battle, drawn["state"])
	return Phase.make_state(core, _intents())

func _intents() -> Array:
	return [
		{"intent_id": "boss-1", "enemy_id": "Boss", "action_order": 1,
			"created_seq": 1, "publicly_declared": true, "target_scope": "MULTI",
			"target_ids": ["A", "B"], "requires_reaction_window": true,
			"hit_count": 3},
		{"intent_id": "boss-2", "enemy_id": "Boss", "action_order": 2,
			"created_seq": 2, "publicly_declared": true, "target_scope": "SINGLE",
			"target_ids": ["A"], "requires_reaction_window": true,
			"hit_count": 1}
	]

func _config() -> Dictionary:
	return {"reaction_definitions": {
		"counter": {"kind": "REACTION_SP", "reaction_trigger": "ENEMY_ACTION",
			"rp_cost": 1, "mp_cost": 2, "fixture_effect": "CANCEL_ACTION_FIXTURE",
			"target_scope": "ANY", "requires_active_enemy_action": true},
		"shield": {"kind": "REACTION_SP", "reaction_trigger": "ENEMY_ACTION",
			"rp_cost": 2, "mp_cost": 1, "fixture_effect": "NOOP_FIXTURE",
			"target_scope": "ANY", "requires_active_enemy_action": true},
		"support": {"kind": "REACTION_SP", "reaction_trigger": "ENEMY_ACTION",
			"rp_cost": 1, "mp_cost": 1, "fixture_effect": "INDEPENDENT_SUPPORT_FIXTURE",
			"target_scope": "ANY", "requires_active_enemy_action": false}
	}}

func _cmd(state: Dictionary, kind: String, command_id: String, extra: Dictionary = {}) -> Dictionary:
	var command: Dictionary = {"type": kind, "command_id": command_id,
		"expected_event_seq": int(state["event_seq"])}
	for k: Variant in extra:
		command[k] = extra[k]
	return command

func _do(state: Dictionary, kind: String, id: String, extra: Dictionary = {}) -> Dictionary:
	return Phase.apply(state, _cmd(state, kind, id, extra), config)

func _card(state: Dictionary, actor: String, slot: int = 0) -> String:
	return str(state["core"]["cards"]["actors"][actor]["zones"]["hand"][slot])

func _entry(state: Dictionary, actor: String, target: String, slot: int = 0) -> Dictionary:
	return {"kind": "REACTION_SP_FIXTURE", "actor_id": actor,
		"card_instance_id": _card(state, actor, slot), "target_actor_id": target}

func _reaction_cmd(state: Dictionary, kind: String, id: String,
		other: Dictionary = {}) -> Dictionary:
	var args: Dictionary = {"window_id": str(state["reaction_window"]["window_id"])}
	args.merge(other)
	return _cmd(state, kind, id, args)

func _reaction(state: Dictionary, kind: String, id: String,
		other: Dictionary = {}) -> Dictionary:
	return Phase.apply(state, _reaction_cmd(state, kind, id, other), config)

func _index(events: Array, kind: String) -> int:
	for i: int in range(events.size()):
		if str(events[i]["kind"]) == kind:
			return i
	return -1

func _atomic(result: Dictionary, original: Dictionary, error: String) -> bool:
	return not result["accepted"] and str(result["error"]) == error and result["events"].is_empty() \
		and Model.state_hash(result["state"]) == Model.state_hash(original)

func _init() -> void:
	config = _config()
	var initial: Dictionary = _fixture()
	if not Phase.validate_state(initial):
		printerr("FAIL M3_2_FIXTURE_INVALID")
		quit(1)
		return
	var base_hash: String = Model.state_hash(initial)
	var end: Dictionary = _do(initial, "END_PLAYER_PHASE", "end")
	var declared: Dictionary = _do(end["state"], "DECLARE_NEXT_ENEMY_ACTION", "declare")
	var pending: Dictionary = declared["state"]
	var active_id: String = str(pending["active_enemy_action_id"])
	_expect("M3_2_ENEMY_ACTION_PINNED", active_id == "round:1:intent:boss-1")
	_expect("M3_2_RP_REAL_M2_LEDGER", pending["core"]["battle"]["party_resources"]["rp"] == 6)
	_expect("M3_2_MUST_OPEN_WINDOW", _atomic(
		_do(pending, "COMPLETE_ENEMY_ACTION_FIXTURE", "bypass",
			{"enemy_action_id": active_id}), pending, "REACTION_WINDOW_REQUIRED"))
	var open_cmd: Dictionary = _cmd(pending, "OPEN_REACTION_WINDOW", "open-1",
		{"enemy_action_id": active_id})
	var opened: Dictionary = Phase.apply(pending, open_cmd, config)
	var opened_state: Dictionary = opened["state"]
	_expect("M3_2_WINDOW_ID", opened["accepted"]
		and opened_state["reaction_window"]["window_id"] == active_id + ":window:0"
		and opened_state["reaction_window"]["status"] == "DRAFTING")
	_expect("M3_2_SINGLE_WINDOW_THREE_HITS", opened_state["enemy_actions"][0]["public_intent"]["hit_count"] == 3
		and _atomic(_do(opened_state, "OPEN_REACTION_WINDOW", "duplicate-open",
			{"enemy_action_id": active_id}), opened_state, "REACTION_WINDOW_ALREADY_OPENED"))
	_expect("M3_2_WRONG_ACTION_ID_REJECTED", _atomic(
		_do(pending, "OPEN_REACTION_WINDOW", "bad-action",
			{"enemy_action_id": "round:1:intent:boss-2"}), pending, "STALE_ENEMY_ACTION_ID"))
	_expect("M3_2_WRONG_WINDOW_ID_REJECTED", _atomic(
		_do(opened_state, "PASS_REACTION", "wrong-window", {"window_id": "stale"}),
		opened_state, "STALE_WINDOW_ID"))

	var old_mp: int = int(opened_state["core"]["battle"]["actors"]["A"]["mp"])
	var old_rp: int = int(opened_state["core"]["battle"]["party_resources"]["rp"])
	var old_card_hash: String = Model.state_hash(opened_state["core"]["cards"])
	var draft1: Dictionary = _reaction(opened_state, "QUEUE_REACTION", "q-a",
		{"entry": _entry(opened_state, "A", "A")})
	var draft2: Dictionary = _reaction(draft1["state"], "QUEUE_REACTION", "q-b",
		{"entry": _entry(draft1["state"], "B", "A")})
	var draft3: Dictionary = _reaction(draft2["state"], "QUEUE_REACTION", "q-c",
		{"entry": _entry(draft2["state"], "C", "C")})
	var drafted: Dictionary = draft3["state"]
	_expect("M3_2_MULTIACTOR_QUEUE", draft1["accepted"] and draft2["accepted"] and draft3["accepted"]
		and drafted["reaction_window"]["draft"].size() == 3)
	_expect("M3_2_QUEUE_DOES_NOT_PAY", drafted["core"]["battle"]["party_resources"]["rp"] == old_rp
		and int(drafted["core"]["battle"]["actors"]["A"]["mp"]) == old_mp
		and Model.state_hash(drafted["core"]["cards"]) == old_card_hash)
	var inspected_hash: String = Model.state_hash(drafted)
	var preview: Dictionary = Queue.preview(drafted, config["reaction_definitions"])
	_expect("M3_2_PURE_PREVIEW", preview["ok"] and preview["estimated_rp"] == 4
		and Model.state_hash(drafted) == inspected_hash)
	var replace: Dictionary = _reaction(drafted, "QUEUE_REACTION", "replace-b",
		{"entry": _entry(drafted, "B", "B", 1)})
	_expect("M3_2_SAME_ACTOR_REPLACES_DRAFT", replace["accepted"]
		and replace["state"]["reaction_window"]["draft"].size() == 3
		and replace["state"]["reaction_window"]["draft"][1]["card_instance_id"] == _card(drafted, "B", 1))
	var undo: Dictionary = _reaction(replace["state"], "REMOVE_REACTION", "remove-b",
		{"actor_id": "B"})
	_expect("M3_2_REMOVE_DRAFT_NO_CARD_SPEND", undo["accepted"]
		and undo["state"]["reaction_window"]["draft"].size() == 2
		and Model.state_hash(undo["state"]["core"]) == Model.state_hash(drafted["core"]))
	var restore: Dictionary = _reaction(undo["state"], "QUEUE_REACTION", "re-add-b",
		{"entry": _entry(undo["state"], "B", "A")})
	var bad_order: Dictionary = _reaction(restore["state"], "REORDER_REACTIONS", "bad-order",
		{"actor_order": ["A", "A", "B"]})
	_expect("M3_2_INVALID_REORDER_ATOMIC", _atomic(bad_order,
		restore["state"], "INVALID_REORDER"))
	var rearranged: Dictionary = _reaction(restore["state"], "REORDER_REACTIONS", "sort",
		{"actor_order": ["A", "B", "C"]})
	_expect("M3_2_USER_ORDER_NOT_SPEED", rearranged["accepted"]
		and Queue.preview(rearranged["state"], config["reaction_definitions"])["draft_actor_order"] == ["A", "B", "C"])

	# Confirm is the only spend point. A cancels pending EnemyAction;
	# B's dependent defence skips WITHOUT MP/RP/card loss; C's explicitly
	# independent support still executes. These are fixture-only effects.
	var before_confirm: Dictionary = rearranged["state"]
	var confirm: Dictionary = _reaction(before_confirm, "CONFIRM_REACTIONS", "confirm")
	var committed: Dictionary = confirm["state"]
	var events: Array = confirm["events"]
	_expect("M3_2_CONFIRM_CLOSES_WINDOW", confirm["accepted"]
		and committed["reaction_window"]["status"] == "CLOSED"
		and committed["reaction_window"]["closure_reason"] == "CONFIRMED_AND_RESOLVED")
	_expect("M3_2_PRE3_R04_JIT_SKIP", _index(events, "ReactionSkipped") >= 0
		and events[_index(events, "ReactionSkipped")]["details"]["actor_id"] == "B"
		and events[_index(events, "ReactionSkipped")]["details"]["reason"] == "TRIGGER_GONE")
	_expect("M3_2_ONLY_EXECUTED_ACTORS_COUNT", committed["reaction_window"]["executed_actor_ids"] == ["A", "C"])
	_expect("M3_2_ONLY_TWO_REAL_SPENDS", committed["core"]["battle"]["party_resources"]["rp"] == 4
		and committed["core"]["battle"]["actors"]["A"]["mp"] == 6
		and committed["core"]["battle"]["actors"]["B"]["mp"] == 8
		and committed["core"]["battle"]["actors"]["C"]["mp"] == 7)
	_expect("M3_2_ONLY_TWO_CARDS_DISCARDED", committed["core"]["cards"]["actors"]["A"]["zones"]["discard"].size() == 1
		and committed["core"]["cards"]["actors"]["B"]["zones"]["discard"].is_empty()
		and committed["core"]["cards"]["actors"]["C"]["zones"]["discard"].size() == 1
		and Zones.validate_state(committed["core"]["cards"]))
	_expect("M3_2_ORDER_CONFIRM_PAY_EXECUTE_SKIP", _index(events, "ReactionConfirmed") <
		_index(events, "ReactionResourcesCommitted")
		and _index(events, "ReactionResourcesCommitted") < _index(events, "ReactionExecuted")
		and _index(events, "ReactionExecuted") < _index(events, "ReactionSkipped")
		and _index(events, "ReactionSkipped") < _index(events, "ReactionWindowClosed"))
	_expect("M3_2_NO_PRECONFIRM_CORE_TRANSACTION", Model.state_hash(before_confirm["core"]) ==
		Model.state_hash(opened_state["core"]))
	_expect("M3_2_AFTER_CONFIRM_REJECTS_EDITS", _atomic(
		_reaction(committed, "REMOVE_REACTION", "late-remove", {"actor_id": "C"}),
		committed, "REACTION_WINDOW_CLOSED"))
	_expect("M3_2_DOUBLE_CONFIRM_ATOMIC", _atomic(
		_reaction(committed, "CONFIRM_REACTIONS", "twice"), committed,
		"REACTION_WINDOW_CLOSED"))
	_expect("M3_2_DUPLICATE_COMMAND", _atomic(
		_reaction(committed, "CONFIRM_REACTIONS", "confirm"), committed,
		"DUPLICATE_COMMAND"))
	var closed_action: Dictionary = _do(committed, "COMPLETE_ENEMY_ACTION_FIXTURE",
		"boss1-finish", {"enemy_action_id": active_id})
	_expect("M3_2_ACTION_COMPLETION_AFTER_WINDOW", closed_action["accepted"]
		and closed_action["state"]["reaction_window"].is_empty()
		and closed_action["state"]["enemy_cursor"] == 1)
	_expect("M3_2_PRIOR_CANCEL_IS_FIXTURE_ONLY", closed_action["state"]["core"]["battle"]["actors"]["A"]["hp"] == 100)
	_expect("M3_2_EXPIRED_WINDOW_AFTER_ACTION", _atomic(
		_do(closed_action["state"], "CONFIRM_REACTIONS", "stale-window",
			{"window_id": opened_state["reaction_window"]["window_id"]}),
		closed_action["state"], "NO_DECLARED_ENEMY_ACTION"))

	# A second independent EnemyAction receives its OWN window; RP pool
	# remains shared across both windows and is not replenished.
	var declared2: Dictionary = _do(closed_action["state"], "DECLARE_NEXT_ENEMY_ACTION", "declare2")
	var a2: String = str(declared2["state"]["active_enemy_action_id"])
	var opened2: Dictionary = _do(declared2["state"], "OPEN_REACTION_WINDOW", "open2",
		{"enemy_action_id": a2})
	_expect("M3_2_WINDOW_IDS_NONREUSED", opened2["accepted"]
		and opened2["state"]["reaction_window"]["window_id"] != opened_state["reaction_window"]["window_id"])
	var second_q: Dictionary = _reaction(opened2["state"], "QUEUE_REACTION", "q2-b",
		{"entry": _entry(opened2["state"], "B", "A")})
	var second_paid: Dictionary = _reaction(second_q["state"], "CONFIRM_REACTIONS", "confirm2")
	_expect("M3_2_RP_PERSISTS_BETWEEN_WINDOWS", second_paid["accepted"]
		and second_paid["state"]["core"]["battle"]["party_resources"]["rp"] == 2
		and second_paid["state"]["core"]["battle"]["actors"]["B"]["mp"] == 7)
	var finished2: Dictionary = _do(second_paid["state"], "COMPLETE_ENEMY_ACTION_FIXTURE", "finish2",
		{"enemy_action_id": a2})
	var enemy_end: Dictionary = _do(finished2["state"], "END_ENEMY_PHASE", "enemy-end")
	_expect("M3_2_RP_EXPIRES_AT_PHASE_END", enemy_end["accepted"]
		and enemy_end["state"]["core"]["battle"]["party_resources"]["rp"] == 0)

	# Explicit Pass and canceled drafting require no cost, even after a
	# preview and simulated 120s elapsed (no timers exist in this domain).
	var passed: Dictionary = _reaction(opened_state, "PASS_REACTION", "player-pass")
	_expect("M3_2_PASS_NO_COST_OR_CARD", passed["accepted"]
		and passed["state"]["reaction_window"]["status"] == "CLOSED"
		and Model.state_hash(passed["state"]["core"]) == Model.state_hash(opened_state["core"]))
	_expect("M3_2_PASS_EXPLICIT_ONLY", _index(passed["events"], "ReactionPassed") >= 0)
	_expect("M3_2_NO_AUTO_PASS_WITH_ELAPSED_DATA", Queue.preview(opened_state,
		config["reaction_definitions"])["ok"] and opened_state["reaction_window"]["status"] == "DRAFTING")

	# Eligibility negative conditions: identity, hand, trigger, phase,
	# action-only scope, no RP, no MP and excluded statuses.
	var action1: Dictionary = opened_state["enemy_actions"][0]
	var catalogue: Dictionary = config["reaction_definitions"]
	_expect("M3_2_WRONG_ACTOR_CARD", Eligibility.check(opened_state["core"], action1,
		{"kind": "REACTION_SP_FIXTURE", "actor_id": "B",
			"card_instance_id": _card(opened_state, "A"), "target_actor_id": "A"}, catalogue)["error"] == "CARD_NOT_IN_OWN_HAND")
	_expect("M3_2_INVALID_TARGET", Eligibility.check(opened_state["core"], action1,
		_entry(opened_state, "B", "C"), catalogue)["error"] == "REACTION_TARGET_MISMATCH")
	var down: Dictionary = opened_state["core"].duplicate(true)
	down["battle"]["actors"]["B"]["hp"] = 0
	down["battle"]["actors"]["B"]["status"] = "INCAPACITATED"
	_expect("M3_2_INCAPACITATED_INVALID", Eligibility.check(down, action1,
		_entry(opened_state, "B", "A"), catalogue)["error"] == "ACTOR_UNAVAILABLE")
	var exhaust: Dictionary = opened_state["core"].duplicate(true)
	exhaust["battle"]["actors"]["B"]["status"] = "EXHAUSTED"
	_expect("M3_2_EXHAUSTED_INVALID", Eligibility.check(exhaust, action1,
		_entry(opened_state, "B", "A"), catalogue)["error"] == "ACTOR_UNAVAILABLE")
	var concentrating: Dictionary = opened_state["core"].duplicate(true)
	concentrating["battle"]["actors"]["B"]["status"] = "CONCENTRATING"
	_expect("M3_2_CONCENTRATION_FAIL_CLOSED", Eligibility.check(concentrating, action1,
		_entry(opened_state, "B", "A"), catalogue)["error"] == "CONCENTRATING_UNSUPPORTED_M4")
	var drained: Dictionary = opened_state["core"].duplicate(true)
	drained["battle"]["party_resources"]["rp"] = 0
	_expect("M3_2_INSUFFICIENT_RP", Eligibility.check(drained, action1,
		_entry(opened_state, "B", "A"), catalogue)["error"] == "INSUFFICIENT_RP")
	var no_mp: Dictionary = opened_state["core"].duplicate(true)
	no_mp["battle"]["actors"]["B"]["mp"] = 0
	_expect("M3_2_INSUFFICIENT_MP", Eligibility.check(no_mp, action1,
		_entry(opened_state, "B", "A"), catalogue)["error"] == "INSUFFICIENT_MP")
	_expect("M3_2_GUARD_PROTECT_NOT_FALSELY_IMPLEMENTED", Eligibility.check(opened_state["core"], action1,
		{"kind": "GUARD", "actor_id": "A", "target_actor_id": "A"}, catalogue)["error"] == "FEATURE_NOT_IMPLEMENTED_M3_3")

	var low_rp: Dictionary = opened_state.duplicate(true)
	low_rp["core"]["battle"]["party_resources"]["rp"] = 2
	var qlow1: Dictionary = _reaction(low_rp, "QUEUE_REACTION", "low-a",
		{"entry": _entry(low_rp, "A", "A")})
	var qlow2: Dictionary = _reaction(qlow1["state"], "QUEUE_REACTION", "low-b",
		{"entry": _entry(qlow1["state"], "B", "A")})
	var insufficient: Dictionary = _reaction(qlow2["state"], "CONFIRM_REACTIONS", "low-confirm")
	_expect("M3_2_CONFIRM_REJECTS_KNOWN_BUDGET_DEFICIT", _atomic(insufficient,
		qlow2["state"], "INSUFFICIENT_RP_DRAFT"))
	_expect("M3_2_NO_FAKE_RESOURCE_PAYMENT", qlow2["state"]["core"]["battle"]["party_resources"]["rp"] == 2)
	var empty: Dictionary = pending.duplicate(true)
	empty["core"]["battle"]["party_resources"]["rp"] = 0
	var skipped: Dictionary = _do(empty, "OPEN_REACTION_WINDOW", "empty-open",
		{"enemy_action_id": active_id})
	_expect("M3_2_NO_LEGAL_OPTIONS_EMPTY_WINDOW", skipped["accepted"]
		and skipped["state"]["reaction_window"]["status"] == "CLOSED"
		and _index(skipped["events"], "ReactionWindowEmptySkipped") >= 0
		and skipped["state"]["core"]["battle"]["party_resources"]["rp"] == 0)

	# Deterministic replay for the full independently-queued collaboration.
	var tape: Array[Dictionary] = []
	var progress: Dictionary = initial
	var steps: Array = [
		{"kind": "END_PLAYER_PHASE", "extra": {}},
		{"kind": "DECLARE_NEXT_ENEMY_ACTION", "extra": {}},
		{"kind": "OPEN_REACTION_WINDOW", "extra": {"enemy_action_id": active_id}},
		{"kind": "QUEUE_REACTION", "extra": {"entry": _entry(opened_state, "A", "A")}},
		{"kind": "QUEUE_REACTION", "extra": {"entry": _entry(opened_state, "B", "A")}},
		{"kind": "QUEUE_REACTION", "extra": {"entry": _entry(opened_state, "C", "C")}},
		{"kind": "CONFIRM_REACTIONS", "extra": {}}
	]
	for i: int in range(steps.size()):
		var kind: String = str(steps[i]["kind"])
		var extra: Dictionary = steps[i]["extra"].duplicate(true)
		if ["QUEUE_REACTION", "CONFIRM_REACTIONS"].has(kind):
			extra["window_id"] = str(progress["reaction_window"]["window_id"])
		var cmd: Dictionary = _cmd(progress, kind, "tape-" + str(i), extra)
		tape.append(cmd)
		var result: Dictionary = Phase.apply(progress, cmd, config)
		if not result["accepted"]:
			printerr("FAIL M3_2_TAPE_SETUP ", kind, " ", result["error"])
			quit(1)
			return
		progress = result["state"]
	var replay1: Dictionary = Phase.replay(initial, tape, config)
	var replay2: Dictionary = Phase.replay(initial, tape, config)
	_expect("M3_2_SEEDED_QUEUE_REPLAY", replay1["accepted"] and replay2["accepted"]
		and replay1["state_hash"] == replay2["state_hash"]
		and replay1["event_hash"] == replay2["event_hash"]
		and replay1["state_hash"] == Model.state_hash(progress))
	_expect("M3_2_REPLAY_NO_INITIAL_MUTATION", Model.state_hash(initial) == base_hash)
	_expect("M3_2_REPLAY_CARD_CONSERVATION", Zones.validate_state(replay1["state"]["core"]["cards"]))
	_expect("M3_2_REPLAY_EVENT_SEQUENCING", _sequence_ok(replay1["state"]))
	var bad_tape: Array[Dictionary] = tape.duplicate(true)
	bad_tape.append(tape[0].duplicate(true))
	var decline: Dictionary = Phase.replay(initial, bad_tape, config)
	_expect("M3_2_REPLAY_STALE_DUPLICATE_ATOMIC", not decline["accepted"]
		and decline["error"] == "DUPLICATE_COMMAND"
		and decline["state_hash"] == replay1["state_hash"])
	print("M3_2_REPLAY seed=", SEED, " initial=", base_hash,
		" events=", replay1["event_hash"], " final=", replay1["state_hash"])
	print("M3_2_TEST_REPORT executed=", pass_count + fail_count,
		" passed=", pass_count, " failed=", fail_count)
	if fail_count == 0:
		print("M3_2_REACTION_QUEUE_DOMAIN_VERIFIED")
	quit(0 if fail_count == 0 else 1)

func _sequence_ok(state: Dictionary) -> bool:
	if int(state["event_seq"]) != state["events"].size():
		return false
	for i: int in range(state["events"].size()):
		if int(state["events"][i]["event_seq"]) != i + 1:
			return false
	return true
