extends SceneTree
## USER_APPROVED 2026-10-16 gesture oracle; not the historical P4.4 GUI suite.
const Scene = preload("res://scenes/battle/battle_screen.tscn")
const Model = preload("res://scripts/domain/m1/combat_model.gd")
var executed: int = 0
var failed: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, id: String) -> void:
	executed += 1
	if not ok: failed += 1
	print(("PASS " if ok else "FAIL ") + id)

func move_pointer(point: Vector2) -> void:
	root.warp_mouse(point)
	var motion := InputEventMouseMotion.new()
	motion.position = point * Vector2(root.size) / root.get_visible_rect().size
	motion.global_position = motion.position
	root.push_input(motion)
	await create_timer(0.04).timeout

func mouse_button(point: Vector2, down: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = point * Vector2(root.size) / root.get_visible_rect().size
	event.global_position = event.position
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = down
	root.push_input(event)
	await process_frame

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("SP gesture verification requires a rendered Godot window")
		quit(1)
		return
	root.size = Vector2i(1280, 720)
	var screen: Control = Scene.instantiate()
	root.add_child(screen)
	await create_timer(0.5).timeout
	screen._command_requested("REDUCED_MOTION", {"enabled": true})
	for full: bool in [false, true]:
		screen._command_requested("RESTART_BATTLE", {})
		screen.select_actor("C")
		await create_timer(0.3).timeout
		var card: Control
		for candidate: Control in screen.hud.card_views:
			if candidate.can_full_chant:
				card = candidate
				break
		check(card != null, "SPG-REAL-DUAL-CARD-" + str(full))
		if card == null: continue
		var instance: String = card.instance_id
		var before: String = Model.state_hash(screen.snapshot)
		var start: Vector2 = card.get_global_transform() * Vector2(60, 80)
		await move_pointer(start)
		await mouse_button(start, true)
		if full:
			await create_timer(0.55).timeout
			check(card.full_chant_held and screen.hud.mode.selected == 1, "SPG-HOLD-FULL-PREVIEW")
			check(Model.state_hash(screen.snapshot) == before, "SPG-HOLD-NO-PAYMENT")
		var target: Vector2 = screen.hud.target_buttons["Boss"].get_global_rect().get_center()
		await move_pointer(target)
		await create_timer(0.07).timeout
		await mouse_button(target, false)
		await create_timer(0.1).timeout
		var tape: Array = screen.controller.tape()
		check(tape.size() == 1, "SPG-RELEASE-ONE-COMMAND-" + str(full))
		if tape.size() == 1:
			check(tape[0].get("casting_mode", "") == ("FULL" if full else "CHANTLESS"), "SPG-RELEASE-MODE-" + str(full))
		check(not screen.snapshot["core"]["cards"]["actors"]["C"]["zones"]["hand"].has(instance), "SPG-REAL-HAND-PAYMENT-" + str(full))
		check(screen.pending_card.is_empty() and screen.hud.mode.selected == 0, "SPG-RESET-AFTER-RELEASE-" + str(full))
		check(screen.controller.replay_receipt()["matches"], "SPG-REPLAY-" + str(full))
	# Invalid Full drop must neither pay nor retain FULL mode.
	screen._command_requested("RESTART_BATTLE", {})
	screen.select_actor("C")
	await create_timer(0.3).timeout
	var invalid_card: Control = screen.hud.card_views[0]
	var invalid_before: String = Model.state_hash(screen.snapshot)
	var p: Vector2 = invalid_card.get_global_transform() * Vector2(60, 80)
	await move_pointer(p)
	await mouse_button(p, true)
	await create_timer(0.55).timeout
	var outside := Vector2(680, 145)
	await move_pointer(outside)
	await create_timer(0.07).timeout
	await mouse_button(outside, false)
	check(Model.state_hash(screen.snapshot) == invalid_before and screen.controller.tape().is_empty(), "SPG-INVALID-ATOMIC")
	check(not invalid_card.full_chant_held and screen.hud.mode.selected == 0, "SPG-INVALID-RESET")
	check(screen.hud.confirm_button.disabled, "SPG-INVALID-NO-STALE-CONFIRM")
	screen.queue_free()
	await process_frame
	print("SP_GESTURE_REPORT executed=%d passed=%d failed=%d" % [executed, executed - failed, failed])
	quit(0 if failed == 0 else 1)
