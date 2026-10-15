extends SceneTree
const Scene = preload("res://scenes/battle/battle_screen.tscn")
const Model = preload("res://scripts/domain/m1/combat_model.gd")
var failures: int = 0
var executed: int = 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, id: String) -> void:
	executed += 1
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ") + id)
func run() -> void:
	var screen: Control = Scene.instantiate()
	root.add_child(screen)
	await process_frame
	check(screen.get_node("Design/Arena").get_child_count() == 4, "P41-SCENE-01-FOUR_ACTORS")
	check(screen.view_model["hands"].size() == 3, "P41-SCENE-02-REAL_PARTY")
	check(screen.view_model["resources"]["current_ap"] == 6, "P41-SCENE-03-DOMAIN_AP")
	check(screen.get_node("Design/Arena/A").body.sprite_frames.get_frame_count("idle") == 3, "P41-SCENE-04-ATLAS_ANIMATION")
	for dims: Vector2i in [Vector2i(1280,720), Vector2i(1920,1080)]:
		root.size = dims
		await process_frame
		check(screen.design.scale.x > 0, "P41-SCENE-05-SIZE-" + str(dims.x))
	var old: WeakRef = weakref(screen)
	screen.queue_free()
	await process_frame
	check(old.get_ref() == null, "P41-SCENE-06-CLEANUP")
	screen = Scene.instantiate()
	root.add_child(screen)
	await process_frame
	check(screen.view_model["event_seq"] == 0, "P41-SCENE-07-FRESH_REENTRY")
	screen.queue_free()
	await process_frame
	print("P4_1_REPORT executed=%d passed=%d failed=%d" % [executed, executed-failures, failures])
	quit(0 if failures == 0 else 1)
