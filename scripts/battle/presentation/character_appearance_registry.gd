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


## User-provided high-resolution AI art, aligned to the existing state atlas.
## Each sheet is 1024x1280 with 512px columns. The generated sheets have
## slightly different transparent row separators; keep the per-sheet split
## below instead of cropping into adjacent poses. Column 0=normal,
## column 1=incapacitated; EXHAUSTED never gets a field CG.
const STATE_SHEET_SPLIT_Y := {"ren": 536, "akane": 512, "tsumugi": 504}
static func state_texture_for(id: String, status: String, on_field: bool) -> Texture2D:
	if status == "EXHAUSTED" and on_field:
		return null
	var roster: Dictionary = Roster.read()
	var actor: Dictionary = roster.get("actors",{}).get(id,{})
	var appearance_path: String = str(actor.get("appearance_path",""))
	if appearance_path.is_empty():
		return null
	var character_slug: String = appearance_path.get_file().get_basename()
	var path: String = "res://assets/characters/%s/cg_states.png" % character_slug
	if not ResourceLoader.exists(path):
		return null
	var atlas: Texture2D = load(path) as Texture2D
	if atlas == null or atlas.get_size() != Vector2(1024,1280):
		return null
	var split_y: int = int(STATE_SHEET_SPLIT_Y.get(character_slug, -1))
	if split_y <= 0 or split_y >= 1280:
		return null
	var region := AtlasTexture.new()
	region.atlas = atlas
	var col: int = 1 if status == "INCAPACITATED" else 0
	region.region = Rect2(col * 512, split_y if on_field else 0,
		512, 1280 - split_y if on_field else split_y)
	return region

static func portrait_for_status(id: String, status: String) -> Texture2D:
	var candidate: Texture2D = state_texture_for(id,status,false)
	return candidate if candidate != null else portrait_for(id)

static func field_cg_for_status(id: String, status: String) -> Texture2D:
	return state_texture_for(id,status,true)
