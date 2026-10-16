@tool
extends Control
signal target_requested(actor: String)
var target_buttons: Dictionary = {}
var basic_choices: HBoxContainer
var hovered_target: String = ""

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for entry: Array in [["Boss", Rect2(722,125,250,335)], ["A", Rect2(340,285,110,175)], ["B", Rect2(590,249,100,173)], ["C", Rect2(475,225,90,164)]]:
		var target := Button.new()
		target.name = "Target" + entry[0]
		target.position = entry[1].position
		target.size = entry[1].size
		target.flat = true
		target.mouse_filter = Control.MOUSE_FILTER_IGNORE
		target.focus_mode = Control.FOCUS_NONE
		target.tooltip_text = tr("BATTLE_TITLE" if entry[0] == "Boss" else "BATTLE_HERO_" + entry[0])
		target.add_theme_font_size_override("font_size", 20)
		target.add_theme_color_override("font_color", Color("#9EEBFF"))
		target.add_theme_color_override("font_outline_color", Color("#07111D"))
		target.add_theme_constant_override("outline_size", 5)
		target.pressed.connect(func() -> void: target_requested.emit(entry[0]))
		add_child(target)
		target_buttons[entry[0]] = target
	basic_choices = HBoxContainer.new()
	basic_choices.name = "BasicAttackTargets"
	basic_choices.position = Vector2(660, 393)
	basic_choices.size = Vector2(310, 43)
	basic_choices.mouse_filter = Control.MOUSE_FILTER_IGNORE
	basic_choices.hide()
	add_child(basic_choices)

func set_targets(ids: Array) -> void:
	for id: String in target_buttons:
		var target: Button = target_buttons[id]
		target.mouse_filter = Control.MOUSE_FILTER_STOP if ids.has(id) else Control.MOUSE_FILTER_IGNORE
		target.focus_mode = Control.FOCUS_ALL if ids.has(id) else Control.FOCUS_NONE
		target.text = "◆" if ids.has(id) and hovered_target == id else "◇" if ids.has(id) else ""
	queue_redraw()

## Pointer-only cue for the same legal hit regions used by the command preview.
## Draws a compact reticle over the hovered actor without changing selection.
func set_hovered_target(actor: String) -> void:
	hovered_target = actor if target_buttons.has(actor) else ""
	for id: String in target_buttons:
		var target: Button = target_buttons[id]
		target.text = "◆" if id == hovered_target else "◇" if target.mouse_filter == Control.MOUSE_FILTER_STOP else ""
	queue_redraw()

func _draw() -> void:
	if hovered_target.is_empty() or not target_buttons.has(hovered_target):
		return
	var target: Control = target_buttons[hovered_target]
	var center: Vector2 = target.position + target.size * 0.5
	var color: Color = Color("#72DBCB") if hovered_target != "Boss" else Color("#FF668D")
	var radius: float = clampf(minf(target.size.x, target.size.y) * 0.16, 13.0, 23.0)
	draw_arc(center, radius + 7.0, 0.0, TAU, 40, Color(color, 0.26), 6.0, true)
	draw_arc(center, radius, 0.0, TAU, 40, color, 2.5, true)
	draw_line(center + Vector2(-radius - 5.0, 0), center + Vector2(-radius + 1.0, 0), color, 2.0, true)
	draw_line(center + Vector2(radius - 1.0, 0), center + Vector2(radius + 5.0, 0), color, 2.0, true)
	draw_line(center + Vector2(0, -radius - 5.0), center + Vector2(0, -radius + 1.0), color, 2.0, true)
	draw_line(center + Vector2(0, radius - 1.0), center + Vector2(0, radius + 5.0), color, 2.0, true)

func set_basic_target_choices(ids: Array, selected_id: String, labels: Dictionary) -> void:
	for child: Node in basic_choices.get_children():
		basic_choices.remove_child(child)
		child.queue_free()
	basic_choices.visible = ids.size() > 1
	if not basic_choices.visible:
		return
	for id: String in ids:
		var choice := Button.new()
		choice.name = "Choice" + id
		choice.text = ("◆ " if id == selected_id else "◇ ") + str(labels.get(id, id))
		choice.tooltip_text = str(labels.get(id, id))
		choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		choice.focus_mode = Control.FOCUS_ALL
		choice.pressed.connect(func() -> void: target_requested.emit(id))
		basic_choices.add_child(choice)
		if target_buttons.has(id):
			target_buttons[id].text = "◆" if id == selected_id else "◇"
