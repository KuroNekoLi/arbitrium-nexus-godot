extends Node2D
## Visual-only foot-anchored actor. No combat state or command callbacks.
@export var actor_id: String = ""
@export var atlas: Texture2D
@export var boss_art: bool = false
@export var visual_height: float = 180.0
@export var accent: Color = Color("79d9ff")
var body: AnimatedSprite2D
var motion: Tween
var home: Vector2
var cast_active: bool = false
var barrier_active: bool = false
var pulse: float = 0.0
var base_tint: Color = Color.WHITE

func _ready() -> void:
	home = position
	body = AnimatedSprite2D.new()
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	if boss_art:
		frames.add_animation("idle")
		var texture := AtlasTexture.new()
		texture.atlas = atlas
		texture.region = Rect2(960, 0, atlas.get_width() - 960, atlas.get_height())
		frames.add_frame("idle", texture)
	else:
		var cell := atlas.get_size() / 3.0
		for row: int in 3:
			var animation: String = ["idle", "run", "strike"][row]
			frames.add_animation(animation)
			frames.set_animation_speed(animation, 7 if row == 0 else 12)
			frames.set_animation_loop(animation, row != 2)
			for col: int in 3:
				var texture := AtlasTexture.new()
				texture.atlas = atlas
				texture.region = Rect2(Vector2(col, row) * cell, cell)
				frames.add_frame(animation, texture)
	body.sprite_frames = frames
	var texture_size: Vector2 = frames.get_frame_texture("idle", 0).get_size()
	body.scale = Vector2.ONE * visual_height / texture_size.y
	body.position.y = -visual_height * 0.5
	add_child(body)
	body.play("idle")
	queue_redraw()

func _draw() -> void:
	draw_set_transform(Vector2.ZERO)
	if cast_active:
		draw_arc(Vector2(0,-visual_height*0.45),visual_height*0.38,pulse,pulse+TAU*0.85,48,Color("77bfff"),3)
	if barrier_active:
		draw_arc(Vector2(0,-visual_height*0.45),visual_height*0.48,PI,TAU,48,Color("6de2cb"),3)
	draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.23))
	draw_circle(Vector2.ZERO, visual_height * 0.19, Color(0.01, 0.02, 0.06, 0.55))
	draw_arc(Vector2.ZERO, visual_height * 0.24, 0, TAU, 48, Color(accent, 0.6), 2)

func play_attack(target_position: Vector2) -> void:
	if motion: motion.kill()
	var home: Vector2 = position
	if not boss_art: body.play("run")
	motion = create_tween()
	motion.tween_property(self, "position", home.lerp(target_position, 0.65), 0.18).set_trans(Tween.TRANS_QUAD)
	if not boss_art: motion.tween_callback(body.play.bind("strike"))
	motion.tween_interval(0.18)
	motion.tween_property(self, "position", home, 0.22).set_trans(Tween.TRANS_CUBIC)
	if not boss_art: motion.tween_callback(body.play.bind("idle"))

func play_hit() -> void:
	body.modulate = Color(2, 1.3, 1.5)
	create_tween().tween_property(body, "modulate", base_tint, 0.28)

func project_conditions(status: String, casting: bool, barrier: bool) -> void:
	cast_active = casting
	barrier_active = barrier
	base_tint = Color("626c83") if status == "INCAPACITATED" else Color("c0a988") if status == "EXHAUSTED" else Color.WHITE
	body.modulate = base_tint
	queue_redraw()

func reset_motion() -> void:
	if motion: motion.kill()
	position = home
	body.play("idle")
	body.modulate = base_tint

func _process(delta: float) -> void:
	if cast_active:
		pulse += delta*0.8
		queue_redraw()

func _exit_tree() -> void:
	if motion: motion.kill()
