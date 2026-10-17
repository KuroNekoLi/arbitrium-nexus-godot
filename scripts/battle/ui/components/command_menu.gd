@tool
extends PanelContainer
## V3.5.2: icon + subtitle command rows. Command IDs, event kinds and fields are
## unchanged from V3.4; Last Spell / End Phase receive the strongest treatment.
const Visual = preload("res://scripts/battle/ui/components/battle_command_visual.gd")
signal command_requested(kind: String, fields: Dictionary)
@export var end_button: Button
var command_buttons: Dictionary = {}
var subtitles: Dictionary = {}
const TITLE_MIN_FONT: int = 11
@export var auto_fit_titles: bool = true
var _title_font_sizes: Dictionary = {}

func _fit_title(action: Button) -> void:
	if not auto_fit_titles:
		return
	var base: int = int(_title_font_sizes.get(action.get_instance_id(), action.get_theme_font_size("font_size")))
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
	_bind_command("BATTLE_BASIC", "BASIC_ATTACK_RESOURCE_ONLY", get_node("CommandContent/Command_BASIC_ATTACK_RESOURCE_ONLY_0"))
	_bind_command("BATTLE_ANALYZE", "UNIMPLEMENTED", get_node("CommandContent/UtilityRow/Command_UNIMPLEMENTED_1"))
	_bind_command("BATTLE_ITEM", "UNIMPLEMENTED", get_node("CommandContent/UtilityRow/Command_UNIMPLEMENTED_2"))
	_bind_command("BATTLE_SWAP", "FREE_SWAP", get_node("CommandContent/Command_FREE_SWAP_3"))
	_bind_command("BATTLE_LAST", "ACTIVATE_LAST_SPELL_M4", get_node("CommandContent/EmphasisRow/Command_ACTIVATE_LAST_SPELL_M4_4"))
	_bind_command("BATTLE_END", "END_PLAYER_PHASE", get_node("CommandContent/EmphasisRow/Command_END_PLAYER_PHASE_5"))

func _bind_command(key: String, kind: String, action: Button) -> void:
	command_buttons[key] = action
	subtitles[key] = action.get_node("Subtitle")
	_title_font_sizes[action.get_instance_id()] = action.get_theme_font_size("font_size")
	action.pressed.connect(func() -> void: command_requested.emit(kind, {}))
	action.resized.connect(_fit_title.bind(action))
	_fit_title(action)

func render_commands(projection: Dictionary) -> void:
	end_button.text = tr("BATTLE_END")
	# Locale may change at runtime; subtitles are re-translated from their keys.
	for key: String in subtitles:
		command_buttons[key].text = tr(key)
		var sub: Label = subtitles[key]
		sub.text = tr(Visual.subtitle_key(key))
		command_buttons[key].tooltip_text = tr(key) + "\n" + sub.text
		_fit_title(command_buttons[key])
	end_button.disabled = projection["phase"] != "PLAYER_PHASE" or projection["outcome"] != "ONGOING"
