extends Node
## Session owner. Only the existing reducer may commit state.
signal resolved(state: Dictionary, events: Array, command: Dictionary)
signal rejected(error: String)
const M5 = preload("res://scripts/domain/m5/integration/m5_domain_resolver.gd")
const Factory = preload("res://scripts/battle/battle_command_factory.gd")
const Model = preload("res://scripts/domain/m1/combat_model.gd")
var _state: Dictionary = {}
var _initial: Dictionary = {}
var _config: Dictionary = {}
var _tape: Array[Dictionary] = []
var _submitting: bool = false

func begin(initial: Dictionary, content: Dictionary) -> void:
	_initial = initial.duplicate(true)
	_state = initial.duplicate(true)
	_config = content.duplicate(true)
	_tape.clear()

func snapshot() -> Dictionary: return _state.duplicate(true)
func tape() -> Array[Dictionary]: return _tape.duplicate(true)

func submit(command: Dictionary) -> bool:
	if _submitting: return false
	_submitting = true
	var accepted: bool = _commit(command)
	if accepted: _advance_system()
	_submitting = false
	return accepted

func _commit(command: Dictionary) -> bool:
	var result: Dictionary = M5.apply(_state,command,_config)
	if not result["accepted"]:
		rejected.emit(str(result["error"]))
		return false
	_state = result["state"]
	_tape.append(command.duplicate(true))
	resolved.emit(snapshot(),result["events"].duplicate(true),command.duplicate(true))
	return true

func _advance_system() -> void:
	# Scheduler commands advance already published Intent, never choose Reaction.
	for _step: int in 32:
		if _state["core"]["battle"]["outcome"] != "ONGOING": return
		var kind: String = ""
		var args: Dictionary = {}
		if _state["phase"] == "PLAYER_PHASE": return
		if _state["phase"] == "AWAITING_PLAYER_START":
			kind = "START_PLAYER_PHASE"
		elif _state["reaction_window"].get("status","") == "DRAFTING":
			return
		elif _state["active_enemy_action_id"] != "":
			args["enemy_action_id"] = _state["active_enemy_action_id"]
			var needs_window: bool = true
			for action: Dictionary in _state["enemy_actions"]:
				if action["enemy_action_id"] == _state["active_enemy_action_id"]:
					needs_window = bool(action["public_intent"].get("requires_reaction_window",true))
			kind = "OPEN_REACTION_WINDOW" if needs_window and _state["reaction_window"].is_empty() else "RESOLVE_ENEMY_ATTACK_M5"
		elif int(_state["enemy_cursor"]) < _state["enemy_actions"].size():
			kind = "DECLARE_NEXT_ENEMY_ACTION"
		else:
			kind = "END_ENEMY_PHASE"
		if not _commit(Factory.build(_state,kind,args,_tape.size())): return
	push_error("Presentation scheduler exceeded finite command guard")

func replay_receipt() -> Dictionary:
	var result: Dictionary = M5.replay(_initial,_tape,_config)
	return {"accepted":result.get("accepted",false),
		"matches":result.get("state_hash","") == Model.state_hash(_state),
		"state_hash":Model.state_hash(_state),"replay_hash":result.get("state_hash","")}

func save_tape(path: String) -> Error:
	var temp: String = path+".tmp"
	var file := FileAccess.open(temp,FileAccess.WRITE)
	if file == null: return FileAccess.get_open_error()
	# Variant encoding retains integer types. Never deserialize arbitrary objects.
	file.store_var({"schema":"p4-tape-v1","initial":_initial,"config":_config,
		"commands":_tape,"state_hash":Model.state_hash(_state)},false)
	file.flush()
	var error: Error = file.get_error()
	file.close()
	if error != OK: return error
	return DirAccess.rename_absolute(temp,path)

static func verify_saved_tape(path: String) -> Dictionary:
	var file := FileAccess.open(path,FileAccess.READ)
	if file == null: return {"accepted":false,"matches":false}
	var data: Variant = file.get_var(false)
	if not data is Dictionary or data.get("schema","") != "p4-tape-v1":
		return {"accepted":false,"matches":false}
	if not data.get("initial") is Dictionary or not data.get("config") is Dictionary or not data.get("commands") is Array:
		return {"accepted":false,"matches":false}
	var commands: Array[Dictionary] = []
	for entry: Variant in data["commands"]:
		if not entry is Dictionary: return {"accepted":false,"matches":false}
		commands.append(entry)
	var result: Dictionary = M5.replay(data["initial"],commands,data["config"])
	return {"accepted":result.get("accepted",false),"matches":result.get("state_hash","") == data.get("state_hash","")}
