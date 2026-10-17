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
	if int(roster.get("schema_version", 0)) != 2:
		push_error("Roster schema version must be 2")
		return {}
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
		var definition_path: String = str(actor.get("character_definition_path", ""))
		if definition_path.is_empty() or not ResourceLoader.exists(definition_path):
			push_error("Character definition missing for roster slot: " + slot)
			return {}
		var loaded: Resource = ResourceLoader.load(definition_path)
		if loaded == null or not loaded is CharacterDefinition:
			push_error("Invalid character definition for roster slot: " + slot)
			return {}
		var slot_data: Dictionary = actor
		var actor_data: Dictionary = (loaded as CharacterDefinition).to_actor_data()
		actor_data["character_definition_path"] = definition_path
		var opening_cards: Variant = slot_data.get("demo_opening_cards", [])
		if not opening_cards is Array:
			push_error("Invalid demo opening cards for roster slot: " + slot)
			return {}
		if not opening_cards.is_empty():
			actor_data["demo_opening_cards"] = opening_cards.duplicate()
		actors[slot] = actor_data
		roster["actors"] = actors
		actor = actor_data
		for key: String in ["character_id", "variant_id", "name_key", "appearance_path", "last_spell_id", "last_spell_name_key"]:
			if str(actor.get(key, "")).is_empty():
				push_error("Roster actor missing " + key + ": " + slot)
				return {}
		for key: String in ["level", "max_hp", "max_mp", "patk", "matk", "pdef", "mdef", "accuracy", "evasion", "crit_rate_bp", "crit_bonus_bp", "last_spell_mp_cost"]:
			if not actor.has(key) or int(actor[key]) < 0:
				return {}
		if int(actor["level"]) < 1 or int(actor["max_hp"]) < 1 or not actor.get("loadout", null) is Array or actor["loadout"].size() != DECK_SIZE:
			push_error("Invalid 12-SP loadout for slot: " + slot)
			return {}
		if not actor.get("last_spell_profile", null) is Dictionary or not actor.get("last_spell_targeting", null) is Dictionary or not actor.get("last_spell_effect", null) is Dictionary:
			return {}
		var effect: Dictionary = actor["last_spell_effect"]
		if not ["DAMAGE", "HEAL_BARRIER"].has(str(effect.get("kind",""))):
			return {}
		if str(effect.get("kind","")) == "HEAL_BARRIER":
			if int(effect.get("heal_max_hp_bp", 0)) <= 0 or int(effect.get("barrier_amount", -1)) < 0:
				return {}
		var full_passive: Variant = actor.get("full_chant_passive", {})
		if not full_passive is Dictionary:
			return {}
		if not full_passive.is_empty() and (str(full_passive.get("kind", "")) != "FULL_CHANT_HP_MULTIPLIER" or str(full_passive.get("id", "")).is_empty() or int(full_passive.get("multiplier_bp", 0)) < 0):
			return {}
		var tags: Variant = actor.get("role_tags", null)
		if not tags is Array:
			return {}
		for tag: Variant in tags:
			if not tag is String or str(tag).is_empty():
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

static func eligible(card_rule: Dictionary, character_id: String, role_tags: Array) -> bool:
	match str(card_rule.get("kind", "")):
		"UNIVERSAL":
			return true
		"ROLE_TAG":
			return role_tags.has(str(card_rule.get("tag", ""))) and not str(card_rule.get("tag","")).is_empty()
		"CHARACTER":
			return not character_id.is_empty() and character_id == str(card_rule.get("character_id", ""))
	return false
