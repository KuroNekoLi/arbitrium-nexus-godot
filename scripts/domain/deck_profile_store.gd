class_name DeckProfileStore
extends RefCounted

const PLAYER_IDS: Array[String] = ["kleya", "nova", "yora"]
const PROFILE_PATH := "user://deck_profile.json"
const EXPORT_PATH := "user://exports/arbitrium_decks.json"
const CardCatalogClass = preload("res://scripts/domain/card_catalog.gd")

static func default_profile() -> Dictionary:
	var decks := {}
	for hero_id: String in PLAYER_IDS:
		decks[hero_id] = CardCatalogClass.default_deck_ids()
	return {"version": 1, "decks": decks}

static func load_profile(path: String = PROFILE_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return default_profile()
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return default_profile()
	var decoded: Variant = JSON.parse_string(file.get_as_text())
	if decoded is Dictionary and is_valid_profile(decoded):
		return _normalize(decoded)
	return default_profile()

static func save_profile(profile: Dictionary, path: String = PROFILE_PATH) -> bool:
	var normalized := _normalize(profile)
	if not is_valid_profile(normalized):
		return false
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(normalized, "\t", true) + "\n")
	return file.get_error() == OK

static func export_profile(profile: Dictionary, path: String = EXPORT_PATH) -> bool:
	var normalized := _normalize(profile)
	if not is_valid_profile(normalized):
		return false
	var absolute_path := ProjectSettings.globalize_path(path)
	var directory := absolute_path.get_base_dir()
	if DirAccess.make_dir_recursive_absolute(directory) != OK and not DirAccess.dir_exists_absolute(directory):
		return false
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(normalized, "\t", true) + "\n")
	return file.get_error() == OK

static func is_valid_profile(profile: Dictionary) -> bool:
	if int(profile.get("version", 0)) != 1:
		return false
	var decks: Variant = profile.get("decks", null)
	if not decks is Dictionary:
		return false
	for hero_id: String in PLAYER_IDS:
		var ids: Variant = decks.get(hero_id, null)
		if not ids is Array or ids.size() != 8:
			return false
		var seen := {}
		for card_id: Variant in ids:
			var normalized_id := String(card_id)
			if not CardCatalogClass.CARDS.has(normalized_id) or seen.has(normalized_id):
				return false
			seen[normalized_id] = true
	return true

static func _normalize(profile: Dictionary) -> Dictionary:
	var output := {"version": 1, "decks": {}}
	var source: Variant = profile.get("decks", {})
	if source is Dictionary:
		for hero_id: String in PLAYER_IDS:
			var ids: Variant = source.get(hero_id, CardCatalogClass.default_deck_ids())
			var normalized: Array[String] = []
			if ids is Array:
				for card_id: Variant in ids:
					normalized.append(String(card_id))
			output["decks"][hero_id] = normalized
	return output
