class_name BattleState
extends RefCounted

const CardDataClass = preload("res://scripts/domain/card_data.gd")

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

func _init() -> void:
	rng.seed = V1_SEED
	for hero_id in PLAYER_IDS:
		heroes[hero_id] = {"hp": 100, "max_hp": 100, "mana": 3, "max_mana": 3}
		decks[hero_id] = _make_deck(hero_id)
		hands[hero_id] = []
		discard[hero_id] = []
	for hero_id in PLAYER_IDS:
		_draw_until(hero_id, DRAW_TARGET)
	_log("ROUND 1 // PLAYER PHASE // Three independent decks online")

func _make_deck(owner_id: String) -> Array:
	var cards: Array = []
	var definitions: Array[Dictionary] = [
		{"id": "strike", "title": "Strike", "desc": "Deal 18 damage.", "cost": 1, "power": 18, "kind": CardDataClass.CardKind.ATTACK},
		{"id": "pierce", "title": "Pierce", "desc": "Deal 26 damage; -6 Stability.", "cost": 2, "power": 26, "kind": CardDataClass.CardKind.ATTACK},
		{"id": "guard", "title": "Guard", "desc": "Restore 16 HP.", "cost": 1, "power": 16, "kind": CardDataClass.CardKind.DEFENSE},
		{"id": "focus", "title": "Focus", "desc": "Analysis +2; gain 1 Mana.", "cost": 0, "power": 2, "kind": CardDataClass.CardKind.SUPPORT},
		{"id": "rupture", "title": "Rupture", "desc": "Deal 12 damage; -12 Stability.", "cost": 2, "power": 12, "kind": CardDataClass.CardKind.ATTACK},
		{"id": "surge", "title": "Surge", "desc": "Deal 34 damage.", "cost": 3, "power": 34, "kind": CardDataClass.CardKind.ATTACK},
		{"id": "scan", "title": "Scan", "desc": "Analysis +3; reveal intent.", "cost": 1, "power": 3, "kind": CardDataClass.CardKind.SUPPORT},
		{"id": "interrupt", "title": "Interrupt", "desc": "Reaction: cancel the intent.", "cost": 2, "power": 0, "kind": CardDataClass.CardKind.REACTION, "reaction": true}
	]
	for definition: Dictionary in definitions:
		var card = CardDataClass.new()
		card.id = owner_id + "_" + String(definition["id"])
		card.title = String(definition["title"])
		card.description = String(definition["desc"])
		card.owner_id = owner_id
		card.cost = int(definition["cost"])
		card.power = int(definition["power"])
		card.kind = int(definition["kind"])
		card.reaction = bool(definition.get("reaction", false))
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
	analysis += card.power if card.id.ends_with("focus") or card.id.ends_with("scan") else 1
	if card.id.ends_with("guard"):
		heroes[hero_id]["hp"] = mini(int(heroes[hero_id]["max_hp"]), int(heroes[hero_id]["hp"]) + card.power)
		_log("%s casts GUARD // +%d HP" % [hero_id.to_upper(), card.power])
	elif card.kind == CardDataClass.CardKind.ATTACK:
		_damage_boss(card.power, card.title)
	else:
		_log("%s casts %s // Analysis +%d" % [hero_id.to_upper(), card.title.to_upper(), card.power])
	if card.id.ends_with("focus"):
		heroes[hero_id]["mana"] = mini(int(heroes[hero_id]["max_mana"]) + 1, int(heroes[hero_id]["mana"]) + 1)
		_log("FOCUS // %s gains +1 retained Mana" % hero_id.to_upper())
	if analysis >= 3:
		_log("ANALYSIS COMPLETE // Intent confidence increased")
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
	_log("INTERRUPT // %s cancels %s" % [hero_id.to_upper(), boss_intent])
	changed.emit()
	return true

func end_player_phase() -> void:
	if phase != "PLAYER":
		return
	phase = "ENEMY"
	interrupt_available = true
	_log("ENEMY PHASE // Reaction window open // %s" % boss_intent)
	changed.emit()

func resolve_enemy_phase() -> void:
	if phase != "ENEMY":
		return
	if interrupt_available:
		if boss_intent == "NEXUS_LANCE":
			var target: String = _lowest_hp_hero()
			heroes[target]["hp"] = maxi(0, int(heroes[target]["hp"]) - 24)
			_log("NEXUS LANCE // %s takes 24 damage" % target.to_upper())
		else:
			boss_stability = mini(BOSS_MAX_STABILITY, boss_stability + 10)
			for hero_id: String in PLAYER_IDS:
				heroes[hero_id]["hp"] = maxi(0, int(heroes[hero_id]["hp"]) - 12)
			_log("STABILITY SURGE // Party takes 12 // Boss Stability +10")
	else:
		_log("INTERRUPTED // Arbitrium Nexus loses its action")
	boss_stability = mini(BOSS_MAX_STABILITY, boss_stability + 4)
	intent_index = (intent_index + 1) % 2
	boss_intent = "NEXUS_LANCE" if intent_index == 0 else "STABILITY_SURGE"
	phase = "PLAYER"
	round += 1
	ordinary_plays = 0
	for hero_id: String in PLAYER_IDS:
		heroes[hero_id]["mana"] = int(heroes[hero_id]["max_mana"])
		_draw_until(hero_id, DRAW_TARGET)
	_log("ROUND %d // PLAYER PHASE // Mana refilled // Hands refilled to 4" % round)
	changed.emit()

func _damage_boss(amount: int, source: String) -> void:
	var final_damage: int = amount
	if boss_stability == 0:
		final_damage = ceili(float(amount) * 1.5)
		boss_stability = 20
		_log("WEAK NODE // %s exploits the exposed node" % source.to_upper())
	boss_hp = maxi(0, boss_hp - final_damage)
	boss_stability = maxi(0, boss_stability - (6 if source == "Pierce" else 0))
	_log("%s // Boss -%d HP // Stability %d" % [source.to_upper(), final_damage, boss_stability])

func _lowest_hp_hero() -> String:
	var result: String = PLAYER_IDS[0]
	for hero_id: String in PLAYER_IDS:
		if int(heroes[hero_id]["hp"]) < int(heroes[result]["hp"]):
			result = hero_id
	return result

func _log(message: String) -> void:
	event_logged.emit(message)

