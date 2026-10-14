extends RefCounted
## PH3-M1-CMD/EVT/REPLAY: authoritative command -> validation -> transaction.
## SELECT_ACTOR is the ONLY functional command; M2-M5 commands fail closed.
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const ALLOWED_COMMANDS: Array[String] = [
	"SELECT_ACTOR", "BASIC_ATTACK", "PLAY_SP", "END_PLAYER_PHASE", "QUEUE_REACTION",
	"CONFIRM_REACTIONS", "PASS_REACTION", "GUARD", "PROTECT", "ANALYZE",
	"SWAP_CARD", "LAST_SPELL", "ITEM"
]

static func _reject(state: Dictionary, code: String) -> Dictionary:
	var unchanged: Dictionary = Model.snapshot(state)
	return {"accepted": false, "state": unchanged, "events": [],
		"error": code, "state_hash": Model.state_hash(unchanged),
		"event_hash": Model.event_hash([])}

static func submit(state: Dictionary, command: Dictionary) -> Dictionary:
	if not Model.validate_shell(state):
		return _reject(state, "INVALID_STATE")
	if state.get("outcome", "") != "ONGOING":
		return _reject(state, "BATTLE_ENDED")
	var kind: String = str(command.get("type", ""))
	if not ALLOWED_COMMANDS.has(kind):
		return _reject(state, "UNKNOWN_COMMAND")
	if kind != "SELECT_ACTOR":
		return _reject(state, "FEATURE_NOT_IMPLEMENTED")
	var command_id: String = str(command.get("command_id", ""))
	if command_id.strip_edges().is_empty():
		return _reject(state, "INVALID_COMMAND_ID")
	var accepted_ids: Array = state["seen_command_ids"]
	if accepted_ids.has(command_id):
		return _reject(state, "DUPLICATE_COMMAND")
	if not command.has("expected_event_seq"):
		return _reject(state, "MISSING_EXPECTED_EVENT_SEQ")
	if int(command["expected_event_seq"]) != int(state["event_seq"]):
		return _reject(state, "STALE_STATE")
	if state.get("phase", "") != "PLAYER_PHASE":
		return _reject(state, "INVALID_PHASE")
	var actor_id: String = str(command.get("actor_id", ""))
	var allies: Array = state["allies"]
	var actors: Dictionary = state["actors"]
	if not allies.has(actor_id) or not actors.has(actor_id):
		return _reject(state, "ACTOR_NOT_FOUND")
	var actor: Dictionary = actors[actor_id]
	if str(actor.get("status", "")) != "ACTIVE" or int(actor.get("hp", 0)) <= 0:
		return _reject(state, "ACTOR_UNAVAILABLE")
	# Snapshot-before-commit ensures caller state/RNG/event log cannot be mutated.
	var next_state: Dictionary = Model.snapshot(state)
	next_state["selected_actor_id"] = actor_id
	next_state["action_seq"] = int(next_state["action_seq"]) + 1
	next_state["event_seq"] = int(next_state["event_seq"]) + 1
	var next_ids: Array = next_state["seen_command_ids"]
	next_ids.append(command_id)
	var event: Dictionary = {
		"event_seq": int(next_state["event_seq"]),
		"action_id": int(next_state["action_seq"]),
		"command_id": command_id,
		"kind": "ActorSelected",
		"actor_id": actor_id,
		"phase": str(next_state["phase"]),
		"rng_draw_index": int(next_state["rng"]["draw_index"])
	}
	var all_events: Array = next_state["events"]
	all_events.append(event)
	return {"accepted": true, "state": next_state, "events": [event],
		"error": "", "state_hash": Model.state_hash(next_state),
		"event_hash": Model.event_hash([event])}

static func replay(initial_state: Dictionary, tape: Array[Dictionary]) -> Dictionary:
	var state: Dictionary = Model.snapshot(initial_state)
	var all_events: Array = []
	var results: Array[Dictionary] = []
	for command: Dictionary in tape:
		var result: Dictionary = submit(state, command)
		if not result["accepted"]:
			return {"accepted": false, "error": result["error"], "state": state,
				"events": all_events, "results": results,
				"state_hash": Model.state_hash(state),
				"event_hash": Model.event_hash(all_events)}
		state = result["state"]
		all_events.append_array(result["events"])
		results.append({"command_id": command.get("command_id", ""), "accepted": true})
	return {"accepted": true, "error": "", "state": state,
		"events": all_events, "results": results,
		"state_hash": Model.state_hash(state), "event_hash": Model.event_hash(all_events)}
