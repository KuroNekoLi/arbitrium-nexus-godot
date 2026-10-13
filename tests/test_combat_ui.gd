extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	var playable: Control
	for view: Control in game.card_views:
		var card: CardData = view.card_data
		if card.is_ordinary():
			playable = view
			break
	if playable == null:
		push_error("UI test could not find an ordinary opening card")
		quit(1)
		return
	var hp_before: int = game.battle.boss_hp
	var hand_before: int = game.battle.hands[game.selected_hero].size()
	game._on_card_drag_started(playable)
	game._on_card_drag_released(playable, Vector2(880, 300))
	if game.battle.boss_hp >= hp_before or game.battle.hands[game.selected_hero].size() != hand_before - 1:
		push_error("Dragging an ordinary card to the boss zone did not play it")
		quit(1)
		return
	print("UI TEST PASS // drag-to-play resolves card and updates boss HP")
	quit(0)
