extends SceneTree
## POC-scoped GUI regression for the original card interaction contract.
## Legacy V25 preferences node paths on current master are a separate known issue.
const Battle = preload("res://scenes/battle/battle_screen.tscn")
const Fixture = preload("res://tests/fixtures/m5_full_battle_fixture.gd")
const Model = preload("res://scripts/domain/m1/combat_model.gd")
var passed: int = 0
var failed: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	if value: passed += 1
	else: failed += 1
	print(("PASS " if value else "FAIL ") + label)

func _eight() -> Dictionary:
	var state: Dictionary = Fixture.initial()
	var zones: Dictionary = state["core"]["cards"]["actors"]["A"]["zones"]
	while zones["hand"].size() < 8 and not zones["draw"].is_empty():
		zones["hand"].append(zones["draw"].pop_back())
	return state

func _physical(logical: Vector2) -> Vector2:
	var logical_size: Vector2 = root.get_visible_rect().size
	return Vector2(logical.x*float(root.size.x)/logical_size.x,logical.y*float(root.size.y)/logical_size.y)

func _move(point: Vector2) -> void:
	root.warp_mouse(point)
	var physical: Vector2 = _physical(point)
	var motion := InputEventMouseMotion.new()
	motion.position = physical
	motion.global_position = physical
	root.push_input(motion)
	await create_timer(0.03).timeout

func _click(point: Vector2) -> void:
	await _move(point)
	var physical: Vector2 = _physical(point)
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.position = physical
	down.global_position = physical
	down.pressed = true
	root.push_input(down)
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.position = physical
	up.global_position = physical
	up.pressed = false
	root.push_input(up)
	await process_frame

func _right() -> void:
	var down := InputEventKey.new()
	down.keycode = KEY_RIGHT
	down.physical_keycode = KEY_RIGHT
	down.pressed = true
	root.push_input(down)
	var up := InputEventKey.new()
	up.keycode = KEY_RIGHT
	up.physical_keycode = KEY_RIGHT
	up.pressed = false
	root.push_input(up)
	await process_frame

func _pick(screen: Control, card: Control) -> bool:
	var id: String = card.instance_id
	for y: float in [0.12, 0.25, 0.45, 0.65, 0.83]:
		for x: float in [0.12, 0.27, 0.40, 0.56, 0.73, 0.88]:
			screen.cancel_action()
			await _move(Vector2(930,434))
			var p: Vector2 = card.get_global_transform() * Vector2(card.size.x*x,card.size.y*y)
			if not root.get_visible_rect().has_point(p): continue
			await _click(p)
			if screen.pending_card == id and card.selected_visual:
				screen.cancel_action()
				return true
	screen.cancel_action()
	return false

func run() -> void:
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	root.size = Vector2i(1280,720)
	var screen: Control = Battle.instantiate()
	root.add_child(screen)
	await create_timer(0.4).timeout
	screen.present(_eight())
	await create_timer(0.25).timeout
	var state_hash: String = Model.state_hash(screen.snapshot)
	check(screen.hud.card_views.size() == 8,"HAND-EIGHT")
	for index: int in screen.hud.card_views.size():
		check(await _pick(screen,screen.hud.card_views[index]),"HAND-MOUSE-%d" % index)
	check(Model.state_hash(screen.snapshot) == state_hash,"HAND-MOUSE-NO-DOMAIN")
	var seen: Dictionary = {}
	for index: int in 8:
		screen.cancel_action()
		await _move(Vector2(930,434))
		await _right()
		seen[screen.pending_card] = true
		check(not screen.pending_card.is_empty() and
			screen.hud.hand.selected_instance == screen.pending_card,
			"HAND-KEYBOARD-%d" % index)
	check(seen.size() == 8,"HAND-KEYBOARD-ALL")
	check(not screen.hud.targeting_arrow.is_aiming,"HAND-NO-ARROW-ON-CLICK")
	check(Model.state_hash(screen.snapshot) == state_hash,"HAND-KEYBOARD-NO-DOMAIN")
	root.size = Vector2i(1920,1080)
	DisplayServer.window_set_size(Vector2i(1920,1080))
	await create_timer(0.3).timeout
	screen.cancel_action()
	check(await _pick(screen,screen.hud.card_views[7]),"HAND-MOUSE-1920-LAST")
	check(Model.state_hash(screen.snapshot) == state_hash,"HAND-1920-NO-DOMAIN")
	screen.queue_free()
	await process_frame
	print("TARGET_ARROW_HAND_REPORT executed=%d passed=%d failed=%d" % [
		passed+failed,passed,failed])
	quit(0 if failed==0 else 1)

