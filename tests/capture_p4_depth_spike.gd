extends SceneTree
## Disposable rendering comparison, never a battle entrypoint.
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1280,720)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 8.0
	camera.position = Vector3(0,0,10)
	viewport.add_child(camera)
	var background := Sprite3D.new()
	background.texture = load("res://assets/battlefield_bg.png")
	background.pixel_size = 8.0 / 941.0
	background.position.z = -1
	viewport.add_child(background)
	var entries: Array = [
		["res://assets/yora_atlas.png",Vector2(549,388),163.0,false],
		["res://assets/kleya_atlas.png",Vector2(497,421),180.0,false],
		["res://assets/nova_atlas.png",Vector2(438,458),200.0,false],
		["res://assets/nexus_party_splash.png",Vector2(845,455),325.0,true]]
	for i: int in entries.size():
		var entry: Array = entries[i]
		var art: Texture2D = load(entry[0])
		var region := AtlasTexture.new()
		region.atlas = art
		region.region = Rect2(960,0,art.get_width()-960,art.get_height()) if entry[3] else Rect2(Vector2.ZERO,art.get_size()/3.0)
		var sprite := Sprite3D.new()
		sprite.texture = region
		sprite.pixel_size = float(entry[2]) / region.get_height() / 90.0
		sprite.position = Vector3((entry[1].x-640)/90.0,(360-entry[1].y+float(entry[2])/2)/90.0,float(i)*0.01)
		viewport.add_child(sprite)
	for i: int in 10: await process_frame
	await RenderingServer.frame_post_draw
	var result: int = viewport.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://outputs/p4_1_sprite3d_spike.png"))
	print("P41_SPRITE3D_SPIKE renderer=Compatibility viewport=1280x720 draw_calls=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	viewport.queue_free()
	await process_frame
	quit(0 if result == OK else 1)
