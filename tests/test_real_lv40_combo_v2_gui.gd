extends SceneTree
const Scene = preload("res://scenes/battle/lv40_playable_battle.tscn")
const Encounter = preload("res://scripts/domain/m5/lv40/lv40_encounter.gd")
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const M5 = preload("res://scripts/domain/m5/integration/m5_domain_resolver.gd")
var screen: Control
var failed: int = 0
func check(ok: bool, id: String) -> void:
	print(("PASS " if ok else "FAIL ")+id)
	if not ok: failed += 1
func motion(point: Vector2) -> void:
	for attempt: int in 8:
		root.warp_mouse(point)
		var event := InputEventMouseMotion.new()
		event.position = point * Vector2(root.size) / root.get_visible_rect().size
		event.global_position = event.position
		root.push_input(event)
		await create_timer(0.08).timeout
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
	await create_timer(0.25).timeout
func card_id(state: Dictionary, actor: String, definition: String) -> String:
	var cards: Dictionary = state["core"]["cards"]["actors"][actor]
	for id: String in cards["zones"]["hand"]:
		if cards["instances"][id]["definition_id"] == definition: return id
	return ""
func card_view(instance: String) -> Control:
	for card: Control in screen.hud.card_views:
		if card.instance_id == instance: return card
	return null
func capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	var path := "res://docs/verification/combo/evidence/real-lv40-"+name+".png"
	var err: Error = root.get_texture().get_image().save_png(path)
	check(err == OK,"screenshot-"+name)
func run() -> void:
	root.size = Vector2i(1280,720)
	var seed: int = 6
	var state: Dictionary = Encounter.initial(seed)
	var config: Dictionary = Encounter.config()
	var setup: String = card_id(state,"A","R08")
	var finisher: String = card_id(state,"C","T04")
	check(not setup.is_empty() and not finisher.is_empty(),"real-v0.3-opening-hand-cards")
	screen = Scene.instantiate()
	root.add_child(screen)
	await create_timer(0.6).timeout
	screen.set_locale("zh_TW")
	screen.director.reduced_motion = true
	screen.director.overlay.reduced_motion = true
	screen.director.overlay.audio_enabled = false
	screen.controller.begin(state,config)
	screen.selected_actor = "A"
	screen.present(state)
	await create_timer(0.5).timeout
	check(screen.encounter_profile == "lv40_playable" and Model.state_hash(screen.snapshot) == Model.state_hash(state),"real-lv40-scene-and-actual-encounter-state")
	await capture("01-start")
	var before: String = Model.state_hash(screen.snapshot)
	var setup_view: Control = card_view(setup)
	check(setup_view != null,"real-setup-card-rendered")
	if setup_view == null: quit(1); return
	await click(setup_view.get_global_transform()*Vector2(82,80))
	check(screen.preparation.state == "SETUP_SELECTED","real-setup-selected-without-domain-write")
	check(screen.preparation.partners().has("C"),"real-hand-finds-partner-finisher")
	await click(screen.hud.roster["C"].get_global_rect().get_center())
	check(screen.selected_actor == "C" and screen.preparation.setup_card_instance_id == setup,"real-actor-switch-keeps-setup")
	await create_timer(0.3).timeout
	var finisher_view: Control = card_view(finisher)
	check(finisher_view != null and finisher_view.combo_eligible,"real-finisher-highlighted")
	if finisher_view == null: quit(1); return
	await capture("02-finisher")
	var start: Vector2 = finisher_view.get_global_transform()*Vector2(82,80)
	await motion(start)
	await button(start,true)
	var end: Vector2 = screen.hud.target_buttons["C"].get_global_rect().get_center()
	await motion(end)
	check(screen.hud.targeting_arrow.is_aiming,"real-card-uses-existing-target-drag")
	await button(end,false)
	await create_timer(0.25).timeout
	check(screen.hud.combo_preview.visible and screen.preparation.state == "AWAITING_CONFIRMATION","real-combo-confirmation-opens")
	if not screen.hud.combo_preview.visible: quit(1); return
	var overlay: Control = screen.hud.combo_preview
	for i: int in overlay.setup_targets.item_count:
		if overlay.setup_targets.get_item_metadata(i) == "B": overlay.setup_targets.select(i)
	screen._update_combo_comparison()
	check(screen.combo_comparison.get("combo_accepted",false) and not overlay.combo_button.disabled,"real-roster-domain-preview-accepts-combo")
	check(screen.preparation.setup_target_ids == ["B"] and screen.preparation.finisher_target_ids == ["C"],"real-combo-separate-legal-ally-targets")
	check(Model.state_hash(screen.snapshot) == before and screen.controller.tape().is_empty(),"real-preview-does-not-pay")
	await capture("03-confirmation")
	await click(overlay.combo_button.get_global_rect().get_center())
	await create_timer(0.8).timeout
	var tape: Array = screen.controller.tape()
	check(tape.size() == 1 and tape[0]["type"] == "COMMIT_PREPARED_COMBO_V2","real-ui-submits-one-composite-command")
	check(screen.controller.replay_receipt().get("matches",false),"real-combat-replay-matches")
	var result_state: Dictionary = screen.snapshot
	var actors: Dictionary = result_state["core"]["cards"]["actors"]
	check(actors["A"]["zones"]["discard"].has(setup) and actors["C"]["zones"]["discard"].has(finisher),"real-setup-and-finisher-card-instances-paid")
	check(float(result_state["core"]["battle"]["hp_barriers"]["B"]) == 90.0 and float(result_state["core"]["battle"]["hp_barriers"]["C"]) == 265.0,"real-combo-effects-apply-to-selected-allies")
	await capture("04-combo-executed")
	print("REAL_LV40_COMBO_REPORT seed=%d checks_failed=%d command_count=%d" % [seed,failed,tape.size()])
	quit(0 if failed == 0 else 1)
func _initialize() -> void: call_deferred("run")