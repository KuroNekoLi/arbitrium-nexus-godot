extends PanelContainer
const UI = preload("res://scripts/battle/ui/components/ui_elements.gd")
const Tokens = preload("res://scripts/battle/ui/components/battle_visual_tokens.gd")
signal command_requested(kind: String, fields: Dictionary)
var end_button: Button
var command_buttons: Dictionary = {}

func _add_command(parent: Node, key: String, kind: String,
		accent: Color, fields: Dictionary = {}) -> Button:
	var action := UI.button(parent, key,
		func() -> void: command_requested.emit(kind, fields))
	action.name = "Command_" + kind + "_" + str(command_buttons.size())
	action.custom_minimum_size.y = 31
	action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action.add_theme_stylebox_override("normal", Tokens.command_surface(accent, false))
	action.add_theme_stylebox_override("hover", Tokens.command_surface(accent, false, true))
	action.add_theme_stylebox_override("pressed", Tokens.command_surface(accent, true))
	action.add_theme_stylebox_override("focus",
		Tokens.inset_frame(Color("#70D8F6"), Color.TRANSPARENT))
	action.add_theme_color_override("font_color", Color("#F0F5F9"))
	action.add_theme_font_size_override("font_size", 14)
	var rail := ColorRect.new()
	rail.name = "AccentRail"
	rail.color = accent
	rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rail.anchor_bottom = 1.0
	rail.offset_left = 3
	rail.offset_right = 6
	rail.offset_top = 6
	rail.offset_bottom = -6
	action.add_child(rail)
	command_buttons[key] = action
	return action

func _ready() -> void:
	var commands: VBoxContainer = UI.column(self)
	commands.name = "CommandContent"
	commands.add_theme_constant_override("separation", 5)
	_add_command(commands, "BATTLE_BASIC", "BASIC_ATTACK_RESOURCE_ONLY", Tokens.COMMAND_STANDARD)
	var utility := HBoxContainer.new()
	utility.name = "UtilityRow"
	utility.add_theme_constant_override("separation", 4)
	commands.add_child(utility)
	_add_command(utility, "BATTLE_ANALYZE", "UNIMPLEMENTED", Tokens.COMMAND_UTILITY)
	_add_command(utility, "BATTLE_ITEM", "UNIMPLEMENTED", Tokens.COMMAND_UTILITY)
	_add_command(commands, "BATTLE_SWAP", "FREE_SWAP", Tokens.COMMAND_SUPPORT)
	_add_command(commands, "BATTLE_LAST", "ACTIVATE_LAST_SPELL_M4", Tokens.COMMAND_LAST)
	end_button = _add_command(commands, "BATTLE_END", "END_PLAYER_PHASE", Tokens.COMMAND_END)
	UI.label(commands, "BATTLE_PROTOTYPE", 12)

func render_commands(projection: Dictionary) -> void:
	end_button.text = tr("BATTLE_END")
	end_button.disabled = projection["phase"] != "PLAYER_PHASE" or projection["outcome"] != "ONGOING"

