extends SceneTree
const Scene = preload("res://scenes/battle/battle_screen.tscn")
func _initialize() -> void:
	call_deferred("capture")
func capture() -> void:
	var screen: Control = Scene.instantiate()
	root.add_child(screen)
	for dims: Vector2i in [Vector2i(1280,720),Vector2i(1920,1080)]:
		root.size = dims
		await process_frame
		await RenderingServer.frame_post_draw
		var path: String = "res://outputs/p4_1_%d.png" % dims.x
		var result: int = root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
		if result != OK:
			quit(1)
			return
		print("CAPTURE ", path)
	screen.queue_free()
	await process_frame
	quit(0)
