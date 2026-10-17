extends SceneTree
## Verify the production encounter's hit regions cover its visible actors.
const Battle = preload("res://scenes/battle/lv40_playable_battle.tscn")
const Model = preload("res://scripts/domain/m1/combat_model.gd")
var executed: int = 0
var failed: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, case_id: String) -> void:
	executed += 1
	if not ok:
		failed += 1
	print(("PASS " if ok else "FAIL ") + case_id)

func run() -> void:
	var screen: Control = Battle.instantiate()
	root.add_child(screen)
	check(screen.hud.feedback.text.is_empty(), "TARGET-RUNTIME-NO-EDITOR-LABEL")
	var before: String = Model.state_hash(screen.snapshot)
	for resolution: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = resolution
		if DisplayServer.get_name() != "headless":
			DisplayServer.window_set_size(resolution)
		await process_frame
		await process_frame
		for id: String in ["A", "B", "C", "Boss"]:
			var actor: Node2D = screen.get_node("Design/Arena/" + id)
			var region: Control = actor.get_node("TargetRegion")
			var art: Sprite2D = actor.body if id == "Boss" else actor.state_cg
			var center: Vector2 = art.get_global_transform() * art.get_rect().get_center()
			var hit: Rect2 = screen.hud.target_buttons[id].get_global_rect()
			check(hit.has_point(center), "TARGET-COVERS-VISIBLE-" + id + "-" + str(resolution.x))
			check(hit.position.is_equal_approx(region.get_global_rect().position) and
				hit.size.is_equal_approx(region.get_global_rect().size),
				"TARGET-FOLLOWS-AUTHORED-" + id + "-" + str(resolution.x))
		check(Model.state_hash(screen.snapshot) == before, "TARGET-NO-DOMAIN-WRITE-" + str(resolution.x))
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			var image: Image = root.get_texture().get_image()
			var directory: String = OS.get_environment("ARBITRIUM_REVIEW_EVIDENCE")
			check(not directory.is_empty() and image != null and not image.is_empty() and
				image.get_size() == resolution and
				image.save_png(directory.path_join("authored_battle_%d.png" % resolution.x)) == OK,
				"TARGET-REAL-GODOT-PNG-" + str(resolution.x))
	screen.queue_free()
	await process_frame
	print("AUTHORED_TARGET_REPORT executed=%d passed=%d failed=%d" % [executed, executed - failed, failed])
	quit(0 if failed == 0 else 1)
