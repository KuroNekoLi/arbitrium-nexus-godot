extends RefCounted
## M3.2 card-only Reaction SP eligibility. Basic Guard/Protect and the
## M4 casting-compatible exception are NOT implemented at this milestone.
## Costs are versioned content, never accepted from client-side commands.
const Zones = preload("res://scripts/domain/m2/cards/card_zone_resolver.gd")

static func check(core: Dictionary, action: Dictionary, entry: Dictionary,
		catalogue: Dictionary, action_active: bool = true) -> Dictionary:
	var battle: Dictionary = core["battle"]
	var cards: Dictionary = core["cards"]
	var actor_id: String = str(entry.get("actor_id", ""))
	if not battle["allies"].has(actor_id) or not cards["actors"].has(actor_id):
		return {"ok": false, "error": "ACTOR_NOT_FOUND"}
	var actor: Dictionary = battle["actors"][actor_id]
	if int(actor.get("hp", 0)) <= 0 or str(actor.get("status", "")) in ["INCAPACITATED", "EXHAUSTED"]:
		return {"ok": false, "error": "ACTOR_UNAVAILABLE"}
	if str(actor.get("status", "")) != "ACTIVE":
		# Explicitly deferred M4 exception; never charge an unsupported
		# Concentrating actor for merely owning a CAST_COMPATIBLE SP.
		return {"ok": false, "error": "CONCENTRATING_UNSUPPORTED_M4"}
	if str(entry.get("kind", "")) != "REACTION_SP_FIXTURE":
		return {"ok": false, "error": "FEATURE_NOT_IMPLEMENTED_M3_3"}
	var card_id: String = str(entry.get("card_instance_id", ""))
	if Zones.location(cards, actor_id, card_id) != "hand":
		return {"ok": false, "error": "CARD_NOT_IN_OWN_HAND"}
	var definition_id: String = str(cards["actors"][actor_id]["instances"][card_id]["definition_id"])
	if not catalogue.has(definition_id) or not catalogue[definition_id] is Dictionary:
		return {"ok": false, "error": "MISSING_REACTION_DEFINITION"}
	var definition: Dictionary = catalogue[definition_id]
	if str(definition.get("kind", "")) != "REACTION_SP":
		return {"ok": false, "error": "NOT_REACTION_SP"}
	if not definition.get("rp_cost", null) is int or not definition.get("mp_cost", null) is int:
		return {"ok": false, "error": "INVALID_REACTION_COST"}
	var rp_cost: int = int(definition["rp_cost"])
	var mp_cost: int = int(definition["mp_cost"])
	if rp_cost < 0 or mp_cost < 0:
		return {"ok": false, "error": "INVALID_REACTION_COST"}
	var effect: String = str(definition.get("fixture_effect", ""))
	if not ["NOOP_FIXTURE", "CANCEL_ACTION_FIXTURE", "INDEPENDENT_SUPPORT_FIXTURE"].has(effect):
		return {"ok": false, "error": "UNIMPLEMENTED_REACTION_EFFECT"}
	if str(definition.get("reaction_trigger", "")) != "ENEMY_ACTION":
		return {"ok": false, "error": "REACTION_TRIGGER_MISMATCH"}
	var required_scope: String = str(definition.get("target_scope", "ANY"))
	if required_scope != "ANY" and required_scope != str(action["public_intent"].get("target_scope", "")):
		return {"ok": false, "error": "REACTION_SCOPE_MISMATCH"}
	var dependent: bool = bool(definition.get("requires_active_enemy_action", true))
	if dependent and not action_active:
		return {"ok": false, "error": "TRIGGER_GONE"}
	var target_id: String = str(entry.get("target_actor_id", ""))
	if target_id.is_empty() or not battle["allies"].has(target_id):
		return {"ok": false, "error": "INVALID_REACTION_TARGET"}
	if int(battle["actors"][target_id].get("hp", 0)) <= 0:
		return {"ok": false, "error": "TARGET_INCAPACITATED"}
	if dependent and not action["public_intent"].get("target_ids", []).has(target_id):
		return {"ok": false, "error": "REACTION_TARGET_MISMATCH"}
	if rp_cost > int(battle["party_resources"]["rp"]):
		return {"ok": false, "error": "INSUFFICIENT_RP"}
	if mp_cost > int(actor["mp"]):
		return {"ok": false, "error": "INSUFFICIENT_MP"}
	return {"ok": true, "error": "", "rp_cost": rp_cost, "mp_cost": mp_cost,
		"definition_id": definition_id, "effect": effect,
		"requires_active_enemy_action": dependent}

static func any_legal(core: Dictionary, action: Dictionary, catalogue: Dictionary) -> bool:
	if not catalogue is Dictionary:
		return false
	for actor_key: Variant in core["cards"]["actors"]:
		var actor_id: String = str(actor_key)
		var hand: Array = core["cards"]["actors"][actor_id]["zones"]["hand"]
		for card_id: Variant in hand:
			var definition_id: String = str(core["cards"]["actors"][actor_id]["instances"][card_id]["definition_id"])
			if not catalogue.has(definition_id) or not catalogue[definition_id] is Dictionary:
				continue
			var defn: Dictionary = catalogue[definition_id]
			var targets: Array = core["battle"]["allies"] if not bool(defn.get("requires_active_enemy_action", true)) else action["public_intent"].get("target_ids", [])
			for target: Variant in targets:
				var preview: Dictionary = check(core, action, {"kind": "REACTION_SP_FIXTURE",
					"actor_id": actor_id, "card_instance_id": card_id,
					"target_actor_id": str(target)}, catalogue)
				if preview["ok"]:
					return true
	return false
