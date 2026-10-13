class_name CardData
extends Resource

enum CardKind { ATTACK, DEFENSE, SUPPORT, REACTION }

@export var id: String = ""
@export var title: String = ""
@export_multiline var description: String = ""
@export var owner_id: String = ""
@export var cost: int = 1
@export var power: int = 0
@export var kind: CardKind = CardKind.ATTACK
@export var reaction: bool = false

func is_ordinary() -> bool:
	return not reaction and kind != CardKind.REACTION

