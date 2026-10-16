extends RefCounted
## Trusted ContentConfig owns scope. A client submits one anchor id, never an
## arbitrary list; all-target effects resolve their living recipients in Domain.
static func definition(config: Dictionary, actor: String) -> Dictionary:
	var spell: String = str(config.get("last_spell_slots", {}).get(actor, {}).get("spell_id", ""))
	var data: Dictionary = config.get("last_spell_targeting", {}).get(spell, {})
	if data.is_empty() and str(config.get("m5_lv40_content_version", "")) == "lv40-starter-v0.3-boss-v0.2-A-provisional-1":
		# Saved v1 tapes embed their old config. Keep their historical single-Boss
		# attack behavior so a v2 content correction does not reinterpret a replay.
		return {"team":"ALLY" if actor == "C" else "ENEMY","scope":"ALL" if actor == "C" else "SINGLE",
			"legacy":true,"legacy_boss_only":actor != "C"}
	if not data.get("team", "") in ["ALLY", "ENEMY"] or not data.get("scope", "") in ["SINGLE", "ALL"]:
		return {}
	return data.duplicate(true)

static func candidates(core: Dictionary, actor: String, config: Dictionary) -> Array[String]:
	var data: Dictionary = definition(config, actor)
	var result: Array[String] = []
	if data.is_empty(): return result
	var battle: Dictionary = core["battle"]
	for id: String in battle["allies" if data["team"] == "ALLY" else "enemies"]:
		if data.get("legacy_boss_only", false) and id != "Boss": continue
		if int(battle["actors"][id]["hp"]) > 0 and not bool(battle.get("retired_from_field_by_actor", {}).get(id, false)):
			result.append(id)
	return result

static func recipients(core: Dictionary, actor: String, anchor: String, config: Dictionary) -> Array[String]:
	var available: Array[String] = candidates(core, actor, config)
	if definition(config, actor).get("scope", "") == "ALL":
		return available
	var result: Array[String] = []
	if available.has(anchor):
		result.append(anchor)
	return result
