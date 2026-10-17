@tool
extends Control
signal target_requested(actor: String)
var target_buttons: Dictionary = {}
@export var basic_choices: HBoxContainer
var hovered_target: String = ""
var arena: Node2D

func _ready() -> void:
	for id: String in ["Boss", "A", "B", "C"]:
		var target: Button = get_node("Target" + id)
		target_buttons[id] = target
		target.pressed.connect(func() -> void: target_requested.emit(id))

## TargetRegion is authored beside the actor visuals and follows their slot.
## Only presentation geometry is copied; legality remains in BattleScreen.
func _process(_delta: float) -> void:
	if not is_instance_valid(arena):
		return
	var inverse: Transform2D = get_global_transform().affine_inverse()
	for id: String in target_buttons:
		var region: Control = arena.get_node_or_null(id + "/TargetRegion") as Control
		if region == null:
			continue
		var transform: Transform2D = inverse * region.get_global_transform()
		var bounds := Rect2(transform * Vector2.ZERO, Vector2.ZERO)
		for corner: Vector2 in [Vector2(region.size.x, 0), region.size, Vector2(0, region.size.y)]:
			bounds = bounds.expand(transform * corner)
		target_buttons[id].position = bounds.position
		target_buttons[id].size = bounds.size
	queue_redraw()

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
