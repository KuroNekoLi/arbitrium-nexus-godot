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


## An independent Godot visual object: the caster remains at its home slot.
## Kenney Particle Pack sprites (already vendored, CC0); no collision or damage.
func launch_projectile(start: Vector2, target: Vector2, style: String) -> void:
	var registry := preload("res://scripts/battle/presentation/spell_animation_catalog.gd")
	var texture: Texture2D = registry.projectile_texture(style)
	if reduced_motion:
		burst(target,true,registry.tint(style))
		return
	var projectile := Sprite2D.new()
	projectile.name = "SpellProjectile"
	projectile.texture = texture
	projectile.position = start
	projectile.z_index = 5
	projectile.modulate = registry.tint(style)
	projectile.scale = Vector2.ONE * (62.0 / maxf(1.0,float(maxi(texture.get_width(),texture.get_height()))))
	projectile.rotation = (target-start).angle()
	projectile.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	projectile.material = material
	add_child(projectile)
	var glow := Sprite2D.new()
	glow.name = "SpellCore"
	glow.texture = preload("res://addons/kenney_particle_pack/circle_04.png")
	glow.modulate = Color(registry.tint(style),0.62)
	glow.scale = Vector2.ONE * (38.0 / maxf(1.0,float(maxi(glow.texture.get_width(),glow.texture.get_height()))))
	projectile.add_child(glow)
	var tween: Tween = projectile.create_tween().set_parallel(true)
	tween.tween_property(projectile,"position",target,0.34).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(projectile,"rotation",projectile.rotation+PI*0.3,0.34)
	tween.chain().tween_callback(projectile.queue_free)

func casting_pulse(point: Vector2, style: String) -> void:
	var registry := preload("res://scripts/battle/presentation/spell_animation_catalog.gd")
	burst(point,true,registry.tint(style))

func support_pulse(point: Vector2, style: String) -> void:
	var registry := preload("res://scripts/battle/presentation/spell_animation_catalog.gd")
	burst(point,true,registry.tint(style))

func clear_effects() -> void:
	for child: Node in get_children():
		if child is AudioStreamPlayer: child.stop()
		else: child.queue_free()
