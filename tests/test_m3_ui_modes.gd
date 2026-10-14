extends SceneTree
## M3.4 P1-D05 / CORE-04: all modes use identical M3.3 Domain
## legality, queue, fixed fees and event hashes. No clock/FPS/UX
## setting can Confirm, Pass, spend RP or complete an EnemyAction.
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const Draw = preload("res://scripts/domain/m2/cards/draw_resolver.gd")
const Zones = preload("res://scripts/domain/m2/cards/card_zone_resolver.gd")
const M2 = preload("res://scripts/domain/m2/integration/m2_domain_resolver.gd")
const Phase = preload("res://scripts/domain/m3/phase/phase_engine.gd")
const Policy = preload("res://scripts/domain/m3/reaction/reaction_presentation_policy.gd")
const Queue = preload("res://scripts/domain/m3/reaction/reaction_queue_resolver.gd")
const Eligibility = preload("res://scripts/domain/m3/reaction/reaction_eligibility.gd")
const SEED: int = 20261014
const MODES: Array[String] = ["SMART", "ALWAYS_ASK", "QUICK"]
var passed: int = 0
var failed: int = 0
var config: Dictionary = {"reaction_definitions": {}}

func _assert(id: String, truth: bool) -> void:
	if truth:
		passed += 1
		print("PASS ", id)
	else:
		failed += 1
		printerr("FAIL ", id)

func _base() -> Dictionary:
	var loadouts: Dictionary = {}
	var contexts: Dictionary = {}
	var owned: Dictionary = {}
	for actor: String in ["A", "B", "C"]:
		var values: Array = []
		for i: int in range(12):
			values.append("ordinary")
		loadouts[actor] = values
		contexts[actor] = {"actor_id": actor, "variant_id": "default", "tags": []}
		owned[actor] = {"ordinary": 12}
	var drawn: Dictionary = Draw.start_battle(loadouts, contexts,
		{"ordinary": {"id": "ordinary", "kind": "SP"}}, owned, SEED)
	if not drawn["accepted"]:
		return {}
	var battle: Dictionary = Model.make_state(["A", "B", "C"], ["Boss"], SEED)
	for actor: String in ["A", "B", "C"]:
		battle["actors"][actor]["mp"] = 8
		battle["actors"][actor]["max_mp"] = 12
	var core: Dictionary = M2.make_state(battle, drawn["state"])
	return Phase.make_state(core, [{
		"intent_id": "sweep", "enemy_id": "Boss",
		"action_order": 1, "created_seq": 0, "publicly_declared": true,
		"target_scope": "SINGLE", "target_ids": ["A"], "hit_count": 3,
		"damage_type": "PHYSICAL", "requires_reaction_window": true
	}])

func _command(s: Dictionary, kind: String, id: String, args: Dictionary = {}) -> Dictionary:
	var d: Dictionary = {"type": kind, "command_id": id,
		"expected_event_seq": int(s["event_seq"])}
	for key: Variant in args:
		d[key] = args[key]
	return d

func _apply(s: Dictionary, kind: String, id: String, args: Dictionary = {}) -> Dictionary:
	return Phase.apply(s, _command(s, kind, id, args), config)

func _prepared() -> Dictionary:
	var initial: Dictionary = _base()
	if initial.is_empty():
		return {}
	var ended: Dictionary = _apply(initial, "END_PLAYER_PHASE", "phase-end")
	if not ended["accepted"]:
		return {}
	var declared: Dictionary = _apply(ended["state"],
		"DECLARE_NEXT_ENEMY_ACTION", "declare")
	if not declared["accepted"]:
		return {}
	var current: Dictionary = declared["state"]
	var open: Dictionary = _apply(current, "OPEN_REACTION_WINDOW", "open",
		{"enemy_action_id": current["active_enemy_action_id"]})
	return open["state"] if open["accepted"] else {}

func _guard() -> Dictionary:
	return {"kind": "BASIC_GUARD", "actor_id": "A", "target_actor_id": "A"}

func _protect() -> Dictionary:
	return {"kind": "BASIC_PROTECT", "actor_id": "B", "target_actor_id": "A"}

func _forbidden(result: Dictionary, before: Dictionary, code: String) -> bool:
	return not result["accepted"] and str(result["error"]) == code \
		and result["events"].is_empty() \
		and Model.state_hash(result["state"]) == Model.state_hash(before)

func _index(events: Array, kind: String) -> int:
	for i: int in range(events.size()):
		if str(events[i]["kind"]) == kind:
			return i
	return -1

func _all_waiting(p: Dictionary) -> bool:
	return p["ok"] and p["prompt_visible"] and p["reaction_pending"] \
		and p["requires_explicit_player_decision"] \
		and p["blocks_enemy_resolution"] and not p["may_complete_enemy_action"] \
		and p["show_persistent_affordance"] \
		and not p["auto_pass"] and not p["auto_confirm"] \
		and not p["auto_spend_rp"] and p["deadline_seconds"] == null \
		and p["timeout_seconds"] == null \
		and p["waiting_policy"] == "UNTIL_EXPLICIT_CONFIRM_OR_PASS" \
		and p["decision_commands"] == ["CONFIRM_REACTIONS", "PASS_REACTION"] \
		and p["edit_commands"] == ["QUEUE_REACTION", "REMOVE_REACTION", "REORDER_REACTIONS"]

func _no_window(p: Dictionary) -> bool:
	return p["ok"] and not p["reaction_pending"] \
		and not p["requires_explicit_player_decision"] \
		and not p["should_block_prompt"] and not p["prompt_visible"] \
		and p["decision_commands"].is_empty() and p["edit_commands"].is_empty() \
		and not p["auto_pass"] and not p["auto_confirm"] \
		and not p["auto_spend_rp"]

func _init() -> void:
	var initial: Dictionary = _base()
	var state: Dictionary = _prepared()
	if initial.is_empty() or state.is_empty() or not Phase.validate_state(state):
		printerr("M3_4_SETUP_FAILED")
		quit(1)
		return
	var before_hash: String = Model.state_hash(state)
	var baseline_rp: int = int(state["core"]["battle"]["party_resources"]["rp"])
	var baseline_card_hash: String = Model.state_hash(state["core"]["cards"])
	var action_id: String = str(state["active_enemy_action_id"])
	var window_id: String = str(state["reaction_window"]["window_id"])

	_assert("M3_4_DEFAULT_SMART", Policy.describe(state)["mode"] == "SMART")
	_assert("M3_4_INVALID_MODE_REJECTED", not Policy.describe(state, "UNKNOWN")["ok"]
		and Policy.describe(state, "UNKNOWN")["error"] == "UNKNOWN_REACTION_UI_MODE")
	_assert("M3_4_INVALID_STATE_REJECTED", not Policy.describe({}, "SMART")["ok"]
		and Policy.describe({}, "SMART")["error"] == "INVALID_PHASE_STATE")
	_assert("M3_4_GUARD_ONLY_WINDOW_REAL", state["reaction_window"]["status"] == "DRAFTING"
		and state["core"]["cards"]["actors"]["A"]["zones"]["hand"].size() == 4)
	_assert("M3_4_NO_SP_CATALOGUE_YET_GUARD_ELIGIBLE",
		Eligibility.any_basic_legal(state["core"], state["enemy_actions"][0])
		and not Eligibility.any_legal(state["core"], state["enemy_actions"][0], {}))
	var mode_outputs: Dictionary = {}
	for mode: String in MODES:
		var p: Dictionary = Policy.describe(state, mode)
		mode_outputs[mode] = p
		_assert("M3_4_" + mode + "_PENDING", _all_waiting(p))
		_assert("M3_4_" + mode + "_SAME_WINDOW", p["window_id"] == window_id
			and p["enemy_action_id"] == action_id)
		_assert("M3_4_" + mode + "_VIEW_ONLY", Model.state_hash(state) == before_hash
			and p["core_resources_changed"] == false)
		_assert("M3_4_" + mode + "_NO_AUTO_SPEND", state["core"]["battle"]["party_resources"]["rp"] == baseline_rp
			and Model.state_hash(state["core"]["cards"]) == baseline_card_hash)
		_assert("M3_4_" + mode + "_PRESENTATION_KEY", str(p["presentation_i18n_key"]).begins_with("reaction.mode."))
		_assert("M3_4_" + mode + "_CANNOT_ADVANCE", _forbidden(_apply(state,
			"COMPLETE_ENEMY_ACTION_FIXTURE", "premature-" + mode, {"enemy_action_id": action_id}),
			state, "REACTION_WINDOW_NOT_RESOLVED"))
	_assert("M3_4_SMART_UNKNOWN_SAFER_MODAL", mode_outputs["SMART"]["should_block_prompt"])
	_assert("M3_4_ALWAYS_ASK_ALWAYS_MODAL", mode_outputs["ALWAYS_ASK"]["should_block_prompt"])
	_assert("M3_4_QUICK_COMPACT_NOT_MODAL", not mode_outputs["QUICK"]["should_block_prompt"]
		and mode_outputs["QUICK"]["interaction_style"] == "COMPACT_PROMPT")
	_assert("M3_4_SMART_MINOR_QUIET_BUT_BLOCKS", not Policy.describe(state, "SMART",
		{"significance": "MINOR"})["should_block_prompt"]
		and _all_waiting(Policy.describe(state, "SMART", {"significance": "MINOR"})))
	_assert("M3_4_SMART_MAJOR_PROMINENT", Policy.describe(state, "SMART",
		{"significance": "MAJOR"})["should_block_prompt"])
	_assert("M3_4_SMART_UNKNOWN_HINT_PROMINENT", Policy.describe(state, "SMART",
		{"significance": "unverified"})["should_block_prompt"])
	_assert("M3_4_ALWAYS_ASK_IGNORES_THREAT_LEVEL", Policy.describe(state, "ALWAYS_ASK",
		{"significance": "MINOR"})["should_block_prompt"])
	_assert("M3_4_QUICK_IGNORES_THREAT_LEVEL", not Policy.describe(state, "QUICK",
		{"significance": "MAJOR"})["should_block_prompt"])
	_assert("M3_4_STYLES_DISTINCT", mode_outputs["SMART"]["interaction_style"] != mode_outputs["QUICK"]["interaction_style"]
		and mode_outputs["ALWAYS_ASK"]["interaction_style"] != mode_outputs["SMART"]["interaction_style"])

	# CORE-04: 120 seconds and arbitrarily long elapsed time are not
	# actually awaited. Simulate passed time ONLY as untrusted UI metadata.
	# No timer callback or real-time transition exists in Domain.
	for elapsed: int in [0, 120, 86400]:
		for mode: String in MODES:
			var hints: Dictionary = {"elapsed_seconds": elapsed, "timeout_seconds": 1,
				"auto_pass": true, "force_confirm": true, "fps": 240,
				"input_device": "CONTROLLER", "significance": "MINOR"}
			var waited: Dictionary = Policy.describe(state, mode, hints)
			_assert("M3_4_" + mode + "_WAIT_" + str(elapsed), _all_waiting(waited)
				and Model.state_hash(state) == before_hash)
	_assert("M3_4_NO_ACTION_ON_ELAPSED_TIME", state["reaction_window"]["status"] == "DRAFTING"
		and state["event_seq"] == _prepared()["event_seq"])
	_assert("M3_4_FPS_AND_DEVICE_NEUTRAL", Policy.describe(state, "QUICK",
		{"fps": 1, "input_device": "TOUCH"}) == Policy.describe(state, "QUICK",
		{"fps": 240, "input_device": "GAMEPAD"}))
	_assert("M3_4_SNAPSHOT_DOES_NOT_STORE_UI_MODE", not state.has("ui_mode")
		and not state["reaction_window"].has("ui_mode"))

	# A queue draft is not an implicit Confirm. All three mode policies
	# must still report an explicit pending decision even after editing.
	var q1: Dictionary = _apply(state, "QUEUE_REACTION", "queue-A",
		{"window_id": window_id, "entry": _guard()})
	var q2: Dictionary = _apply(q1["state"], "QUEUE_REACTION", "queue-B",
		{"window_id": window_id, "entry": _protect()})
	if not q1["accepted"] or not q2["accepted"]:
		printerr("M3_4_DRAFT_SETUP_FAILED")
		quit(1)
		return
	var drafted: Dictionary = q2["state"]
	_assert("M3_4_DRAFT_NO_RP_DEBIT", drafted["core"]["battle"]["party_resources"]["rp"] == baseline_rp)
	_assert("M3_4_DRAFT_NO_CARD_MOVE", Model.state_hash(drafted["core"]["cards"]) == baseline_card_hash)
	_assert("M3_4_PREVIEW_UNCHANGED_WITH_MODE", _all_waiting(Policy.describe(drafted, "SMART",
		{"significance": "MINOR"})) and _all_waiting(Policy.describe(drafted, "QUICK")))
	_assert("M3_4_DRAFT_FEE_IS_SAME", Queue.preview(drafted, config["reaction_definitions"])["estimated_rp"] == 3)
	_assert("M3_4_DRAFT_STILL_CANNOT_AUTO_COMPLETE", _forbidden(_apply(drafted,
		"COMPLETE_ENEMY_ACTION_FIXTURE", "draft-advance", {"enemy_action_id": action_id}),
		drafted, "REACTION_WINDOW_NOT_RESOLVED"))

	# Mode is a front-end hint only, not a field of Phase.apply. Even if
	# sent in commands (or a malicious fps/timeout), Domain must ignore it.
	# One identical command tape executes and replays identically across
	# all three modes with the actual M2 RP engine and M3.3 Guard/Protect.
	var hash_by_mode: Dictionary = {}
	var event_by_mode: Dictionary = {}
	var final_by_mode: Dictionary = {}
	for mode: String in MODES:
		var now: Dictionary = state.duplicate(true)
		var tape: Array[Dictionary] = []
		var commands: Array = [
			{"type": "QUEUE_REACTION", "entry": _guard()},
			{"type": "QUEUE_REACTION", "entry": _protect()},
			{"type": "REORDER_REACTIONS", "actor_order": ["B", "A"]},
			{"type": "CONFIRM_REACTIONS"},
			{"type": "COMPLETE_ENEMY_ACTION_FIXTURE", "enemy_action_id": action_id}
		]
		for i: int in range(commands.size()):
			var kind: String = str(commands[i]["type"])
			var values: Dictionary = commands[i].duplicate(true)
			values.erase("type")
			if kind in ["QUEUE_REACTION", "REORDER_REACTIONS", "CONFIRM_REACTIONS"]:
				values["window_id"] = window_id
			var cmd: Dictionary = _command(now, kind, "tape-" + str(i), values)
			cmd["ui_mode"] = mode
			cmd["elapsed_seconds"] = 120
			cmd["fps"] = 1 if mode == "QUICK" else 240
			cmd["auto_pass"] = true
			tape.append(cmd)
			var result: Dictionary = Phase.apply(now, cmd, config)
			if not result["accepted"]:
				printerr("M3_4_MODE_TAPE_FAILED ", mode, " ", kind, ": ", result["error"])
				quit(1)
				return
			now = result["state"]
		var playback: Dictionary = Phase.replay(state, tape, config)
		_assert("M3_4_" + mode + "_REPLAY_EXACT", playback["accepted"]
			and playback["state_hash"] == Model.state_hash(now)
			and Model.event_hash(playback["events"]) == playback["event_hash"])
		_assert("M3_4_" + mode + "_FIXED_COST", now["core"]["battle"]["party_resources"]["rp"] == baseline_rp - 2)
		_assert("M3_4_" + mode + "_SAME_CARD_ZONES", Model.state_hash(now["core"]["cards"]) == baseline_card_hash
			and Zones.validate_state(now["core"]["cards"]))
		_assert("M3_4_" + mode + "_REORDER_JIT", _index(playback["events"], "AttackTargetRedirected") >= 0
			and _index(playback["events"], "ReactionSkipped") >= 0
			and _index(playback["events"], "GuardCoverageRegistered") == -1)
		_assert("M3_4_" + mode + "_ENEMY_FINISHES_ONLY_AFTER_CONFIRM", now["reaction_window"].is_empty()
			and now["enemy_cursor"] == 1)
		hash_by_mode[mode] = playback["state_hash"]
		event_by_mode[mode] = playback["event_hash"]
		final_by_mode[mode] = now
	_assert("M3_4_THREE_MODES_IDENTICAL_STATE_HASH",
		hash_by_mode["SMART"] == hash_by_mode["ALWAYS_ASK"]
		and hash_by_mode["ALWAYS_ASK"] == hash_by_mode["QUICK"])
	_assert("M3_4_THREE_MODES_IDENTICAL_EVENT_HASH",
		event_by_mode["SMART"] == event_by_mode["ALWAYS_ASK"]
		and event_by_mode["ALWAYS_ASK"] == event_by_mode["QUICK"])
	_assert("M3_4_THREE_MODES_IDENTICAL_DOMAIN_EVENTS",
		final_by_mode["SMART"]["events"] == final_by_mode["QUICK"]["events"])
	_assert("M3_4_THREE_MODES_IDENTICAL_COMMAND_LEDGER",
		final_by_mode["SMART"]["seen_command_ids"] == final_by_mode["QUICK"]["seen_command_ids"])

	# Explicit Pass closes a real window, does not charge RP/MP/cards.
	var passing: Dictionary = _apply(state, "PASS_REACTION", "manual-pass", {"window_id": window_id})
	_assert("M3_4_PASS_EXPLICIT_NO_RP", passing["accepted"]
		and int(passing["state"]["core"]["battle"]["party_resources"]["rp"]) == baseline_rp)
	_assert("M3_4_PASS_NO_CARD_CHANGE", passing["accepted"]
		and Model.state_hash(passing["state"]["core"]["cards"]) == baseline_card_hash)
	for mode: String in MODES:
		var closed: Dictionary = Policy.describe(passing["state"], mode)
		_assert("M3_4_" + mode + "_CLOSED_NO_PROMPT", _no_window(closed)
			and closed["may_complete_enemy_action"] and not closed["empty_window_skipped"])
	_assert("M3_4_MANUAL_PASS_ENEMY_CAN_COMPLETE", _apply(passing["state"],
		"COMPLETE_ENEMY_ACTION_FIXTURE", "end-after-pass", {"enemy_action_id": action_id})["accepted"])
	_assert("M3_4_DUPLICATE_PASS_REJECTS", _forbidden(_apply(passing["state"],
		"PASS_REACTION", "manual-pass", {"window_id": window_id}),
		passing["state"], "DUPLICATE_COMMAND"))

	# No RP and no SP => actual M3.2 window opens CLOSED/EMPTY; a
	# mode must never show a blocking empty prompt or spend anything.
	var no_rp: Dictionary = _base()
	no_rp["core"]["battle"]["party_resources"]["current_ap"] = 0
	var ended_empty: Dictionary = _apply(no_rp, "END_PLAYER_PHASE", "empty-end")
	var declared_empty: Dictionary = _apply(ended_empty["state"],
		"DECLARE_NEXT_ENEMY_ACTION", "empty-declare")
	var prior: Dictionary = declared_empty["state"]
	var empty: Dictionary = _apply(prior, "OPEN_REACTION_WINDOW", "empty-window",
		{"enemy_action_id": str(prior["active_enemy_action_id"])})
	_assert("M3_4_NO_LEGAL_OPTIONS_DETECTED", empty["accepted"]
		and empty["state"]["reaction_window"]["closure_reason"] == "NO_LEGAL_REACTION")
	_assert("M3_4_EMPTY_NO_AUTO_RESOURCE_CHANGE",
		int(empty["state"]["core"]["battle"]["party_resources"]["rp"]) == 0
		and _index(empty["events"], "ReactionWindowEmptySkipped") >= 0)
	for mode: String in MODES:
		var p: Dictionary = Policy.describe(empty["state"], mode)
		_assert("M3_4_" + mode + "_EMPTY_SKIPS_PROMPT", _no_window(p)
			and p["empty_window_skipped"] and p["may_complete_enemy_action"])
	_assert("M3_4_EMPTY_CAN_FINISH_ACTION", _apply(empty["state"],
		"COMPLETE_ENEMY_ACTION_FIXTURE", "empty-finish",
		{"enemy_action_id": str(prior["active_enemy_action_id"])})["accepted"])
	_assert("M3_4_NO_DECISION_BEFORE_WINDOW_OPENED", _no_window(Policy.describe(prior, "SMART")))
	_assert("M3_4_PLAYER_PHASE_NO_WINDOW", _no_window(Policy.describe(initial, "QUICK")))

	# Domain boundary only, not an actual rendered UI test; no live
	# countdown/node/input handler is driven by this headless script.
	print("M3_4_REPLAY seed=", SEED, " initial=", before_hash,
		" events=", event_by_mode["SMART"], " final=", hash_by_mode["SMART"])
	print("M3_4_TEST_REPORT executed=", passed + failed, " passed=", passed, " failed=", failed)
	if failed == 0:
		print("M3_4_PRESENTATION_POLICY_DOMAIN_VERIFIED")
	quit(0 if failed == 0 else 1)
