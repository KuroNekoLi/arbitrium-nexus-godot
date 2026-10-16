@tool
extends RefCounted
## Battle slots are stable; identity and appearance come from versioned roster.
const Roster = preload("res://scripts/domain/m5/lv40/lv40_party_catalog.gd")

static func appearance_for(id: String) -> BattleCharacterAppearance:
	var roster: Dictionary = Roster.read()
	var actor: Dictionary = roster.get("actors", {}).get(id, {})
	var path: String = str(actor.get("appearance_path", ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as BattleCharacterAppearance

static func portrait_for(id: String) -> Texture2D:
	var item: BattleCharacterAppearance = appearance_for(id)
	return item.portrait_texture() if item != null else null

static func cg_for(id: String) -> Texture2D:
	var item: BattleCharacterAppearance = appearance_for(id)
	return item.cg if item != null else null
