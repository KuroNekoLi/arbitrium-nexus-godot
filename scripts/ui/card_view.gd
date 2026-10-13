extends "res://addons/simple_cards/card/card.gd"

const CARD_ART_ATLAS: Texture2D = preload("res://assets/card_art_atlas.png")

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
	var kind_color := _kind_color()
	var bg := Color("#201d2a") if combat_data and combat_data.kind == CardData.CardKind.ATTACK else Color("#10242b") if combat_data and combat_data.kind == CardData.CardKind.DEFENSE else Color("#201b31") if combat_data and combat_data.kind == CardData.CardKind.SUPPORT else Color("#2a172b")
	_draw_round(rect.grow(-1),10,bg)
	_draw_outline(rect.grow(-1),10,kind_color)
	_draw_outline(rect.grow(-5),8,Color(kind_color.r, kind_color.g, kind_color.b, 0.28))
	draw_rect(Rect2(7,7,size.x-14,4),kind_color)
	var kind_name := _kind_name()
	draw_string(ThemeDB.fallback_font, Vector2(12, 26), kind_name, HORIZONTAL_ALIGNMENT_LEFT, 76, 9, kind_color)
	if combat_data:
		var art_index: int = _card_art_index(combat_data.id)
		var source := Rect2(Vector2((art_index % 3) * 512, int(art_index / 3) * 512), Vector2(512, 512))
		draw_texture_rect_region(CARD_ART_ATLAS, Rect2(8, 34, size.x - 16, 70), source)
		draw_rect(Rect2(8, 34, size.x - 16, 70), Color(kind_color.r, kind_color.g, kind_color.b, 0.25), false, 1.0)
	if combat_data:
		draw_string(ThemeDB.fallback_font,Vector2(12,111),combat_data.title,HORIZONTAL_ALIGNMENT_LEFT,118,11,Color("#f4f3fa"))
		var lines := _wrap(combat_data.description,11)
		for i in mini(3,lines.size()):
			draw_string(ThemeDB.fallback_font,Vector2(12,130+i*13),lines[i],HORIZONTAL_ALIGNMENT_LEFT,118,9,Color("#c3ced9"))
		draw_circle(Vector2(size.x-21,21),14,Color(kind_color.r*0.2,kind_color.g*0.2,kind_color.b*0.2))
		draw_arc(Vector2(size.x-21,21),14,0,TAU,32,kind_color,1.6)
		draw_string(ThemeDB.fallback_font,Vector2(size.x-29,26),str(combat_data.cost),HORIZONTAL_ALIGNMENT_CENTER,16,14,Color.WHITE)
		var hero_names := {"kleya": "克蕾雅", "nova": "諾瓦", "yora": "尤拉"}
		draw_string(ThemeDB.fallback_font,Vector2(12,size.y-10),hero_names.get(combat_data.owner_id, ""),HORIZONTAL_ALIGNMENT_LEFT,95,9,accent)

func _wrap(text_value: String, width: int) -> PackedStringArray:
	var out := PackedStringArray()
	var line := ""
	for i in text_value.length():
		var character := text_value.substr(i, 1)
		if character == "，" or character == "。":
			line += character
			continue
		if line.length() >= width:
			out.append(line)
			line = ""
		line += character
	if not line.is_empty(): out.append(line)
	return out

func _kind_color() -> Color:
	if combat_data == null: return accent
	match combat_data.kind:
		CardData.CardKind.ATTACK: return Color("#ff765f")
		CardData.CardKind.DEFENSE: return Color("#53d8c2")
		CardData.CardKind.SUPPORT: return Color("#c29aff")
		CardData.CardKind.REACTION: return Color("#ff5cba")
	return accent

func _kind_name() -> String:
	if combat_data == null: return "戰術牌"
	match combat_data.kind:
		CardData.CardKind.ATTACK: return "攻擊"
		CardData.CardKind.DEFENSE: return "防禦"
		CardData.CardKind.SUPPORT: return "支援"
		CardData.CardKind.REACTION: return "反應"
	return "戰術牌"

func _card_art_index(card_id: String) -> int:
	if card_id.ends_with("nova_burst") or card_id.ends_with("surge"):
		return 1
	if card_id.ends_with("guard"):
		return 2
	if card_id.ends_with("focus") or card_id.ends_with("scan") or card_id.ends_with("tactical_read"):
		return 3
	if card_id.ends_with("field_medic"):
		return 4
	if card_id.ends_with("interrupt"):
		return 5
	return 0

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
