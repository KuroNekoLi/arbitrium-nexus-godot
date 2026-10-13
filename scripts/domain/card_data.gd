class_name CardData
extends "res://addons/simple_cards/card/card_resource/card_resource.gd"

enum CardKind { ATTACK, DEFENSE, SUPPORT, REACTION }

@export var id: String = ""
@export var title: String = ""
@export_multiline var description: String = ""
@export var owner_id: String = ""
@export var cost: int = 1
@export var power: int = 0
@export var kind: CardKind = CardKind.ATTACK
@export var reaction: bool = false
@export var analysis_gain: int = 1
@export var healing: int = 0
@export var stability_damage: int = 0
@export var mana_gain: int = 0

func is_ordinary() -> bool:
	return not reaction and kind != CardKind.REACTION

