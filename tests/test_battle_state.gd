extends SceneTree

const BattleStateClass = preload("res://scripts/domain/battle_state.gd")

var failures: int = 0

func _init() -> void:
	_test_opening_hands()
	_test_play_limit_and_mana()
	_test_enemy_phase_and_reaction()
	_test_deterministic_intent()
	_test_support_effects_do_not_damage_boss()
	_test_attack_stability_effects()
	if failures == 0:
		print("M1 TESTS PASS // 6 suites")
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

func _test_support_effects_do_not_damage_boss() -> void:
	var state = BattleStateClass.new()
	var focus: CardData = null
	var focus_index := -1
	for i: int in range(state.hands["nova"].size()):
		if state.hands["nova"][i].id.ends_with("focus"):
			focus = state.hands["nova"][i]
			focus_index = i
			break
	for i: int in range(state.decks["nova"].size()):
		if focus != null: break
		if state.decks["nova"][i].id.ends_with("focus"):
			focus = state.decks["nova"].pop_at(i)
			break
	_assert(focus != null, "focus exists in character deck")
	if focus == null: return
	if focus_index < 0:
		state.hands["nova"].append(focus)
		focus_index = state.hands["nova"].size() - 1
	var hp_before: int = state.boss_hp
	_assert(state.play_card("nova", focus_index), "focus is playable")
	_assert(state.boss_hp == hp_before, "support card does not deal unintended boss damage")
	_assert(state.analysis == 2, "focus grants its declared Analysis")
	_assert(state.heroes["nova"]["mana"] == 4, "focus grants its declared Mana")

func _test_attack_stability_effects() -> void:
	for definition: Dictionary in [{"suffix": "pierce", "loss": 6}, {"suffix": "rupture", "loss": 12}]:
		var state = BattleStateClass.new()
		state.heroes["kleya"]["mana"] = 10
		var card_index := _ensure_card_in_hand(state, "kleya", String(definition.suffix))
		_assert(card_index >= 0, String(definition.suffix) + " card exists")
		if card_index >= 0:
			_assert(state.play_card("kleya", card_index), String(definition.suffix) + " is playable")
			_assert(state.boss_stability == BattleStateClass.BOSS_MAX_STABILITY - int(definition.loss), String(definition.suffix) + " applies its Stability damage")

func _ensure_card_in_hand(state: BattleState, hero_id: String, suffix: String) -> int:
	for i: int in range(state.hands[hero_id].size()):
		if state.hands[hero_id][i].id.ends_with(suffix): return i
	for i: int in range(state.decks[hero_id].size()):
		if state.decks[hero_id][i].id.ends_with(suffix):
			state.hands[hero_id].append(state.decks[hero_id].pop_at(i))
			return state.hands[hero_id].size() - 1
	return -1

func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		print("FAIL: " + message)
	else:
		print("PASS: " + message)

