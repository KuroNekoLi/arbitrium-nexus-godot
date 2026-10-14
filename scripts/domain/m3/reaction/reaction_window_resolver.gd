extends RefCounted
## One reaction window for an actual declared EnemyAction ID; multi-hit
## attacks share that same window. No real-time countdown/auto-Pass.
const Eligibility = preload("res://scripts/domain/m3/reaction/reaction_eligibility.gd")

static func open(core: Dictionary, action: Dictionary, catalogue: Dictionary) -> Dictionary:
	if action.is_empty() or str(action.get("status", "")) != "DECLARED":
		return {"ok": false, "error": "ENEMY_ACTION_NOT_DECLARED"}
	if not action.get("public_intent", null) is Dictionary:
		return {"ok": false, "error": "INVALID_PUBLIC_INTENT"}
	if not action["public_intent"].get("target_ids", null) is Array:
		return {"ok": false, "error": "MISSING_PUBLIC_TARGETS"}
	var possible: bool = Eligibility.any_legal(core, action, catalogue)
	if not possible and int(core["battle"]["party_resources"]["rp"]) >= 1:
		# M3.3 Basic Guard is an APPROVED reaction without any SP in
		# Hand. Until M3.3 is actually implemented, never misclassify
		# a targeted active ally's attack as an empty Reaction Window.
		# AOE/MULTI HP hits can still be Guard-eligible (not Protect).
		var scope: String = str(action["public_intent"].get("target_scope", ""))
		if ["SINGLE", "MULTI", "AOE", "ALL"].has(scope):
			for target: Variant in action["public_intent"]["target_ids"]:
				if not core["battle"]["allies"].has(target):
					continue
				var actor: Dictionary = core["battle"]["actors"][target]
				if str(actor.get("status", "")) == "ACTIVE" and int(actor.get("hp", 0)) > 0:
					return {"ok": false, "error": "BASIC_REACTIONS_DEFERRED_M3_3"}
	var action_id: String = str(action["enemy_action_id"])
	return {"ok": true, "error": "", "has_legal_options": possible,
		"window": {"window_id": action_id + ":window:0", "enemy_action_id": action_id,
			"status": "DRAFTING" if possible else "CLOSED",
			"draft": [], "executed_actor_ids": [], "action_active": true,
			"closure_reason": "" if possible else "NO_LEGAL_REACTION"}}
