extends Node2D
## Shared presentation layer for combat audio and lightweight sprite-particle effects.

const SLASH_TEXTURE: Texture2D = preload("res://addons/kenney_particle_pack/slash_02.png")
const MAGIC_TEXTURE: Texture2D = preload("res://addons/kenney_particle_pack/magic_03.png")
const SPARK_TEXTURE: Texture2D = preload("res://addons/kenney_particle_pack/spark_02.png")
const UI_CLICK: AudioStream = preload("res://addons/kenney_ui_audio/click1.wav")
const UI_PICK: AudioStream = preload("res://addons/kenney_ui_audio/switch3.wav")
const UI_HOVER: AudioStream = preload("res://addons/kenney_ui_audio/rollover2.wav")
const RPG_SWISH: AudioStream = preload("res://addons/kenney_rpg_audio/knifeSlice.ogg")
const RPG_IMPACT: AudioStream = preload("res://addons/kenney_rpg_audio/chop.ogg")

func play_ui(kind: String = "click") -> void:
	var stream: AudioStream = UI_CLICK
	if kind == "pick":
		stream = UI_PICK
	elif kind == "hover":
		stream = UI_HOVER
	_play_stream(stream, -12.0)

func play_slash(center: Vector2, color: Color) -> void:
	_spawn_sprite(SLASH_TEXTURE, center, color, Vector2(0.025, 0.09), Vector2(0.28, 0.16), -0.32, 0.2)
	_spawn_sparks(center, color, 7)
	_play_stream(RPG_SWISH, -7.0)

func play_magic(center: Vector2, color: Color, interrupt: bool = false) -> void:
	var texture := MAGIC_TEXTURE if not interrupt else SPARK_TEXTURE
	_spawn_sprite(texture, center, color, Vector2(0.05, 0.05), Vector2(0.34, 0.34), 0.0, 0.36)
	_spawn_sparks(center, color, 7 if not interrupt else 12)

func play_enemy_hit() -> void:
	_play_stream(RPG_IMPACT, -5.0)

func _spawn_sprite(texture: Texture2D, center: Vector2, color: Color, start_scale: Vector2, end_scale: Vector2, rotation: float, duration: float) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.position = center
	sprite.modulate = color
	sprite.scale = start_scale
	sprite.rotation = rotation
	sprite.z_index = 28
	add_child(sprite)
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "scale", end_scale, duration)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, duration)
	tween.tween_callback(sprite.queue_free)

func _spawn_sparks(center: Vector2, color: Color, count: int) -> void:
	var particles := GPUParticles2D.new()
	particles.position = center
	particles.texture = SPARK_TEXTURE
	particles.amount = count
	particles.lifetime = 0.42
	particles.one_shot = true
	particles.explosiveness = 0.92
	particles.z_index = 29
	particles.visibility_rect = Rect2(-180, -180, 360, 360)
	var material := ParticleProcessMaterial.new()
	material.direction = Vector3(0, -1, 0)
	material.spread = 180.0
	material.initial_velocity_min = 28.0
	material.initial_velocity_max = 92.0
	material.gravity = Vector3(0, 18, 0)
	material.scale_min = 0.055
	material.scale_max = 0.16
	material.color = color
	particles.process_material = material
	add_child(particles)
	particles.finished.connect(particles.queue_free)
	particles.emitting = true

func _play_stream(stream: AudioStream, volume_db: float) -> void:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
