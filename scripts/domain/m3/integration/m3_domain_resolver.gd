extends RefCounted
## M3.5 headless integration boundary: NO second phase/ledger/card/Reaction
## implementation. M1 hash, M2 integrated transaction, M3.1–M3.4
## authoritative reducers and view policy remain single-source-of-truth.
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const Zones = preload("res://scripts/domain/m2/cards/card_zone_resolver.gd")
const Phase = preload("res://scripts/domain/m3/phase/phase_engine.gd")
const Policy = preload("res://scripts/domain/m3/reaction/reaction_presentation_policy.gd")
const SCHEMA: String = "arbitrium-m3.5-headless-fixture-v1"

static func make_state(core: Dictionary, intents: Array,
		hooks: Array = []) -> Dictionary:
	var phase_state: Dictionary = Phase.make_state(core, intents, hooks)
	if phase_state.is_empty() or not validate_state(phase_state):
		return {}
	return phase_state

static func validate_state(state: Dictionary) -> bool:
	if not Phase.validate_state(state):
		return false
	var core: Dictionary = state["core"]
	if not Zones.validate_state(core["cards"]):
		return false
	var battle: Dictionary = core["battle"]
	var r: Dictionary = battle["party_resources"]
	for name: String in ["current_ap", "rp", "ap_debt"]:
		if int(r.get(name, -1)) < 0:
			return false
	## Dynamic AP bonuses and dynamic RP caps are already validated by M2.
	# Never impose a new AP ceiling here: M2 may allow explicit AP grants.
	if int(r["rp"]) > int(r.get("rp_cap", 6)):
		return false
	for ally: Variant in battle["allies"]:
		var a: Dictionary = battle["actors"][ally]
		if int(a.get("mp", -1)) < 0 or int(a.get("mp", -1)) > int(a.get("max_mp", -1)):
			return false
	var window: Dictionary = state["reaction_window"]
	if not window.is_empty() and str(window.get("status", "")) == "DRAFTING":
		if str(state["active_enemy_action_id"]).is_empty():
			return false
	return true

static func _failed(state: Dictionary, error: String) -> Dictionary:
	var copy: Dictionary = state.duplicate(true)
	return {"accepted": false, "error": error, "state": copy,
		"events": [], "state_hash": Model.state_hash(copy),
		"event_hash": Model.event_hash([]), "schema": SCHEMA}

static func apply(state: Dictionary, command: Dictionary, config: Dictionary) -> Dictionary:
	if not validate_state(state):
		return _failed(state, "INVALID_INTEGRATED_STATE")
	# Explicit, immutable one-command bridge. No hidden auto progression
	# and no instruction rewrite. The PhaseEngine rejects stale/duplicate.
	var result: Dictionary = Phase.apply(state, command, config)
	if not result["accepted"]:
		if Model.state_hash(result["state"]) != Model.state_hash(state):
			return _failed(state, "REJECT_MUTATED_STATE")
		return result
	if not validate_state(result["state"]):
		return _failed(state, "INTEGRATION_INVARIANT_VIOLATED")
	if result["state_hash"] != Model.state_hash(result["state"]):
		return _failed(state, "STATE_HASH_MISMATCH")
	if result["event_hash"] != Model.event_hash(result["events"]):
		return _failed(state, "EVENT_HASH_MISMATCH")
	if int(result["state"]["event_seq"]) - int(state["event_seq"]) != result["events"].size():
		return _failed(state, "EVENT_COUNT_MISMATCH")
	return result

static func view(state: Dictionary, mode: String = "SMART",
		hints: Dictionary = {}) -> Dictionary:
	if not validate_state(state):
		return {"ok": false, "error": "INVALID_INTEGRATED_STATE"}
	return Policy.describe(state, mode, hints)

static func replay(initial: Dictionary, commands: Array[Dictionary],
		config: Dictionary) -> Dictionary:
	if not validate_state(initial):
		return {"accepted": false, "error": "INVALID_INITIAL_STATE",
			"state": initial.duplicate(true), "events": [], "receipts": []}
	var state: Dictionary = initial.duplicate(true)
	var events: Array = []
	var receipts: Array = []
	var seen: Dictionary = {}
	for i: int in range(commands.size()):
		var command: Dictionary = commands[i]
		var id: String = str(command.get("command_id", ""))
		if id.is_empty() or seen.has(id):
			return _stopped(state, events, receipts, "EMPTY_OR_DUPLICATE_TAPE_COMMAND", i)
		seen[id] = true
		var result: Dictionary = apply(state, command, config)
		if not result["accepted"]:
			return _stopped(state, events, receipts, str(result["error"]), i)
		state = result["state"]
		events.append_array(result["events"])
		receipts.append({"step": i, "command_id": id,
			"command_type": str(command.get("type", "")),
			"event_seq": int(state["event_seq"]),
			"state_hash": str(result["state_hash"]),
			"event_hash": str(result["event_hash"])})
	return {"accepted": true, "error": "", "schema": SCHEMA,
		"state": state, "events": events, "receipts": receipts,
		"initial_state_hash": Model.state_hash(initial),
		"state_hash": Model.state_hash(state),
		"event_hash": Model.event_hash(events)}

static func _stopped(state: Dictionary, events: Array, receipts: Array,
		error: String, failed_step: int) -> Dictionary:
	return {"accepted": false, "error": error, "schema": SCHEMA,
		"failed_step": failed_step, "state": state.duplicate(true),
		"events": events.duplicate(true), "receipts": receipts.duplicate(true),
		"state_hash": Model.state_hash(state),
		"event_hash": Model.event_hash(events)}
