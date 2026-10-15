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

func _move(point: Vector2) -> void:
	root.warp_mouse(point)
	var move := InputEventMouseMotion.new()
	move.position = point
	move.global_position = point
	root.push_input(move)
	await create_timer(0.03).timeout

func _click(point: Vector2) -> void:
	await _move(point)
	var down := InputEventMouseButton.new()
	down.position = point
	down.global_position = point
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	root.push_input(down)
	var up := InputEventMouseButton.new()
	up.position = point
	up.global_position = point
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
	var disclosure: Button = context.get_node("PreferencesDisclosure")
	var settings: Control = context.detail_scroll.get_child(0).get_node("PreferencesContent")
	var confirm: Button = screen.hud.confirm_button
	var baseline: Rect2 = confirm.get_global_rect()
	check(not settings.visible, "V25-PREFERENCES-DEFAULT-COLLAPSED")
	await _click(disclosure.get_global_rect().get_center())
	check(settings.visible, "V25-PREFERENCES-MOUSE-OPEN")
	check(not context.detail_scroll.is_ancestor_of(confirm), "V25-CONFIRM-OUTSIDE-SCROLL")
	check(confirm.is_visible_in_tree() and context.get_global_rect().encloses(confirm.get_global_rect()),
		"V25-CONFIRM-VISIBLE-EXPANDED")
	check(baseline.position.distance_to(confirm.get_global_rect().position) < 2.0,
		"V25-CONFIRM-PINNED")
	check(context.reduced_toggle != null and context.mute_toggle != null,
		"V25-PREFERENCES-COMPAT-ALIASES")
	await _click(disclosure.get_global_rect().get_center())
	check(not settings.visible, "V25-PREFERENCES-MOUSE-CLOSE")
	screen.select_card(screen.hud.card_views[0].instance_id)
	var cancel: Button = context.action_row.get_child(1)
	await _click(cancel.get_global_rect().get_center())
	check(screen.pending_card.is_empty(), "V25-FOOTER-CANCEL-REAL-MOUSE")
	check(Model.state_hash(screen.snapshot) == hash, "V25-FOOTER-NO-DOMAIN-WRITE")

	# Also exercise the same physical GUI geometry under 1920x1080 stretch.
	root.size = Vector2i(1920, 1080)
	await create_timer(0.25).timeout
	screen.cancel_action()
	var last: Control = screen.hud.card_views[7]
	check(await _mouse_pick(screen, last), "V25-MOUSE-1920-LAST-CARD")
	check(Model.state_hash(screen.snapshot) == hash, "V25-1920-NO-DOMAIN-WRITE")

	screen.queue_free()
	await process_frame
	print("V25_GUI_REPORT executed=%d passed=%d failed=%d" % [passed + failed, passed, failed])
	quit(0 if failed == 0 else 1)

