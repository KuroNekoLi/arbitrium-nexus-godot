extends SceneTree
const Scene = preload("res://scenes/battle/battle_screen.tscn")
var failed: int = 0
var executed: int = 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, id: String) -> void:
	executed += 1
	if not ok: failed += 1
	print(("PASS " if ok else "FAIL ")+id)
func shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://outputs/"+path+".png")) == OK,"P43-CAPTURE-"+path)
func mouse(point: Vector2, down: bool) -> void:
	root.warp_mouse(point)
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = point
	event.global_position = point
	event.pressed = down
	root.push_input(event)
func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	root.push_input(event)
	event = InputEventKey.new()
	event.physical_keycode = code
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
	root.warp_mouse(Vector2(820,285))
	await create_timer(0.15).timeout
	check(card.holding,"P43-MOUSE-DRAG-ACTUAL-ADDON")
	await shot("p4_3_drag_1280")
	mouse(Vector2(820,285),false)
	await process_frame
	check(screen.selected_target == "Boss" and not screen.hud.confirm_button.disabled,"P43-DROP-LEGAL-TARGET")
	var hp: int = screen.snapshot["core"]["battle"]["actors"]["Boss"]["hp"]
	key(KEY_ENTER)
	check(screen.snapshot["core"]["battle"]["actors"]["Boss"]["hp"] < hp,"P43-KEYBOARD-CONFIRM-PAYS-AND-DAMAGES")
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
	mouse(center,true)
	mouse(center,false)
	await process_frame
	check(screen.snapshot["phase"] == "PLAYER_PHASE","P43-MOUSE-PASS-RESUMES-BOSS")
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
