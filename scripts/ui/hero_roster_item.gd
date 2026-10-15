class_name HeroRosterItem
extends Button

const FANTASY_FRAME: Texture2D = preload("res://addons/kenney_fantasy_ui_borders/panel-border-000.png")
const CREST: Texture2D = preload("res://assets/ui/v35/ap_crystal.svg")
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
## V3.5.1 presentation-only status surface. Populated exclusively by callers
## that read authoritative projection fields; this component never infers state.
var status_badges: HBoxContainer
var status_kind: String = ""

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
	var subtitle: Label = get_node("Layout/Stats/Subtitle")
	for item: Label in [name_label, hp_label, mana_label, subtitle]:
		item.autowrap_mode = TextServer.AUTOWRAP_OFF
		item.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	# The status pill is SHRINK_BEGIN; with ellipsis trimming its minimum width is
	# ~0 and the text vanishes (V3.5.5 VIS01). Status labels are short words.
	subtitle.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	name_label.add_theme_font_size_override("font_size", 15)
	hp_label.add_theme_font_size_override("font_size", 12)
	mana_label.add_theme_font_size_override("font_size", 12)
	subtitle.add_theme_font_size_override("font_size", 11)
	subtitle.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_status_overlay()

func _make_resource_bar(container: VBoxContainer, label: String, fill_color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.name = label
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Tokens.setup_read_only_bar(bar, fill_color)
	bar.add_theme_stylebox_override("background", Tokens.hero_bar_track())
	bar.custom_minimum_size.y = 8
	container.add_child(bar)
	# Ornamental crest at the bar end; ignores input and never encodes a value.
	var crest := TextureRect.new()
	crest.name = "BarCrest"
	crest.texture = CREST
	crest.modulate = fill_color.lightened(0.25)
	crest.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	crest.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	crest.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crest.anchor_left = 1.0
	crest.anchor_right = 1.0
	crest.anchor_top = 0.5
	crest.anchor_bottom = 0.5
	crest.offset_left = -5
	crest.offset_right = 5
	crest.offset_top = -7
	crest.offset_bottom = 7
	bar.add_child(crest)
	return bar

func _build_status_overlay() -> void:
	# Zero-minimum overlay: the PortraitFrame size is never enlarged by badges.
	var overlay := Control.new()
	overlay.name = "StatusOverlay"
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.get_parent().add_child(overlay)
	status_badges = HBoxContainer.new()
	status_badges.name = "StatusBadges"
	status_badges.add_theme_constant_override("separation", 1)
	status_badges.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_badges.anchor_top = 1.0
	status_badges.anchor_bottom = 1.0
	status_badges.anchor_right = 1.0
	status_badges.offset_top = -17
	status_badges.offset_bottom = 1
	status_badges.alignment = BoxContainer.ALIGNMENT_BEGIN
	overlay.add_child(status_badges)

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
	var subtitle: Label = get_node("Layout/Stats/Subtitle")
	subtitle.text = state_text
	subtitle.tooltip_text = state_text
	set_status_kind(str(actor.get("status", "")))

func _update_resources(hp: int, max_hp: int, mana: int, max_mana: int) -> void:
	hp_label.text = tr("BATTLE_HP") % [hp, max_hp]
	mana_label.text = tr("BATTLE_MP") % [mana, max_mana]
	hp_bar.max_value = maxf(1.0, float(max_hp))
	hp_bar.value = clampf(float(hp), 0.0, hp_bar.max_value)
	mana_bar.max_value = maxf(1.0, float(max_mana))
	mana_bar.value = clampf(float(mana), 0.0, mana_bar.max_value)
	hp_bar.tooltip_text = hp_label.text
	mana_bar.tooltip_text = mana_label.text

## Presentation-only status pill. Incapacitated is dimmed but the button stays
## enabled: viewing an ally never depends on that ally being able to act.
func set_status_kind(status: String) -> void:
	status_kind = status
	var subtitle: Label = get_node("Layout/Stats/Subtitle")
	if status.is_empty():
		subtitle.remove_theme_stylebox_override("normal")
	else:
		subtitle.add_theme_stylebox_override("normal", Tokens.status_pill(status))
		subtitle.add_theme_color_override("font_color",
			Tokens.STATUS_COLORS.get(status, Tokens.COMMAND_UTILITY).lightened(0.35))
	portrait.modulate = Color(0.55, 0.5, 0.55) if status == "INCAPACITATED" else Color.WHITE

## badges: Array of {"id": String, "icon": Texture2D, "tooltip": String}.
## Callers must source each entry from a real projection field.
func set_status_badges(badges: Array) -> void:
	for old: Node in status_badges.get_children():
		status_badges.remove_child(old)
		old.queue_free()
	for badge: Dictionary in badges:
		var icon := TextureRect.new()
		icon.name = "Badge_" + str(badge.get("id", ""))
		icon.texture = badge.get("icon", null)
		icon.custom_minimum_size = Vector2(17, 17)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.tooltip_text = str(badge.get("tooltip", ""))
		# Tooltip lives on the Button; icons never intercept selection input.
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		status_badges.add_child(icon)

func badge_ids() -> Array:
	var ids: Array = []
	for child: Node in status_badges.get_children():
		if not child.is_queued_for_deletion():
			ids.append(str(child.name).trim_prefix("Badge_"))
	return ids

func set_selected(selected: bool) -> void:
	button_pressed = selected
	_apply_style()

func _on_pressed() -> void:
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
	add_theme_stylebox_override("normal", Tokens.hero_surface(accent, button_pressed))
	add_theme_stylebox_override("hover", Tokens.hero_surface(accent, button_pressed, true))
	add_theme_stylebox_override("pressed", Tokens.hero_surface(accent, true))
	add_theme_stylebox_override("hover_pressed", Tokens.hero_surface(accent, true, true))
	add_theme_stylebox_override("focus", Tokens.focus_ring())
