extends SceneTree
## New static Lv40 scene evidence only. No mouse/keyboard or legacy GUI assertions.
const Scene = preload("res://scenes/battle/lv40_playable_battle.tscn")
const Writer = preload("res://scripts/qa/screenshot_writer.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Static scene evidence requires a real renderer")
		quit(1)
		return
	var prefix: String = "p45_static_"+str(OS.get_process_id())+"_"+str(Time.get_ticks_usec())
	var writer = Writer.new()
	var failed: bool = false
	for dimensions: Vector2i in [Vector2i(1280,720),Vector2i(1920,1080)]:
		root.size = dimensions
		var screen: Control = Scene.instantiate()
		root.add_child(screen)
		await process_frame
		if dimensions.x == 1920: screen.set_locale("en")
		await create_timer(0.35).timeout
		await RenderingServer.frame_post_draw
		var result: Dictionary = writer.write_png(root.get_texture().get_image(),"lv40_"+str(dimensions.x),prefix)
		print("P45_STATIC_SCENE ",JSON.stringify(result))
		failed = failed or not result["ok"]
		screen.queue_free()
		await process_frame
	quit(1 if failed else 0)
