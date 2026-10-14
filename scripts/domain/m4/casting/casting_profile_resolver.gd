extends RefCounted
## M4.1 fixed, versioned spell profile. Costs remain solely M2's quote.
const Zones = preload("res://scripts/domain/m2/cards/card_zone_resolver.gd")

static func resolve(core: Dictionary, instruction: Dictionary, config: Dictionary) -> Dictionary:
	var actor_id: String = str(instruction.get("actor_id", ""))
	var card_id: String = str(instruction.get("card_instance_id", ""))
	if core["battle"]["phase"] != "PLAYER_PHASE" or not core["battle"]["allies"].has(actor_id):
		return {"ok": false, "error": "INVALID_PHASE_OR_ACTOR"}
	if Zones.location(core["cards"], actor_id, card_id) != "hand":
		return {"ok": false, "error": "CARD_NOT_IN_OWN_HAND"}
	var actor: Dictionary = core["battle"]["actors"][actor_id]
	if int(actor["hp"]) <= 0 or str(actor["status"]) != "ACTIVE":
		return {"ok": false, "error": "ACTOR_UNAVAILABLE"}
	for existing: Variant in core["battle"]["casting_instances"].values():
		if str(existing.get("caster_id", "")) == actor_id:
			return {"ok": false, "error": "CASTER_ALREADY_CONCENTRATING"}
	var definition: String = str(core["cards"]["actors"][actor_id]["instances"][card_id]["definition_id"])
	var catalogue: Variant = config.get("casting_profiles", null)
	if not catalogue is Dictionary or not catalogue.has(definition):
		return {"ok": false, "error": "MISSING_CASTING_PROFILE"}
	var spell: Variant = catalogue[definition]
	if not spell is Dictionary or str(spell.get("spell_id", "")) != definition:
		return {"ok": false, "error": "INVALID_CASTING_PROFILE"}
	if not spell.get("allowed_modes", null) is Array:
		return {"ok": false, "error": "INVALID_CASTING_MODES"}
	for allowed: Variant in spell["allowed_modes"]:
		if not ["CHANTLESS", "FULL"].has(allowed):
			return {"ok": false, "error": "INVALID_CASTING_MODES"}
	var mode: String = str(instruction.get("casting_mode", ""))
	if not ["CHANTLESS", "FULL"].has(mode) or not spell["allowed_modes"].has(mode):
		return {"ok": false, "error": "CASTING_MODE_NOT_ALLOWED"}
	var costs: Variant = config.get("definitions", null)
	if not costs is Dictionary or not costs.has(definition):
		return {"ok": false, "error": "MISSING_VERSIONED_COST"}
	if str(costs[definition].get("card_id", "")) != definition:
		return {"ok": false, "error": "MISMATCHED_COST_DEFINITION"}
	var target: String = str(instruction.get("target_actor_id", ""))
	if target.is_empty() or not core["battle"]["actors"].has(target):
		return {"ok": false, "error": "INVALID_CASTING_TARGET"}
	if int(core["battle"]["actors"][target].get("hp", 0)) <= 0:
		return {"ok": false, "error": "TARGET_UNAVAILABLE"}
	if mode == "FULL" and (not spell.get("base_stability", null) is int or int(spell["base_stability"]) <= 0):
		return {"ok": false, "error": "MISSING_PROVISIONAL_STABILITY_FIXTURE"}
	# No user supplied AP/MP prices.  M2's current cost quote is the
	# single source and assumes M-D21's same base MP in both modes.
	return {"ok": true, "definition_id": definition, "profile": spell.duplicate(true),
		"actor_id": actor_id, "card_instance_id": card_id, "target_actor_id": target,
		"mode": mode}
