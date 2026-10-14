extends RefCounted
## M3.1 authoritative PHASE CLOCK for fixture-only M2 commands.
## Player actions are immediate, and may use A->A->B->A without waiting
## for a party-wide action submission. EnemyAction content execution and
## Reaction windows deliberately fail closed until M3.2/M5.
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const Integrated = preload("res://scripts/domain/m2/integration/m2_domain_resolver.gd")
const Scheduler = preload("res://scripts/domain/m3/enemy/enemy_action_scheduler.gd")
const Boundary = preload("res://scripts/domain/m3/phase/phase_boundary_resolver.gd")
const Window = preload("res://scripts/domain/m3/reaction/reaction_window_resolver.gd")
const ReactionQueue = preload("res://scripts/domain/m3/reaction/reaction_queue_resolver.gd")
const SCHEMA: String = "m3.1-phase-fixture-v1"
const PLAYER_KINDS: Array[String] = [
	"COMMIT_SP_CARD_FIXTURE", "FREE_SWAP", "EXTRA_DRAW_FIXTURE",
	"BASIC_ATTACK_RESOURCE_ONLY"
]

static func make_state(core: Dictionary, published_intents: Array = [],
		boundary_hooks: Array = []) -> Dictionary:
	if not Integrated.validate_state(core) or core["battle"]["phase"] != "PLAYER_PHASE":
		return {}
	if not Boundary.validate_hooks(boundary_hooks):
		return {}
	var planned: Dictionary = Scheduler.plan(published_intents, core["battle"]["enemies"],
		int(core["battle"]["round"]))
	if not planned["ok"]:
		return {}
	var state: Dictionary = {"schema_version": SCHEMA, "core": core.duplicate(true),
		"phase": "PLAYER_PHASE", "published_intents": published_intents.duplicate(true),
		"pending_boundary_hooks": boundary_hooks.duplicate(true),
		"enemy_actions": [], "enemy_cursor": 0, "active_enemy_action_id": "",
		"reaction_window": {},
		"event_seq": 0, "events": [], "seen_command_ids": []}
	return state if validate_state(state) else {}

static func validate_state(state: Dictionary) -> bool:
	if str(state.get("schema_version", "")) != SCHEMA:
		return false
	if not state.get("core", null) is Dictionary or not Integrated.validate_state(state["core"]):
		return false
	if str(state.get("phase", "")) != str(state["core"]["battle"]["phase"]):
		return false
	if not ["PLAYER_PHASE", "ENEMY_PHASE", "AWAITING_PLAYER_START"].has(str(state["phase"])):
		return false
	if not state.get("seen_command_ids", null) is Array or not state.get("events", null) is Array:
		return false
	if not state.get("event_seq", null) is int or int(state["event_seq"]) != state["events"].size():
		return false
	if not state.get("enemy_actions", null) is Array or not state.get("enemy_cursor", null) is int:
		return false
	if not state.get("reaction_window", null) is Dictionary:
		return false
	if not state["reaction_window"].is_empty():
		var rw: Dictionary = state["reaction_window"]
		if not ["DRAFTING", "RESOLVING", "CLOSED"].has(str(rw.get("status", ""))):
			return false
		if str(rw.get("enemy_action_id", "")) != str(state.get("active_enemy_action_id", "")):
			return false
		if not rw.get("draft", null) is Array or not rw.get("executed_actor_ids", null) is Array:
			return false
		if not rw.get("action_active", null) is bool:
			return false
		var draft_actors: Dictionary = {}
		for option: Variant in rw["draft"]:
			if not option is Dictionary or not option.get("actor_id", null) is String:
				return false
			if draft_actors.has(option["actor_id"]):
				return false
			draft_actors[option["actor_id"]] = true
		var executed_actors: Dictionary = {}
		for option: Variant in rw["executed_actor_ids"]:
			if not option is String or executed_actors.has(option):
				return false
			executed_actors[option] = true
	if not state.get("active_enemy_action_id", null) is String:
		return false
	if not state.get("published_intents", null) is Array or not Boundary.validate_hooks(state.get("pending_boundary_hooks", [])):
		return false
	var planned: Dictionary = Scheduler.plan(state["published_intents"],
		state["core"]["battle"]["enemies"], int(state["core"]["battle"]["round"]))
	if not planned["ok"]:
		return false
	if int(state["enemy_cursor"]) < 0 or int(state["enemy_cursor"]) > state["enemy_actions"].size():
		return false
	if str(state["phase"]) == "PLAYER_PHASE" and not state["enemy_actions"].is_empty():
		return false
	if str(state["phase"]) != "ENEMY_PHASE" and str(state["active_enemy_action_id"]) != "":
		return false
	if str(state["active_enemy_action_id"]) != "":
		if int(state["enemy_cursor"]) >= state["enemy_actions"].size():
			return false
		if str(state["enemy_actions"][int(state["enemy_cursor"])]["enemy_action_id"]) != str(state["active_enemy_action_id"]):
			return false
		if str(state["enemy_actions"][int(state["enemy_cursor"])]["status"]) != "DECLARED":
			return false
	var ids: Dictionary = {}
	for value: Variant in state["seen_command_ids"]:
		if not value is String or str(value).is_empty() or ids.has(value):
			return false
		ids[value] = true
	for i: int in range(state["events"].size()):
		if not state["events"][i] is Dictionary:
			return false
		if int(state["events"][i].get("event_seq", -1)) != i + 1:
			return false
	return true

static func _reject(original: Dictionary, reason: String) -> Dictionary:
	var copy: Dictionary = original.duplicate(true)
	return {"accepted": false, "error": reason, "state": copy, "events": [],
		"state_hash": Model.state_hash(copy), "event_hash": Model.event_hash([])}

static func _emit(next: Dictionary, emitted: Array, kind: String,
		command_id: String, details: Dictionary = {}, source: String = "phase") -> void:
	next["event_seq"] = int(next["event_seq"]) + 1
	var event: Dictionary = {"event_seq": int(next["event_seq"]), "kind": kind,
		"command_id": command_id, "source": source, "details": details.duplicate(true),
		"phase": str(next["phase"]), "round": int(next["core"]["battle"]["round"])}
	next["events"].append(event)
	emitted.append(event)

static func _core_events(next: Dictionary, emitted: Array, core_events: Array,
		command_id: String) -> void:
	for item: Dictionary in core_events:
		_emit(next, emitted, str(item["event"]["kind"]), command_id,
			{"core_event": item.duplicate(true)}, "m2")

static func _outcome_check(next: Dictionary, emitted: Array, command_id: String) -> String:
	var verified: Dictionary = Boundary.check_action_outcome(next["core"])
	if not verified["ok"]:
		return str(verified["error"])
	next["core"] = verified["core"]
	_emit(next, emitted, "BattleOutcomeEvaluated", command_id, verified["event"], "boundary")
	return ""

static func apply(original: Dictionary, instruction: Dictionary, config: Dictionary) -> Dictionary:
	if not validate_state(original):
		return _reject(original, "INVALID_PHASE_STATE")
	var command_id: String = str(instruction.get("command_id", ""))
	if command_id.strip_edges().is_empty():
		return _reject(original, "INVALID_COMMAND_ID")
	if original["seen_command_ids"].has(command_id):
		return _reject(original, "DUPLICATE_COMMAND")
	if not instruction.get("expected_event_seq", null) is int:
		return _reject(original, "INVALID_EXPECTED_EVENT_SEQ")
	if int(instruction["expected_event_seq"]) != int(original["event_seq"]):
		return _reject(original, "STALE_STATE")
	if str(original["core"]["battle"]["outcome"]) != "ONGOING":
		return _reject(original, "BATTLE_ENDED")
	var kind: String = str(instruction.get("type", ""))
	var phase: String = str(original["phase"])
	var next: Dictionary = original.duplicate(true)
	var emitted: Array = []
	if PLAYER_KINDS.has(kind):
		if phase != "PLAYER_PHASE":
			return _reject(original, "INVALID_PHASE")
		var nested: Dictionary = instruction.duplicate(true)
		nested.erase("expected_event_seq")
		nested["expected_event_seq"] = int(next["core"]["event_seq"])
		var acted: Dictionary = Integrated.apply(next["core"], nested, config)
		if not acted["accepted"]:
			return _reject(original, str(acted["error"]))
		next["core"] = acted["state"]
		_core_events(next, emitted, acted["events"], command_id)
		_emit(next, emitted, "PlayerActionSettled", command_id,
			{"actor_id": str(instruction.get("actor_id", "")), "action_type": kind,
				"result": "COST_AND_CARD_ONLY_NO_DAMAGE"})
		var outcome_error: String = _outcome_check(next, emitted, command_id)
		if not outcome_error.is_empty():
			return _reject(original, outcome_error)
	elif kind == "END_PLAYER_PHASE":
		if phase != "PLAYER_PHASE":
			return _reject(original, "INVALID_PHASE")
		var plan: Dictionary = Scheduler.plan(next["published_intents"],
			next["core"]["battle"]["enemies"], int(next["core"]["battle"]["round"]))
		if not plan["ok"]:
			return _reject(original, str(plan["error"]))
		var boundary_error: String = _outcome_check(next, emitted, command_id)
		if not boundary_error.is_empty():
			return _reject(original, boundary_error)
		if str(next["core"]["battle"]["outcome"]) == "ONGOING":
			var end: Dictionary = Integrated.apply(next["core"], {
				"type": "CONVERT_AP_TO_RP", "command_id": command_id,
				"expected_event_seq": int(next["core"]["event_seq"])}, config)
			if not end["accepted"]:
				return _reject(original, str(end["error"]))
			next["core"] = end["state"]
			next["phase"] = "ENEMY_PHASE"
			next["enemy_actions"] = plan["actions"]
			next["enemy_cursor"] = 0
			_core_events(next, emitted, end["events"], command_id)
			_emit(next, emitted, "EnemyActionsScheduled", command_id, {"ordered_enemy_action_ids":
				_ordered_ids(next["enemy_actions"]), "count": next["enemy_actions"].size()}, "enemy")
	elif kind == "DECLARE_NEXT_ENEMY_ACTION":
		if phase != "ENEMY_PHASE":
			return _reject(original, "INVALID_PHASE")
		if str(next["active_enemy_action_id"]) != "":
			return _reject(original, "ENEMY_ACTION_ALREADY_ACTIVE")
		var index: int = int(next["enemy_cursor"])
		var action: Dictionary = Scheduler.next_pending(next["enemy_actions"], index)
		if action.is_empty():
			return _reject(original, "NO_PENDING_ENEMY_ACTION")
		if str(action["status"]) != "PENDING":
			return _reject(original, "INVALID_ENEMY_ACTION_STATUS")
		next["enemy_actions"][index]["status"] = "DECLARED"
		next["active_enemy_action_id"] = str(action["enemy_action_id"])
		_emit(next, emitted, "EnemyActionDeclared", command_id,
			{"enemy_action_id": str(action["enemy_action_id"]),
				"enemy_id": str(action["enemy_id"]), "public_intent": action["public_intent"]}, "enemy")
	elif kind == "OPEN_REACTION_WINDOW":
		if phase != "ENEMY_PHASE" or str(next["active_enemy_action_id"]).is_empty():
			return _reject(original, "NO_DECLARED_ENEMY_ACTION")
		if not next["reaction_window"].is_empty():
			return _reject(original, "REACTION_WINDOW_ALREADY_OPENED")
		var action_id: String = str(next["active_enemy_action_id"])
		if str(instruction.get("enemy_action_id", "")) != action_id:
			return _reject(original, "STALE_ENEMY_ACTION_ID")
		var catalogue: Variant = config.get("reaction_definitions", null)
		if not catalogue is Dictionary:
			return _reject(original, "MISSING_REACTION_CATALOGUE")
		var selected_action: Dictionary = next["enemy_actions"][int(next["enemy_cursor"])]
		var opened: Dictionary = Window.open(next["core"], selected_action, catalogue)
		if not opened["ok"]:
			return _reject(original, str(opened["error"]))
		next["reaction_window"] = opened["window"]
		_emit(next, emitted, "ReactionWindowOpened" if opened["has_legal_options"]
			else "ReactionWindowEmptySkipped", command_id,
			{"window_id": str(opened["window"]["window_id"]),
				"enemy_action_id": action_id, "has_legal_options": bool(opened["has_legal_options"])},
			"reaction")
	elif ["QUEUE_REACTION", "REMOVE_REACTION", "REORDER_REACTIONS",
			"CONFIRM_REACTIONS", "PASS_REACTION"].has(kind):
		if phase != "ENEMY_PHASE" or str(next["active_enemy_action_id"]).is_empty():
			return _reject(original, "NO_DECLARED_ENEMY_ACTION")
		var processed: Dictionary = ReactionQueue.apply(next, instruction, config)
		if not processed["ok"]:
			return _reject(original, str(processed["error"]))
		next = processed["state"]
		for record: Dictionary in processed["records"]:
			if str(record["kind"]) == "CORE_EVENTS":
				_core_events(next, emitted, record["events"], command_id)
			else:
				_emit(next, emitted, str(record["kind"]), command_id,
					record.get("details", {}), "reaction")
	elif kind == "COMPLETE_ENEMY_ACTION_FIXTURE":
		if phase != "ENEMY_PHASE":
			return _reject(original, "INVALID_PHASE")
		var active: String = str(next["active_enemy_action_id"])
		if not next["reaction_window"].is_empty():
			if str(next["reaction_window"]["status"]) != "CLOSED":
				return _reject(original, "REACTION_WINDOW_NOT_RESOLVED")
		if active.is_empty():
			return _reject(original, "NO_ACTIVE_ENEMY_ACTION")
		if str(instruction.get("enemy_action_id", "")) != active:
			return _reject(original, "STALE_ENEMY_ACTION_ID")
		var current_action: Dictionary = next["enemy_actions"][int(next["enemy_cursor"])]
		if bool(current_action["public_intent"].get("requires_reaction_window", false)):
			if next["reaction_window"].is_empty() or str(next["reaction_window"]["status"]) != "CLOSED":
				return _reject(original, "REACTION_WINDOW_REQUIRED")
		var cursor: int = int(next["enemy_cursor"])
		next["enemy_actions"][cursor]["status"] = "FIXTURE_RESOLVED"
		next["enemy_cursor"] = cursor + 1
		next["active_enemy_action_id"] = ""
		next["reaction_window"] = {}
		_emit(next, emitted, "EnemyActionFixtureResolved", command_id,
			{"enemy_action_id": active, "damage_status": "DEFERRED_TO_M5",
				"reaction_status": "DEFERRED_TO_M3_2"}, "enemy")
	elif kind == "END_ENEMY_PHASE":
		if phase != "ENEMY_PHASE":
			return _reject(original, "INVALID_PHASE")
		if not str(next["active_enemy_action_id"]).is_empty():
			return _reject(original, "ACTIVE_ENEMY_ACTION")
		if int(next["enemy_cursor"]) != next["enemy_actions"].size():
			return _reject(original, "PENDING_ENEMY_ACTIONS")
		var expired: Dictionary = Integrated.apply(next["core"], {
			"type": "EXPIRE_RP", "command_id": command_id,
			"expected_event_seq": int(next["core"]["event_seq"])}, config)
		if not expired["accepted"]:
			return _reject(original, str(expired["error"]))
		next["core"] = expired["state"]
		next["phase"] = "AWAITING_PLAYER_START"
		_core_events(next, emitted, expired["events"], command_id)
	elif kind == "START_PLAYER_PHASE":
		if phase != "AWAITING_PLAYER_START":
			return _reject(original, "INVALID_PHASE")
		var opened: Dictionary = Boundary.open_player(next["core"],
			next["pending_boundary_hooks"], config, command_id)
		if not opened["ok"]:
			return _reject(original, str(opened["error"]))
		next["core"] = opened["core"]
		next["pending_boundary_hooks"] = opened["remaining_hooks"]
		next["phase"] = str(next["core"]["battle"]["phase"])
		next["enemy_actions"] = []
		next["enemy_cursor"] = 0
		next["active_enemy_action_id"] = ""
		next["reaction_window"] = {}
		for event: Dictionary in opened["timeline"]:
			if str(event["kind"]) == "core_event":
				_core_events(next, emitted, [event["raw"]], command_id)
			else:
				_emit(next, emitted, str(event["kind"]), command_id, event, "boundary")
		if not bool(opened["battle_ended"]):
			_emit(next, emitted, "PlayerPhaseOpened", command_id,
				{"round": int(next["core"]["battle"]["round"]),
					"hand_refill": "M2_DRAW_TO_FOUR", "source": "PRE3-R09"}, "phase")
	else:
		return _reject(original, "FEATURE_NOT_IMPLEMENTED_M3_1")
	if not validate_state(next):
		return _reject(original, "PHASE_INVARIANT_BROKEN")
	next["seen_command_ids"].append(command_id)
	return {"accepted": true, "error": "", "state": next, "events": emitted,
		"state_hash": Model.state_hash(next), "event_hash": Model.event_hash(emitted)}

static func _ordered_ids(actions: Array) -> Array:
	var ids: Array = []
	for action: Dictionary in actions:
		ids.append(str(action["enemy_action_id"]))
	return ids

static func replay(initial: Dictionary, tape: Array[Dictionary], config: Dictionary) -> Dictionary:
	var state: Dictionary = initial.duplicate(true)
	var events: Array = []
	for command: Dictionary in tape:
		var result: Dictionary = apply(state, command, config)
		if not result["accepted"]:
			return {"accepted": false, "error": result["error"], "state": state,
				"events": events, "state_hash": Model.state_hash(state),
				"event_hash": Model.event_hash(events)}
		state = result["state"]
		events.append_array(result["events"])
	return {"accepted": true, "error": "", "state": state, "events": events,
		"state_hash": Model.state_hash(state), "event_hash": Model.event_hash(events)}
