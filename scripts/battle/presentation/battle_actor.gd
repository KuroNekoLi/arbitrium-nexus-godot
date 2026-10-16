@tool
extends Node2D
## Presentation-only actor. Resource/Inspector changes work in the editor.
## Existing animation API stays stable for AnimationDirector and P4 tests.
@export var actor_id: String = ""
@export var atlas: Texture2D  # Boss/legacy fallback, not the Lv40 party.
@export var boss_art: bool = false
@export var appearance: BattleCharacterAppearance:
	set(value):
		if appearance != null and appearance.changed.is_connected(_on_art_changed):
			appearance.changed.disconnect(_on_art_changed)
		appearance = value
		if appearance != null and not appearance.changed.is_connected(_on_art_changed):
			appearance.changed.connect(_on_art_changed)
		_on_art_changed()
@export var visual_height: float = 180.0:
	set(value):
		visual_height = maxf(1.0, value)
		_on_art_changed()
@export var accent: Color = Color("79d9ff")
@export var shadow_width: float = 0.19:
	set(value):
		shadow_width = clampf(value, 0.0, 1.0)
		queue_redraw()
var body: AnimatedSprite2D
var motion: Tween
var home: Vector2
var cast_active: bool = false
var barrier_active: bool = false
var pulse: float = 0.0
var base_tint: Color = Color.WHITE

func _ready() -> void:
	home = position
	_on_art_changed()
	if Engine.is_editor_hint():
		# Editor redraws appearance only; no combat commands or tweens.
		set_process(false)

func _on_art_changed() -> void:
	if not is_inside_tree():
		return
	if body == null or not is_instance_valid(body):
		body = AnimatedSprite2D.new()
		body.name = "ActorFramesPreview"
		add_child(body) # no owner: editor does not save transient children
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	if boss_art:
		if atlas == null:
			return
		frames.add_animation("idle")
		var texture := AtlasTexture.new()
		texture.atlas = atlas
		texture.region = Rect2(960, 0, maxf(1, atlas.get_width()-960), atlas.get_height())
		frames.add_frame("idle", texture)
	else:
		var source: Texture2D = appearance.atlas if appearance != null else atlas
		if source == null:
			return
		for row: int in 3:
			var animation: String = ["idle", "run", "strike"][row]
			frames.add_animation(animation)
			frames.set_animation_speed(animation, 7 if row == 0 else 12)
			frames.set_animation_loop(animation, row != 2)
			for col: int in 3:
				var texture: Texture2D
				if appearance != null:
					texture = appearance.sprite_texture(row, col)
				else:
					var fallback := AtlasTexture.new()
					fallback.atlas = source
					fallback.region = Rect2(Vector2(col,row)*source.get_size()/3.0,source.get_size()/3.0)
					texture = fallback
				if texture != null:
					frames.add_frame(animation, texture)
	if not frames.has_animation("idle") or frames.get_frame_count("idle") == 0:
		return
	body.sprite_frames = frames
	var size: Vector2 = frames.get_frame_texture("idle",0).get_size()
	body.scale = Vector2.ONE * (visual_height / maxf(1.0,size.y))
	var offset: Vector2 = appearance.foot_offset if appearance != null and not boss_art else Vector2.ZERO
	body.position = Vector2(0,-visual_height*0.5) + offset
	body.modulate = (appearance.tint if appearance != null and not boss_art else Color.WHITE)*base_tint
	body.play("idle")
	queue_redraw()

func _draw() -> void:
	if cast_active:
		draw_arc(Vector2(0,-visual_height*0.45),visual_height*0.38,pulse,pulse+TAU*0.85,48,Color("77bfff"),3)
	if barrier_active:
		draw_arc(Vector2(0,-visual_height*0.45),visual_height*0.48,PI,TAU,48,Color("6de2cb"),3)
	draw_set_transform(Vector2.ZERO,0,Vector2(1,0.23))
	draw_circle(Vector2.ZERO,visual_height*shadow_width,Color(0.01,0.02,0.06,0.55))
	draw_arc(Vector2.ZERO,visual_height*0.24,0,TAU,48,Color(accent,0.6),2)

func play_attack(target_position: Vector2) -> void:
	if Engine.is_editor_hint() or body == null:
		return
	if motion: motion.kill()
	var from: Vector2 = position
	if not boss_art: body.play("run")
	motion = create_tween()
	motion.tween_property(self,"position",from.lerp(target_position,0.65),0.18).set_trans(Tween.TRANS_QUAD)
	if not boss_art: motion.tween_callback(body.play.bind("strike"))
	motion.tween_interval(0.18)
	motion.tween_property(self,"position",from,0.22).set_trans(Tween.TRANS_CUBIC)
	if not boss_art: motion.tween_callback(body.play.bind("idle"))

func play_hit() -> void:
	if Engine.is_editor_hint() or body == null: return
	body.modulate = Color(2,1.3,1.5)
	create_tween().tween_property(body,"modulate",base_tint,0.28)

func project_conditions(status: String, casting: bool, barrier: bool) -> void:
	if Engine.is_editor_hint() or body == null:
		return
	cast_active = casting
	barrier_active = barrier
	base_tint = Color("626c83") if status == "INCAPACITATED" else Color("c0a988") if status == "EXHAUSTED" else Color.WHITE
	body.modulate = base_tint
	queue_redraw()

func reset_motion() -> void:
	if Engine.is_editor_hint() or body == null:
		return
	if motion: motion.kill()
	position = home
	body.play("idle")
	body.modulate = base_tint

func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	if cast_active:
		pulse += delta*0.8
		queue_redraw()

func _exit_tree() -> void:
	if motion: motion.kill()
	if appearance != null and appearance.changed.is_connected(_on_art_changed):
		appearance.changed.disconnect(_on_art_changed)
