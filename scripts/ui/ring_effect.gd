extends Node2D

func _draw() -> void:
	var radius := float(get_meta("radius", 24.0))
	var color: Color = get_meta("ring_color", Color.WHITE)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, color, 3.0, true)
	var inner := color
	inner.a = 0.55
	draw_arc(Vector2.ZERO, radius * 0.72, 0.25, TAU * 0.68, 32, inner, 1.2, true)
