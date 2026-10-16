extends RefCounted
## Data-only starter roster. Stable battle slots are not character identities.
const PATH: String = "res://resources/combat/rosters/lv40_party_v0_3.json"
const DECK_SIZE: int = 12

static func read(path: String = PATH) -> Dictionary:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Roster missing: " + path)
		return {}
	var value: Variant = JSON.parse_string(file.get_as_text())
	if not value is Dictionary:
		push_error("Roster must be a JSON object")
		return {}
	var roster: Dictionary = value
	var order: Variant = roster.get("party_order", null)
	var actors: Variant = roster.get("actors", null)
	if not order is Array or not actors is Dictionary or order.size() != 3:
		push_error("Roster must specify three active battle slots")
		return {}
	var seen: Dictionary = {}
	for item: Variant in order:
		var slot: String = str(item)
		if slot.is_empty() or slot == "Boss" or seen.has(slot) or not actors.has(slot):
			push_error("Invalid or duplicate roster slot: " + slot)
			return {}
		seen[slot] = true
		var actor: Variant = actors[slot]
		if not actor is Dictionary:
			return {}
		for key: String in ["character_id", "variant_id", "name_key", "appearance_path", "last_spell_id"]:
			if str(actor.get(key, "")).is_empty():
				push_error("Roster actor missing " + key + ": " + slot)
				return {}
		for key: String in ["max_hp", "max_mp", "patk", "matk", "pdef", "mdef", "accuracy", "evasion", "crit_rate_bp", "crit_bonus_bp", "last_spell_mp_cost"]:
			if not actor.has(key) or int(actor[key]) < 0:
				return {}
		if int(actor["max_hp"]) < 1 or not actor.get("loadout", null) is Array or actor["loadout"].size() != DECK_SIZE:
			push_error("Invalid 12-SP loadout for slot: " + slot)
			return {}
		for card: Variant in actor["loadout"]:
			if not card is String or str(card).is_empty():
				return {}
	var boss: Variant = roster.get("boss", null)
	if not boss is Dictionary or str(boss.get("actor_id", "")) != "Boss":
		return {}
	for key: String in ["character_id", "name_key", "display_zh", "max_hp", "max_mp", "patk", "matk", "pdef", "mdef", "accuracy", "evasion", "crit_rate_bp", "crit_bonus_bp"]:
		if not boss.has(key):
			return {}
	if int(boss["max_hp"]) < 1:
		return {}
	return roster

static func party_ids(roster: Dictionary = {}) -> Array[String]:
	var data: Dictionary = read() if roster.is_empty() else roster
	var result: Array[String] = []
	for item: Variant in data.get("party_order", []):
		result.append(str(item))
	return result

static func loadouts(roster: Dictionary = {}) -> Dictionary:
	var data: Dictionary = read() if roster.is_empty() else roster
	var result: Dictionary = {}
	for actor: String in party_ids(data):
		result[actor] = data["actors"][actor]["loadout"].duplicate()
	return result

static func characters(roster: Dictionary = {}) -> Dictionary:
	var data: Dictionary = read() if roster.is_empty() else roster
	var result: Dictionary = {}
	for actor: String in party_ids(data):
		result[actor] = str(data["actors"][actor]["character_id"])
	return result

static func variants(roster: Dictionary = {}) -> Dictionary:
	var data: Dictionary = read() if roster.is_empty() else roster
	var result: Dictionary = {}
	for actor: String in party_ids(data):
		result[actor] = str(data["actors"][actor]["variant_id"])
	return result
