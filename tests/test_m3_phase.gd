extends SceneTree
## M3.1 headless Phase Engine: P1-D01, PRE3-R09, CORE-01, M-D08/09,
## actual M2 payment/swap/hand refill and deterministic EnemyAction IDs.
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const Draw = preload("res://scripts/domain/m2/cards/draw_resolver.gd")
const Zones = preload("res://scripts/domain/m2/cards/card_zone_resolver.gd")
const M2 = preload("res://scripts/domain/m2/integration/m2_domain_resolver.gd")
const PhaseEngine = preload("res://scripts/domain/m3/phase/phase_engine.gd")
const Scheduler = preload("res://scripts/domain/m3/enemy/enemy_action_scheduler.gd")
const Boundary = preload("res://scripts/domain/m3/phase/phase_boundary_resolver.gd")
const SEED: int = 20261014
var passed: int = 0
var failed: int = 0
var config: Dictionary = {}

func _expect(id: String, ok: bool) -> void:
	if ok:
		passed += 1
		print("PASS ", id)
	else:
		failed += 1
		printerr("FAIL ", id)

func _core(seed: int = SEED) -> Dictionary:
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
	var cards_created: Dictionary = Draw.start_battle(loadouts, contexts,
		{"burst": {"id": "burst", "kind": "SP"}}, owned, seed)
	if not cards_created["accepted"]:
		return {}
	var battle: Dictionary = Model.make_state(["A", "B", "C"], ["Boss", "Minion"], seed)
	for ally: String in ["A", "B", "C"]:
		battle["actors"][ally]["mp"] = 8
		battle["actors"][ally]["max_mp"] = 12
	return M2.make_state(battle, cards_created["state"])

func _intents() -> Array:
	return [
		{"intent_id": "z", "enemy_id": "Boss", "action_order": 20,
			"created_seq": 9, "publicly_declared": true, "target_scope": "SINGLE"},
		{"intent_id": "a", "enemy_id": "Minion", "action_order": 10,
			"created_seq": 7, "publicly_declared": true, "target_scope": "SINGLE"},
		{"intent_id": "b", "enemy_id": "Boss", "action_order": 10,
			"created_seq": 1, "publicly_declared": true, "target_scope": "MULTI"}
	]

func _state(intents: Array = [], hooks: Array = [], seed: int = SEED) -> Dictionary:
	return PhaseEngine.make_state(_core(seed), intents, hooks)

func _cmd(s: Dictionary, kind: String, id: String, params: Dictionary = {}) -> Dictionary:
	var instruction: Dictionary = {"type": kind, "command_id": id,
		"expected_event_seq": int(s["event_seq"])}
	for key: Variant in params:
		instruction[key] = params[key]
	return instruction

func _apply(s: Dictionary, kind: String, id: String, params: Dictionary = {}) -> Dictionary:
	return PhaseEngine.apply(s, _cmd(s, kind, id, params), config)

func _hand(s: Dictionary, actor: String) -> Array:
	return s["core"]["cards"]["actors"][actor]["zones"]["hand"]

func _cost(s: Dictionary, actor: String, mode: String = "CHANTLESS") -> Dictionary:
	return {"actor_id": actor, "card_instance_id": str(_hand(s, actor)[0]),
		"casting_mode": mode}

func _reject_unchanged(result: Dictionary, initial: Dictionary, why: String) -> bool:
	return (not result["accepted"] and str(result["error"]) == why
		and result["events"].is_empty()
		and Model.state_hash(result["state"]) == Model.state_hash(initial))

func _index(events: Array, kind: String) -> int:
	for i: int in range(events.size()):
		if str(events[i]["kind"]) == kind:
			return i
	return -1

func _init() -> void:
	var c: Variant = JSON.parse_string(FileAccess.get_file_as_string(
		"res://resources/combat/rulesets/m2_2_provisional_costs.json"))
	var r: Variant = JSON.parse_string(FileAccess.get_file_as_string(
		"res://resources/combat/rulesets/m2_1_provisional_resources.json"))
	if not c is Dictionary or not r is Dictionary:
		printerr("M3_1_CONFIG_MISSING")
		quit(1)
		return
	var res: Dictionary = c.duplicate(true)
	res["basic_attack_ap_cost"] = int(r["basic_attack_ap_cost"])
	res["basic_attack_mp_gain"] = int(r["basic_attack_mp_gain"])
	config = {"costs": c, "resources": res,
		"definitions": {"burst": {"card_id": "burst", "ap_cost": 1, "mp_cost": 1}},
		"trigger_rules": []}
	var state: Dictionary = _state(_intents())
	if not PhaseEngine.validate_state(state):
		printerr("M3_1_SETUP_FAILED")
		quit(1)
		return
	var seed_initial: String = Model.state_hash(state)
	_expect("M3_1_INITIAL_PHASE", state["phase"] == "PLAYER_PHASE"
		and state["core"]["battle"]["party_resources"]["current_ap"] == 6)
	_expect("M3_1_ACTUAL_36_CARDS", Zones.validate_state(state["core"]["cards"]))
	_expect("M3_1_NO_PREDECLARED_ENEMY_ACTION", state["enemy_actions"].is_empty())
	var plan: Dictionary = Scheduler.plan(_intents(), state["core"]["battle"]["enemies"], 1)
	_expect("M3_1_ACTION_ORDER_STABLE", plan["ok"]
		and plan["actions"].map(func(a: Dictionary) -> String: return str(a["intent_id"])) == ["b", "a", "z"])
	_expect("M3_1_ACTION_IDS_ROUND_SCOPED", str(plan["actions"][0]["enemy_action_id"]) ==
		"round:1:intent:b" and str(plan["actions"][1]["enemy_action_id"]) ==
		"round:1:intent:a")
	var invisible: Array = _intents()
	invisible[0]["publicly_declared"] = false
	_expect("M3_1_NO_HIDDEN_INTENT", not Scheduler.plan(invisible,
		state["core"]["battle"]["enemies"], 1)["ok"])
	var duplicate: Array = _intents()
	duplicate[0]["intent_id"] = "a"
	_expect("M3_1_DUPLICATE_INTENT_REJECT", not Scheduler.plan(duplicate,
		state["core"]["battle"]["enemies"], 1)["ok"])
	var wrong_enemy: Array = _intents()
	wrong_enemy[0]["enemy_id"] = "Unknown"
	_expect("M3_1_ENEMY_OWNERSHIP_REJECT", not Scheduler.plan(wrong_enemy,
		state["core"]["battle"]["enemies"], 1)["ok"])
	var next_round_plan: Dictionary = Scheduler.plan(_intents(),
		state["core"]["battle"]["enemies"], 2)
	_expect("M3_1_NEW_ROUND_NEW_IDS", next_round_plan["ok"]
		and next_round_plan["actions"][0]["enemy_action_id"] == "round:2:intent:b")

	# The player explicitly chooses one legal action, immediately resolves
	# it and can choose the SAME actor again. No party-wide prequeue.
	var tape: Array[Dictionary] = []
	var current: Dictionary = state
	var order: Array = []
	for i: int in range(4):
		var actor_id: String = ["A", "A", "B", "A"][i]
		var cmd: Dictionary = _cmd(current, "COMMIT_SP_CARD_FIXTURE",
			"sp-" + str(i), _cost(current, actor_id))
		tape.append(cmd)
		var result: Dictionary = PhaseEngine.apply(current, cmd, config)
		if not result["accepted"]:
			printerr("M3_1_PLAYER_FIXTURE_FAIL ", result["error"])
			quit(1)
			return
		current = result["state"]
		order.append(str(result["events"][_index(result["events"], "PlayerActionSettled")]["details"]["actor_id"]))
	_expect("M3_1_P1_D01_AABA", order == ["A", "A", "B", "A"])
	_expect("M3_1_PLAYER_ACTIONS_IMMEDIATE", current["phase"] == "PLAYER_PHASE"
		and current["core"]["battle"]["party_resources"]["current_ap"] == 2
		and current["core"]["battle"]["actors"]["A"]["mp"] == 5
		and current["core"]["battle"]["actors"]["B"]["mp"] == 7
		and _hand(current, "A").size() == 1 and _hand(current, "B").size() == 3)
	_expect("M3_1_NO_AUTOMATIC_END", current["phase"] == "PLAYER_PHASE"
		and current["enemy_actions"].is_empty())
	_expect("M3_1_SEED_INPUT_IMMUTABLE", Model.state_hash(state) == seed_initial)

	var stale: Dictionary = _cmd(current, "COMMIT_SP_CARD_FIXTURE", "stale", _cost(current, "A"))
	stale["expected_event_seq"] = int(state["event_seq"])
	_expect("M3_1_STALE_NO_MUTATION", _reject_unchanged(PhaseEngine.apply(current, stale, config),
		current, "STALE_STATE"))
	var repeated: Dictionary = _cmd(current, "COMMIT_SP_CARD_FIXTURE", "sp-0", _cost(current, "A"))
	_expect("M3_1_DUPLICATE_NO_MUTATION", _reject_unchanged(PhaseEngine.apply(current, repeated, config),
		current, "DUPLICATE_COMMAND"))
	_expect("M3_1_ILLEGAL_OWNER_NO_PAYMENT", _reject_unchanged(
		_apply(current, "COMMIT_SP_CARD_FIXTURE", "wrong-owner",
			{"actor_id": "B", "card_instance_id": str(_hand(current, "A")[0])}),
		current, "CARD_NOT_IN_OWN_HAND"))
	var exhausted: Dictionary = current.duplicate(true)
	exhausted["core"]["battle"]["actors"]["A"]["hp"] = 0
	exhausted["core"]["battle"]["actors"]["A"]["status"] = "INCAPACITATED"
	_expect("M3_1_INCAPACITATED_CANNOT_ACT", _reject_unchanged(
		_apply(exhausted, "COMMIT_SP_CARD_FIXTURE", "incap", _cost(exhausted, "A")),
		exhausted, "ACTOR_UNAVAILABLE_OR_PHASE"))

	var ended_command: Dictionary = _cmd(current, "END_PLAYER_PHASE", "end-player")
	tape.append(ended_command)
	var ended: Dictionary = PhaseEngine.apply(current, ended_command, config)
	if not ended["accepted"]:
		printerr("M3_1_END_PHASE_FAILED ", ended["error"])
		quit(1)
		return
	var enemy: Dictionary = ended["state"]
	_expect("M3_1_END_PLAYER_AP_TO_RP", enemy["phase"] == "ENEMY_PHASE"
		and enemy["core"]["battle"]["party_resources"]["current_ap"] == 0
		and enemy["core"]["battle"]["party_resources"]["rp"] == 2)
	_expect("M3_1_END_BOUNDARY_BEFORE_ENEMY", _index(ended["events"], "BattleOutcomeEvaluated") >= 0
		and _index(ended["events"], "PlayerResourcesClosed") > _index(ended["events"], "BattleOutcomeEvaluated")
		and _index(ended["events"], "EnemyActionsScheduled") > _index(ended["events"], "PlayerResourcesClosed"))
	_expect("M3_1_END_NEEDS_USER_COMMAND", _reject_unchanged(
		_apply(enemy, "END_PLAYER_PHASE", "double-end"), enemy, "INVALID_PHASE"))
	_expect("M3_1_ENEMY_PENDING_BLOCKS_END", _reject_unchanged(
		_apply(enemy, "END_ENEMY_PHASE", "early-end"), enemy, "PENDING_ENEMY_ACTIONS"))
	_expect("M3_1_ENEMY_CANNOT_PLAY_CARD", _reject_unchanged(
		_apply(enemy, "COMMIT_SP_CARD_FIXTURE", "enemy-sp", _cost(enemy, "A")),
		enemy, "INVALID_PHASE"))

	# Enemy intent is a stable declared snapshot. M3.1 only exposes and
	# resolves no-damage fixtures; M3.2 will attach Reaction windows.
	for i: int in range(3):
		var dc: Dictionary = _cmd(enemy, "DECLARE_NEXT_ENEMY_ACTION", "declare-" + str(i))
		tape.append(dc)
		var declared: Dictionary = PhaseEngine.apply(enemy, dc, config)
		if not declared["accepted"]:
			printerr("M3_1_DECLARE_FAILED ", declared["error"])
			quit(1)
			return
		enemy = declared["state"]
		var action_id: String = str(enemy["active_enemy_action_id"])
		_expect("M3_1_DECLARED_" + str(i), action_id == "round:1:intent:" + ["b", "a", "z"][i])
		_expect("M3_1_DOUBLE_DECLARE_" + str(i), _reject_unchanged(
			_apply(enemy, "DECLARE_NEXT_ENEMY_ACTION", "declare-conflict-" + str(i)),
			enemy, "ENEMY_ACTION_ALREADY_ACTIVE"))
		_expect("M3_1_WRONG_ENEMY_ID_" + str(i), _reject_unchanged(
			_apply(enemy, "COMPLETE_ENEMY_ACTION_FIXTURE", "bad-complete-" + str(i),
				{"enemy_action_id": "round:1:intent:wrong"}), enemy, "STALE_ENEMY_ACTION_ID"))
		var cc: Dictionary = _cmd(enemy, "COMPLETE_ENEMY_ACTION_FIXTURE",
			"finish-" + str(i), {"enemy_action_id": action_id})
		tape.append(cc)
		var closed: Dictionary = PhaseEngine.apply(enemy, cc, config)
		if not closed["accepted"]:
			printerr("M3_1_COMPLETE_FAILED ", closed["error"])
			quit(1)
			return
		enemy = closed["state"]
		_expect("M3_1_ENEMY_FIXTURE_NO_DAMAGE_" + str(i),
			int(enemy["core"]["battle"]["actors"]["A"]["hp"]) == 100
			and enemy["active_enemy_action_id"] == "")
	_expect("M3_1_ALL_ENEMY_ACTIONS_CONSUMED", int(enemy["enemy_cursor"]) == 3)
	_expect("M3_1_NO_REDECLARATION", _reject_unchanged(
		_apply(enemy, "DECLARE_NEXT_ENEMY_ACTION", "too-many"), enemy, "NO_PENDING_ENEMY_ACTION"))
	var ee: Dictionary = _cmd(enemy, "END_ENEMY_PHASE", "enemy-end")
	tape.append(ee)
	var expired: Dictionary = PhaseEngine.apply(enemy, ee, config)
	if not expired["accepted"]:
		printerr("M3_1_EXPIRE_FAILED ", expired["error"])
		quit(1)
		return
	var awaiting: Dictionary = expired["state"]
	_expect("M3_1_RP_EXPIRES_AT_ENEMY_END", awaiting["phase"] == "AWAITING_PLAYER_START"
		and awaiting["core"]["battle"]["party_resources"]["rp"] == 0)
	_expect("M3_1_NO_PLAYER_ACTION_WHILE_AWAITING", _reject_unchanged(
		_apply(awaiting, "COMMIT_SP_CARD_FIXTURE", "awaiting-action", _cost(awaiting, "A")),
		awaiting, "INVALID_PHASE"))
	var sc: Dictionary = _cmd(awaiting, "START_PLAYER_PHASE", "round-two-start")
	tape.append(sc)
	var opened: Dictionary = PhaseEngine.apply(awaiting, sc, config)
	if not opened["accepted"]:
		printerr("M3_1_OPEN_FAILED ", opened["error"])
		quit(1)
		return
	var round_two: Dictionary = opened["state"]
	_expect("M3_1_PHASE_TWO_RESOURCES", round_two["phase"] == "PLAYER_PHASE"
		and int(round_two["core"]["battle"]["round"]) == 2
		and int(round_two["core"]["battle"]["party_resources"]["current_ap"]) == 6)
	_expect("M3_1_PHASE_TWO_HAND_REFILL", _hand(round_two, "A").size() == 4
		and _hand(round_two, "B").size() == 4
		and Zones.validate_state(round_two["core"]["cards"]))
	_expect("M3_1_PHASE_TWO_ORDERED_EVENTS", _index(opened["events"], "BattleOutcomeEvaluated") >= 0
		and _index(opened["events"], "PlayerResourcesOpened") > _index(opened["events"], "BattleOutcomeEvaluated")
		and _index(opened["events"], "CardDrawn") > _index(opened["events"], "PlayerResourcesOpened"))
	_expect("M3_1_FREE_SWAP_QUOTA_RENEWED", not round_two["core"]["cards"]["swap_used_by_actor"]["A"])
	_expect("M3_1_PHASE_REPLAY_CARD_RNG_PRESERVED", Zones.validate_state(round_two["core"]["cards"]))

	var repeated_run: Dictionary = PhaseEngine.replay(state, tape, config)
	var other_run: Dictionary = PhaseEngine.replay(state, tape, config)
	_expect("M3_1_SEEDED_FULL_PHASE_REPLAY", repeated_run["accepted"]
		and other_run["accepted"] and repeated_run["state_hash"] == other_run["state_hash"]
		and repeated_run["event_hash"] == other_run["event_hash"]
		and repeated_run["state_hash"] == Model.state_hash(round_two))
	_expect("M3_1_REPLAY_EVENT_SEQUENCE", _events_ordered(round_two)
		and round_two["event_seq"] == repeated_run["events"].size())
	var poisoned: Array[Dictionary] = tape.duplicate(true)
	poisoned.append(tape[0].duplicate(true))
	var stopped: Dictionary = PhaseEngine.replay(state, poisoned, config)
	_expect("M3_1_REPLAY_DUPLICATE_STOPS", not stopped["accepted"]
		and stopped["error"] == "DUPLICATE_COMMAND"
		and stopped["state_hash"] == Model.state_hash(round_two))

	# At 0 AP neither forced phase end nor forbidden zero-cost Free Swap.
	var zero_ap: Dictionary = state.duplicate(true)
	zero_ap["core"]["battle"]["party_resources"]["current_ap"] = 0
	var first_swap: Dictionary = _apply(zero_ap, "FREE_SWAP", "zero-swap",
		{"actor_id": "A", "card_instance_id": str(_hand(zero_ap, "A")[0])})
	_expect("M3_1_ZERO_AP_SWAP_STILL_LEGAL", first_swap["accepted"]
		and first_swap["state"]["phase"] == "PLAYER_PHASE"
		and int(first_swap["state"]["core"]["battle"]["party_resources"]["current_ap"]) == 0)
	_expect("M3_1_ZERO_AP_STILL_NO_AUTOPHASE", _reject_unchanged(
		_apply(zero_ap, "COMMIT_SP_CARD_FIXTURE", "sp-at-zero", _cost(zero_ap, "A")),
		zero_ap, "INSUFFICIENT_AP"))
	_expect("M3_1_ZERO_AP_CAN_END_EXPLICITLY",
		_apply(first_swap["state"], "END_PLAYER_PHASE", "zero-end")["accepted"])

	# Existing M2.1 basic attack policy. First successful per actor restores
	# fixture MP, later attacks do not; no new action-count limit.
	var basic_start: Dictionary = state.duplicate(true)
	basic_start["core"]["battle"]["actors"]["A"]["mp"] = 5
	var basic1: Dictionary = _apply(basic_start, "BASIC_ATTACK_RESOURCE_ONLY", "basic-1", {"actor_id": "A"})
	var basic2: Dictionary = _apply(basic1["state"], "BASIC_ATTACK_RESOURCE_ONLY", "basic-2", {"actor_id": "A"})
	var basic3: Dictionary = _apply(basic2["state"], "BASIC_ATTACK_RESOURCE_ONLY", "basic-3", {"actor_id": "B"})
	_expect("M3_1_FIRST_BASIC_MP_ONLY", basic1["accepted"] and basic2["accepted"]
		and basic1["state"]["core"]["battle"]["actors"]["A"]["mp"] == 7
		and basic2["state"]["core"]["battle"]["actors"]["A"]["mp"] == 7)
	_expect("M3_1_B_ACTS_AFTER_A", basic3["accepted"]
		and basic3["state"]["core"]["battle"]["party_resources"]["current_ap"] == 3)

	# PRE3-R09 fail closed on unresolved Casting. Explicitly marked TEST
	# hooks may move the physical instance to Discard, never deal damage.
	var solo: Dictionary = _state()
	var full_id: String = str(_hand(solo, "A")[0])
	var full: Dictionary = _apply(solo, "COMMIT_SP_CARD_FIXTURE", "full-setup", _cost(solo, "A", "FULL"))
	var full_end: Dictionary = _apply(full["state"], "END_PLAYER_PHASE", "full-end")
	var full_enemy: Dictionary = _apply(full_end["state"], "END_ENEMY_PHASE", "full-enemy-end")
	_expect("M3_1_CASTING_NOT_SILENTLY_RESOLVED", _reject_unchanged(
		_apply(full_enemy["state"], "START_PLAYER_PHASE", "no-cast-hook"),
		full_enemy["state"], "UNRESOLVED_CASTING_ZONE"))
	var hooks: Array = [
		{"hook_id": "status-high", "kind": "STATUS_FIXTURE", "execute_round": 2,
			"priority": 5, "created_seq": 3, "fixture_only": true},
		{"hook_id": "casting-complete", "kind": "CASTING_FIXTURE", "execute_round": 2,
			"priority": 0, "created_seq": 1, "fixture_only": true,
			"actor_id": "A", "card_instance_id": full_id},
		{"hook_id": "status-low", "kind": "STATUS_FIXTURE", "execute_round": 2,
			"priority": 1, "created_seq": 2, "fixture_only": true}
	]
	var timed: Dictionary = PhaseEngine.make_state(_core(), [], hooks)
	var tf: Dictionary = _apply(timed, "COMMIT_SP_CARD_FIXTURE", "tf", _cost(timed, "A", "FULL"))
	var te: Dictionary = _apply(tf["state"], "END_PLAYER_PHASE", "te")
	var tx: Dictionary = _apply(te["state"], "END_ENEMY_PHASE", "tx")
	var boundary: Dictionary = _apply(tx["state"], "START_PLAYER_PHASE", "tb")
	var b_events: Array = boundary.get("events", [])
	_expect("M3_1_PRE3_R09_CASTING_FIXTURE_FIRST", boundary["accepted"]
		and _index(b_events, "BoundaryHookFixtureResolved") >= 0
		and _index(b_events, "BattleOutcomeEvaluated") > _index(b_events, "BoundaryHookFixtureResolved")
		and _index(b_events, "PlayerResourcesOpened") > _index(b_events, "BattleOutcomeEvaluated")
		and boundary["state"]["core"]["cards"]["actors"]["A"]["zones"]["casting"].is_empty())
	var resolved_ids: Array = []
	for item: Dictionary in b_events:
		if str(item["kind"]) == "BoundaryHookFixtureResolved":
			resolved_ids.append(str(item["details"]["hook_id"]))
	_expect("M3_1_PRE3_R09_STABLE_FIXTURE_ORDER", resolved_ids ==
		["casting-complete", "status-low", "status-high"])
	_expect("M3_1_UNRESOLVED_REAL_CASTING_BLOCKED",
		Boundary.validate_hooks(hooks) and not Boundary.validate_hooks([
			{"hook_id": "bad", "kind": "CASTING_FIXTURE", "execute_round": 2,
				"priority": 0, "created_seq": 1, "fixture_only": false}]))
	var pending_real: Dictionary = full_enemy["state"].duplicate(true)
	pending_real["core"]["battle"]["statuses"] = [{"effect": "future"}]
	_expect("M3_1_REAL_STATUS_FAIL_CLOSED", _reject_unchanged(
		_apply(pending_real, "START_PLAYER_PHASE", "real-status"), pending_real,
		"UNIMPLEMENTED_REAL_TICKS"))

	# CORE-01: outcome checked BEFORE AP refresh and hand draw. Win takes
	# priority over everyone HP0. No fictitious LastSpell/casting effects.
	var terminal: Dictionary = awaiting.duplicate(true)
	for actor_id: String in ["A", "B", "C", "Boss", "Minion"]:
		terminal["core"]["battle"]["actors"][actor_id]["hp"] = 0
	var win: Dictionary = _apply(terminal, "START_PLAYER_PHASE", "terminal-win")
	_expect("M3_1_CORE_01_VICTORY_PRIORITY", win["accepted"]
		and win["state"]["core"]["battle"]["outcome"] == "VICTORY"
		and _index(win["events"], "PlayerResourcesOpened") == -1
		and int(win["state"]["core"]["battle"]["round"]) == 1)
	_expect("M3_1_TERMINAL_NO_ACTION", _reject_unchanged(
		_apply(win["state"], "START_PLAYER_PHASE", "terminal-again"),
		win["state"], "BATTLE_ENDED"))
	var defeat: Dictionary = awaiting.duplicate(true)
	for actor_id: String in ["A", "B", "C"]:
		defeat["core"]["battle"]["actors"][actor_id]["hp"] = 0
	var lost: Dictionary = _apply(defeat, "START_PLAYER_PHASE", "terminal-defeat")
	_expect("M3_1_DEFEAT_WITH_SURVIVING_BOSS", lost["accepted"]
		and lost["state"]["core"]["battle"]["outcome"] == "DEFEAT")
	_expect("M3_1_ACTUAL_RNG_STABLE", state["core"]["battle"]["rng"] ==
		round_two["core"]["battle"]["rng"])
	var different: Dictionary = _state(_intents(), [], SEED + 1)
	var other_seed: Dictionary = PhaseEngine.replay(different, tape, config)
	_expect("M3_1_DIFFERENT_SEED_REPLAY_DISTINCT", not other_seed["accepted"]
		or other_seed["state_hash"] != repeated_run["state_hash"])
	print("M3_1_REPLAY seed=", SEED, " initial=", seed_initial,
		" events=", repeated_run["event_hash"], " final=", repeated_run["state_hash"])
	print("M3_1_TEST_REPORT executed=", passed + failed, " passed=", passed,
		" failed=", failed)
	if failed == 0:
		print("M3_1_PHASE_DOMAIN_VERIFIED")
	quit(0 if failed == 0 else 1)

func _events_ordered(s: Dictionary) -> bool:
	if int(s["event_seq"]) != s["events"].size():
		return false
	for i: int in range(s["events"].size()):
		if int(s["events"][i]["event_seq"]) != i + 1:
			return false
	return true
