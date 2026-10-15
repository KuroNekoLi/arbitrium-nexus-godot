extends SceneTree
## V3.5.5 true-render HUD evidence (VIS01–VIS10). Requires a real display
## server; never --headless. MOCK_ONLY cases are labelled in the manifest and
## never reach the Domain. Real-event cases go through BattleController.
const Scene = preload("res://scenes/battle/battle_screen.tscn")
const Writer = preload("res://scripts/qa/screenshot_writer.gd")
const Encounter = preload("res://tests/fixtures/m5_full_battle_fixture.gd")
const Factory = preload("res://scripts/battle/battle_command_factory.gd")
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
	for path: String in ["TopBar", "TopBar/ResourcePanel", "PartyStatusPanel", "Commands",
		"EnemyStatus", "Context", "BattleLogPanel", "HandView"]:
		found[path] = bounds(hud.get_node(path))
	return found

func capture(screen: Control, name: String, kind: String, extra: Dictionary = {}) -> void:
	await create_timer(0.35).timeout
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	check(image != null and not image.is_empty(), "V35V-IMAGE-" + name)
	if image == null or image.is_empty():
		return
	check(image.get_size() == root.size, "V35V-DIMENSIONS-" + name)
	var result: Dictionary = writer.write_png(image, name, prefix)
	check(bool(result.get("ok", false)), "V35V-WRITER-" + name)
	var info: Dictionary = {"id": name, "kind": kind, "viewport": [root.size.x, root.size.y],
		"locale": TranslationServer.get_locale(), "path": str(result.get("path", "")),
		"layout": layout(screen.hud)}
	info.merge(extra)
	cases.append(info)
	print("V35_CAPTURE " + JSON.stringify(info))

func stage(screen: Control, resolution: Vector2i, locale: String, count: int) -> void:
	root.size = resolution
	screen.set_locale(locale)
	screen.select_actor("A")
	screen.present(hand_fixture(count))
	await process_frame

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("V3.5.5 capture requires real rendering, never --headless.")
		quit(1)
		return
	var opt: Dictionary = Writer.prefix_from_args(OS.get_cmdline_user_args())
	prefix = str(opt.get("prefix", ""))
	if not opt.get("ok", false) or prefix.is_empty():
		push_error("V3.5.5 capture requires unique --capture-prefix.")
		quit(1)
		return
	root.size = Vector2i(1280, 720)
	var screen: Control = Scene.instantiate()
	root.add_child(screen)
	await create_timer(0.5).timeout
	screen._command_requested("REDUCED_MOTION", {"enabled": true})
	var initial: Dictionary = screen.controller.snapshot()

	# VIS01–04: idle, two locales × two resolutions, 4-card hand.
	for spec: Array in [["vis01_idle_1280_zh", Vector2i(1280, 720), "zh_TW"],
		["vis02_idle_1920_zh", Vector2i(1920, 1080), "zh_TW"],
		["vis03_idle_1280_en", Vector2i(1280, 720), "en"],
		["vis04_idle_1920_en", Vector2i(1920, 1080), "en"]]:
		await stage(screen, spec[1], spec[2], 4)
		await capture(screen, spec[0], "PROJECTION_FIXTURE_HAND", {"hand_count": 4})

	# VIS05: selected card detail.
	await stage(screen, Vector2i(1280, 720), "zh_TW", 4)
	screen.select_card(str(screen.hud.card_views[0].instance_id))
	check(not screen.pending_card.is_empty(), "V35V-VIS05-CARD-SELECTED")
	await capture(screen, "vis05_selected_1280_zh", "PROJECTION_FIXTURE_HAND", {"selected": true})
	screen.cancel_action()

	# VIS06: hand counts 0 / 1 / 8.
	for count: int in [0, 1, 8]:
		await stage(screen, Vector2i(1280, 720), "zh_TW", count)
		check(screen.hud.card_views.size() == count, "V35V-VIS06-HAND-%d" % count)
		await capture(screen, "vis06_hand%d_1280_zh" % count, "PROJECTION_FIXTURE_HAND", {"hand_count": count})

	# VIS07: MOCK_ONLY status badges (display boundary only).
	await stage(screen, Vector2i(1280, 720), "zh_TW", 4)
	var mock: Dictionary = screen.hud.vm.duplicate(true)
	mock["barriers"] = {"B": 12}
	mock["reaction"]["guard_actor_ids"] = ["A"]
	mock["casts"] = {"mock-cast": {"caster_id": "C", "current_stability": 3, "focus_ward": 1}}
	mock["actors"]["A"]["status"] = "EXHAUSTED"
	screen.hud.get_node("PartyStatusPanel").render_party(mock, "A")
	check(screen.hud.roster["B"].badge_ids() == ["BARRIER"], "V35V-VIS07-MOCK-BADGES")
	await capture(screen, "vis07_mock_status_1280_zh", "MOCK_ONLY")

	# VIS08: keyboard focus ring on roster B (selection stays A).
	await stage(screen, Vector2i(1280, 720), "zh_TW", 4)
	screen.hud.roster["B"].grab_focus()
	await process_frame
	check(screen.hud.roster["B"].has_focus() and screen.selected_actor == "A", "V35V-VIS08-FOCUS-NOT-SELECT")
	await capture(screen, "vis08_focus_1280_zh", "PROJECTION_FIXTURE_HAND")

	# VIS09–10: real Domain events (full chant + end phase) → log, intent, End disabled.
	screen.present(initial)
	screen.set_locale("zh_TW")
	root.size = Vector2i(1280, 720)
	await process_frame
	var state: Dictionary = screen.controller.snapshot()
	var spell: String = ""
	for id: String in state["core"]["cards"]["actors"]["C"]["zones"]["hand"]:
		if state["core"]["cards"]["actors"]["C"]["instances"][id]["definition_id"] == "regular":
			spell = id
			break
	check(screen.controller.submit(Factory.card(state, "C", spell, "Boss", "FULL")), "V35V-VIS09-REAL-CAST")
	await process_frame
	await capture(screen, "vis11_real_casting_1280_zh", "REAL_DOMAIN",
		{"actor_statuses": screen.view_model["actors"], "casts": screen.view_model["casts"]})
	screen._command_requested("END_PLAYER_PHASE", {})
	await process_frame
	var log_rows: int = screen.hud.get_node("BattleLogPanel").visible_rows().size()
	var targets: Array = screen.hud.get_node("EnemyStatus").target_badge_ids()
	check(log_rows > 0 and not targets.is_empty() and screen.hud.end_button.disabled, "V35V-VIS09-REAL-STATE")
	await capture(screen, "vis09_real_events_1280_zh", "REAL_DOMAIN",
		{"log_rows": log_rows, "intent_targets": targets, "end_disabled": screen.hud.end_button.disabled})
	screen.set_locale("en")
	root.size = Vector2i(1920, 1080)
	await process_frame
	await capture(screen, "vis10_real_events_1920_en", "REAL_DOMAIN",
		{"log_rows": screen.hud.get_node("BattleLogPanel").visible_rows().size(),
		"intent_targets": screen.hud.get_node("EnemyStatus").target_badge_ids()})
	# Additional real Lv40 view: no mocked gauge or fixture-only retail claims.
	var live: Control = preload("res://scenes/battle/lv40_playable_battle.tscn").instantiate()
	screen.queue_free()
	await process_frame
	root.add_child(live)
	root.size = Vector2i(1280, 720)
	await create_timer(0.4).timeout
	await capture(live, "vis12_lv40_idle_1280_zh", "REAL_DOMAIN_LV40_BALANCE_PROVISIONAL",
		{"content_version": live.config.get("content_version", ""), "tactical": live.view_model["tactical"]})

	var directory: String = ProjectSettings.globalize_path(Writer.OUTPUT_SCOPE).path_join(prefix)
	var f: FileAccess = FileAccess.open(directory.path_join("v35_capture_manifest.json"), FileAccess.WRITE)
	check(f != null, "V35V-MANIFEST")
	if f != null:
		f.store_string(JSON.stringify({"display_server": DisplayServer.get_name(),
			"godot": str(Engine.get_version_info().get("string", "")),
			"renderer": RenderingServer.get_video_adapter_name(), "cases": cases}, "\t"))
		f.close()
	live.queue_free()
	await process_frame
	print("V35_CAPTURE_REPORT executed=%d passed=%d failed=%d" % [executed, executed - failed, failed])
	quit(0 if failed == 0 else 1)
