extends PanelContainer
## Reusable read-only battle log, independent from card/action preview.
const UI = preload("res://scripts/battle/ui/components/ui_elements.gd")
var log_label: Label
var log_scroll: ScrollContainer

func _ready() -> void:
	var body: VBoxContainer = UI.column(self)
	body.add_theme_constant_override("separation", 4)
	UI.label(body, "BATTLE_LOG", 14)
	log_scroll = ScrollContainer.new()
	log_scroll.name = "LogScroll"
	log_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	log_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	log_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(log_scroll)
	log_label = UI.label(log_scroll, "", 12)
	log_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_label.max_lines_visible = 3
