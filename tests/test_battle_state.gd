extends SceneTree

const BattleStateClass = preload("res://scripts/domain/battle_state.gd")

var failures: int = 0

func _init() -> void:
	_test_opening_hands()
	_test_play_limit_and_mana()
	_test_enemy_phase_and_reaction()
	_test_deterministic_intent()
	if failures == 0:
		print("M1 TESTS PASS // 4 suites")
		quit(0)
	else:
		print("M1 TESTS FAIL // %d failures" % failures)
		quit(1)

func _test_opening_hands() -> void:
	var state = BattleStateClass.new()
	for hero_id: String in ["kleya", "nova", "yora"]:
		_assert(state.hands[hero_id].size() == 4, "opening hand is 4 for " + hero_id)
		_assert(state.decks[hero_id].size() == 4, "remaining deck is 4 for " + hero_id)

func _test_play_limit_and_mana() -> void:
	var state = BattleStateClass.new()
	var hero_id := "kleya"
	state.heroes[hero_id]["mana"] = 10
	var first_ordinary := 0
	while first_ordinary < state.hands[hero_id].size() and not state.hands[hero_id][first_ordinary].is_ordinary():
		first_ordinary += 1
	_assert(state.play_card(hero_id, first_ordinary), "first ordinary card plays")
	var second_ordinary := 0
	while second_ordinary < state.hands[hero_id].size() and not state.hands[hero_id][second_ordinary].is_ordinary():
		second_ordinary += 1
	_assert(state.play_card(hero_id, second_ordinary), "second ordinary card plays")
	var hand_before: int = state.hands[hero_id].size()
	_assert(not state.play_card(hero_id, 0), "third ordinary card is blocked")
	_assert(state.hands[hero_id].size() == hand_before, "blocked play does not mutate hand")

func _test_enemy_phase_and_reaction() -> void:
	var state = BattleStateClass.new()
	state.heroes["kleya"]["mana"] = 3
	var reaction_index := -1
	for i: int in range(state.hands["kleya"].size()):
		if state.hands["kleya"][i].reaction:
			reaction_index = i
			break
	_assert(reaction_index >= 0, "reaction card is in independent deck")
	state.end_player_phase()
	_assert(state.phase == "ENEMY", "enemy phase opens")
	_assert(state.play_reaction("kleya", reaction_index), "reaction interrupts intent")
	state.resolve_enemy_phase()
	_assert(state.phase == "PLAYER", "player phase resumes")

func _test_deterministic_intent() -> void:
	var a = BattleStateClass.new()
	var b = BattleStateClass.new()
	_assert(a.boss_intent == b.boss_intent, "fixed seed initial intent")
	a.end_player_phase()
	b.end_player_phase()
	a.resolve_enemy_phase()
	b.resolve_enemy_phase()
	_assert(a.boss_intent == b.boss_intent and a.round == b.round, "fixed seed intent order")

func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		print("FAIL: " + message)
	else:
		print("PASS: " + message)

