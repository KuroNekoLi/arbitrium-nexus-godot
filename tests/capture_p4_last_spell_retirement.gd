extends SceneTree
## Review-only true-render screenshots: Domain-backed fixture states, not
## a claim that the new Lv40 encounter is fully playable.
const Scene = preload("res://scenes/battle/battle_screen.tscn")
const Fixture = preload("res://tests/fixtures/m5_full_battle_fixture.gd")
const Last = preload("res://scripts/domain/m4/last_spell/last_spell_resolver.gd")
const Writer = preload("res://scripts/qa/screenshot_writer.gd")
const Encounter = preload("res://scripts/domain/m5/lv40/lv40_encounter.gd")
const M5 = preload("res://scripts/domain/m5/integration/m5_domain_resolver.gd")
const Factory = preload("res://scripts/battle/battle_command_factory.gd")
const Appearances = preload("res://scripts/battle/presentation/character_appearance_registry.gd")
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
	if should_retire:
		check(actor.state_cg == null or not actor.state_cg.visible,
			"RET-VIS-RETIRED-CG-HIDDEN-" + label)
	else:
		var expected_field: Texture2D = Appearances.field_cg_for_status("B", "INCAPACITATED")
		var expected_portrait: Texture2D = Appearances.portrait_for_status("B", "INCAPACITATED")
		check(actor.state_cg != null and actor.state_cg.visible and
			actor.state_cg.texture is AtlasTexture and expected_field is AtlasTexture and
			(actor.state_cg.texture as AtlasTexture).atlas == (expected_field as AtlasTexture).atlas and
			(actor.state_cg.texture as AtlasTexture).region == (expected_field as AtlasTexture).region,
			"RET-VIS-INCAPACITATED-FIELD-CG-" + label)
		check(record.portrait.texture is AtlasTexture and expected_portrait is AtlasTexture and
			(record.portrait.texture as AtlasTexture).atlas == (expected_portrait as AtlasTexture).atlas and
			(record.portrait.texture as AtlasTexture).region == (expected_portrait as AtlasTexture).region,
			"RET-VIS-INCAPACITATED-PORTRAIT-" + label)
	var picture: Image = root.get_texture().get_image()
	check(picture != null and not picture.is_empty() and picture.get_size() == size,
		"RET-VIS-PIXELS-" + label)
	if picture == null or picture.is_empty(): return
	var output: Dictionary = writer.write_png(picture,label,capture_prefix)
	check(bool(output.get("ok",false)), "RET-VIS-SAVED-" + label)
	if label in ["ret_ko_1280_zh","ret_exhausted_1280_zh"]:
		var thumb: Image = picture.duplicate()
		thumb.resize(640,360,Image.INTERPOLATE_LANCZOS)
		var thumb_path: String = str(output.get("path","")).get_base_dir().path_join(label+"_thumb.jpg")
		check(thumb.save_jpg(thumb_path,0.72) == OK,"RET-VIS-THUMB-"+label)
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
	var identity_ok: bool = true
	var normal_cg_atlases: Array[Texture2D] = []
	for actor_id: String in ["A", "B", "C"]:
		var actor: Node2D = screen.get_node("Design/Arena/" + actor_id)
		var expected_cg: Texture2D = Appearances.field_cg_for_status(actor_id, "ACTIVE")
		var expected_portrait: Texture2D = Appearances.portrait_for_status(actor_id, "ACTIVE")
		var cg_matches: bool = actor.state_cg != null and actor.state_cg.visible and \
			actor.state_cg.texture is AtlasTexture and expected_cg is AtlasTexture and \
			(actor.state_cg.texture as AtlasTexture).atlas == (expected_cg as AtlasTexture).atlas and \
			(actor.state_cg.texture as AtlasTexture).region == (expected_cg as AtlasTexture).region
		var portrait_matches: bool = screen.hud.roster[actor_id].portrait.texture is AtlasTexture and \
			expected_portrait is AtlasTexture and \
			(screen.hud.roster[actor_id].portrait.texture as AtlasTexture).atlas == (expected_portrait as AtlasTexture).atlas and \
			(screen.hud.roster[actor_id].portrait.texture as AtlasTexture).region == (expected_portrait as AtlasTexture).region
		identity_ok = identity_ok and cg_matches and portrait_matches
		if expected_cg is AtlasTexture:
			normal_cg_atlases.append((expected_cg as AtlasTexture).atlas)
	check(identity_ok, "RET-VIS-ACTIVE-CG-AND-PORTRAITS-FROM-ROSTER")
	check(normal_cg_atlases.size() == 3 and normal_cg_atlases[0] != normal_cg_atlases[1] and
		normal_cg_atlases[1] != normal_cg_atlases[2] and normal_cg_atlases[0] != normal_cg_atlases[2],
		"RET-VIS-THREE-ROSTER-IDENTITIES-DISTINCT")
	await _shot(screen,down,"ret_ko_1280_zh",Vector2i(1280,720),"zh_TW",false)
	await _shot(screen,down,"ret_ko_1920_en",Vector2i(1920,1080),"en",false)
	await _shot(screen,retired,"ret_exhausted_1280_zh",Vector2i(1280,720),"zh_TW",true)
	await _shot(screen,retired,"ret_exhausted_1920_en",Vector2i(1920,1080),"en",true)
	# Explicit prepared fixture, not a claim of a human-played battle. All
	# payments/releases/outcome and the saved tape go through the actual M5.
	var config: Dictionary = Encounter.config()
	var prepared: Dictionary = Encounter.initial()
	prepared.core.battle.party_resources.current_ap = 18
	prepared.core.battle.actors.Boss.hp = 999999
	prepared.core.battle.actors.Boss.max_hp = 999999
	for hero: String in ["A","B","C"]:
		var activation: Dictionary = Factory.build(prepared,"ACTIVATE_LAST_SPELL_M4",
			{"actor_id":hero,"target_actor_id":"A" if hero=="C" else "Boss","confirmed":true,"casting_mode":"FULL"})
		var committed: Dictionary = M5.apply(prepared,activation,config)
		check(committed.get("accepted", false),"RET-VIS-PAID-"+hero)
		if not committed.get("accepted", false): quit(1); return
		prepared = committed.state
	prepared.phase = "AWAITING_PLAYER_START"
	prepared.core.battle.phase = "AWAITING_PLAYER_START"
	prepared.core.battle.round = 2
	prepared.core.cards.phase = "AWAITING_PLAYER_START"
	prepared.core.cards.player_phase_index = 2
	screen.config = config
	screen.controller.begin(prepared,config)
	screen.director.reduced_motion = true
	screen.present(prepared)
	screen._submit(Factory.build(prepared,"START_PLAYER_PHASE"))
	check(screen.controller.snapshot().core.battle.outcome == "DEFEAT", "RET-VIS-CONTROLLER-DEFEAT")
	check(screen.hud.result_panel.visible, "RET-VIS-DEFEAT-HUD")
	check(screen.controller.replay_receipt().matches, "RET-VIS-DEFEAT-REPLAY")
	for resolution: Vector2i in [Vector2i(1280,720),Vector2i(1920,1080)]:
		root.size = resolution
		screen.set_locale("zh_TW" if resolution.x == 1280 else "en")
		await create_timer(0.7).timeout
		await RenderingServer.frame_post_draw
		var saved: Dictionary = writer.write_png(root.get_texture().get_image(),"ret_defeat_"+str(resolution.x),capture_prefix)
		check(saved.ok, "RET-VIS-DEFEAT-SCREENSHOT-"+str(resolution.x))
	check(screen.controller.save_tape("res://outputs/p4_input_capture/"+capture_prefix+"/retirement.tape") == OK,"RET-VIS-SAVED-TAPE")
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
