extends SceneTree
## V2.5 isolated GUI hit-testing; DOES NOT invoke historical P4.4 input suite.
const Scene = preload("res://scenes/battle/battle_screen.tscn")
const Encounter = preload("res://tests/fixtures/m5_full_battle_fixture.gd")
const Model = preload("res://scripts/domain/m1/combat_model.gd")
var passed: int = 0
var failed: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else: failed += 1
	print(("PASS " if ok else "FAIL ") + label)

func _eight_hand() -> Dictionary:
	var state: Dictionary = Encounter.initial()
	var zones: Dictionary = state["core"]["cards"]["actors"]["A"]["zones"]
	while zones["hand"].size() < 8 and not zones["draw"].is_empty():
		zones["hand"].append(zones["draw"].pop_back())
	return state

## Window input events use physical pixels; canvas_items Control transforms are
## still in the 1280x720 logical viewport after a 1920x1080 window resize.
func _window_point(logical: Vector2) -> Vector2:
	var viewport: Vector2 = root.get_visible_rect().size
	return Vector2(logical.x * float(root.size.x) / viewport.x,
		logical.y * float(root.size.y) / viewport.y)

func _move(point: Vector2) -> void:
	var physical: Vector2 = _window_point(point)
	root.warp_mouse(physical)
	var move := InputEventMouseMotion.new()
	move.position = physical
	move.global_position = physical
	root.push_input(move)
	await create_timer(0.03).timeout

func _click(point: Vector2) -> void:
	await _move(point)
	var physical: Vector2 = _window_point(point)
	var down := InputEventMouseButton.new()
	down.position = physical
	down.global_position = physical
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	root.push_input(down)
	var up := InputEventMouseButton.new()
	up.position = physical
	up.global_position = physical
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	root.push_input(up)
	await process_frame

func _right() -> void:
	var press := InputEventKey.new()
	press.keycode = KEY_RIGHT
	press.physical_keycode = KEY_RIGHT
	press.pressed = true
	root.push_input(press)
	var release := InputEventKey.new()
	release.keycode = KEY_RIGHT
	release.physical_keycode = KEY_RIGHT
	release.pressed = false
	root.push_input(release)
	await process_frame

func _escape() -> void:
	var press := InputEventKey.new()
	press.keycode = KEY_ESCAPE
	press.physical_keycode = KEY_ESCAPE
	press.pressed = true
	root.push_input(press)
	var release := InputEventKey.new()
	release.keycode = KEY_ESCAPE
	release.physical_keycode = KEY_ESCAPE
	root.push_input(release)
	await process_frame

func _mouse_pick(screen: Control, card: Control) -> bool:
	var want: String = card.instance_id
	for y: float in [0.12, 0.25, 0.45, 0.65, 0.83]:
		for x: float in [0.12, 0.27, 0.40, 0.56, 0.73, 0.88]:
			screen.cancel_action()
			await _move(Vector2(930, 434))
			var p: Vector2 = card.get_global_transform() * Vector2(card.size.x * x, card.size.y * y)
			if not root.get_visible_rect().has_point(p):
				continue
			await _click(p)
			if screen.pending_card == want and card.selected_visual:
				screen.cancel_action()
				return true
	screen.cancel_action()
	print("V25_HIT_DIAG want=%s viewport=%s window=%s screen=%s card=%s mouse=%s pending=%s" % [
		want, root.get_visible_rect(), root.size, screen.size,
		card.get_global_rect(), root.get_mouse_position(), screen.pending_card])
	return false

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("V25 requires an X11-rendered GUI, not --headless.")
		quit(1)
		return
	root.size = Vector2i(1280, 720)
	var screen: Control = Scene.instantiate()
	root.add_child(screen)
	await create_timer(0.4).timeout
	screen.select_actor("A")
	screen.present(_eight_hand())
	await create_timer(0.28).timeout
	var hash: String = Model.state_hash(screen.snapshot)
	check(screen.hud.card_views.size() == 8, "V25-EIGHT-CARDS")
	for i: int in screen.hud.card_views.size():
		var card: Control = screen.hud.card_views[i]
		var reachable: bool = await _mouse_pick(screen, card)
		check(reachable, "V25-MOUSE-REAL-CLICK-%d" % i)
	check(Model.state_hash(screen.snapshot) == hash, "V25-MOUSE-NO-DOMAIN-WRITE")

	# Existing BattleScreen key mapping: Right cycles through every card instance.
	var visited: Dictionary = {}
	for i: int in 8:
		screen.cancel_action()
		await _move(Vector2(930, 434))
		await _right()
		visited[screen.pending_card] = true
		check(not screen.pending_card.is_empty() and screen.hud.hand.selected_instance == screen.pending_card,
			"V25-KEYBOARD-SELECT-%d" % i)
	check(visited.size() == 8, "V25-KEYBOARD-ALL-EIGHT")
	check(Model.state_hash(screen.snapshot) == hash, "V25-KEYBOARD-NO-DOMAIN-WRITE")

	# Disclosure must never scroll the confirmation footer away.
	var context: Control = screen.hud.get_node("Context")
	var disclosure: Button = context.preferences_disclosure
	var confirm: Button = screen.hud.confirm_button
	var baseline: Rect2 = confirm.get_global_rect()
	var confirm_visible: bool = confirm.is_visible_in_tree()
	check(not screen.hud.preferences_panel.visible, "V25-PREFERENCES-DEFAULT-COLLAPSED")
	await _click(disclosure.get_global_rect().get_center())
	check(screen.hud.preferences_panel.visible, "V25-PREFERENCES-MOUSE-OPEN")
	check(not context.detail_scroll.is_ancestor_of(confirm), "V25-CONFIRM-OUTSIDE-SCROLL")
	check(confirm.is_visible_in_tree() == confirm_visible, "V25-CONFIRM-VISIBILITY-UNCHANGED")
	check(baseline.position.distance_to(confirm.get_global_rect().position) < 2.0,
		"V25-CONFIRM-PINNED")
	check(context.reduced_toggle != null and context.mute_toggle != null,
		"V25-PREFERENCES-COMPAT-ALIASES")
	await _click(disclosure.get_global_rect().get_center())
	check(not screen.hud.preferences_panel.visible, "V25-PREFERENCES-MOUSE-CLOSE")
	await _escape()
	check(screen.pending_card.is_empty(), "V25-SELECTION-CANCEL-KEYBOARD")
	check(Model.state_hash(screen.snapshot) == hash, "V25-CANCEL-NO-DOMAIN-WRITE")

	# Also exercise the same physical GUI geometry under 1920x1080 stretch.
	root.size = Vector2i(1920, 1080)
	await create_timer(0.25).timeout
	print("V25_RESIZE_DIAG screen=%s design_scale=%s root=%s hand=%s" % [screen.size, screen.design.scale, root.size, screen.hud.hand.get_global_rect()])
	screen.cancel_action()
	var last: Control = screen.hud.card_views[7]
	check(await _mouse_pick(screen, last), "V25-MOUSE-1920-LAST-CARD")
	check(Model.state_hash(screen.snapshot) == hash, "V25-1920-NO-DOMAIN-WRITE")

	screen.queue_free()
	await process_frame
	print("V25_GUI_REPORT executed=%d passed=%d failed=%d" % [passed + failed, passed, failed])
	quit(0 if failed == 0 else 1)

