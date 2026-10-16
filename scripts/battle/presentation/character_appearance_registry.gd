@tool
extends RefCounted
## Current reversible art mapping: actual Lv40 actors A Ren / B Akane / C Tsumugi.
## No domain metadata is stored here. Boss keeps its current placeholder.
const REN: Resource = preload("res://resources/ui/characters/ren.tres")
const AKANE: Resource = preload("res://resources/ui/characters/akane.tres")
const TSUMUGI: Resource = preload("res://resources/ui/characters/tsumugi.tres")

static func appearance_for(id: String) -> BattleCharacterAppearance:
	match id:
		"A": return REN as BattleCharacterAppearance
		"B": return AKANE as BattleCharacterAppearance
		"C": return TSUMUGI as BattleCharacterAppearance
	return null

static func portrait_for(id: String) -> Texture2D:
	var item: BattleCharacterAppearance = appearance_for(id)
	return item.portrait_texture() if item != null else null

static func cg_for(id: String) -> Texture2D:
	var item: BattleCharacterAppearance = appearance_for(id)
	return item.cg if item != null else null
