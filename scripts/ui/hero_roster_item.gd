class_name HeroRosterItem
extends Button

const FANTASY_FRAME: Texture2D = preload("res://addons/kenney_fantasy_ui_borders/panel-border-000.png")

signal hero_selected(hero_id: String)

@onready var portrait: TextureRect = %Portrait
@onready var name_label: Label = %HeroName
@onready var hp_label: Label = %HeroHP
@onready var mana_label: Label = %HeroMana

var hero_id: String = ""
var accent: Color = Color.WHITE

func _ready() -> void:
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

func configure(id: String, display_name: String, portrait_texture: Texture2D, accent_color: Color) -> void:
	hero_id = id
	accent = accent_color
	name_label.text = display_name
	name_label.add_theme_color_override("font_color", accent)
	portrait.texture = portrait_texture
	_apply_style()

func update_status(hp: int, max_hp: int, mana: int, max_mana: int, hand_count: int) -> void:
	hp_label.text = "HP  %d / %d" % [hp, max_hp]
	mana_label.text = "MP  %d / %d     手牌 %d" % [mana, max_mana, hand_count]

## Phase 4 projection keeps the legacy API intact; no redundant hand counter.
func update_projection(actor: Dictionary, state_text: String) -> void:
	hp_label.text = tr("BATTLE_HP") % [actor["hp"], actor["max_hp"]]
	mana_label.text = tr("BATTLE_MP") % [actor["mp"], actor["max_mp"]]
	(get_node("Layout/Stats/Subtitle") as Label).text = state_text
	for item: Label in [hp_label, mana_label]:
		item.add_theme_font_size_override("font_size", 15)
	(get_node("Layout/Stats/Subtitle") as Label).add_theme_font_size_override("font_size", 14)
	for item: Label in [hp_label,mana_label]:
		var bar := item.get_node_or_null("ResourceBar") as ProgressBar
		if bar == null:
			bar = ProgressBar.new()
			bar.name = "ResourceBar"
			bar.show_percentage = false
			bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
			item.add_child(bar)
			bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
			bar.offset_top = -2
			var fill := StyleBoxFlat.new()
			fill.bg_color = Color("70d6a0") if item == hp_label else Color("68caff")
			bar.add_theme_stylebox_override("fill",fill)
			var background := StyleBoxFlat.new()
			background.bg_color = Color("182c40")
			bar.add_theme_stylebox_override("background",background)
		bar.max_value = actor["max_hp"] if item == hp_label else actor["max_mp"]
		bar.value = actor["hp"] if item == hp_label else actor["mp"]

func set_selected(selected: bool) -> void:
	button_pressed = selected
	_apply_style()

func _on_pressed() -> void:
	hero_selected.emit(hero_id)

func _apply_style() -> void:
	var fantasy_frame := get_node_or_null("FantasyBorder") as NinePatchRect
	if fantasy_frame:
		fantasy_frame.modulate = accent.lightened(0.35) if button_pressed else Color("#7892a7")
	var portrait_frame := portrait.get_parent() as PanelContainer
	var portrait_style := StyleBoxFlat.new()
	portrait_style.bg_color = Color("#07111d")
	portrait_style.border_color = accent
	portrait_style.set_border_width_all(1)
	portrait_style.set_corner_radius_all(5)
	portrait_style.content_margin_left = 3
	portrait_style.content_margin_right = 3
	portrait_style.content_margin_top = 3
	portrait_style.content_margin_bottom = 3
	portrait_frame.add_theme_stylebox_override("panel", portrait_style)
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color("#102338") if button_pressed else Color("#081725")
	panel.border_color = accent if button_pressed else Color("#274154")
	panel.set_border_width_all(2 if button_pressed else 1)
	panel.set_corner_radius_all(8)
	panel.content_margin_left = 7
	panel.content_margin_right = 7
	panel.content_margin_top = 6
	panel.content_margin_bottom = 6
	add_theme_stylebox_override("normal", panel)
	add_theme_stylebox_override("hover", panel)
	add_theme_stylebox_override("pressed", panel)
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
