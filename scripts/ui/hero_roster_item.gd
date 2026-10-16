class_name HeroRosterItem
extends Button

const FANTASY_FRAME: Texture2D = preload("res://addons/kenney_fantasy_ui_borders/panel-border-000.png")
const Tokens = preload("res://scripts/battle/ui/components/battle_visual_tokens.gd")
const BattleTranslations = preload("res://scripts/battle/presentation/battle_translations.gd")

signal hero_selected(hero_id: String)

@onready var portrait: TextureRect = %Portrait
@onready var name_label: Label = %HeroName
@onready var hp_label: Label = %HeroHP
@onready var mana_label: Label = %HeroMana

var hero_id: String = ""
var accent: Color = Color.WHITE
var hp_bar: ProgressBar
var mana_bar: ProgressBar
var combat_status: String = "ACTIVE"
var retirement_mark: Label

func _ready() -> void:
	# This reusable component also lives in the legacy scene, which does not
	# initialize BattleScreen's catalogues. Installation is idempotent and
	# does not change the user's locale or any combat state.
	BattleTranslations.install()
	pressed.connect(_on_pressed)
	var frame := NinePatchRect.new()
	frame.name = "FantasyBorder"
	frame.texture = FANTASY_FRAME
	frame.patch_margin_left = 12
	frame.patch_margin_top = 12
	frame.patch_margin_right = 12
	frame.patch_margin_bottom = 12
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.z_index = 1
	add_child(frame)
	var stats: VBoxContainer = get_node("Layout/Stats")
	stats.add_theme_constant_override("separation", 1)
	hp_bar = _make_resource_bar(stats, "HeroHPBar", Tokens.HERO_HP)
	stats.move_child(hp_bar, mana_label.get_index())
	mana_bar = _make_resource_bar(stats, "HeroMPBar", Tokens.HERO_MP)
	for item: Label in [name_label, hp_label, mana_label, get_node("Layout/Stats/Subtitle")]:
		item.autowrap_mode = TextServer.AUTOWRAP_OFF
		item.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.add_theme_font_size_override("font_size", 16)
	hp_label.add_theme_font_size_override("font_size", 13)
	mana_label.add_theme_font_size_override("font_size", 13)
	var subtitle: Label = get_node("Layout/Stats/Subtitle")
	subtitle.add_theme_font_size_override("font_size", 12)
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	retirement_mark = Label.new()
	retirement_mark.name = "RetirementMark"
	retirement_mark.text = "✕"
	retirement_mark.add_theme_font_size_override("font_size", 48)
	retirement_mark.add_theme_color_override("font_color", Color("#EE718D"))
	retirement_mark.add_theme_color_override("font_outline_color",Color("#180C1A"))
	retirement_mark.add_theme_constant_override("outline_size", 5)
	retirement_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	retirement_mark.z_index = 2
	portrait.get_parent().add_child(retirement_mark)
	retirement_mark.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	retirement_mark.position = Vector2(-14,-33)
	retirement_mark.visible = false

func _make_resource_bar(container: VBoxContainer, label: String, fill_color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.name = label
	bar.custom_minimum_size.y = 5
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Tokens.setup_read_only_bar(bar, fill_color)
	bar.custom_minimum_size.y = 5
	container.add_child(bar)
	return bar

func configure(id: String, display_name: String, portrait_texture: Texture2D, accent_color: Color) -> void:
	hero_id = id
	accent = accent_color
	name_label.text = display_name
	name_label.tooltip_text = display_name
	name_label.add_theme_color_override("font_color", accent)
	portrait.texture = portrait_texture
	_apply_style()

## Legacy interface retained; no persistent hand counter is rendered.
func update_status(hp: int, max_hp: int, mana: int, max_mana: int, _hand_count: int) -> void:
	_update_resources(hp, max_hp, mana, max_mana)

func update_projection(actor: Dictionary, state_text: String) -> void:
	_update_resources(int(actor["hp"]), int(actor["max_hp"]), int(actor["mp"]), int(actor["max_mp"]))
	combat_status = str(actor.get("status","ACTIVE"))
	_apply_combat_state()
	var subtitle: Label = get_node("Layout/Stats/Subtitle")
	subtitle.text = state_text
	subtitle.tooltip_text = state_text

func _update_resources(hp: int, max_hp: int, mana: int, max_mana: int) -> void:
	hp_label.text = tr("BATTLE_HP") % [hp, max_hp]
	mana_label.text = tr("BATTLE_MP") % [mana, max_mana]
	hp_bar.max_value = maxf(1.0, float(max_hp))
	hp_bar.value = clampf(float(hp), 0.0, hp_bar.max_value)
	mana_bar.max_value = maxf(1.0, float(max_mana))
	mana_bar.value = clampf(float(mana), 0.0, mana_bar.max_value)
	hp_bar.tooltip_text = hp_label.text
	mana_bar.tooltip_text = mana_label.text

func _apply_combat_state() -> void:
	if not is_node_ready(): return
	var exhausted: bool = combat_status == "EXHAUSTED"
	var incapacitated: bool = combat_status == "INCAPACITATED"
	portrait.modulate = Color("#646464") if exhausted else Color("#B1A7BA") if incapacitated else Color.WHITE
	retirement_mark.visible = exhausted
	if exhausted:
		name_label.add_theme_color_override("font_color",Color("#929292"))
		hp_label.add_theme_color_override("font_color",Color("#929292"))
		mana_label.add_theme_color_override("font_color",Color("#929292"))
	elif incapacitated:
		name_label.add_theme_color_override("font_color",accent)
		hp_label.add_theme_color_override("font_color",Color("#EF7885"))
		mana_label.add_theme_color_override("font_color",Color("#87C9E8"))
	else:
		name_label.add_theme_color_override("font_color",accent)
		hp_label.add_theme_color_override("font_color",Color("#D0EFF5"))
		mana_label.add_theme_color_override("font_color",Color("#74D9FA"))

func set_selected(selected: bool) -> void:
	button_pressed = selected
	_apply_style()
	_apply_combat_state()

func _on_pressed() -> void:
	if combat_status == "EXHAUSTED": return
	hero_selected.emit(hero_id)

func _apply_style() -> void:
	var fantasy_frame := get_node_or_null("FantasyBorder") as NinePatchRect
	if fantasy_frame:
		fantasy_frame.modulate = accent.lightened(0.35) if button_pressed else Color("#7892A7")
	if not is_node_ready():
		return
	var portrait_frame := portrait.get_parent() as PanelContainer
	portrait_frame.add_theme_stylebox_override("panel",
		Tokens.hero_portrait_surface(accent, button_pressed))
	add_theme_stylebox_override("normal", Tokens.hero_surface(Color("#777777") if combat_status == "EXHAUSTED" else accent, button_pressed and combat_status != "EXHAUSTED"))
	add_theme_stylebox_override("hover", Tokens.hero_surface(accent, button_pressed, true))
	add_theme_stylebox_override("pressed", Tokens.hero_surface(accent, true))
	add_theme_stylebox_override("focus", Tokens.inset_frame(Color("#70D8F6"), Color.TRANSPARENT))

