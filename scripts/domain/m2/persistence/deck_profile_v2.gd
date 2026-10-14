extends RefCounted
## M2.3 v2 persistence. Legacy v1 stays byte-for-byte untouched and is NEVER
## guessed into 12 cards. V2 is saved separately and validated with the actual
## catalogue + ownership + currently selected character variants.
const DeckValidator = preload("res://scripts/domain/m2/cards/deck_validator.gd")
const DEFAULT_PATH: String = "user://deck_profile_v2.json"
const SCHEMA_VERSION: int = 2

static func inspect_profile(raw: Variant) -> Dictionary:
	if not raw is Dictionary:
		return {"status": "INVALID_PROFILE", "original": raw}
	var version: Variant = raw.get("version", null)
	if not version is int:
		return {"status": "INVALID_PROFILE", "original": raw.duplicate(true)}
	if version == 1:
		var legacy: Variant = raw.get("decks", null)
		if not legacy is Dictionary or legacy.size() != 3:
			return {"status": "INVALID_PROFILE", "original": raw.duplicate(true)}
		for key: Variant in legacy:
			if not legacy[key] is Array or legacy[key].size() != 8:
				return {"status": "INVALID_PROFILE", "original": raw.duplicate(true)}
		return {"status": "LEGACY_RECONFIGURATION_REQUIRED", "original": raw.duplicate(true)}
	if version != SCHEMA_VERSION:
		return {"status": "UNSUPPORTED_VERSION", "original": raw.duplicate(true)}
	var loadouts: Variant = raw.get("loadouts", null)
	if not loadouts is Dictionary or loadouts.size() != 3:
		return {"status": "INVALID_PROFILE", "original": raw.duplicate(true)}
	for key: Variant in loadouts:
		if not loadouts[key] is Dictionary:
			return {"status": "INVALID_PROFILE", "original": raw.duplicate(true)}
		if not loadouts[key].get("cards", null) is Array:
			return {"status": "INVALID_PROFILE", "original": raw.duplicate(true)}
		if not loadouts[key].get("variant_id", null) is String:
			return {"status": "INVALID_PROFILE", "original": raw.duplicate(true)}
	return {"status": "V2_CANDIDATE", "original": raw.duplicate(true)}

static func validate_for_battle(raw: Variant, contexts: Dictionary, definitions: Dictionary,
		ownership: Dictionary, deck_rules: Dictionary = {}) -> Dictionary:
	var status: Dictionary = inspect_profile(raw)
	if status["status"] != "V2_CANDIDATE":
		return {"ok": false, "error": str(status["status"])}
	var loadouts: Dictionary = {}
	for key: Variant in raw["loadouts"]:
		var actor_id: String = str(key)
		var entry: Dictionary = raw["loadouts"][key]
		if not contexts.has(actor_id) or not contexts[actor_id] is Dictionary:
			return {"ok": false, "error": "ACTOR_CONTEXT_MISSING"}
		if str(entry["variant_id"]) != str(contexts[actor_id].get("variant_id", "")):
			return {"ok": false, "error": "VARIANT_CHANGED_REVALIDATE"}
		loadouts[actor_id] = entry["cards"]
	return DeckValidator.validate_party(loadouts, contexts, definitions, ownership, deck_rules)

static func load_profile(path: String = DEFAULT_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"status": "NOT_FOUND"}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"status": "READ_FAILED"}
	var decoded: Variant = JSON.parse_string(file.get_as_text())
	return inspect_profile(decoded)

static func save_profile(raw: Dictionary, contexts: Dictionary, definitions: Dictionary,
		ownership: Dictionary, path: String = DEFAULT_PATH, deck_rules: Dictionary = {}) -> Dictionary:
	var verification: Dictionary = validate_for_battle(raw, contexts, definitions, ownership, deck_rules)
	if not verification["ok"]:
		return {"saved": false, "error": verification["error"]}
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return {"saved": false, "error": "WRITE_FAILED"}
	file.store_string(JSON.stringify(raw, "\t", true) + "\n")
	if file.get_error() != OK:
		return {"saved": false, "error": "WRITE_FAILED"}
	return {"saved": true, "error": ""}
