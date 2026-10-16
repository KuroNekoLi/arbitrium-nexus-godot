extends SceneTree
## New USER_APPROVED cut-in flow, distinct from exhausted V3.5 capture group.
const Scene = preload("res://scenes/battle/lv40_playable_battle.tscn")
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const Last = preload("res://scripts/domain/m4/last_spell/last_spell_resolver.gd")
var executed: int = 0
var failed: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, id: String) -> void:
	executed += 1
	if not ok: failed += 1
	print(("PASS " if ok else "FAIL ") + id)

func click(button: Button) -> void:
	await create_timer(0.08).timeout
	var point: Vector2 = button.get_global_rect().get_center()
	root.warp_mouse(point)
	var motion := InputEventMouseMotion.new()
	motion.position = point * Vector2(root.size) / root.get_visible_rect().size
	motion.global_position = motion.position
	root.push_input(motion)
	await create_timer(0.04).timeout
	for down: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = motion.position
		event.global_position = motion.position
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		root.push_input(event)
		await process_frame

func open_preview(screen: Control) -> void:
	if DisplayServer.get_name() == "headless":
		screen._command_requested("ACTIVATE_LAST_SPELL_M4", {})
	else:
		await click(screen.hud.get_node("Commands").command_buttons["BATTLE_LAST"])

func run() -> void:
	root.size = Vector2i(1280, 720)
	var screen: Control = Scene.instantiate()
	root.add_child(screen)
	await process_frame
	screen.director.reduced_motion = true
	for actor: String in ["A", "B", "C"]:
		screen.select_actor(actor)
		var hash_before: String = Model.state_hash(screen.snapshot)
		await open_preview(screen)
		var panel: Control = screen.hud.last_preview
		var inspected: Dictionary = Last.inspect(screen.snapshot["core"], actor, screen.config)
		check(panel.visible and panel.artwork.texture != null, "LSP-IMMEDIATE-CUTIN-" + actor)
		check(not screen.hud.get_node("Context").visible, "LSP-NOT-CARD-DETAILS-" + actor)
		check(panel.costs.text == screen.tr("BATTLE_COST") % [inspected["quote"]["ap_cost"], inspected["quote"]["mp_cost"]], "LSP-DOMAIN-QUOTE-" + actor)
		check(Model.state_hash(screen.snapshot) == hash_before and screen.controller.tape().is_empty(), "LSP-OPEN-NO-PAYMENT-" + actor)
		# Superseded by the user's 2026-10-16 scope-selection references: keep
		# battlefield actors visible so the new target markers identify recipients.
		check(screen.get_node("Design/Arena/A").visible and screen.get_node("Design/Arena/B").visible and screen.get_node("Design/Arena/C").visible, "LSP-WORLD-PARTY-RETAINED-" + actor)
		check(screen.hud.roster[actor].visible and screen.hud.get_node("ModalInputShield").visible, "LSP-ROSTER-RETAINED-MODAL-" + actor)
		if DisplayServer.get_name() == "headless":
			screen.cancel_action()
		else:
			await click(panel.cancel_button)
		check(not panel.visible and screen.get_node("Design/Arena/A").visible and Model.state_hash(screen.snapshot) == hash_before, "LSP-CANCEL-RESTORES-" + actor)
	screen.select_actor("A")
	await open_preview(screen)
	if DisplayServer.get_name() == "headless":
		screen._command_requested("ACTIVATE_LAST_PREVIEW", {"target_id": "Boss"})
	else:
		await click(screen.hud.last_preview.activate_button)
	check(screen.controller.tape().size() == 1 and screen.controller.tape()[0]["confirmed"], "LSP-ACTIVATE-REAL-COMMAND")
	check(not screen.hud.last_preview.visible and screen.get_node("Design/Arena/A").visible, "LSP-COMMIT-CLOSES-CUTIN")
	check(screen.controller.replay_receipt()["matches"], "LSP-REPLAY")
	await open_preview(screen)
	check(screen.hud.last_preview.activate_button.disabled, "LSP-SECOND-ACTIVATION-BLOCKED")
	screen.cancel_action()
	screen.queue_free()
	await process_frame
	print("LAST_PREVIEW_REPORT executed=%d passed=%d failed=%d" % [executed, executed - failed, failed])
	quit(0 if failed == 0 else 1)
