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


static func state_texture_for(id: String, status: String, on_field: bool) -> Texture2D:
	var appearance: BattleCharacterAppearance = appearance_for(id)
	return appearance.state_texture(status,on_field) if appearance != null else null

static func portrait_for_status(id: String, status: String) -> Texture2D:
	var appearance: BattleCharacterAppearance = appearance_for(id)
	return appearance.portrait_texture_for_status(status) if appearance != null else null

static func field_cg_for_status(id: String, status: String) -> Texture2D:
	var appearance: BattleCharacterAppearance = appearance_for(id)
	return appearance.field_cg_for_status(status) if appearance != null else null
