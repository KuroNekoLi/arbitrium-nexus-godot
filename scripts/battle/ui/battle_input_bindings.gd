extends RefCounted
## Install missing battle actions only; never overwrite user remaps.
static func install() -> void:
	var keys: Dictionary = {"battle_party_1":KEY_1,"battle_party_2":KEY_2,"battle_party_3":KEY_3}
	for action: String in keys:
		if InputMap.has_action(action): continue
		InputMap.add_action(action)
		var event := InputEventKey.new()
		event.physical_keycode = keys[action]
		InputMap.action_add_event(action,event)
