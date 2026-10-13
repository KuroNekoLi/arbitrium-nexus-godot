extends SceneTree

const DeckProfileStoreClass = preload("res://scripts/domain/deck_profile_store.gd")
const BattleStateClass = preload("res://scripts/domain/battle_state.gd")
const GameScene = preload("res://scenes/main.tscn")

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_profile_save_load_export()
	await _test_builder_composition()
	if failures == 0:
		print("M5 TESTS PASS // profile persistence, export, and editor composition")
		quit(0)
	else:
		print("M5 TESTS FAIL // %d failures" % failures)
		quit(1)

func _test_profile_save_load_export() -> void:
	var profile: Dictionary = DeckProfileStoreClass.default_profile()
	_assert(DeckProfileStoreClass.is_valid_profile(profile), "default profile contains three valid 8-card decks")
	profile["decks"]["kleya"].erase("strike")
	profile["decks"]["kleya"].append("rapid_cut")
	var save_path := "user://deck_profile_test.json"
	var export_path := "user://deck_profile_test_export/decks.json"
	_assert(DeckProfileStoreClass.save_profile(profile, save_path), "custom deck profile saves")
	var loaded: Dictionary = DeckProfileStoreClass.load_profile(save_path)
	_assert(loaded["decks"]["kleya"].has("rapid_cut"), "saved deck profile loads with edits")
	_assert(DeckProfileStoreClass.export_profile(profile, export_path), "deck profile exports as JSON")
	_assert(FileAccess.file_exists(export_path), "export JSON exists at its selected path")
	var invalid: Dictionary = profile.duplicate(true)
	invalid["decks"]["nova"].pop_back()
	_assert(not DeckProfileStoreClass.save_profile(invalid, save_path), "invalid deck size is rejected")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(export_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://deck_profile_test_export"))

func _test_builder_composition() -> void:
	var game: Control = GameScene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game._open_deck_builder()
	await process_frame
	var builder: Control = game.deck_builder
	_assert(builder != null, "deck editor opens from the battle screen")
	if builder != null:
		builder._restore_defaults()
		var initial_count: int = builder.profile["decks"]["kleya"].size()
		builder._remove_card("strike")
		builder._add_card("rapid_cut")
		_assert(initial_count == 8 and builder.profile["decks"]["kleya"].size() == 8, "deck editor keeps the configured deck size")
		_assert(builder.profile["decks"]["kleya"].has("rapid_cut"), "deck editor replaces cards from the catalog")
		_assert(DeckProfileStoreClass.is_valid_profile(builder.profile), "edited profile passes validation")
		var battle = BattleStateClass.new(builder.profile)
		var has_custom_card := false
		var configured_cards: Array = battle.decks["kleya"] + battle.hands["kleya"]
		for card in configured_cards:
			if card.id == "kleya_rapid_cut": has_custom_card = true
		_assert(has_custom_card, "customized Resource deck is used by the combat engine")
	game.queue_free()

func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + message)
	else:
		print("PASS: " + message)
