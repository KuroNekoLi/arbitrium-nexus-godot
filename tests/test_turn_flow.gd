extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame

	# Verify that ending the player phase automatically resolves when no reaction is playable.
	for hero_id: String in game.HEROES:
		game.battle.hands[hero_id] = game.battle.hands[hero_id].filter(func(card: CardData) -> bool: return not card.reaction)
		game.battle.heroes[hero_id]["mana"] = 0
	game._on_end_turn()
	if game.battle.phase != "PLAYER" or game.battle.round != 2:
		push_error("Boss did not automatically act and begin the next round when no reaction was available")
		quit(1)
		return

	# Force an available reaction and confirm that the boss resolves after the short window.
	var reaction: CardData = load("res://resources/cards/interrupt.tres")
	game.battle.hands["kleya"].append(reaction)
	game.battle.heroes["kleya"]["mana"] = maxi(1, int(game.battle.heroes["kleya"]["mana"]))
	game._on_end_turn()
	if game.battle.phase != "ENEMY" or not game._has_reaction_option():
		push_error("Available reaction did not open the reaction window")
		quit(1)
		return
	await create_timer(game.REACTION_WINDOW_SECONDS + 0.3).timeout
	if game.battle.phase != "PLAYER" or game.battle.round != 3:
		push_error("Boss did not automatically resolve after the reaction window")
		quit(1)
		return
	print("TURN FLOW TEST PASS // auto boss action, brief reaction window, automatic next round")
	quit(0)
