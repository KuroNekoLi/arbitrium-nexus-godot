extends RefCounted
## Presentation-only factories. New controls inherit their parent's HUD theme.
static func label(parent: Node, key: String, font_size: int = 16) -> Label:
	var item := Label.new()
	item.text = parent.tr(key)
	item.add_theme_font_size_override("font_size", font_size)
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(item)
	return item

static func button(parent: Node, key: String, callback: Callable) -> Button:
	var item := Button.new()
	item.text = parent.tr(key)
	item.pressed.connect(callback)
	parent.add_child(item)
	return item

static func column(panel: PanelContainer) -> VBoxContainer:
	var result := VBoxContainer.new()
	result.add_theme_constant_override("separation", 6)
	panel.add_child(result)
	return result
