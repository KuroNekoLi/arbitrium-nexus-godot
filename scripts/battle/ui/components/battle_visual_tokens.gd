@tool
extends RefCounted
## V3.1 presentation tokens. Values are candidates, not a new Domain schema.
## Keep one canonical Theme for general components; these style factories serve
## only semantic accents (e.g. Boss Break vs Boss HP) that Theme cannot infer.
const HP: Color = Color("#CA5561")
const BREAK: Color = Color("#D4AE71")
const TRACK: Color = Color("#0A1421")
const TRACK_BORDER: Color = Color("#647989")
const INTENT: Color = Color("#F5A883")

static func bar_track() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = TRACK
	box.border_color = TRACK_BORDER
	box.set_border_width_all(1)
	box.set_corner_radius_all(4)
	return box

static func bar_fill(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(3)
	return box

static func setup_read_only_bar(bar: ProgressBar, accent: Color) -> void:
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.custom_minimum_size.y = 11
	bar.add_theme_stylebox_override("background", bar_track())
	bar.add_theme_stylebox_override("fill", bar_fill(accent))


## V3.3 semantic visual surfaces; ornamental only, never a legal threat score.
const METAL: Color = Color("#B59C6D")
const PANEL_DEEP: Color = Color("#0C1C2F")

static func inset_frame(border: Color, background: Color = PANEL_DEEP) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = background
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(5)
	box.content_margin_left = 7.0
	box.content_margin_right = 7.0
	box.content_margin_top = 5.0
	box.content_margin_bottom = 5.0
	return box

static func heading_rule() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = METAL.darkened(0.2)
	return box

## V3.4 party resources and command identity. All accent colors are visual only.
const HERO_HP: Color = Color("#70D6A0")
const HERO_MP: Color = Color("#68CAFF")
const HERO_SELECTED: Color = Color("#B59C6D")
const COMMAND_STANDARD: Color = Color("#6CCDFC")
const COMMAND_UTILITY: Color = Color("#7892A7")
const COMMAND_SUPPORT: Color = Color("#77D9C6")
const COMMAND_LAST: Color = Color("#D4A8DD")
const COMMAND_END: Color = Color("#D4AE71")

static func hero_surface(accent: Color, selected: bool, hover: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#173550") if selected else Color("#12283C") if hover else Color("#081725")
	style.border_color = accent.lerp(METAL, 0.25) if selected else accent.darkened(0.12) if hover else Color("#31495C")
	# V3.5.1: selected identity is thicker and glows; hover stays a lighter step.
	style.set_border_width_all(3 if selected else 2 if hover else 1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 7
	style.content_margin_right = 7
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	if selected:
		style.shadow_color = Color(accent.r, accent.g, accent.b, 0.42)
		style.shadow_size = 8
	elif hover:
		style.shadow_color = Color(accent.r, accent.g, accent.b, 0.18)
		style.shadow_size = 3
	return style

static func hero_portrait_surface(accent: Color, selected: bool) -> StyleBoxFlat:
	var style := inset_frame(accent if selected else accent.darkened(0.35), Color("#07111D"))
	style.set_border_width_all(2 if selected else 1)
	style.content_margin_left = 3
	style.content_margin_right = 3
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	return style

## V3.5.1 party identity. Status colors only label projection.actor.status.
const FOCUS_RING: Color = Color("#70D8F6")
const STATUS_COLORS: Dictionary = {
	"ACTIVE": Color("#5FCB9A"), "CONCENTRATING": Color("#B48CF0"),
	"EXHAUSTED": Color("#E0A75C"), "INCAPACITATED": Color("#E36A78")}

static func status_pill(status: String) -> StyleBoxFlat:
	var tint: Color = STATUS_COLORS.get(status, COMMAND_UTILITY)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(tint.r, tint.g, tint.b, 0.20)
	style.border_color = tint
	style.set_border_width_all(1)
	style.set_corner_radius_all(7)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style

static func focus_ring() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.draw_center = false
	style.border_color = FOCUS_RING
	style.set_border_width_all(2)
	style.set_corner_radius_all(9)
	style.set_expand_margin_all(2)
	return style

static func hero_bar_track() -> StyleBoxFlat:
	var box := bar_track()
	box.border_color = METAL.darkened(0.15)
	box.set_corner_radius_all(3)
	return box

static func command_surface(accent: Color, active: bool, hover: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#19364B") if active else Color("#152C40") if hover else Color("#0C2033")
	style.border_color = accent if active else accent.darkened(0.15) if hover else Color("#415566")
	style.set_border_width_all(2 if active else 1)
	style.set_corner_radius_all(5)
	style.content_margin_left = 12
	style.content_margin_right = 6
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style


