extends SceneTree
## Rendered Godot input test: native GUI picking → SimpleCards gesture →
## BattleScreen → Controller → real Domain. No signal-only substitutes.
const Scene = preload("res://scenes/battle/lv40_playable_battle.tscn")
const Fixture = preload("res://tests/fixtures/combo_preparation_v2_fixture.gd")
const Model = preload("res://scripts/domain/m1/combat_model.gd")
var executed: int = 0
var failed: int = 0
var screen: Control
var prefix: String = ""

func _initialize() -> void: call_deferred("run")

func check(ok: bool, id: String) -> void:
	executed += 1
	if not ok: failed += 1
	print(("PASS " if ok else "FAIL ")+prefix+"-"+id)

func motion(point: Vector2) -> void:
	# Windows may deliver a stale OS motion after the synthetic event. Settle
	# the actual cursor before SimpleCards samples it on its next frame.
	for attempt: int in 6:
		root.warp_mouse(point)
		var event := InputEventMouseMotion.new()
		event.position = point * Vector2(root.size) / root.get_visible_rect().size
		event.global_position = event.position
		root.push_input(event)
		await create_timer(0.07).timeout
		if screen.get_global_mouse_position().distance_to(point) < 2.0: break

func button(point: Vector2, down: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = point * Vector2(root.size) / root.get_visible_rect().size
	event.global_position = event.position
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = down
	root.push_input(event)
	await process_frame

func click(point: Vector2) -> void:
	await motion(point)
	await button(point,true)
	await button(point,false)
	await create_timer(0.1).timeout

func card_for(instance: String) -> Control:
	for card: Control in screen.hud.card_views:
		if card.instance_id == instance: return card
	return null

func capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	var path: String = "res://docs/verification/combo/evidence/"+prefix+"-"+label+".png"
	var error: Error = root.get_texture().get_image().save_png(path)
	check(error == OK,"PNG-"+label)

func reset(rig: Dictionary) -> void:
	screen.director.reset_session()
	screen.cancel_action()
	screen.controller.begin(rig["state"],rig["config"])
	screen.selected_actor = "A"
	screen.present(rig["state"])
	await create_timer(0.3).timeout

func begin_pair(rig: Dictionary, target: String, screenshot: bool = false) -> void:
	var before: String = Model.state_hash(screen.snapshot)
	var card: Control = card_for(rig["setup"])
	if card == null:
		check(false,"setup-card-found")
		return
	await click(card.get_global_transform()*Vector2(82,80))
	check(screen.preparation.state == "SETUP_SELECTED","CP2-31-select-A-real-mouse")
	check(screen.hud.roster[rig["partner"]].combo_strength == 2,"CP2-03-partner-highlight")
	check(Model.state_hash(screen.snapshot) == before,"CP2-01-02-setup-free")
	if screenshot: await capture("02-setup")
	await click(screen.hud.roster[rig["partner"]].get_global_rect().get_center())
	check(screen.selected_actor == rig["partner"] and screen.preparation.setup_card_instance_id == rig["setup"],"CP2-32-preserve-A-switch-B")
	await create_timer(0.3).timeout
	var finisher: Control = card_for(rig["finisher"])
	if finisher == null:
		check(false,"finisher-found")
		return
	check(finisher.combo_eligible,"CP2-33-finisher-highlight")
	check(finisher.appearance.name_key == "LV40_"+("A06" if rig["partner"] == "B" else "T04")+"_NAME","CP2-05-original-card-name")
	if screenshot: await capture("03-finisher")
	var start: Vector2 = finisher.get_global_transform()*Vector2(82,80)
	await motion(start)
	await button(start,true)
	var end: Vector2 = screen.hud.target_buttons[target].get_global_rect().get_center()
	await motion(end)
	print("GUI_POINTER requested=",end," actual=",screen.get_global_mouse_position()," target=",target," root=",root.get_visible_rect().size)
	check(screen.hud.targeting_arrow.is_aiming,"CP2-34-existing-drag-arrow")
	if screenshot: await capture("04-drag")
	await button(end,false)
	await create_timer(0.1).timeout
	check(screen.hud.combo_preview.visible and screen.preparation.state == "AWAITING_CONFIRMATION","CP2-35-confirmation")
	check(Model.state_hash(screen.snapshot) == before and screen.controller.tape().is_empty(),"CP2-drop-no-payment")

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Combo GUI suite requires a rendered window")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/verification/combo/evidence"))
	for dimensions: Vector2i in [Vector2i(1280,720),Vector2i(1920,1080)]:
		for locale: String in ["zh_TW","en"]:
			root.size = dimensions
			screen = Scene.instantiate()
			root.add_child(screen)
			await create_timer(0.4).timeout
			screen.set_locale(locale)
			screen.director.reduced_motion = true
			screen.director.overlay.reduced_motion = true
			screen.director.overlay.audio_enabled = false
			prefix = "%dx%d-%s" % [dimensions.x,dimensions.y,locale]
			await capture("01-normal")
			var rig: Dictionary = Fixture.make()
			await reset(rig)
			await begin_pair(rig,"C",true)
			if not screen.hud.combo_preview.visible:
				screen.queue_free()
				await process_frame
				continue
			# R08 permits separate ally targets; pick B explicitly through GUI.
			var overlay: Control = screen.hud.combo_preview
			overlay.setup_targets.select(1)
			screen._update_combo_comparison()
			check(screen.preparation.setup_target_ids == ["B"] and screen.preparation.finisher_target_ids == ["C"],"CP2-26-separate-targets")
			check(not overlay.combo_button.disabled and not overlay.normal_button.disabled,"CP2-both-choices-legal")
			check(root.gui_get_focus_owner() == overlay.cancel_button,"CP2-42-safe-default-focus")
			await capture("05-comparison")
			var before: String = Model.state_hash(screen.snapshot)
			await click(screen.hud.end_button.get_global_rect().get_center())
			check(Model.state_hash(screen.snapshot) == before and overlay.visible,"CP2-44-modal-no-clickthrough")
			await click(overlay.cancel_button.get_global_rect().get_center())
			check(not overlay.visible and Model.state_hash(screen.snapshot) == before,"CP2-36-cancel-free")
			await capture("12-cancel")
			await reset(rig)
			await begin_pair(rig,"C")
			await click(screen.hud.combo_preview.normal_button.get_global_rect().get_center())
			check(screen.controller.tape().size() == 1 and screen.snapshot["core"]["cards"]["actors"]["A"] == rig["state"]["core"]["cards"]["actors"]["A"],"CP2-37-normal-only-B")
			check(screen.controller.replay_receipt()["matches"],"CP2-normal-GUI-replay")
			await reset(rig)
			await begin_pair(rig,"C")
			screen.hud.combo_preview.setup_targets.select(1)
			screen._update_combo_comparison()
			# The longer English comparison expands the VBox. Read button geometry
			# only after the real Container layout completes. NOT rerun locally:
			# user retained the three-attempt GUI gate on 2026-10-16.
			await process_frame
			await process_frame
			await click(screen.hud.combo_preview.combo_button.get_global_rect().get_center())
			check(screen.controller.tape().size() == 1 and screen.controller.tape()[0]["type"] == "COMMIT_PREPARED_COMBO_V2","CP2-38-one-composite-command")
			check(screen.controller.replay_receipt()["matches"],"CP2-combo-GUI-replay")
			await capture("06-cooperation-placeholder")
			var low: Dictionary = Fixture.make()
			low["state"]["core"]["battle"]["actors"]["A"]["mp"] = 0
			await reset(low)
			await begin_pair(low,"C")
			check(screen.hud.combo_preview.combo_button.disabled and not screen.hud.combo_preview.normal_button.disabled,"CP2-MP-short-normal-still-available")
			await capture("08-MP-short")
			screen.cancel_action()
			var attack: Dictionary = Fixture.make(true)
			await reset(attack)
			await begin_pair(attack,"Boss",false)
			check(not screen.hud.combo_preview.combo_button.disabled,"CP2-24-Boss-legal")
			await capture("04b-Boss-comparison")
			screen.queue_free()
			await process_frame
	print("COMBO_V2_GUI_REPORT executed=%d passed=%d failed=%d" % [executed,executed-failed,failed])
	quit(0 if failed == 0 else 1)
