extends Button
## Pure presentation and selection over an existing actor slot.
var accent: Color = Color("#6FD6FF")
var selected: bool = false

func _ready() -> void:
	flat = true

func _draw() -> void:
	var color: Color = accent if selected else Color("#68BFE9")
	var center := Vector2(size.x * 0.5, 18)
	draw_polyline(PackedVector2Array([center + Vector2(0,-12),center + Vector2(9,0),
		center + Vector2(0,12),center + Vector2(-9,0),center + Vector2(0,-12)]), color, 2.5, true)
	if selected:
		draw_line(center + Vector2(-4,0), center + Vector2(4,0), Color.WHITE, 2)
		draw_line(center + Vector2(0,-5), center + Vector2(0,5), Color.WHITE, 2)
		draw_set_transform(Vector2(size.x * 0.5, size.y - 4), 0, Vector2(1,0.22))
		draw_arc(Vector2.ZERO, size.x * 0.48, 0, TAU, 48, Color(color,0.25), 10, true)
		draw_arc(Vector2.ZERO, size.x * 0.48, 0, TAU, 48, color, 2, true)
