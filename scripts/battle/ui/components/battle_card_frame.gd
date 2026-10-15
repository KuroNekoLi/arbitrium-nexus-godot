extends RefCounted
## V3.2 reusable card face, composed from true appearance, cost and i18n.
## This file knows NOTHING about CardInstanceID, zones, legality or transactions.
const BASE: Color = Color("#101C30")
const DEEP: Color = Color("#071120")
const GOLD: Color = Color("#B59C6D")
const TEXT: Color = Color("#F0F5F9")
const SECONDARY: Color = Color("#B9C9D8")
const INVALID: Color = Color("#647180")

static func outer_frame(accent: Color, legal: bool) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = BASE
	box.border_color = accent.lerp(GOLD, 0.36) if legal else INVALID
	box.set_border_width_all(2)
	box.set_corner_radius_all(10)
	box.content_margin_left = 9.0
	box.content_margin_right = 9.0
	box.content_margin_top = 7.0
	box.content_margin_bottom = 7.0
	box.shadow_color = Color(0.0, 0.02, 0.08, 0.58)
	box.shadow_size = 4
	return box

static func cost_frame(accent: Color, legal: bool) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color("#172B40") if legal else Color("#252A34")
	box.border_color = accent.lerp(GOLD, 0.48) if legal else INVALID
	box.set_border_width_all(1)
	box.set_corner_radius_all(5)
	box.content_margin_left = 7.0
	box.content_margin_right = 7.0
	box.content_margin_top = 3.0
	box.content_margin_bottom = 3.0
	return box

static func illustration_frame() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = DEEP
	box.border_color = GOLD.darkened(0.24)
	box.set_border_width_all(1)
	box.set_corner_radius_all(4)
	box.content_margin_left = 2.0
	box.content_margin_right = 2.0
	box.content_margin_top = 2.0
	box.content_margin_bottom = 2.0
	return box

static func ornamental_rule() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = GOLD.darkened(0.14)
	return box

static func _label(parent: Node, name: String, text: String, font_size: int, color: Color) -> Label:
	var item := Label.new()
	item.name = name
	item.text = text
	item.add_theme_font_size_override("font_size", font_size)
	item.add_theme_color_override("font_color", color)
	parent.add_child(item)
	return item

static func build(face: PanelContainer, appearance: Resource, cost_text: String,
	legal: bool, unavailable_reason: String) -> Dictionary:
	var accent: Color = appearance.accent
	var column := VBoxContainer.new()
	column.name = "CardContents"
	column.add_theme_constant_override("separation", 3)
	face.add_child(column)

	var header := HBoxContainer.new()
	header.name = "CostRow"
	header.add_theme_constant_override("separation", 2)
	column.add_child(header)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	var cost_badge := PanelContainer.new()
	cost_badge.name = "CostBadge"
	cost_badge.add_theme_stylebox_override("panel", cost_frame(accent, legal))
	header.add_child(cost_badge)
	var cost_label: Label = _label(cost_badge, "CostLabel", cost_text, 13,
		accent.lightened(0.24) if legal else SECONDARY)
	cost_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	cost_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	cost_label.tooltip_text = cost_text

	var artwork_frame := PanelContainer.new()
	artwork_frame.name = "ArtworkFrame"
	artwork_frame.add_theme_stylebox_override("panel", illustration_frame())
	artwork_frame.custom_minimum_size.y = 88
	column.add_child(artwork_frame)
	var artwork := TextureRect.new()
	artwork.name = "Artwork"
	artwork.texture = appearance.artwork
	artwork.custom_minimum_size.y = 84
	artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	artwork_frame.add_child(artwork)

	var rule := PanelContainer.new()
	rule.name = "OrnamentalRule"
	rule.custom_minimum_size.y = 2
	rule.add_theme_stylebox_override("panel", ornamental_rule())
	column.add_child(rule)

	var title: Label = _label(column, "CardName", face.tr(appearance.name_key), 16, TEXT)
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var description: Label = _label(column, "CardDescription",
		face.tr(appearance.description_key), 12, SECONDARY)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# Retain reviewed V2's stable wrapping width before the first layout pass.
	# An illegal card reserves a line for its reason without growing the face.
	description.custom_minimum_size.x = 144
	description.max_lines_visible = 2 if legal else 1
	description.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	description.tooltip_text = face.tr(appearance.description_key)
	var reason: Label
	if not legal:
		reason = _label(column, "UnavailableReason", face.tr("BATTLE_UNAVAILABLE"), 11,
			Color("#DFB1AF"))
		reason.tooltip_text = unavailable_reason
		reason.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	return {
		"cost_badge": cost_badge,
		"cost_label": cost_label,
		"artwork_frame": artwork_frame,
		"artwork": artwork,
		"title": title,
		"description": description,
		"reason": reason
	}

