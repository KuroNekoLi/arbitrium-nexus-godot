extends Control

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("#07111d"))
	for i in 44:
		var x := fmod(float(i*173+21),size.x)
		var y := fmod(float(i*79+11),size.y)
		draw_circle(Vector2(x,y),1.0 if i%5 else 1.5,Color(0.45,0.77,0.9,0.15))
