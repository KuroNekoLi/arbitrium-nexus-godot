extends SceneTree
## V2.3 non-interactive true-render screenshots, not exhausted P4.4 input suite.
const Scene = preload("res://scenes/battle/battle_screen.tscn")
const Writer = preload("res://scripts/qa/screenshot_writer.gd")
const Encounter = preload("res://tests/fixtures/m5_full_battle_fixture.gd")
var writer = Writer.new()
var prefix: String = ""
var executed: int = 0
var failed: int = 0
var cases: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, id: String) -> void:
	executed += 1
	if not value:
		failed += 1
	print(("PASS " if value else "FAIL ") + id)

func hand_fixture(count: int) -> Dictionary:
	var snapshot: Dictionary = Encounter.initial()
	var zones: Dictionary = snapshot["core"]["cards"]["actors"]["A"]["zones"]
	while zones["hand"].size() > count:
		zones["draw"].append(zones["hand"].pop_back())
	while zones["hand"].size() < count and not zones["draw"].is_empty():
		zones["hand"].append(zones["draw"].pop_back())
	return snapshot

func bounds(node: Control) -> Dictionary:
	var rect: Rect2 = node.get_global_rect()
	return {"x": snappedf(rect.position.x, 0.1), "y": snappedf(rect.position.y, 0.1),
		"w": snappedf(rect.size.x, 0.1), "h": snappedf(rect.size.y, 0.1)}

func layout(hud: Control) -> Dictionary:
	var found: Dictionary = {}
	for path: String in ["TopBar", "TopBar/ResourcePanel", "TopBar/PhasePanel",
		"TopBar/UtilityPanel", "PartyStatusPanel", "Commands", "EnemyStatus",
		"Context", "BattleLogPanel", "HandView"]:
		found[path] = bounds(hud.get_node(path))
	found["Context/Confirm"] = bounds(hud.confirm_button)
	found["CardCount"] = hud.card_views.size()
	found["ConditionsVisible"] = hud.get_node("Conditions").visible
	return found

func shot(screen: Control, name: String, resolution: Vector2i, locale: String,
	count: int, select_card: bool) -> void:
	root.size = resolution
	screen.set_locale(locale)
	screen.select_actor("A")
	screen.present(hand_fixture(count))
	if select_card and not screen.hud.card_views.is_empty():
		screen.select_card(str(screen.hud.card_views[0].instance_id))
	await create_timer(0.4).timeout
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	check(image != null and not image.is_empty(), "V23-IMAGE-" + name)
	if image == null or image.is_empty():
		return
	check(image.get_size() == resolution, "V23-DIMENSIONS-" + name)
	var result: Dictionary = writer.write_png(image, name, prefix)
	check(bool(result.get("ok", false)), "V23-WRITER-" + name)
	var info: Dictionary = {"id": name, "viewport": [resolution.x, resolution.y],
		"observed_image": [image.get_width(), image.get_height()],
		"locale": locale, "hand_count": count, "selected": select_card,
		"write": result.get("stage", ""), "ok": result.get("ok", false),
		"layout": layout(screen.hud)}
	cases.append(info)
	print("V23_CAPTURE " + JSON.stringify(info))
	if name in ["v23_idle_1280_zh", "v23_selected_1280_zh"]:
		var thumbnail: Image = image.duplicate()
		thumbnail.resize(640, 360, Image.INTERPOLATE_LANCZOS)
		var p: String = str(result.get("path", "")).get_base_dir().path_join(name + "_thumb.jpg")
		check(thumbnail.save_jpg(p, 0.68) == OK, "V23-THUMB-" + name)

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("V2.3 requires real rendering, never --headless.")
		quit(1)
		return
	var opt: Dictionary = Writer.prefix_from_args(OS.get_cmdline_user_args())
	prefix = str(opt.get("prefix", ""))
	if not opt.get("ok", false) or prefix.is_empty():
		push_error("V2.3 requires unique --capture-prefix.")
		quit(1)
		return
	root.size = Vector2i(1280, 720)
	var screen: Control = Scene.instantiate()
	root.add_child(screen)
	await create_timer(0.5).timeout
	await shot(screen, "v23_idle_1280_zh", Vector2i(1280, 720), "zh_TW", 4, false)
	await shot(screen, "v23_idle_1920_zh", Vector2i(1920, 1080), "zh_TW", 4, false)
	await shot(screen, "v23_idle_1280_en", Vector2i(1280, 720), "en", 4, false)
	await shot(screen, "v23_idle_1920_en", Vector2i(1920, 1080), "en", 4, false)
	await shot(screen, "v23_selected_1280_zh", Vector2i(1280, 720), "zh_TW", 4, true)
	await shot(screen, "v23_hand8_1280_zh", Vector2i(1280, 720), "zh_TW", 8, false)
	await shot(screen, "v23_hand8_1920_en", Vector2i(1920, 1080), "en", 8, false)
	await shot(screen, "v23_hand1_1280_zh", Vector2i(1280, 720), "zh_TW", 1, false)
	await shot(screen, "v23_hand0_1280_zh", Vector2i(1280, 720), "zh_TW", 0, false)
	var directory: String = ProjectSettings.globalize_path(Writer.OUTPUT_SCOPE).path_join(prefix)
	var f: FileAccess = FileAccess.open(directory.path_join("v23_capture_manifest.json"), FileAccess.WRITE)
	check(f != null, "V23-MANIFEST")
	if f != null:
		f.store_string(JSON.stringify({"display_server": DisplayServer.get_name(),
			"godot": str(Engine.get_version_info().get("string", "")), "cases": cases}, "\t"))
		f.close()
	screen.queue_free()
	await process_frame
	print("V23_CAPTURE_REPORT executed=%d passed=%d failed=%d" % [executed, executed - failed, failed])
	quit(0 if failed == 0 else 1)

