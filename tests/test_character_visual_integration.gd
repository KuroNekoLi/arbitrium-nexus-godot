extends SceneTree
## Native render evidence for the integrated appearances, not historical GUI QA.
const Scene = preload("res://scenes/battle/lv40_playable_battle.tscn")
const Writer = preload("res://scripts/qa/screenshot_writer.gd")
var failed: int = 0
var checks: int = 0
var prefix: String

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, id: String) -> void:
	checks += 1
	if not ok: failed += 1
	print(("PASS " if ok else "FAIL ") + id)

func capture(label: String) -> void:
	await create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	var result: Dictionary = Writer.new().write_png(root.get_texture().get_image(), label, prefix)
	print("CHARACTER_CAPTURE ", JSON.stringify(result))
	check(result.ok, label)

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Native renderer required")
		quit(1)
		return
	prefix = "character_merge_" + str(OS.get_process_id())
	var screen: Control = Scene.instantiate()
	root.add_child(screen)
	await process_frame
	screen.director.reduced_motion = true
	for resolution: Vector2i in [Vector2i(1280,720), Vector2i(1920,1080)]:
		root.size = resolution
		for locale: String in ["zh_TW","en"]:
			screen.set_locale(locale)
			await capture("idle_"+str(resolution.x)+"_"+locale)
	root.size = Vector2i(1280,720)
	screen.set_locale("zh_TW")
	for actor: String in ["A","B","C"]:
		screen.select_actor(actor)
		screen._command_requested("ACTIVATE_LAST_SPELL_M4", {})
		check(screen.hud.last_preview.visible, "CUTIN-"+actor)
		await capture("last_"+actor)
		screen.cancel_action()
	var hp: int = screen.snapshot.core.battle.actors.Boss.hp
	screen._command_requested("BASIC_ATTACK_RESOURCE_ONLY", {})
	check(screen.snapshot.core.battle.actors.Boss.hp < hp, "REAL-M5-BASIC")
	await create_timer(0.9).timeout
	await capture("real_event_log")
	screen.director.skip_all()
	check(screen.director.pending_timers.is_empty(), "SKIP-DRAINS-WAITS")
	screen.director.reduced_motion = false
	screen._command_requested("BASIC_ATTACK_RESOURCE_ONLY", {})
	check(not screen.director.pending_timers.is_empty(), "LIVE-WINDUP-BEFORE-EXIT")
	var director: Node = screen.director
	screen.remove_child(director)
	check(director.pending_timers.is_empty() and not director.playing, "EXIT-DRAINS-WAITS")
	director.free()
	screen.queue_free()
	await process_frame
	await process_frame
	print("CHARACTER_VISUAL_REPORT executed=%d passed=%d failed=%d" % [checks, checks-failed, failed])
	quit(0 if failed == 0 else 1)
