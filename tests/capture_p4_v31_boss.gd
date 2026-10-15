extends SceneTree
## V3.1 true-render-only projection fixture; NEVER a replacement for Domain rules.
const Scene = preload("res://scenes/battle/battle_screen.tscn")
const Writer = preload("res://scripts/qa/screenshot_writer.gd")
const Model = preload("res://scripts/domain/m1/combat_model.gd")
var writer = Writer.new()
var passed: int = 0
var failed: int = 0
var prefix: String = ""
var captures: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, id: String) -> void:
	if ok: passed += 1
	else: failed += 1
	print(("PASS " if ok else "FAIL ") + id)

func _capture(screen: Control, label: String, resolution: Vector2i, locale: String,
	gauge: int, locked: bool, exposed: bool) -> void:
	root.size = resolution
	screen.set_locale(locale)
	var vm: Dictionary = screen.hud.vm.duplicate(true)
	var panel: Control = screen.hud.get_node("EnemyStatus")
	vm["tactical"] = {
		"break_gauge": gauge, "break_max": 80, "break_locked": locked,
		"exposed": {"Boss": true} if exposed else {}
	}
	# Projection fixture only. screen.snapshot/Controller/Domain are NOT changed.
	var hash: String = Model.state_hash(screen.snapshot)
	panel.render_enemy(vm)
	await create_timer(0.25).timeout
	await RenderingServer.frame_post_draw
	check(Model.state_hash(screen.snapshot) == hash, "V31-RENDER-NO-DOMAIN-" + label)
	check(panel.break_bar.visible and panel.break_stats.visible, "V31-BREAK-VISIBLE-" + label)
	check(is_equal_approx(float(panel.break_bar.value), float(gauge)), "V31-BREAK-VALUE-" + label)
	var image: Image = root.get_texture().get_image()
	check(image != null and image.get_size() == resolution, "V31-BREAK-IMAGE-" + label)
	if image == null:
		return
	var result: Dictionary = writer.write_png(image, label, prefix)
	check(result.get("ok", false), "V31-BREAK-WRITE-" + label)
	var rect: Rect2 = panel.get_global_rect()
	var intent_rect: Rect2 = panel.intent.get_global_rect()
	check(intent_rect.end.y <= rect.end.y + 1.0, "V31-INTENT-WITHIN-PANEL-" + label)
	var info: Dictionary = {
		"id": label, "projection_fixture_only": true, "locale": locale,
		"viewport": [resolution.x, resolution.y], "gauge": gauge,
		"locked": locked, "exposed": exposed,
		"break_text": panel.break_stats.text, "write": result.get("stage", ""),
		"intent_bottom": intent_rect.end.y, "panel_bottom": rect.end.y
	}
	captures.append(info)
	print("V31_BOSS_CAPTURE " + JSON.stringify(info))
	if label == "v31_boss_break_1280_zh":
		var thumb: Image = image.duplicate()
		thumb.resize(640, 360, Image.INTERPOLATE_LANCZOS)
		var p: String = str(result.get("path", "")).get_base_dir().path_join("v31_boss_break_thumb.jpg")
		check(thumb.save_jpg(p, 0.72) == OK, "V31-BREAK-THUMB")

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Requires true rendered Godot viewport, not --headless.")
		quit(1)
		return
	var opt: Dictionary = Writer.prefix_from_args(OS.get_cmdline_user_args())
	prefix = str(opt.get("prefix", ""))
	if not opt.get("ok", false) or prefix.is_empty():
		push_error("Unique --capture-prefix= token required")
		quit(1)
		return
	root.size = Vector2i(1280, 720)
	var screen: Control = Scene.instantiate()
	root.add_child(screen)
	await create_timer(0.45).timeout
	await _capture(screen, "v31_boss_break_1280_zh", Vector2i(1280, 720), "zh_TW", 30, false, false)
	await _capture(screen, "v31_boss_locked_1280_zh", Vector2i(1280, 720), "zh_TW", 0, true, true)
	await _capture(screen, "v31_boss_break_1920_en", Vector2i(1920, 1080), "en", 62, false, false)
	var folder: String = ProjectSettings.globalize_path(Writer.OUTPUT_SCOPE).path_join(prefix)
	var f: FileAccess = FileAccess.open(folder.path_join("v31_boss_projection_fixture_manifest.json"), FileAccess.WRITE)
	check(f != null, "V31-BREAK-MANIFEST")
	if f != null:
		f.store_string(JSON.stringify({"fixture":"MOCK_ONLY / projection layout", "cases":captures}, "\t"))
		f.close()
	screen.queue_free()
	await process_frame
	print("V31_BOSS_RENDER_REPORT executed=%d passed=%d failed=%d" % [passed+failed, passed, failed])
	quit(0 if failed == 0 else 1)

