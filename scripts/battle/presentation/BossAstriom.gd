class_name BossAstriom
extends Node2D
## Presentation-only layered Boss actor. Combat state remains in the M1-M5 Domain.

@export var actor_id: String = "Boss"
@export var visual_height: float = 325.0

var body: Sprite2D
var downed: bool = false
var retired: bool = false
var cast_active: bool = false
var barrier_active: bool = false
var home: Vector2
var motion: Tween
var _defeated: bool = false
var _body_base_scale: Vector2
var _body_base_position: Vector2
var _aura_base_scale: Vector2
var _aura_base_modulate: Color = Color(1.0, 1.0, 1.0, 0.72)

@onready var magic_circle: Sprite2D = $MagicCircle
@onready var aura_back: Sprite2D = $AuraBack
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	home = position
	body = $Body
	_fit_layers()
	_build_animations()
	animation_player.root_node = NodePath("..")
	animation_player.animation_finished.connect(_on_animation_finished)
	play_idle()

func _fit_layers() -> void:
	if body.texture != null:
		body.centered = true
		_body_base_scale = Vector2.ONE * (visual_height / maxf(1.0, body.texture.get_height()))
		_body_base_position = Vector2(0.0, -visual_height * 0.5)
		body.scale = _body_base_scale
		body.position = _body_base_position
	if aura_back.texture != null:
		aura_back.centered = true
		_aura_base_scale = Vector2.ONE * (visual_height * 1.15 / maxf(1.0, aura_back.texture.get_height()))
		aura_back.scale = _aura_base_scale
		aura_back.position = Vector2(0.0, -visual_height * 0.58)
		aura_back.modulate = Color(1.15, 1.1, 1.5, 0.78)
		_aura_base_modulate = aura_back.modulate
	if magic_circle.texture != null:
		magic_circle.centered = true
		# The supplied image includes a tall sigil behind the floor circle. Show
		# only its lower half so rotation reads as a ground ring rather than a wall.
		magic_circle.region_enabled = true
		magic_circle.region_rect = Rect2(
			0.0,
			magic_circle.texture.get_height() * 0.5,
			magic_circle.texture.get_width(),
			magic_circle.texture.get_height() * 0.5)
		magic_circle.scale = Vector2(
			visual_height * 1.55 / maxf(1.0, magic_circle.texture.get_width()),
			visual_height * 0.36 / maxf(1.0, magic_circle.texture.get_height() * 0.5))
		magic_circle.position = Vector2(0.0, 5.0)

func _build_animations() -> void:
	var library := AnimationLibrary.new()
	var idle := Animation.new()
	idle.length = 4.0
	idle.loop_mode = Animation.LOOP_LINEAR
	_add_value_track(idle, "MagicCircle:rotation", [0.0, 4.0], [0.0, TAU])
	_add_value_track(idle, "AuraBack:modulate", [0.0, 2.0, 4.0], [
		_aura_base_modulate, Color(1.25, 1.15, 1.6, 0.95), _aura_base_modulate])
	_add_value_track(idle, "AuraBack:scale", [0.0, 2.0, 4.0], [
		_aura_base_scale, _aura_base_scale * 1.035, _aura_base_scale])
	_add_value_track(idle, "Body:position:y", [0.0, 2.0, 4.0], [
		_body_base_position.y, _body_base_position.y - 6.0, _body_base_position.y])
	library.add_animation("idle", idle)

	var hit := Animation.new()
	hit.length = 0.34
	_add_value_track(hit, "Body:modulate", [0.0, 0.07, 0.18, 0.34], [
		Color.WHITE, Color(2.0, 1.35, 1.8, 1.0), Color(1.35, 1.0, 1.3, 1.0), Color.WHITE])
	library.add_animation("hit", hit)

	var cast := Animation.new()
	cast.length = 0.52
	_add_value_track(cast, "AuraBack:modulate", [0.0, 0.24, 0.52], [
		_aura_base_modulate, Color(1.7, 1.35, 2.0, 1.0), _aura_base_modulate])
	_add_value_track(cast, "Body:scale", [0.0, 0.24, 0.52], [
		_body_base_scale, _body_base_scale * 1.025, _body_base_scale])
	library.add_animation("cast", cast)

	var defeated := Animation.new()
	defeated.length = 0.85
	_add_value_track(defeated, "Body:modulate", [0.0, 0.85], [Color.WHITE, Color(0.45, 0.38, 0.7, 0.0)])
	_add_value_track(defeated, "Body:scale", [0.0, 0.85], [_body_base_scale, _body_base_scale * 0.9])
	_add_value_track(defeated, "AuraBack:modulate", [0.0, 0.85], [_aura_base_modulate, Color(1.0, 1.0, 1.0, 0.0)])
	_add_value_track(defeated, "MagicCircle:modulate", [0.0, 0.85], [Color.WHITE, Color(1.0, 1.0, 1.0, 0.0)])
	library.add_animation("defeated", defeated)
	animation_player.add_animation_library("", library)

func _add_value_track(animation: Animation, path: String, times: Array, values: Array) -> void:
	var track: int = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track, NodePath(path))
	for index: int in times.size():
		animation.track_insert_key(track, float(times[index]), values[index])

## Start or resume the looped layered idle animation.
func play_idle() -> void:
	if _defeated or retired:
		return
	visible = true
	if animation_player.current_animation != "idle":
		animation_player.play("idle")

## Play a short visual-only impact response.
func play_hit() -> void:
	if _defeated or retired:
		return
	animation_player.play("hit")

## Play the visual-only casting accent used by the shared battle presenter.
func play_spell_cast() -> void:
	if _defeated or retired:
		return
	animation_player.play("cast")

## Lunge toward a target for an accepted physical action, then return to the slot.
func play_attack(target_position: Vector2) -> void:
	if _defeated or retired:
		return
	if motion != null and motion.is_running():
		motion.kill()
	position = home
	play_idle()
	motion = create_tween()
	motion.tween_property(self, "position", home.lerp(target_position, 0.65), 0.18).set_trans(Tween.TRANS_QUAD)
	motion.tween_interval(0.18)
	motion.tween_property(self, "position", home, 0.22).set_trans(Tween.TRANS_CUBIC)

## Fade the Boss layers after its defeat; does not write or infer combat state.
func play_defeated() -> void:
	if _defeated:
		return
	_defeated = true
	if motion != null and motion.is_running():
		motion.kill()
	position = home
	queue_redraw()
	animation_player.play("defeated")

## Receives the existing battle presentation projection; never mutates Domain state.
func project_conditions(status: String, casting: bool, barrier: bool, field_retired: bool = false) -> void:
	if Engine.is_editor_hint():
		return
	var was_retired: bool = retired
	retired = field_retired
	downed = status == "INCAPACITATED"
	cast_active = casting and not downed and not retired
	barrier_active = barrier and not retired
	visible = not retired
	if was_retired and not retired:
		reset_motion()
	elif status == "ACTIVE" and _defeated:
		reset_motion()

## Restore the visual slot and idle animation after a skip or encounter restart.
func reset_motion() -> void:
	if Engine.is_editor_hint():
		return
	if motion != null and motion.is_running():
		motion.kill()
	motion = null
	_defeated = false
	queue_redraw()
	retired = false
	downed = false
	position = home
	visible = true
	body.modulate = Color.WHITE
	body.scale = _body_base_scale
	body.position = _body_base_position
	aura_back.modulate = _aura_base_modulate
	aura_back.scale = _aura_base_scale
	magic_circle.modulate = Color.WHITE
	magic_circle.rotation = 0.0
	play_idle()

func get_portrait_texture() -> Texture2D:
	return body.texture

func _on_animation_finished(animation_name: StringName) -> void:
	if animation_name in [&"hit", &"cast"]:
		play_idle()

func _draw() -> void:
	if _defeated:
		return
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.22))
	draw_circle(Vector2.ZERO, visual_height * 0.22, Color(0.01, 0.02, 0.06, 0.42))

func _exit_tree() -> void:
	if motion != null and motion.is_running():
		motion.kill()
