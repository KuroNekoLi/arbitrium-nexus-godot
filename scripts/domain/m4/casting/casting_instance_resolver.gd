extends RefCounted
## One Full Chant per caster, deterministic instance ID and one card in casting.
const Zones = preload("res://scripts/domain/m2/cards/card_zone_resolver.gd")

static func build(core: Dictionary, profile: Dictionary, command_id: String) -> Dictionary:
	var actor: String = str(profile["actor_id"])
	var card: String = str(profile["card_instance_id"])
	var id: String = "cast:" + command_id
	if core["battle"]["casting_instances"].has(id):
		return {"ok": false, "error": "DUPLICATE_CASTING_ID"}
	if Zones.location(core["cards"], actor, card) != "casting":
		return {"ok": false, "error": "CAST_CARD_NOT_COMMITTED"}
	for value: Variant in core["battle"]["casting_instances"].values():
		if str(value.get("caster_id", "")) == actor:
			return {"ok": false, "error": "CASTER_ALREADY_CONCENTRATING"}
	if str(core["battle"]["actors"][actor]["status"]) != "ACTIVE":
		return {"ok": false, "error": "CASTER_NOT_ACTIVE"}
	var instance: Dictionary = {
		"casting_id": id, "caster_id": actor, "card_instance_id": card,
		"spell_id": str(profile["definition_id"]), "mode": "FULL",
		"target_snapshot": {"actor_id": str(profile["target_actor_id"])},
		"started_round": int(core["battle"]["round"]),
		"planned_resolve_round": int(core["battle"]["round"]) + 1,
		"base_stability": int(profile["profile"]["base_stability"]),
		"current_stability": int(profile["profile"]["base_stability"]),
		"focus_ward": 0, "disruption_events": [],
		"concentration": true, "can_cancel": false, "state": "CASTING",
		"effect_resolution": "DEFERRED_TO_M5",
		"stability_authority": "BALANCE_PROVISIONAL_M4_2_NOT_IMPLEMENTED"
	}
	return {"ok": true, "error": "", "instance": instance}

static func valid(core: Dictionary) -> bool:
	var casts: Variant = core["battle"].get("casting_instances", null)
	if not casts is Dictionary:
		return false
	var used: Dictionary = {}
	for id: Variant in casts:
		var spell: Dictionary = casts[id]
		var actor: String = str(spell.get("caster_id", ""))
		var card: String = str(spell.get("card_instance_id", ""))
		if str(id) != str(spell.get("casting_id", "")) or used.has(actor):
			return false
		if not core["battle"]["allies"].has(actor) or not core["cards"]["actors"].has(actor):
			return false
		if str(core["battle"]["actors"][actor]["status"]) != "CONCENTRATING":
			return false
		if Zones.location(core["cards"], actor, card) != "casting":
			return false
		if spell.get("planned_resolve_round", null) is not int:
			return false
		if spell.get("state", "") != "CASTING" or spell.get("mode", "") != "FULL":
			return false
		used[actor] = true
	for ally: Variant in core["battle"]["allies"]:
		if str(core["battle"]["actors"][ally]["status"]) == "CONCENTRATING" and not used.has(str(ally)):
			return false
	return true
