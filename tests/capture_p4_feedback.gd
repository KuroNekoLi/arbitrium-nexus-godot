extends SceneTree
const Scene = preload("res://scenes/battle/battle_screen.tscn")
const F = preload("res://tests/fixtures/m5_full_battle_fixture.gd")
const Driver = preload("res://tests/fixtures/m5_full_battle_driver.gd")
func _initialize() -> void: call_deferred("run")
func shot(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var error: Error = root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://outputs/p4_4_"+name+".png"))
	assert(error == OK)
	print("CAPTURE p4_4_",name)
func run() -> void:
	root.size = Vector2i(1280,720)
	var screen: Control = Scene.instantiate()
	root.add_child(screen)
	await process_frame
	screen.select_actor("C")
	for card: Control in screen.hud.card_views:
		if card.appearance.definition_id == "regular":
			screen.select_card(card.instance_id)
			break
	screen.hud.mode.select(1)
	screen.select_target("Boss")
	screen.confirm_action()
	await create_timer(0.25).timeout
	await shot("full_chant_1280")
	screen._command_requested("END_PLAYER_PHASE",{})
	screen._command_requested("QUEUE_REACTION",{"entry":{"kind":"BASIC_PROTECT","actor_id":"B","target_actor_id":"A"}})
	await shot("protect_draft_1280")
	screen._command_requested("CONFIRM_REACTIONS",{})
	await create_timer(0.22).timeout
	await shot("protect_hit_1280")
	await create_timer(0.8).timeout
	screen._command_requested("RESTART_BATTLE",{})
	screen.select_actor("A")
	screen._command_requested("ACTIVATE_LAST_SPELL_M4",{})
	screen.select_target("Boss")
	await shot("last_confirmation_1280")
	screen.confirm_action()
	await create_timer(0.15).timeout
	await shot("last_chant_1280")
	var golden: Dictionary = Driver.run(F.SEED)
	assert(golden["ok"])
	screen.director.reset_session()
	screen.present(golden["final"])
	await shot("victory_1280")
	root.size = Vector2i(1920,1080)
	screen.set_locale("en")
	await shot("victory_en_1920")
	screen.queue_free()
	await process_frame
	quit(0)
