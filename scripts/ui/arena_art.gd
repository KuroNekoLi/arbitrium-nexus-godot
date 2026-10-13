extends Control

func _draw() -> void:
	var s := size
	for ring in 4:
		draw_arc(Vector2(s.x*0.57,s.y*0.52),76.0+ring*39,0,TAU,96,Color(0.24,0.57,0.71,0.11),1.0)
	for i in 18:
		var x := float(i)*s.x/18.0
		draw_line(Vector2(x,s.y*0.13),Vector2(x,s.y*0.88),Color(0.23,0.53,0.66,0.045),1)
	draw_line(Vector2(0,s.y*0.83),Vector2(s.x,s.y*0.83),Color(0.25,0.65,0.78,0.18),2)
