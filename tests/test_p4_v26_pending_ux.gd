extends SceneTree
## V2 missing contracts: all-eight at 1920, selected fan drag, preferences scroll,
## and modal isolation. Never invokes V25 or the restricted P43 capture runner.
const Scene = preload("res://scenes/battle/battle_screen.tscn")
const Fixture = preload("res://tests/fixtures/m5_full_battle_fixture.gd")
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const Writer = preload("res://scripts/qa/screenshot_writer.gd")
var executed: int = 0
var failed: int = 0
var last_physical: Vector2 = Vector2.ZERO

func _initialize() -> void: call_deferred("run")
func check(ok: bool, id: String) -> void:
	executed += 1
	if not ok: failed += 1
	print(("PASS " if ok else "FAIL ")+id)

func physical(point: Vector2) -> Vector2:
	return point * Vector2(root.size) / root.get_visible_rect().size

func move(point: Vector2) -> void:
	var p: Vector2 = physical(point)
	# warp_mouse takes Viewport coordinates; push_input(false) takes window pixels.
	# Mixing them can make OS cursor queries disagree with synthetic hit tests.
	root.warp_mouse(point)
	var event := InputEventMouseMotion.new()
	event.position = p
	event.global_position = p
	event.relative = p-last_physical
	last_physical = p
	root.push_input(event)
	await create_timer(0.04).timeout

func button(point: Vector2, pressed: bool, index: MouseButton = MOUSE_BUTTON_LEFT) -> void:
	var event := InputEventMouseButton.new()
	event.position = physical(point)
	event.global_position = event.position
	event.button_index = index
	event.pressed = pressed
	root.push_input(event)
	await process_frame

func click(point: Vector2) -> void:
	await move(point)
	await button(point,true)
	await button(point,false)

func tab() -> void:
	for down: bool in [true,false]:
		var event := InputEventKey.new()
		event.keycode = KEY_TAB
		event.physical_keycode = KEY_TAB
		event.pressed = down
		root.push_input(event)
	await process_frame

func pick(screen: Control, card: Control) -> bool:
	for x: float in [0.1,0.28,0.5,0.72,0.9]:
		for y: float in [0.1,0.3,0.6,0.85]:
			screen.cancel_action()
			await move(Vector2(970,440))
			await click(card.get_global_transform()*Vector2(card.size.x*x,card.size.y*y))
			if screen.pending_card == card.instance_id: return true
	return false

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("V26 pending UX requires a real renderer")
		quit(1)
		return
	root.size = Vector2i(1920,1080)
	var screen: Control = Scene.instantiate()
	root.add_child(screen)
	await create_timer(0.3).timeout
	var initial: Dictionary = Fixture.initial()
	var zones: Dictionary = initial["core"]["cards"]["actors"]["A"]["zones"]
	while zones["hand"].size() < 8:
		zones["hand"].append(zones["draw"].pop_back())
	screen.controller.begin(initial,Fixture.config())
	screen.present(initial)
	await create_timer(0.3).timeout
	var before: String = Model.state_hash(screen.snapshot)
	for card: Control in screen.hud.card_views:
		check(await pick(screen,card),"V26-1920-ALL-EIGHT-"+card.instance_id)
	check(Model.state_hash(screen.snapshot) == before,"V26-PICK-NO-PAYMENT")
	var chosen: Control = screen.hud.card_views[0]
	check(await pick(screen,chosen),"V26-SELECTED-FAN-PICK")
	await create_timer(0.2).timeout
	var boss_hp_before: int = int(screen.snapshot["core"]["battle"]["actors"]["Boss"]["hp"])
	var discard_before: int = screen.snapshot["core"]["cards"]["actors"]["A"]["zones"]["discard"].size()
	var start: Vector2 = chosen.get_global_transform()*Vector2(20,25)
	await move(start)
	await button(start,true)
	await move(start+Vector2(0,-25))
	var target: Vector2 = screen.hud.target_buttons["Boss"].get_global_rect().get_center()
	await move(target)
	check(chosen.holding,"V26-SELECTED-FAN-DRAG")
	await button(target,false)
	await process_frame
	check(int(screen.snapshot["core"]["battle"]["actors"]["Boss"]["hp"]) < boss_hp_before,
		"V26-LEGAL-DROP-COMMITS-DAMAGE")
	check(screen.controller.tape().size() == 1,"V26-DROP-ONE-COMMAND")
	check(screen.snapshot["core"]["cards"]["actors"]["A"]["zones"]["discard"].size() == discard_before + 1,
		"V26-DROP-ONE-CARD-TRANSACTION")
	check(screen.controller.replay_receipt()["matches"],"V26-TRANSACTION-REPLAY")
	var context: Control = screen.hud.get_node("Context")
	var disclosure: Button = context.preferences_disclosure
	var confirm_rect: Rect2 = context.confirm_button.get_global_rect()
	await click(disclosure.get_global_rect().get_center())
	check(screen.hud.preferences_panel.visible,"V26-PREFERENCES-REAL-OPEN")
	check(screen.hud.preferences_panel.get_global_rect().position.y < context.get_global_rect().position.y,
		"V26-PREFERENCES-POPOVER-OUTSIDE-CONTEXT")
	context.mute_toggle.grab_focus()
	await create_timer(0.1).timeout
	await click(context.mute_toggle.get_global_rect().get_center())
	check(not screen.director.overlay.audio_enabled,"V26-MUTE-REAL-CLICK")
	context.reduced_toggle.grab_focus()
	await create_timer(0.1).timeout
	await click(context.reduced_toggle.get_global_rect().get_center())
	check(screen.director.reduced_motion,"V26-REDUCED-REAL-CLICK")
	await click(disclosure.get_global_rect().get_center())
	check(not screen.hud.preferences_panel.visible,"V26-PREFERENCES-REAL-CLOSE")
	check(context.confirm_button.get_global_rect() == confirm_rect,"V26-CONFIRM-RECT-STABLE")
	screen._command_requested("END_PLAYER_PHASE",{})
	await process_frame
	check(screen.hud.reaction_panel.visible,"V26-MODAL-SETUP")
	var frozen: String = Model.state_hash(screen.snapshot)
	check(screen.hud.get_node("ModalInputShield").visible,"V26-MODAL-SHIELD")
	screen.cancel_action()
	await click(screen.hud.card_views[0].get_global_rect().get_center())
	check(screen.pending_card.is_empty(),"V26-MODAL-BLOCKS-BACKGROUND-CARDS")
	for i: int in 20:
		await tab()
		check(screen.hud.reaction_panel.is_ancestor_of(root.gui_get_focus_owner()),"V26-MODAL-TAB-"+str(i))
	check(Model.state_hash(screen.snapshot) == frozen,"V26-MODAL-DOES-NOT-AUTOPASS")
	var actions: HBoxContainer = screen.hud.reaction_column.get_child(screen.hud.reaction_column.get_child_count()-1)
	await click(actions.get_child(1).get_global_rect().get_center())
	check(not screen.hud.get_node("ModalInputShield").visible and screen.snapshot["phase"] == "PLAYER_PHASE","V26-EXPLICIT-PASS-RESTORES-INPUT")
	check(screen.controller.replay_receipt()["matches"],"V26-MODAL-REPLAY")
	var writer = Writer.new()
	await RenderingServer.frame_post_draw
	var shot: Dictionary = writer.write_png(root.get_texture().get_image(),"v26_after_modal","v26_"+str(OS.get_process_id()))
	print("V26_CAPTURE ",JSON.stringify(shot))
	check(shot["ok"],"V26-EVIDENCE-WRITE")
	screen.queue_free()
	await process_frame
	print("V26_PENDING_UX_REPORT executed=%d passed=%d failed=%d" % [executed,executed-failed,failed])
	quit(1 if failed else 0)
