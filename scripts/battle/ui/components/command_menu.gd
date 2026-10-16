@tool
extends PanelContainer
## V3.5.2: icon + subtitle command rows. Command IDs, event kinds and fields are
## unchanged from V3.4; Last Spell / End Phase receive the strongest treatment.
const UI = preload("res://scripts/battle/ui/components/ui_elements.gd")
const Tokens = preload("res://scripts/battle/ui/components/battle_visual_tokens.gd")
const Visual = preload("res://scripts/battle/ui/components/battle_command_visual.gd")
signal command_requested(kind: String, fields: Dictionary)
var end_button: Button
var command_buttons: Dictionary = {}
var subtitles: Dictionary = {}

static func _margins(style: StyleBoxFlat) -> StyleBoxFlat:
	# Extra bottom inset lifts the centred title so the subtitle has its own line.
	style.content_margin_left = 12
	style.content_margin_right = 4
	style.content_margin_top = 2
	style.content_margin_bottom = 13
	return style

func _add_command(parent: Node, key: String, kind: String,
		accent: Color, fields: Dictionary = {}) -> Button:
	var action := UI.button(parent, key,
		func() -> void: command_requested.emit(kind, fields))
	action.name = "Command_" + kind + "_" + str(command_buttons.size())
	action.custom_minimum_size.y = 40
	action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action.alignment = HORIZONTAL_ALIGNMENT_LEFT
	action.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	action.clip_text = true
	action.icon = Visual.icon_for(key)
	action.add_theme_constant_override("icon_max_width", 20)
	action.add_theme_constant_override("h_separation", 6)
	if Visual.is_emphasis(key):
		action.custom_minimum_size.y = 46
		action.add_theme_stylebox_override("normal", _margins(Visual.emphasis_surface(accent, "normal")))
		action.add_theme_stylebox_override("hover", _margins(Visual.emphasis_surface(accent, "hover")))
		action.add_theme_stylebox_override("pressed", _margins(Visual.emphasis_surface(accent, "pressed")))
		action.add_theme_stylebox_override("disabled", _margins(Visual.emphasis_surface(accent, "disabled")))
		action.add_theme_color_override("font_color", accent.lightened(0.55))
		action.add_theme_font_size_override("font_size", 15)
	else:
		action.add_theme_stylebox_override("normal", _margins(Tokens.command_surface(accent, false)))
		action.add_theme_stylebox_override("hover", _margins(Tokens.command_surface(accent, false, true)))
		action.add_theme_stylebox_override("pressed", _margins(Tokens.command_surface(accent, true)))
		action.add_theme_stylebox_override("disabled", _margins(Visual.disabled_surface()))
		action.add_theme_color_override("font_color", Color("#F0F5F9"))
		action.add_theme_font_size_override("font_size", 14)
	action.add_theme_color_override("font_disabled_color", Color("#6F7F8C"))
	action.add_theme_stylebox_override("focus", Tokens.focus_ring())
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
	var subtitle := Label.new()
	subtitle.name = "Subtitle"
	subtitle.text = tr(Visual.subtitle_key(key))
	subtitle.add_theme_font_size_override("font_size", 10)
	subtitle.add_theme_color_override("font_color", accent.lerp(Color("#C7D3DC"), 0.55))
	subtitle.autowrap_mode = TextServer.AUTOWRAP_OFF
	subtitle.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	subtitle.clip_text = true
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	subtitle.anchor_top = 1.0
	subtitle.anchor_bottom = 1.0
	subtitle.anchor_right = 1.0
	subtitle.offset_left = 38
	subtitle.offset_right = -4
	subtitle.offset_top = -16
	subtitle.offset_bottom = -2
	action.add_child(subtitle)
	action.tooltip_text = tr(key) + "\n" + subtitle.text
	action.set_meta("title_font_size", 15 if Visual.is_emphasis(key) else 14)
	action.resized.connect(_fit_title.bind(action))
	command_buttons[key] = action
	subtitles[key] = subtitle
	return action

const TITLE_MIN_FONT: int = 11

## Steps the title font down (base → 11) until it fits the button's text area;
## ellipsis stays as the final fallback. Presentation only (V3.5.5 VIS04/10).
func _fit_title(action: Button) -> void:
	var base: int = int(action.get_meta("title_font_size", 14))
	var style: StyleBox = action.get_theme_stylebox("normal")
	var room: float = action.size.x - style.get_margin(SIDE_LEFT) - style.get_margin(SIDE_RIGHT)
	if action.icon != null:
		room -= float(action.get_theme_constant("icon_max_width") + action.get_theme_constant("h_separation"))
	var font: Font = action.get_theme_font("font")
	var chosen: int = base
	while chosen > TITLE_MIN_FONT and \
			font.get_string_size(action.text, HORIZONTAL_ALIGNMENT_LEFT, -1, chosen).x > room:
		chosen -= 1
	if action.get_theme_font_size("font_size") != chosen:
		action.add_theme_font_size_override("font_size", chosen)

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
	var emphasis := HBoxContainer.new()
	emphasis.name = "EmphasisRow"
	emphasis.add_theme_constant_override("separation", 5)
	commands.add_child(emphasis)
	_add_command(emphasis, "BATTLE_LAST", "ACTIVATE_LAST_SPELL_M4", Tokens.COMMAND_LAST)
	end_button = _add_command(emphasis, "BATTLE_END", "END_PLAYER_PHASE", Tokens.COMMAND_END)
	UI.label(commands, "BATTLE_PROTOTYPE", 11).add_theme_color_override("font_color", Color("#8AA0B0"))

func render_commands(projection: Dictionary) -> void:
	end_button.text = tr("BATTLE_END")
	# Locale may change at runtime; subtitles are re-translated from their keys.
	for key: String in subtitles:
		var sub: Label = subtitles[key]
		sub.text = tr(Visual.subtitle_key(key))
		command_buttons[key].tooltip_text = tr(key) + "\n" + sub.text
	end_button.disabled = projection["phase"] != "PLAYER_PHASE" or projection["outcome"] != "ONGOING"
