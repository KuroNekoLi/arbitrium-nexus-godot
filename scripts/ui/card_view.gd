extends "res://addons/simple_cards/card/card.gd"

var combat_data: CardData
var accent := Color("#72e8ff")

func _ready() -> void:
	super._ready()
	custom_minimum_size = Vector2(142, 184)
	size = custom_minimum_size
	self_modulate = Color.WHITE
	center_pos = size * 0.5
	pivot_offset = center_pos
	drag_threshold = 12.0
	drag_coef = -22.0
	set_meta("home_position", position)
	call_deferred("_hide_default_layout")
	card_hovered.connect(_animate_hover.bind(true))
	card_unhovered.connect(_animate_hover.bind(false))

func _hide_default_layout() -> void:
	if is_instance_valid(_layout):
		_layout.hide()
		_layout.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _animate_hover(hovering: bool) -> void:
	if holding: return
	var target_scale := Vector2(1.06, 1.06) if hovering else Vector2.ONE
	var home: Vector2 = get_meta("home_position", position)
	var target_position := home + Vector2(0, -18) if hovering else home
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", target_scale, 0.13)
	tween.parallel().tween_property(self, "position", target_position, 0.13)

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO,size)
	var bg := Color("#111f31")
	_draw_round(rect.grow(-1),10,bg)
	_draw_outline(rect.grow(-1),10,accent)
	draw_rect(Rect2(7,7,size.x-14,3),accent)
	# engraved suit emblem
	draw_circle(Vector2(size.x*0.5,65),31,Color(accent.r,accent.g,accent.b,0.09))
	draw_arc(Vector2(size.x*0.5,65),25,0,TAU,48,Color(accent.r,accent.g,accent.b,0.6),1.4)
	if combat_data:
		match combat_data.kind:
			CardData.CardKind.ATTACK:
				draw_line(Vector2(54,80),Vector2(74,49),accent,3.0,true)
				draw_line(Vector2(65,82),Vector2(82,56),Color(accent.r,accent.g,accent.b,0.65),2.0,true)
			CardData.CardKind.DEFENSE:
				draw_colored_polygon(PackedVector2Array([Vector2(71,44),Vector2(90,51),Vector2(87,69),Vector2(71,83),Vector2(55,69),Vector2(52,51)]),Color(accent.r,accent.g,accent.b,0.13))
				draw_polyline(PackedVector2Array([Vector2(71,44),Vector2(90,51),Vector2(87,69),Vector2(71,83),Vector2(55,69),Vector2(52,51),Vector2(71,44)]),accent,2.0,true)
			CardData.CardKind.SUPPORT:
				draw_colored_polygon(PackedVector2Array([Vector2(71,45),Vector2(89,65),Vector2(71,84),Vector2(53,65)]),Color(accent.r,accent.g,accent.b,0.17))
				draw_polyline(PackedVector2Array([Vector2(71,45),Vector2(89,65),Vector2(71,84),Vector2(53,65),Vector2(71,45)]),accent,2.0,true)
			CardData.CardKind.REACTION:
				draw_polyline(PackedVector2Array([Vector2(77,44),Vector2(62,64),Vector2(73,64),Vector2(64,83),Vector2(84,59),Vector2(73,59)]),accent,3.0,true)
	if combat_data:
		draw_string(ThemeDB.fallback_font,Vector2(12,111),combat_data.title.to_upper(),HORIZONTAL_ALIGNMENT_LEFT,118,11,Color("#e5f4f7"))
		var lines := _wrap(combat_data.description,20)
		for i in mini(3,lines.size()):
			draw_string(ThemeDB.fallback_font,Vector2(12,130+i*13),lines[i],HORIZONTAL_ALIGNMENT_LEFT,118,9,Color("#a9c2ce"))
		draw_circle(Vector2(size.x-21,21),14,Color("#172f40"))
		draw_arc(Vector2(size.x-21,21),14,0,TAU,32,accent,1.2)
		draw_string(ThemeDB.fallback_font,Vector2(size.x-29,26),str(combat_data.cost),HORIZONTAL_ALIGNMENT_CENTER,16,14,Color.WHITE)
		draw_string(ThemeDB.fallback_font,Vector2(12,size.y-10),combat_data.owner_id.to_upper(),HORIZONTAL_ALIGNMENT_LEFT,95,8,accent)

func _wrap(text_value: String, width: int) -> PackedStringArray:
	var out := PackedStringArray()
	var words := text_value.split(" ")
	var line := ""
	for word in words:
		if line.length()+word.length()+1 > width and not line.is_empty():
			out.append(line)
			line = word
		else:
			line = (line+" "+word).strip_edges()
	if not line.is_empty(): out.append(line)
	return out

func _draw_round(r: Rect2, radius: float, color: Color) -> void:
	var st := StyleBoxFlat.new()
	st.bg_color = color
	st.set_corner_radius_all(int(radius))
	draw_style_box(st,r)

func _draw_outline(r: Rect2, radius: float, color: Color) -> void:
	var st := StyleBoxFlat.new()
	st.bg_color = Color.TRANSPARENT
	st.border_color = color
	st.set_border_width_all(1)
	st.set_corner_radius_all(int(radius))
	draw_style_box(st,r)
