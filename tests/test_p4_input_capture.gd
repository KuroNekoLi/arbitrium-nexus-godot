extends SceneTree
const Scene = preload("res://scenes/battle/battle_screen.tscn")
const ScreenshotWriter = preload("res://scripts/qa/screenshot_writer.gd")
var failed: int = 0
var executed: int = 0
var screenshot_writer = ScreenshotWriter.new()
var capture_options: Dictionary = ScreenshotWriter.prefix_from_args(OS.get_cmdline_user_args())
func _initialize() -> void: call_deferred("run")
func check(ok: bool, id: String) -> void:
	executed += 1
	if not ok: failed += 1
	print(("PASS " if ok else "FAIL ")+id)
func shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	var result: Dictionary = {"ok": false, "stage": "arguments", "detail": capture_options["detail"]}
	if capture_options["ok"]:
		result = screenshot_writer.write_png(root.get_texture().get_image(), path, capture_options["prefix"])
	print("P43_CAPTURE_WRITE ", JSON.stringify(result))
	check(result["ok"],"P43-CAPTURE-"+path)
func mouse(point: Vector2, down: bool) -> void:
	var physical: Vector2 = point * Vector2(root.size) / root.get_visible_rect().size
	root.warp_mouse(point)
	var motion := InputEventMouseMotion.new()
	motion.position = physical
	motion.global_position = physical
	root.push_input(motion)
	await create_timer(0.05).timeout
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = physical
	event.global_position = physical
	event.pressed = down
	root.push_input(event)
	await process_frame
func move_pointer(point: Vector2) -> void:
	var physical: Vector2 = point * Vector2(root.size) / root.get_visible_rect().size
	root.warp_mouse(point)
	var motion := InputEventMouseMotion.new()
	motion.position = physical
	motion.global_position = physical
	root.push_input(motion)
	await create_timer(0.05).timeout
func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	root.push_input(event)
	event = InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = false
	root.push_input(event)
func run() -> void:
	root.size = Vector2i(1280,720)
	var screen: Control = Scene.instantiate()
	root.add_child(screen)
	await create_timer(0.3).timeout
	await shot("p4_3_idle_1280")
	key(KEY_2)
	check(screen.selected_actor == "B","P43-KEYBOARD-CHARACTER")
	key(KEY_1)
	var card: Control = screen.hud.card_views[0]
	var origin: Vector2 = card.global_position+card.size*0.5
	mouse(origin,true)
	await create_timer(0.08).timeout
	await move_pointer(Vector2(820,285))
	check(card.holding,"P43-MOUSE-DRAG-ACTUAL-ADDON")
	check(card.face.visible and card.position.distance_to(card.home) < 1.0,"P43-DRAG-CARD-REMAINS-IN-HAND")
	await shot("p4_3_drag_1280")
	mouse(Vector2(820,285),false)
	await create_timer(0.35).timeout
	var hp: int = screen.snapshot["core"]["battle"]["actors"]["Boss"]["hp"]
	check(hp < 290 and screen.controller.tape().size() == 1,"P43-DROP-LEGAL-TARGET-COMMITS-ONCE")
	# Keyboard confirmation is a separate path: select a card, select its target,
	# then use Enter. Do not Enter the already committed drag transaction.
	var keyboard_card: Control = screen.hud.card_views[0]
	var keyboard_origin: Vector2 = keyboard_card.global_position+keyboard_card.size*0.5
	mouse(keyboard_origin,true)
	mouse(keyboard_origin,false)
	await create_timer(0.12).timeout
	check(screen.pending_kind == "CARD" and screen.pending_card == keyboard_card.instance_id,"P43-KEYBOARD-CARD-SELECTION")
	key(KEY_ENTER)
	await process_frame
	check(screen.legal_targets.has(screen.selected_target) and not screen.hud.confirm_button.disabled,"P43-KEYBOARD-CONFIRM-PREVIEW")
	var keyboard_hp: int = screen.snapshot["core"]["battle"]["actors"]["Boss"]["hp"]
	key(KEY_ENTER)
	await create_timer(0.35).timeout
	check(screen.snapshot["core"]["battle"]["actors"]["Boss"]["hp"] < keyboard_hp,"P43-KEYBOARD-CONFIRM-PAYS-AND-DAMAGES")
	await create_timer(0.22).timeout
	await shot("p4_3_hit_1280")
	await create_timer(0.5).timeout
	key(KEY_SPACE)
	await process_frame
	check(screen.hud.reaction_panel.visible,"P43-KEYBOARD-END-REACTION")
	await shot("p4_3_reaction_1280")
	# Click the actual modal Pass button, not a direct command/test damage hook.
	var pass_button: Button = screen.hud.reaction_column.get_child(-1).get_child(-1)
	var center: Vector2 = pass_button.get_global_rect().get_center()
	var tape_before_pass: int = screen.controller.tape().size()
	mouse(center,true)
	mouse(center,false)
	await create_timer(0.65).timeout
	check(screen.controller.tape().size() > tape_before_pass,"P43-MOUSE-PASS-SUBMITS-REACTION")
	var explicit_passes: int = 1
	while screen.snapshot["phase"] == "ENEMY_PHASE" and screen.hud.reaction_panel.visible and explicit_passes < 4:
		var next_actions: HBoxContainer = screen.hud.reaction_column.get_child(screen.hud.reaction_column.get_child_count()-1)
		var next_pass: Button = next_actions.get_child(1)
		var next_center: Vector2 = next_pass.get_global_rect().get_center()
		mouse(next_center,true)
		mouse(next_center,false)
		await create_timer(0.65).timeout
		explicit_passes += 1
	check(screen.snapshot["phase"] == "PLAYER_PHASE","P43-MOUSE-PASS-EXPLICITLY-COMPLETES-ENEMY-PHASE")
	await create_timer(0.8).timeout
	root.size = Vector2i(1920,1080)
	await process_frame
	await shot("p4_3_round2_1920")
	screen.set_locale("en")
	await process_frame
	await shot("p4_3_en_1920")
	var eight: Dictionary = screen.controller.snapshot()
	var zones: Dictionary = eight["core"]["cards"]["actors"]["A"]["zones"]
	while zones["hand"].size() < 8: zones["hand"].append(zones["draw"].pop_back())
	screen.present(eight)
	await create_timer(0.3).timeout
	for dims: Vector2i in [Vector2i(1280,720),Vector2i(1920,1080)]:
		root.size = dims
		await process_frame
		var safe: bool = true
		for view: Control in screen.hud.card_views:
			for corner: Vector2 in [Vector2.ZERO,Vector2(view.size.x,0),view.size,Vector2(0,view.size.y)]:
				var point: Vector2 = view.get_global_transform()*corner
				safe = safe and point.x >= 0 and point.y >= 0 and point.x <= dims.x and point.y <= dims.y
		check(safe,"P43-EIGHT-ROTATED-BOUNDS-"+str(dims.x))
		await shot("p4_3_eight_"+str(dims.x))
	screen.queue_free()
	await process_frame
	print("P4_INPUT_REPORT executed=%d passed=%d failed=%d" % [executed,executed-failed,failed])
	quit(0 if failed == 0 else 1)
