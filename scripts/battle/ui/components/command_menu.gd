extends PanelContainer
const UI = preload("res://scripts/battle/ui/components/ui_elements.gd")
signal command_requested(kind: String, fields: Dictionary)
var end_button: Button

func _ready() -> void:
	var commands: VBoxContainer = UI.column(self)
	UI.button(commands, "BATTLE_BASIC", func() -> void: command_requested.emit("BASIC_ATTACK_RESOURCE_ONLY", {}))
	var utility := HBoxContainer.new()
	commands.add_child(utility)
	UI.button(utility, "BATTLE_ANALYZE", func() -> void: command_requested.emit("UNIMPLEMENTED", {}))
	UI.button(utility, "BATTLE_ITEM", func() -> void: command_requested.emit("UNIMPLEMENTED", {}))
	UI.button(commands, "BATTLE_SWAP", func() -> void: command_requested.emit("FREE_SWAP", {}))
	UI.button(commands, "BATTLE_LAST", func() -> void: command_requested.emit("ACTIVATE_LAST_SPELL_M4", {}))
	end_button = UI.button(commands, "BATTLE_END", func() -> void: command_requested.emit("END_PLAYER_PHASE", {}))
	UI.label(commands, "BATTLE_PROTOTYPE", 12)

func render_commands(projection: Dictionary) -> void:
	end_button.text = tr("BATTLE_END")
	end_button.disabled = projection["phase"] != "PLAYER_PHASE" or projection["outcome"] != "ONGOING"
