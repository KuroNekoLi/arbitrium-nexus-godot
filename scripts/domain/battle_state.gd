class_name BattleState
extends RefCounted

const CardDataClass = preload("res://scripts/domain/card_data.gd")
const CardCatalogClass = preload("res://scripts/domain/card_catalog.gd")
const DeckProfileStoreClass = preload("res://scripts/domain/deck_profile_store.gd")

signal changed
signal event_logged(message: String)

const PLAYER_IDS: Array[String] = ["kleya", "nova", "yora"]
const MAX_HAND: int = 6
const DRAW_TARGET: int = 4
const MAX_ORDINARY_PLAYS: int = 2
const BOSS_MAX_HP: int = 300
const BOSS_MAX_STABILITY: int = 50
const V1_SEED: int = 104729

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var phase: String = "PLAYER"
var round: int = 1
var ordinary_plays: int = 0
var analysis: int = 0
var boss_hp: int = BOSS_MAX_HP
var boss_stability: int = BOSS_MAX_STABILITY
var boss_intent: String = "NEXUS_LANCE"
var intent_index: int = 0
var interrupt_available: bool = true
var heroes: Dictionary = {}
var decks: Dictionary = {}
var hands: Dictionary = {}
var discard: Dictionary = {}

func _init(profile_override: Dictionary = {}) -> void:
	rng.seed = V1_SEED
	var active_profile: Dictionary = profile_override if DeckProfileStoreClass.is_valid_profile(profile_override) else DeckProfileStoreClass.load_profile()
	for hero_id in PLAYER_IDS:
		heroes[hero_id] = {"hp": 100, "max_hp": 100, "mana": 3, "max_mana": 3}
		decks[hero_id] = _make_deck(hero_id, active_profile["decks"][hero_id])
		hands[hero_id] = []
		discard[hero_id] = []
	for hero_id in PLAYER_IDS:
		_draw_until(hero_id, DRAW_TARGET)
	_log("第 1 回合｜我方階段｜三組獨立牌組已就緒")

func _make_deck(owner_id: String, card_ids: Array) -> Array:
	var cards: Array = []
	for card_id: Variant in card_ids:
		var card: CardData = CardCatalogClass.create_card(String(card_id), owner_id)
		if card != null:
			cards.append(card)
	return cards

func _draw_until(hero_id: String, target: int) -> void:
	while hands[hero_id].size() < target and hands[hero_id].size() < MAX_HAND:
		if decks[hero_id].is_empty():
			decks[hero_id] = discard[hero_id].duplicate()
			discard[hero_id].clear()
		if decks[hero_id].is_empty():
			return
		var index: int = rng.randi_range(0, decks[hero_id].size() - 1)
		hands[hero_id].append(decks[hero_id].pop_at(index))

func play_card(hero_id: String, hand_index: int) -> bool:
	if phase != "PLAYER" or ordinary_plays >= MAX_ORDINARY_PLAYS:
		return false
	if not hands.has(hero_id) or hand_index < 0 or hand_index >= hands[hero_id].size():
		return false
	var card = hands[hero_id][hand_index]
	if not card.is_ordinary() or int(heroes[hero_id]["mana"]) < card.cost:
		return false
	heroes[hero_id]["mana"] -= card.cost
	hands[hero_id].remove_at(hand_index)
	discard[hero_id].append(card)
	ordinary_plays += 1
	analysis += card.analysis_gain
	if card.healing > 0:
		heroes[hero_id]["hp"] = mini(int(heroes[hero_id]["max_hp"]), int(heroes[hero_id]["hp"]) + card.healing)
		_log("%s 施展%s｜生命 +%d" % [_hero_name(hero_id), card.title, card.healing])
	elif card.kind == CardDataClass.CardKind.ATTACK:
		_damage_boss(card.power, card.title, card.stability_damage)
	else:
		_log("%s 施展%s｜分析值 +%d" % [_hero_name(hero_id), card.title, card.analysis_gain])
	if card.mana_gain > 0:
		heroes[hero_id]["mana"] = mini(int(heroes[hero_id]["max_mana"]) + 1, int(heroes[hero_id]["mana"]) + card.mana_gain)
		_log("%s 回復能量 +%d" % [_hero_name(hero_id), card.mana_gain])
	if analysis >= 3:
		_log("分析完成｜已提高對敵方意圖的掌握")
		analysis = 0
	changed.emit()
	return true

func play_reaction(hero_id: String, hand_index: int) -> bool:
	if phase != "ENEMY" or not interrupt_available or hand_index < 0 or hand_index >= hands[hero_id].size():
		return false
	var card = hands[hero_id][hand_index]
	if not card.reaction or int(heroes[hero_id]["mana"]) < card.cost:
		return false
	heroes[hero_id]["mana"] -= card.cost
	hands[hero_id].remove_at(hand_index)
	discard[hero_id].append(card)
	interrupt_available = false
	_log("中斷成功｜%s 取消了敵方意圖" % _hero_name(hero_id))
	changed.emit()
	return true

func end_player_phase() -> void:
	if phase != "PLAYER":
		return
	phase = "ENEMY"
	interrupt_available = true
	_log("敵方階段｜反應時機開啟｜%s" % _intent_name(boss_intent))
	changed.emit()

func resolve_enemy_phase() -> void:
	if phase != "ENEMY":
		return
	if interrupt_available:
		if boss_intent == "NEXUS_LANCE":
			var target: String = _lowest_hp_hero()
			heroes[target]["hp"] = maxi(0, int(heroes[target]["hp"]) - 24)
			_log("核心長槍｜%s 受到 24 點傷害" % _hero_name(target))
		else:
			boss_stability = mini(BOSS_MAX_STABILITY, boss_stability + 10)
			for hero_id: String in PLAYER_IDS:
				heroes[hero_id]["hp"] = maxi(0, int(heroes[hero_id]["hp"]) - 12)
			_log("穩定度脈衝｜全隊受到 12 點傷害｜首領穩定度 +10")
	else:
		_log("敵方行動已中斷｜仲裁核心失去本回合行動")
	boss_stability = mini(BOSS_MAX_STABILITY, boss_stability + 4)
	intent_index = (intent_index + 1) % 2
	boss_intent = "NEXUS_LANCE" if intent_index == 0 else "STABILITY_SURGE"
	phase = "PLAYER"
	round += 1
	ordinary_plays = 0
	for hero_id: String in PLAYER_IDS:
		heroes[hero_id]["mana"] = int(heroes[hero_id]["max_mana"])
		_draw_until(hero_id, DRAW_TARGET)
	_log("第 %d 回合｜我方階段｜能量已回滿｜手牌補至 4 張" % round)
	changed.emit()

func _damage_boss(amount: int, source: String, stability_damage: int = 0) -> void:
	var final_damage: int = amount
	if boss_stability == 0:
		final_damage = ceili(float(amount) * 1.5)
		boss_stability = 20
		_log("弱點節點暴露｜%s 把握破綻，傷害提升" % source)
	boss_hp = maxi(0, boss_hp - final_damage)
	boss_stability = maxi(0, boss_stability - stability_damage)
	_log("%s｜首領生命 −%d｜穩定度 %d" % [source, final_damage, boss_stability])

func _intent_name(intent: String) -> String:
	return "核心長槍" if intent == "NEXUS_LANCE" else "穩定度脈衝"

func _hero_name(hero_id: String) -> String:
	var names := {"kleya": "克蕾雅", "nova": "諾瓦", "yora": "尤拉"}
	return String(names.get(hero_id, hero_id))

func _lowest_hp_hero() -> String:
	var result: String = PLAYER_IDS[0]
	for hero_id: String in PLAYER_IDS:
		if int(heroes[hero_id]["hp"]) < int(heroes[result]["hp"]):
			result = hero_id
	return result

func _log(message: String) -> void:
	event_logged.emit(message)

