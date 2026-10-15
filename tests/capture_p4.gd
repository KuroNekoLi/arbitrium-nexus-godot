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
		var path: String = "res://outputs/p4_2_%d_zh.png" % dims.x
		var result: int = root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
		if result != OK:
			quit(1)
			return
		print("CAPTURE ", path)
	screen.set_locale("en")
	root.size = Vector2i(1280,720)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://outputs/p4_2_1280_en.png"))
	var eight: Dictionary = screen.snapshot.duplicate(true)
	var zones: Dictionary = eight["core"]["cards"]["actors"]["A"]["zones"]
	for i: int in 4: zones["hand"].append(zones["draw"].pop_back())
	screen.present(eight)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://outputs/p4_2_eight_cards.png"))
	screen.queue_free()
	await process_frame
	quit(0)
