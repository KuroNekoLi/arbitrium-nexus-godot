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
		else: child.free() # Skip disposes temporary effects and their tweens immediately.

## Replaceable placeholder cut-in using existing character CG. No AI asset
## is required for gameplay; timings and appearance never drive the reducer.
func show_combo(setup: String, finisher: String, name_key: String) -> void:
	var panel := PanelContainer.new()
	panel.name = "ComboPlaceholderCutIn"
	panel.position = Vector2(330,145)
	panel.size = Vector2(590,230)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
	panel.z_index = 150
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04,0.025,0.1,0.95)
	style.border_color = Color("d9b46d")
	style.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel",style)
	add_child(panel)
	var row := HBoxContainer.new()
	panel.add_child(row)
	for actor: String in [setup,finisher]:
		var cg := TextureRect.new()
		cg.texture = preload("res://scripts/battle/presentation/character_appearance_registry.gd").cg_for(actor)
		cg.custom_minimum_size = Vector2(155,225)
		cg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		cg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(cg)
		if actor == setup:
			var label := Label.new()
			label.text = tr(name_key)+"\n"+tr("CP2_SUCCESS")
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			label.custom_minimum_size.x = 260
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.add_theme_font_size_override("font_size",24)
			label.add_theme_color_override("font_color",Color("e1beff"))
			row.add_child(label)
	var tween: Tween = panel.create_tween()
	tween.tween_interval(0.8 if reduced_motion else 1.4)
	tween.tween_property(panel,"modulate:a",0.0,0.2)
	tween.tween_callback(panel.queue_free)
