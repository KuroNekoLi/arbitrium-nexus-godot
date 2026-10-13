class_name CardCatalog
extends RefCounted

const PLAYER_IDS: Array[String] = ["kleya", "nova", "yora"]
const CARDS := {
	"strike": preload("res://resources/cards/strike.tres"),
	"pierce": preload("res://resources/cards/pierce.tres"),
	"guard": preload("res://resources/cards/guard.tres"),
	"focus": preload("res://resources/cards/focus.tres"),
	"rupture": preload("res://resources/cards/rupture.tres"),
	"surge": preload("res://resources/cards/surge.tres"),
	"scan": preload("res://resources/cards/scan.tres"),
	"interrupt": preload("res://resources/cards/interrupt.tres"),
	"rapid_cut": preload("res://resources/cards/rapid_cut.tres"),
	"nova_burst": preload("res://resources/cards/nova_burst.tres"),
	"field_medic": preload("res://resources/cards/field_medic.tres"),
	"tactical_read": preload("res://resources/cards/tactical_read.tres")
}

static func card_ids() -> Array[String]:
	var result: Array[String] = []
	for card_id: String in CARDS.keys():
		result.append(card_id)
	result.sort()
	return result

static func create_card(card_id: String, owner_id: String) -> CardData:
	if not CARDS.has(card_id):
		return null
	var card: CardData = (CARDS[card_id] as CardData).duplicate() as CardData
	card.id = owner_id + "_" + card_id
	card.owner_id = owner_id
	return card

static func get_definition(card_id: String) -> CardData:
	return CARDS.get(card_id) as CardData

static func default_deck_ids() -> Array[String]:
	return ["strike", "pierce", "guard", "focus", "rupture", "surge", "scan", "interrupt"]
