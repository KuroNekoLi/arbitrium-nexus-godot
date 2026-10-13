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
		if card.kind == CardData.CardKind.ATTACK:
			playable = view
			break
	if playable == null:
		push_error("UI test could not find an ordinary opening card")
		quit(1)
		return
	var hp_before: int = game.battle.boss_hp
	var hand_before: int = game.battle.hands[game.selected_hero].size()
	var card_start: Vector2 = playable.global_position
	var actor: AnimatedSprite2D = game.hero_actors[game.selected_hero]
	var actor_start: Vector2 = actor.position
	game._on_card_drag_started(playable, playable)
	game._handle_card_release(playable, Vector2(880, 300))
	await create_timer(0.18).timeout
	if playable.global_position.distance_to(card_start) < 10.0:
		push_error("Card did not visibly travel toward the boss after release")
		quit(1)
		return
	if actor.position.distance_to(actor_start) < 5.0:
		push_error("Selected hero did not move to perform the attack")
		quit(1)
		return
	if actor.animation != "run":
		push_error("Hero did not switch to its run-cycle atlas during the charge")
		quit(1)
		return
	if game.battle.boss_hp != hp_before:
		push_error("Card effect resolved before its impact animation completed")
		quit(1)
		return
	await create_timer(0.5).timeout
	if game.battle.boss_hp >= hp_before or game.battle.hands[game.selected_hero].size() != hand_before - 1:
		push_error("Dragging an ordinary card to the boss zone did not play it")
		quit(1)
		return
	print("UI TEST PASS // drag-to-play resolves card and updates boss HP")
	quit(0)
