extends SceneTree
## Scoped V3.4 X11 GUI test. Input goes through Godot event dispatch.
## Does not invoke historical P4.4 GUI suite or change Domain rules.
const Scene = preload("res://scenes/battle/battle_screen.tscn")
const Commands = preload("res://scenes/battle/ui/command_menu.tscn")
const Model = preload("res://scripts/domain/m1/combat_model.gd")
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, id: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print(("PASS " if ok else "FAIL ") + id)

func _window_point(logical: Vector2) -> Vector2:
	var visible: Vector2 = root.get_visible_rect().size
	return Vector2(logical.x * float(root.size.x) / visible.x,
		logical.y * float(root.size.y) / visible.y)

func _click(point: Vector2) -> void:
	var physical: Vector2 = _window_point(point)
	root.warp_mouse(physical)
	var move := InputEventMouseMotion.new()
	move.position = physical
	move.global_position = physical
	root.push_input(move)
	await create_timer(0.04).timeout
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
	await create_timer(0.04).timeout

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("V3.4 requires actual GUI event dispatch, not --headless.")
		quit(1)
		return
	root.size = Vector2i(1280, 720)
	var screen: Control = Scene.instantiate()
	root.add_child(screen)
	await create_timer(0.42).timeout
	var initial: String = Model.state_hash(screen.snapshot)
	var hud: Control = screen.hud
	for actor: String in ["B", "C", "A"]:
		var button: Button = hud.roster[actor]
		await _click(button.get_global_rect().get_center())
		check(screen.selected_actor == actor, "V34-GUI-HERO-CLICK-" + actor)
		check(button.button_pressed, "V34-GUI-HERO-SELECTED-" + actor)
		check(Model.state_hash(screen.snapshot) == initial, "V34-GUI-HERO-HASH-" + actor)

	# Command component detached from battle so real clicks cannot execute commands.
	# This validates exact signal routing and accent rails do not steal the event.
	var commands: Control = Commands.instantiate()
	commands.position = Vector2(560, 115)
	commands.size = Vector2(248, 266)
	commands.z_index = 500
	root.add_child(commands)
	await process_frame
	var events: Array[String] = []
	commands.command_requested.connect(func(kind: String, _fields: Dictionary) -> void:
		events.append(kind))
	var keys: Array[String] = ["BATTLE_BASIC", "BATTLE_SWAP", "BATTLE_LAST",
		"BATTLE_END", "BATTLE_ANALYZE", "BATTLE_ITEM"]
	var expected: Array[String] = ["BASIC_ATTACK_RESOURCE_ONLY", "FREE_SWAP",
		"ACTIVATE_LAST_SPELL_M4", "END_PLAYER_PHASE", "UNIMPLEMENTED", "UNIMPLEMENTED"]
	for i: int in keys.size():
		var button: Button = commands.command_buttons[keys[i]]
		await _click(button.get_global_rect().get_center())
		check(events.size() == i+1, "V34-GUI-COMMAND-FIRES-ONE-" + keys[i])
		check(events.size() > i and events[i] == expected[i],
			"V34-GUI-COMMAND-UNCHANGED-" + keys[i])
	check(Model.state_hash(screen.snapshot) == initial, "V34-GUI-COMMAND-READONLY")

	# Focus styles are readable for keyboard navigation, without navigating menus.
	hud.roster["A"].grab_focus()
	await process_frame
	check(root.gui_get_focus_owner() == hud.roster["A"], "V34-GUI-HERO-KEYBOARD-FOCUS")
	check(hud.roster["A"].get_theme_stylebox("focus") is StyleBoxFlat,
		"V34-GUI-HERO-FOCUS-VISIBLE")
	commands.command_buttons["BATTLE_LAST"].grab_focus()
	await process_frame
	check(root.gui_get_focus_owner() == commands.command_buttons["BATTLE_LAST"],
		"V34-GUI-COMMAND-KEYBOARD-FOCUS")
	check(commands.command_buttons["BATTLE_LAST"].get_theme_stylebox("focus") is StyleBoxFlat,
		"V34-GUI-COMMAND-FOCUS-VISIBLE")
	commands.queue_free()
	await process_frame
	root.size = Vector2i(1920, 1080)
	await create_timer(0.22).timeout
	hud = screen.hud
	await _click(hud.roster["C"].get_global_rect().get_center())
	check(screen.selected_actor == "C", "V34-GUI-1920-HERO-C")
	check(Model.state_hash(screen.snapshot) == initial, "V34-GUI-1920-DOMAIN-READONLY")
	screen.queue_free()
	await process_frame
	print("V34_GUI_REPORT executed=%d passed=%d failed=%d" % [checks, checks-failures, failures])
	quit(0 if failures == 0 else 1)

