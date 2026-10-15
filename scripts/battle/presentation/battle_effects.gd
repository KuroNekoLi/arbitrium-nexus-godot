extends Control
## Short-lived Kenney texture effects. Owns no combat references.
const MAGIC: Texture2D = preload("res://addons/kenney_particle_pack/magic_01.png")
const SLASH: Texture2D = preload("res://addons/kenney_particle_pack/slash_01.png")
var reduced_motion: bool = false
var audio_enabled: bool = true
var voices: Array[AudioStreamPlayer] = []
var voice_index: int = 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i: int in 4:
		var player := AudioStreamPlayer.new()
		player.volume_db = -20
		add_child(player)
		voices.append(player)

func sound(magic: bool) -> void:
	if not audio_enabled: return
	var player: AudioStreamPlayer = voices[voice_index]
	voice_index = (voice_index+1)%voices.size()
	player.stream = preload("res://addons/kenney_ui_audio/click2.wav") if magic else preload("res://addons/kenney_rpg_audio/knifeSlice.ogg")
	player.play()

func burst(point: Vector2, magic: bool, tint: Color = Color.WHITE) -> void:
	var sprite := TextureRect.new()
	sprite.texture = MAGIC if magic else SLASH
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.size = Vector2(90,90) if reduced_motion else Vector2(150,150)
	sprite.position = point-sprite.size*0.5
	sprite.pivot_offset = sprite.size*0.5
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sprite.modulate = tint
	add_child(sprite)
	var tween: Tween = sprite.create_tween()
	if not reduced_motion: tween.tween_property(sprite,"scale",Vector2(1.3,1.3),0.12)
	tween.tween_property(sprite,"modulate:a",0.0,0.25)
	tween.tween_callback(sprite.queue_free)

func clear_effects() -> void:
	for child: Node in get_children():
		if child is AudioStreamPlayer: child.stop()
		else: child.queue_free()
