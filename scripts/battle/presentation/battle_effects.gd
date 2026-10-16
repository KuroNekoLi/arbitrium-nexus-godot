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

## Candidate Combo UI cut-in (assets/ui/combo, CANDIDATE manifest). Three
## texture layers around the existing character CG; no new character art.
## Played only from accepted receipts after the Domain already resolved the
## combo. Timings and visuals never feed back into the reducer.
const CUTIN_BACKGROUND: Texture2D = preload("res://assets/ui/combo/combo_cutin_background.png")
const CUTIN_FRAME: Texture2D = preload("res://assets/ui/combo/combo_cutin_frame.png")
const CUTIN_ENERGY: Texture2D = preload("res://assets/ui/combo/combo_cutin_energy.png")
const COMBO_OFFENSE_SHEET: Texture2D = preload("res://assets/ui/combo/combo_offense_impact_sheet.png")
const COMBO_DEFENSE_SHEET: Texture2D = preload("res://assets/ui/combo/combo_defense_barrier_sheet.png")
const CUTIN_RECT: Rect2 = Rect2(330, 145, 590, 230) # 1180x460 source at 0.5x
const CUTIN_HOLD_NORMAL: float = 1.4
const CUTIN_HOLD_REDUCED: float = 0.8
const CUTIN_FADE: float = 0.2
## Sheet contract from asset_manifest.json: 4x4, 256px cells, 12 fps.
const SHEET_COLUMNS: int = 4
const SHEET_ROWS: int = 4
const SHEET_CELL: int = 256
const SHEET_FPS: float = 12.0
const SHEET_STATIC_FRAME: int = 7 # inside impact 4-11, used for reduced motion

func show_combo(setup: String, finisher: String, name_key: String) -> void:
	skip_combo()
	var root := Control.new()
	root.name = "ComboCutIn"
	root.position = CUTIN_RECT.position
	root.size = CUTIN_RECT.size
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
	root.z_index = 150
	add_child(root)
	_cutin_layer(root, "Background", CUTIN_BACKGROUND)
	var registry := preload("res://scripts/battle/presentation/character_appearance_registry.gd")
	# Left/right wells of the frame (310/1180 => 155px each at 0.5x).
	var wells: Array[Rect2] = [Rect2(6, 4, 149, 222), Rect2(435, 4, 149, 222)]
	var actors: Array[String] = [setup, finisher]
	for i: int in 2:
		# Clipping well: show the existing full-body CG at bust framing.
		var well := Control.new()
		well.name = "SetupWell" if i == 0 else "FinisherWell"
		well.clip_contents = true
		well.mouse_filter = Control.MOUSE_FILTER_IGNORE
		well.position = wells[i].position
		well.size = wells[i].size
		root.add_child(well)
		var cg := TextureRect.new()
		cg.name = "SetupCG" if i == 0 else "FinisherCG"
		# expand_mode first, otherwise size is clamped to the texture size.
		cg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		cg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		cg.texture = registry.cg_for(actors[i])
		var bust: Vector2 = Vector2(wells[i].size.x * 1.7, wells[i].size.x * 1.7 * 1.5)
		cg.size = bust
		cg.position = Vector2((wells[i].size.x - bust.x) * 0.5, -6)
		cg.flip_h = i == 1
		cg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		well.add_child(cg)
	var label := Label.new()
	label.name = "ComboTitle"
	label.text = tr(name_key) + "\n" + tr("CP2_SUCCESS")
	label.position = Vector2(163, 20)
	label.size = Vector2(264, 190)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", Color("f3e2ff"))
	label.add_theme_color_override("font_outline_color", Color("1a0b2e"))
	label.add_theme_constant_override("outline_size", 6)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(label)
	var energy: TextureRect = _cutin_layer(root, "Energy", CUTIN_ENERGY)
	_cutin_layer(root, "Frame", CUTIN_FRAME)
	var tween: Tween = root.create_tween()
	if reduced_motion:
		# Static: no slide, no shimmer, no scale.
		tween.tween_interval(CUTIN_HOLD_REDUCED)
	else:
		root.modulate.a = 0.0
		tween.tween_property(root, "modulate:a", 1.0, 0.12)
		var shimmer: Tween = energy.create_tween().set_loops(3).set_trans(Tween.TRANS_SINE)
		shimmer.tween_property(energy, "modulate:a", 0.55, 0.23)
		shimmer.tween_property(energy, "modulate:a", 1.0, 0.23)
		tween.tween_interval(CUTIN_HOLD_NORMAL - 0.12)
	tween.tween_property(root, "modulate:a", 0.0, CUTIN_FADE)
	tween.tween_callback(root.queue_free)

func _cutin_layer(parent: Control, layer_name: String, texture: Texture2D) -> TextureRect:
	var layer := TextureRect.new()
	layer.name = layer_name
	layer.texture = texture
	layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	layer.stretch_mode = TextureRect.STRETCH_SCALE
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(layer)
	return layer

## Skip only the cut-in (the global Skip control uses clear_effects()).
func skip_combo() -> void:
	var existing: Node = get_node_or_null("ComboCutIn")
	if existing != null:
		remove_child(existing)
		existing.queue_free()

## ComboExecuted follow-up VFX. `center` is the recipient body centre and
## `body_height` its visual height. No full-screen flash is ever drawn; the
## defensive ring has a transparent interior so the silhouette stays visible.
func combo_cutin_duration() -> float:
	return (CUTIN_HOLD_REDUCED if reduced_motion else CUTIN_HOLD_NORMAL) + CUTIN_FADE

## `delay` sequences the VFX after the cut-in so the arena is not covered.
func combo_vfx(center: Vector2, defense: bool, body_height: float, delay: float = 0.0) -> Node2D:
	var sheet: Texture2D = COMBO_DEFENSE_SHEET if defense else COMBO_OFFENSE_SHEET
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	frames.add_animation(&"combo")
	frames.set_animation_loop(&"combo", false)
	frames.set_animation_speed(&"combo", SHEET_FPS)
	for index: int in SHEET_COLUMNS * SHEET_ROWS:
		var cell := AtlasTexture.new()
		cell.atlas = sheet
		var column: int = index % SHEET_COLUMNS
		var row: int = floori(float(index) / float(SHEET_COLUMNS))
		cell.region = Rect2(column * SHEET_CELL, row * SHEET_CELL, SHEET_CELL, SHEET_CELL)
		frames.add_frame(&"combo", cell)
	var sprite := AnimatedSprite2D.new()
	sprite.name = "ComboDefenseBarrier" if defense else "ComboOffenseImpact"
	sprite.sprite_frames = frames
	sprite.animation = &"combo"
	sprite.position = center
	sprite.z_index = 6
	# Defense ring outer diameter ~1.25x body; offense burst ~0.9x body.
	var diameter: float = clampf(body_height * (1.25 if defense else 0.9), 120.0, 340.0)
	sprite.scale = Vector2.ONE * (diameter / float(SHEET_CELL))
	sprite.modulate = Color(1, 1, 1, 0.82 if defense else 1.0)
	if not defense:
		var material := CanvasItemMaterial.new()
		material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		sprite.material = material
	sprite.visible = false
	add_child(sprite)
	var sequence: Tween = sprite.create_tween()
	if delay > 0.0: sequence.tween_interval(delay)
	if reduced_motion:
		# Static impact frame, fixed position/scale, short fade.
		sequence.tween_callback(func() -> void:
			sprite.frame = SHEET_STATIC_FRAME
			sprite.visible = true)
		sequence.tween_interval(0.5)
		sequence.tween_property(sprite, "modulate:a", 0.0, CUTIN_FADE)
		sequence.tween_callback(sprite.queue_free)
	else:
		sprite.animation_finished.connect(sprite.queue_free)
		sequence.tween_callback(func() -> void:
			sprite.visible = true
			sprite.play(&"combo"))
	return sprite
