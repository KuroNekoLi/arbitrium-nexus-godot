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

