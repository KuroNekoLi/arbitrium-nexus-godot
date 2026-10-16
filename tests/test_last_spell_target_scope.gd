extends SceneTree
## New targeting-scope decision coverage; does not run the exhausted original
## Last-preview / V3.5 capture suites. Extra enemies are TEST_FIXTURE_ONLY.
const Scene = preload("res://scenes/battle/lv40_playable_battle.tscn")
const Encounter = preload("res://scripts/domain/m5/lv40/lv40_encounter.gd")
const Targeting = preload("res://scripts/domain/m5/lv40/last_spell_targeting.gd")
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const Factory = preload("res://scripts/battle/battle_command_factory.gd")
const M5 = preload("res://scripts/domain/m5/integration/m5_domain_resolver.gd")
const CastEffect = preload("res://scripts/domain/m5/lv40/lv40_cast_effect.gd")
const Writer = preload("res://scripts/qa/screenshot_writer.gd")
var executed: int = 0
var failed: int = 0
var prefix: String

func _initialize() -> void: call_deferred("run")

func check(ok: bool, id: String) -> void:
	executed += 1
	if not ok: failed += 1
	print(("PASS " if ok else "FAIL ") + id)

func click(button: Button) -> void:
	if DisplayServer.get_name() == "headless":
		button.pressed.emit()
		return
	await create_timer(0.08).timeout
	var point: Vector2 = button.get_global_rect().get_center()
	var physical: Vector2 = point * Vector2(root.size) / root.get_visible_rect().size
	root.warp_mouse(point)
	var motion := InputEventMouseMotion.new()
	motion.position = physical
	motion.global_position = physical
	root.push_input(motion)
	await process_frame
	for down: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = physical
		event.global_position = physical
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		root.push_input(event)
		await process_frame

func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await create_timer(0.12).timeout
	await RenderingServer.frame_post_draw
	var result: Dictionary = Writer.new().write_png(root.get_texture().get_image(), name, prefix)
	print("LAST_SCOPE_CAPTURE ", JSON.stringify(result))
	check(result["ok"], "LST-CAPTURE-" + name)

func multi_fixture() -> Dictionary:
	var state: Dictionary = Encounter.initial()
	var cfg: Dictionary = Encounter.config()
	var battle: Dictionary = state["core"]["battle"]
	battle["enemies"].append("Extra")
	battle["actors"]["Extra"] = battle["actors"]["Boss"].duplicate(true)
	battle["actors"]["Extra"]["id"] = "Extra"
	cfg["m5_actor_stats"]["Extra"] = cfg["m5_actor_stats"]["Boss"].duplicate(true)
	cfg["m5_element_resistance"]["Extra"] = cfg["m5_element_resistance"]["Boss"].duplicate(true)
	return {"state":state,"config":cfg}

func domain_cases() -> void:
	var fixture: Dictionary = multi_fixture()
	var state: Dictionary = fixture["state"]
	var cfg: Dictionary = fixture["config"]
	check(Targeting.definition(cfg, "A")["scope"] == "SINGLE" and
		Targeting.definition(cfg, "B")["scope"] == "ALL" and
		Targeting.definition(cfg, "C")["team"] == "ALLY", "LST-01-CONTENT-SCOPE")
	var legacy: Dictionary = cfg.duplicate(true)
	legacy.erase("last_spell_targeting")
	legacy["m5_lv40_content_version"] = "lv40-starter-v0.3-boss-v0.2-A-provisional-1"
	check(Targeting.definition(legacy, "B")["scope"] == "SINGLE" and Targeting.candidates(state["core"], "B", legacy) == ["Boss"],
		"LST-18-OLD-CONFIG-REPLAY-SEMANTICS")
	var wrong: Dictionary = Factory.build(state, "ACTIVATE_LAST_SPELL_M4",
		{"actor_id":"A","target_actor_id":"C","confirmed":true,"casting_mode":"FULL"})
	var rejection: Dictionary = M5.apply(state, wrong, cfg)
	check(not rejection["accepted"] and Model.state_hash(rejection["state"]) == Model.state_hash(state),
		"LST-02-WRONG-TEAM-ATOMIC")
	var aoe: Dictionary = M5.apply(state, Factory.build(state, "ACTIVATE_LAST_SPELL_M4",
		{"actor_id":"B","target_actor_id":"Boss","confirmed":true,"casting_mode":"FULL"}), cfg)
	check(aoe["accepted"], "LST-03-ENEMY-ALL-COMMIT")
	if aoe["accepted"]:
		var cast: Dictionary = aoe["state"]["core"]["battle"]["casting_instances"].values()[0]
		var released: Dictionary = CastEffect.settle(aoe["state"]["core"], cast, 3, cfg, "scope-release")
		check(released["ok"] and released["core"]["battle"]["actors"]["Boss"]["hp"] < state["core"]["battle"]["actors"]["Boss"]["hp"] and
			released["core"]["battle"]["actors"]["Extra"]["hp"] < state["core"]["battle"]["actors"]["Extra"]["hp"], "LST-04-AOE-DAMAGES-BOTH")
		var dead_anchor: Dictionary = aoe["state"]["core"].duplicate(true)
		dead_anchor["battle"]["actors"]["Boss"]["hp"] = 0
		dead_anchor["battle"]["actors"]["Boss"]["status"] = "INCAPACITATED"
		var remaining: Dictionary = CastEffect.settle(dead_anchor, cast, 3, cfg, "scope-remaining")
		check(remaining["ok"] and remaining["core"]["battle"]["actors"]["Extra"]["hp"] < dead_anchor["battle"]["actors"]["Extra"]["hp"],
			"LST-05-DEAD-ANCHOR-NOT-AOE-LOCK")
		# Prepared release-boundary fixture: replay uses a genuine START_PLAYER_PHASE
		# command, so M4's ordered timeline invokes the same M5 AoE resolver.
		var prepared: Dictionary = aoe["state"].duplicate(true)
		prepared["phase"] = "AWAITING_PLAYER_START"
		prepared["core"]["battle"]["phase"] = "AWAITING_PLAYER_START"
		prepared["core"]["battle"]["round"] = 2
		prepared["core"]["cards"]["phase"] = "AWAITING_PLAYER_START"
		prepared["core"]["cards"]["player_phase_index"] = 2
		var release_command: Dictionary = Factory.build(prepared, "START_PLAYER_PHASE")
		var released_boundary: Dictionary = M5.apply(prepared, release_command, cfg)
		if not released_boundary["accepted"]:
			print("LST_RELEASE_REJECTION ", released_boundary.get("error", ""))
		check(released_boundary["accepted"] and released_boundary["state"]["core"]["battle"]["actors"]["Extra"]["hp"] <
			prepared["core"]["battle"]["actors"]["Extra"]["hp"], "LST-16-M5-RELEASE-BOUNDARY-AOE")
		var release_tape: Array[Dictionary] = [release_command]
		var replayed: Dictionary = M5.replay(prepared, release_tape, cfg)
		check(replayed["accepted"] and replayed["state_hash"] == released_boundary["state_hash"],
			"LST-17-AOE-RELEASE-REPLAY")
	var allied: Dictionary = Encounter.initial()
	for id: String in ["A", "B", "C"]:
		allied["core"]["battle"]["actors"][id]["hp"] = 100
	var healing: Dictionary = M5.apply(allied, Factory.build(allied, "ACTIVATE_LAST_SPELL_M4",
		{"actor_id":"C","target_actor_id":"C","confirmed":true,"casting_mode":"FULL"}), Encounter.config())
	check(healing["accepted"], "LST-06-ALLY-ALL-COMMIT")
	if healing["accepted"]:
		var cast: Dictionary = healing["state"]["core"]["battle"]["casting_instances"].values()[0]
		var released: Dictionary = CastEffect.settle(healing["state"]["core"], cast, 3, Encounter.config(), "heal-release")
		var all_healed: bool = released["ok"]
		if all_healed:
			for id: String in ["A", "B", "C"]:
				all_healed = all_healed and released["core"]["battle"]["actors"][id]["hp"] > 100
		check(all_healed, "LST-07-ALL-ALLIES-HEALED")

func run() -> void:
	prefix = "last_scope_" + str(OS.get_process_id())
	root.size = Vector2i(1280, 720)
	domain_cases()
	var screen: Control = Scene.instantiate()
	root.add_child(screen)
	await process_frame
	screen.director.reduced_motion = true
	screen.director.overlay.audio_enabled = false
	for actor: String in ["A", "B", "C"]:
		screen.select_actor(actor)
		var frozen: String = Model.state_hash(screen.snapshot)
		await click(screen.hud.get_node("Commands").command_buttons["BATTLE_LAST"])
		var preview: Control = screen.hud.last_preview
		var scope: Dictionary = Targeting.definition(screen.config, actor)
		check(preview.visible and preview.targeting["team"] == scope["team"] and preview.targeting["scope"] == scope["scope"],
			"LST-08-SCOPE-UI-" + actor)
		check(Model.state_hash(screen.snapshot) == frozen and screen.controller.tape().is_empty(), "LST-09-SCOPE-PREVIEW-ATOMIC-" + actor)
		if actor == "A":
			check(preview.target_ids == ["Boss"] and preview.target_selector.selected == 0 and not preview.activate_button.disabled,
				"LST-10-SINGLE-ENEMY-AUTOSELECT")
		else:
			var all_selected: bool = true
			for marker: Button in preview.world_markers.values(): all_selected = all_selected and marker.selected
			check(all_selected and preview.target_ids.size() == (3 if actor == "C" else 1), "LST-11-ALL-MARKED-" + actor)
		await capture("real_" + actor + "_1280_zh")
		await click(preview.cancel_button)
		check(screen.hud.hand.visible, "LST-12-CANCEL-RESTORES-HAND-" + actor)
	var fixture: Dictionary = multi_fixture()
	screen.config = fixture["config"]
	screen.controller.begin(fixture["state"], fixture["config"])
	screen.present(fixture["state"])
	screen.select_actor("A")
	screen._open_last_preview()
	var preview: Control = screen.hud.last_preview
	var frozen: String = Model.state_hash(screen.snapshot)
	await click(preview.target_cards["Extra"])
	check(screen.selected_target == "Extra" and Model.state_hash(screen.snapshot) == frozen and screen.controller.tape().is_empty(),
		"LST-13-MULTI-TARGET-CARD-CHANGES-ONLY")
	await click(preview.activate_button)
	check(screen.controller.tape().size() == 1 and screen.controller.tape()[0]["target_actor_id"] == "Extra" and
		screen.snapshot["core"]["battle"]["casting_instances"].values()[0]["target_snapshot"]["actor_id"] == "Extra",
		"LST-14-EXPLICIT-ACTIVATION-SELECTED-TARGET")
	check(screen.controller.replay_receipt()["matches"], "LST-15-MULTI-COMMAND-REPLAY")
	screen.cancel_action()
	screen.set_locale("en")
	screen.select_actor("C")
	root.size = Vector2i(1920, 1080)
	await process_frame
	screen._open_last_preview()
	await capture("real_C_1920_en")
	screen.cancel_action()
	screen.queue_free()
	await process_frame
	await create_timer(0.15).timeout
	print("LAST_TARGET_SCOPE_REPORT executed=%d passed=%d failed=%d" % [executed, executed-failed, failed])
	quit(1 if failed else 0)
