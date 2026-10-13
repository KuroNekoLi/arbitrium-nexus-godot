extends SceneTree

const GameScene = preload("res://scenes/main.tscn")

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var game: Control = GameScene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	var viewport_image: Image = root.get_viewport().get_texture().get_image()
	viewport_image.save_png(ProjectSettings.globalize_path("res://outputs/combat_ui_mvp.png"))
	var attack_card: Control
	for view: Control in game.card_views:
		if view.combat_data.kind == CardData.CardKind.ATTACK:
			attack_card = view
			break
	if attack_card == null:
		push_error("No ordinary attack card is available for capture")
		quit(1)
		return
	game._on_card_drag_started(attack_card, attack_card)
	game._handle_card_release(attack_card, Vector2(880, 300))
	await create_timer(0.17).timeout
	viewport_image = root.get_viewport().get_texture().get_image()
	viewport_image.save_png(ProjectSettings.globalize_path("res://outputs/card_attack_midflight.png"))
	await create_timer(0.4).timeout
	viewport_image = root.get_viewport().get_texture().get_image()
	viewport_image.save_png(ProjectSettings.globalize_path("res://outputs/card_attack_impact.png"))
	print("Saved current card travel and impact captures")
	quit(0)
