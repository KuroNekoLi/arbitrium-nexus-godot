@tool
extends Button
## A portrait target choice, not an actor switch or a gameplay state owner.
const UI = preload("res://scripts/battle/ui/components/ui_elements.gd")
const Tokens = preload("res://scripts/battle/ui/components/battle_visual_tokens.gd")
const Visual = preload("res://scripts/battle/ui/components/battle_command_visual.gd")
var selection_label: Label
var target_id: String = ""
var accent: Color

func configure(data: Dictionary, color: Color, selectable: bool) -> void:
	target_id = str(data["id"])
	accent = color
	custom_minimum_size = Vector2(145, 96)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	focus_mode = Control.FOCUS_ALL if selectable and data.get("legal", false) else Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_STOP if selectable else Control.MOUSE_FILTER_IGNORE
	disabled = not data.get("legal", false)
	tooltip_text = str(data["name"])
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 5)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	margin.add_child(column)
	var portrait := TextureRect.new()
	portrait.texture = data.get("portrait")
	if portrait.texture != null:
		var crop := AtlasTexture.new()
		crop.atlas = portrait.texture
		crop.region = Rect2(crop.atlas.get_width() * 0.12, 0, crop.atlas.get_width() * 0.76, crop.atlas.get_height() * 0.46)
		portrait.texture = crop
	portrait.custom_minimum_size = Vector2(0, 43)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	column.add_child(portrait)
	var title: Label = UI.label(column, str(data["name"]), 12)
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var hp: Label = UI.label(column, "", 10)
	hp.text = tr("BATTLE_HP") % [data["hp"], data["max_hp"]]
	hp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	selection_label = UI.label(column, "", 10)
	selection_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ignore_descendants(margin)
	add_theme_stylebox_override("hover", Visual.emphasis_surface(color, "hover"))
	add_theme_stylebox_override("focus", Tokens.focus_ring())
	add_theme_stylebox_override("disabled", Visual.disabled_surface())
	preload("res://scripts/battle/ui/components/battle_hud_chrome.gd").install(self)

func _ignore_descendants(node: Node) -> void:
	if node is Control: node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child: Node in node.get_children(): _ignore_descendants(child)

func set_selected(selected: bool, all_targets: bool) -> void:
	var style: StyleBoxFlat = Tokens.inset_frame(accent if selected else Color("#78694F"), Color("#040C17"))
	if selected:
		style.set_border_width_all(2)
		style.shadow_color = Color(accent, 0.4)
		style.shadow_size = 5
	add_theme_stylebox_override("normal", style)
	selection_label.text = tr("LAST_INCLUDED" if all_targets else "LAST_SELECTED") if selected else ""
	selection_label.add_theme_color_override("font_color", accent.lightened(0.4))
