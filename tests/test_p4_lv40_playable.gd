extends SceneTree
## New positive scene integration contract, not a rerun of the restricted GUI suite.
const Scene = preload("res://scenes/battle/lv40_playable_battle.tscn")
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const Factory = preload("res://scripts/battle/battle_command_factory.gd")
const Controller = preload("res://scripts/battle/battle_controller.gd")
var executed: int = 0
var failed: int = 0

func _initialize() -> void: call_deferred("run")

func check(ok: bool, id: String) -> void:
	executed += 1
	if not ok: failed += 1
	print(("PASS " if ok else "FAIL ")+id)

func pass_window(screen: Control) -> void:
	if screen.snapshot["reaction_window"].get("status","") == "DRAFTING":
		screen._command_requested("PASS_REACTION",{})

func restart(screen: Control) -> void:
	screen._command_requested("RESTART_BATTLE",{})
	screen.director.reduced_motion = true

func run() -> void:
	var screen: Control = Scene.instantiate()
	root.add_child(screen)
	await process_frame
	screen.director.reduced_motion = true
	check(screen.config.get("m5_lv40_enabled",false),"P45-LIVE-CONFIG")
	check(screen.snapshot["core"]["battle"]["actors"]["Boss"]["max_hp"] == 2700,"P45-NOT-LEGACY-FIXTURE")
	var initial_hash: String = Model.state_hash(screen.snapshot)
	for actor: String in ["A","B","C"]:
		screen.select_actor(actor)
		var own: Dictionary = screen.snapshot["core"]["cards"]["actors"][actor]
		check(own["instances"].size() == 12 and screen.hud.card_views.size() == 4,"P45-DECK-"+actor)
		check(screen.hud.roster[actor].name_label.text == screen.tr(screen.config["actor_name_keys"][actor]),"P45-NAME-"+actor)
	check(Model.state_hash(screen.snapshot) == initial_hash,"P45-SELECTION-NO-COMMAND")
	var chosen: bool = false
	for actor: String in ["A","B","C"]:
		screen.select_actor(actor)
		for card: Control in screen.hud.card_views.duplicate():
			var instance: String = card.instance_id
			screen.select_card(instance)
			if not screen.legal_targets.has("Boss"): continue
			screen.select_target("Boss")
			var command: Dictionary = screen.pending_command.duplicate(true)
			var before: Dictionary = screen.controller.snapshot()
			var expected: Dictionary = Factory.preview(before,command,screen.config)
			check(command["type"] == "PLAY_LV40_CARD","P45-CONTENT-COMMAND")
			screen.confirm_action()
			check(Model.state_hash(screen.snapshot) == expected["state_hash"],"P45-REDUCER-PARITY")
			check(screen.snapshot["core"]["cards"]["actors"][actor]["zones"]["discard"].has(instance),"P45-REAL-DISCARD")
			check(screen.snapshot["core"]["battle"]["party_resources"]["current_ap"] < before["core"]["battle"]["party_resources"]["current_ap"],"P45-REAL-PAYMENT")
			var frozen: String = Model.state_hash(screen.snapshot)
			check(not screen.controller.submit(command) and Model.state_hash(screen.snapshot) == frozen,"P45-DUPLICATE-ATOMIC")
			chosen = true
			break
		if chosen: break
	check(chosen,"P45-REAL-CARD-FOUND")
	check(screen.controller.replay_receipt()["matches"],"P45-CARD-REPLAY")
	restart(screen)
	var full: bool = false
	for actor: String in ["A","B","C"]:
		screen.select_actor(actor)
		for card: Control in screen.hud.card_views.duplicate():
			screen.select_card(card.instance_id)
			if not screen.hud.mode.visible: continue
			screen.hud.mode.select(1)
			screen._command_requested("REFRESH_PREVIEW",{})
			if not screen.legal_targets.has("Boss"): continue
			screen.select_target("Boss")
			if screen.hud.confirm_button.disabled: continue
			screen.confirm_action()
			full = true
			break
		if full: break
	check(full and not screen.view_model["casts"].is_empty(),"P45-FULL-CAST-START")
	screen._command_requested("END_PLAYER_PHASE",{})
	check(screen.snapshot["reaction_window"].get("status","") == "DRAFTING","P45-REACTION-MANUAL")
	var paused: String = Model.state_hash(screen.snapshot)
	await create_timer(0.1).timeout
	check(Model.state_hash(screen.snapshot) == paused,"P45-NO-AUTO-PASS")
	pass_window(screen)
	check(screen.snapshot["phase"] == "PLAYER_PHASE" and screen.view_model["round"] == 2,"P45-NEXT-ROUND")
	check(screen.controller.replay_receipt()["matches"],"P45-FULL-REPLAY")
	restart(screen)
	screen.select_actor("C")
	screen._command_requested("ACTIVATE_LAST_SPELL_M4",{})
	check(screen.legal_targets.has("C") and not screen.legal_targets.has("Boss"),"P45-SUPPORT-LAST-TARGET")
	screen.select_target("C")
	screen.confirm_action()
	check(not screen.view_model["casts"].is_empty(),"P45-LAST-STARTED")
	for i: int in 2:
		screen._command_requested("END_PLAYER_PHASE",{})
		pass_window(screen)
	check(screen.view_model["actors"]["C"]["status"] == "EXHAUSTED","P45-LAST-RELEASED")
	check(screen.controller.replay_receipt()["matches"],"P45-LAST-REPLAY")
	restart(screen)
	for i: int in 24:
		if screen.view_model["outcome"] != "ONGOING": break
		screen._command_requested("END_PLAYER_PHASE",{})
		pass_window(screen)
	check(screen.view_model["outcome"] == "DEFEAT","P45-NATURAL-TERMINAL")
	check(screen.hud.result_panel.visible,"P45-OUTCOME-HUD")
	check(screen.controller.save_tape("user://p45_lv40.tape") == OK,"P45-TAPE-SAVE")
	check(Controller.verify_saved_tape("user://p45_lv40.tape")["matches"],"P45-TAPE-REPLAY")
	screen.set_locale("en")
	check(screen.view_model["actor_name_keys"]["A"] == screen.config["actor_name_keys"]["A"],"P45-LOCALE-CONFIG-RETAINED")
	var owner_ref: WeakRef = weakref(screen.controller)
	screen.queue_free()
	await process_frame
	check(owner_ref.get_ref() == null,"P45-CLEANUP")
	var again: Control = Scene.instantiate()
	root.add_child(again)
	await process_frame
	check(again.controller.tape().is_empty() and Model.state_hash(again.snapshot) == initial_hash,"P45-FRESH-REENTRY")
	again.queue_free()
	await process_frame
	print("P4_LV40_PLAYABLE_REPORT executed=%d passed=%d failed=%d" % [executed,executed-failed,failed])
	quit(1 if failed else 0)
