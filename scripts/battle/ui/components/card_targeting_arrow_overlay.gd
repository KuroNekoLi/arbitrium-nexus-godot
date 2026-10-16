@tool
extends Control
## Input-transparent Slay-the-Spire-style curved card-targeting arrow.
## Coordinates are Godot Control global canvas coordinates (not window pixels).
## Target eligibility comes only from BattleScreen's Domain preview.
const SAMPLES: int = 32
const POINT_MIN_DISTANCE: float = 35.0
const ATTACK: Color = Color("#FF668D")
const ALLY: Color = Color("#72DBCB")
const NEUTRAL: Color = Color("#A4BBF9")

var is_aiming: bool = false
var source_global: Vector2 = Vector2.ZERO
var legal_ids: Array = []
var target_buttons: Dictionary = {}
var hovered_target: String = ""
var end_global: Vector2 = Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	set_process(false)

func begin_aim(source: Vector2, targets: Array, buttons: Dictionary) -> void:
	if targets.is_empty():
		end_aim()
		return
	source_global = source
	target_buttons = buttons
	legal_ids = targets.duplicate()
	hovered_target = ""
	is_aiming = true
	visible = true
	set_process(true)
	_update_pointer(get_global_mouse_position())

func update_legal_targets(targets: Array) -> void:
	if not is_aiming:
		return
	legal_ids = targets.duplicate()
	if legal_ids.is_empty():
		end_aim()
		return
	_update_pointer(get_global_mouse_position())

func end_aim() -> void:
	is_aiming = false
	hovered_target = ""
	legal_ids.clear()
	target_buttons = {}
	set_process(false)
	queue_redraw()

func target_at(point: Vector2) -> String:
	# Rectangles are those already used by BattleScreen._drop_card().
	# Never snap an invalid, inactive or exhausted unit.
	for id: String in legal_ids:
		if target_buttons.has(id):
			var hit: Control = target_buttons[id]
			if is_instance_valid(hit) and hit.get_global_rect().has_point(point):
				return id
	return ""

func _process(_delta: float) -> void:
	if is_aiming:
		_update_pointer(get_global_mouse_position())

func _update_pointer(point: Vector2) -> void:
	hovered_target = target_at(point)
	if not hovered_target.is_empty():
		var target: Control = target_buttons[hovered_target]
		end_global = target.get_global_rect().get_center()
	else:
		end_global = point
	queue_redraw()

func _local_geometry() -> PackedVector2Array:
	var inverse: Transform2D = get_global_transform().affine_inverse()
	var from_point: Vector2 = inverse * source_global
	var target_point: Vector2 = inverse * end_global
	var offset: Vector2 = target_point - from_point
	var lift: float = minf(130.0, maxf(42.0, absf(offset.y) * 0.45))
	var control_a: Vector2 = from_point + Vector2(offset.x * 0.12, -lift)
	var control_b: Vector2 = target_point + Vector2(-offset.x * 0.15, -lift * 0.55)
	var points := PackedVector2Array()
	for i: int in SAMPLES + 1:
		var t: float = float(i) / float(SAMPLES)
		var inv: float = 1.0 - t
		var pos: Vector2 = inv * inv * inv * from_point \
			+ 3.0 * inv * inv * t * control_a \
			+ 3.0 * inv * t * t * control_b \
			+ t * t * t * target_point
		points.append(pos)
	return points

func _draw() -> void:
	if not is_aiming:
		return
	var points: PackedVector2Array = _local_geometry()
	if points.size() < 2 or points[0].distance_to(points[-1]) < POINT_MIN_DISTANCE:
		return
	var on_ally: bool = not hovered_target.is_empty() and hovered_target != "Boss"
	var hue: Color = ALLY if on_ally else ATTACK if not hovered_target.is_empty() else NEUTRAL
	draw_polyline(points,Color(hue.r,hue.g,hue.b,0.17),15.0,true)
	draw_polyline(points,Color(hue.r,hue.g,hue.b,0.42),7.0,true)
	draw_polyline(points,hue,3.0,true)
	var tip: Vector2 = points[-1]
	var direction: Vector2 = (tip-points[-2]).normalized()
	var side: Vector2 = direction.orthogonal()
	var head := PackedVector2Array([
		tip + direction * 3.0,
		tip - direction * 20.0 + side * 9.0,
		tip - direction * 15.0,
		tip - direction * 20.0 - side * 9.0])
	draw_colored_polygon(head,hue)
	if not hovered_target.is_empty():
		draw_arc(tip,21.0,0.0,TAU,40,Color(hue.r,hue.g,hue.b,0.6),2.0,true)
		draw_arc(tip,27.0,0.0,TAU,40,Color(hue.r,hue.g,hue.b,0.23),6.0,true)
