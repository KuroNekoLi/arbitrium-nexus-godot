extends SceneTree
## Review-only true-render screenshots: Domain-backed fixture states, not
## a claim that the new Lv40 encounter is fully playable.
const Scene = preload("res://scenes/battle/battle_screen.tscn")
const Fixture = preload("res://tests/fixtures/m5_full_battle_fixture.gd")
const Last = preload("res://scripts/domain/m4/last_spell/last_spell_resolver.gd")
const Writer = preload("res://scripts/qa/screenshot_writer.gd")
var writer = Writer.new()
var capture_prefix: String = ""
var passed: int = 0
var failed: int = 0
var cases: Array = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else: failed += 1
	print(("PASS " if ok else "FAIL ") + label)

func _retired_state(original: Dictionary) -> Dictionary:
	var state: Dictionary = original.duplicate(true)
	state["core"]["battle"]["actors"]["B"]["status"] = "CONCENTRATING"
	var cast: Dictionary = {
		"kind":"LAST_SPELL","state":"CASTING",
		"casting_id":"last:visual:b","caster_id":"B",
		"spell_id":"review_last",
		"target_snapshot":{"actor_id":"Boss"},
		"outcome_modifier_numerator":1,"outcome_modifier_denominator":1
	}
	state["core"]["battle"]["casting_instances"][cast["casting_id"]] = cast.duplicate(true)
	var effect: Dictionary = Last.settle(state["core"],cast,3,true)
	if not effect["ok"]: return {}
	state["core"] = effect["core"]
	return state

func _shot(screen: Control, state: Dictionary, label: String,
		size: Vector2i, locale: String, should_retire: bool) -> void:
	root.size = size
	screen.set_locale(locale)
	screen.present(state)
	await create_timer(0.45).timeout
	await RenderingServer.frame_post_draw
	var actor: Node2D = screen.get_node("Design/Arena/B")
	var record: Button = screen.hud.roster["B"]
	check(actor.visible == not should_retire, "RET-VIS-CG-" + label)
	check(record.retirement_mark.visible == should_retire, "RET-VIS-ROSTER-" + label)
	var picture: Image = root.get_texture().get_image()
	check(picture != null and not picture.is_empty() and picture.get_size() == size,
		"RET-VIS-PIXELS-" + label)
	if picture == null or picture.is_empty(): return
	var output: Dictionary = writer.write_png(picture,label,capture_prefix)
	check(bool(output.get("ok",false)), "RET-VIS-SAVED-" + label)
	cases.append({"case":label,"resolution":[size.x,size.y],"locale":locale,
		"condition":"EXHAUSTED" if should_retire else "INCAPACITATED",
		"written":bool(output.get("ok",false))})

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Retirement screenshots require a real Xvfb/GL renderer.")
		quit(1)
		return
	var args: Dictionary = Writer.prefix_from_args(OS.get_cmdline_user_args())
	if not args.get("ok",false):
		quit(1)
		return
	capture_prefix = str(args["prefix"])
	var initial: Dictionary = Fixture.initial()
	var down: Dictionary = initial.duplicate(true)
	down["core"]["battle"]["actors"]["B"]["hp"] = 0
	down["core"]["battle"]["actors"]["B"]["status"] = "INCAPACITATED"
	var retired: Dictionary = _retired_state(initial)
	check(not retired.is_empty(), "RET-VIS-AUTHORITATIVE-SETTLE")
	if retired.is_empty():
		quit(1)
		return
	root.size = Vector2i(1280,720)
	var screen: Control = Scene.instantiate()
	root.add_child(screen)
	await create_timer(0.45).timeout
	await _shot(screen,down,"ret_ko_1280_zh",Vector2i(1280,720),"zh_TW",false)
	await _shot(screen,down,"ret_ko_1920_en",Vector2i(1920,1080),"en",false)
	await _shot(screen,retired,"ret_exhausted_1280_zh",Vector2i(1280,720),"zh_TW",true)
	await _shot(screen,retired,"ret_exhausted_1920_en",Vector2i(1920,1080),"en",true)
	var directory: String = ProjectSettings.globalize_path(Writer.OUTPUT_SCOPE).path_join(capture_prefix)
	var f: FileAccess = FileAccess.open(directory.path_join("retirement_manifest.json"),FileAccess.WRITE)
	check(f != null, "RET-VIS-MANIFEST")
	if f != null:
		f.store_string(JSON.stringify({"godot":Engine.get_version_info().get("string",""),
			"runtime":"REAL_X11","reference":"VISUAL_FIXTURE_NOT_LIVE_BATTLE",
			"cases":cases}, "\t"))
		f.close()
	screen.queue_free()
	await process_frame
	print("RETIREMENT_RENDER_REPORT executed=%d passed=%d failed=%d" %
		[passed+failed,passed,failed])
	quit(0 if failed == 0 else 1)
