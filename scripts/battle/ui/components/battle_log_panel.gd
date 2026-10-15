extends PanelContainer
## Reusable read-only battle log, independent from card/action preview.
## V3.5.4: rows rendered from real DomainEvents (seq chip + category rail).
## log_label stays the V2.2 plain-text facade and mirrors the newest rows.
const UI = preload("res://scripts/battle/ui/components/ui_elements.gd")
const Formatter = preload("res://scripts/battle/presentation/battle_log_formatter.gd")
const HISTORY_LIMIT: int = 24
const VISIBLE_ROWS: int = 4
var log_label: Label
var log_scroll: ScrollContainer
var entry_list: VBoxContainer
var history: Array = []

func _ready() -> void:
	var body: VBoxContainer = UI.column(self)
	body.add_theme_constant_override("separation", 4)
	var heading: Label = UI.label(body, "BATTLE_LOG", 14)
	heading.name = "LogHeading"
	heading.add_theme_color_override("font_color", Color("#D8C08A"))
	log_scroll = ScrollContainer.new()
	log_scroll.name = "LogScroll"
	log_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	log_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	log_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(log_scroll)
	var content := VBoxContainer.new()
	content.name = "LogContent"
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 2)
	log_scroll.add_child(content)
	entry_list = VBoxContainer.new()
	entry_list.name = "LogEntries"
	entry_list.add_theme_constant_override("separation", 2)
	entry_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(entry_list)
	log_label = UI.label(content, "", 12)
	log_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_label.max_lines_visible = 3

## Appends formatter rows (already derived from real events) and redraws.
func append_rows(rows: Array) -> void:
	history.append_array(rows)
	if history.size() > HISTORY_LIMIT:
		history = history.slice(history.size() - HISTORY_LIMIT)
	_redraw()

func clear_rows() -> void:
	history.clear()
	_redraw()

func visible_rows() -> Array:
	return history.slice(maxi(0, history.size() - VISIBLE_ROWS))

func _redraw() -> void:
	for old: Node in entry_list.get_children():
		entry_list.remove_child(old)
		old.queue_free()
	var shown: Array = visible_rows()
	var plain: PackedStringArray = []
	for i: int in shown.size():
		var row: Dictionary = shown[i]
		plain.append(Formatter.plain(row))
		entry_list.add_child(_make_row(row, i == shown.size() - 1))
	log_label.text = "\n".join(plain.slice(maxi(0, plain.size() - 3)))
	# Rows supersede the plain mirror visually; the facade text is kept in sync.
	log_label.visible = shown.is_empty()

func _make_row(row: Dictionary, newest: bool) -> HBoxContainer:
	var accent: Color = Formatter.CATEGORY_COLORS.get(str(row["category"]), Formatter.CATEGORY_COLORS["GENERIC"])
	var line := HBoxContainer.new()
	line.name = "Entry_%d" % int(row["seq"])
	line.add_theme_constant_override("separation", 5)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.tooltip_text = Formatter.plain(row)
	var rail := ColorRect.new()
	rail.name = "CategoryRail"
	rail.color = accent if newest else accent.darkened(0.25)
	rail.custom_minimum_size = Vector2(3, 14)
	rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(rail)
	var seq := Label.new()
	seq.name = "Seq"
	seq.text = Formatter.seq_label(row)
	seq.add_theme_font_size_override("font_size", 11)
	seq.add_theme_color_override("font_color", Color("#8FA3B3"))
	seq.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(seq)
	var text := Label.new()
	text.name = "Text"
	text.text = str(row["text"])
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.autowrap_mode = TextServer.AUTOWRAP_OFF
	text.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	text.clip_text = true
	text.add_theme_font_size_override("font_size", 12)
	text.add_theme_color_override("font_color", accent.lerp(Color.WHITE, 0.55) if newest else Color("#B9C6D0"))
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(text)
	return line
