extends RefCounted
## M3.3 basic Guard: 1 RP, no card, no MP; applies to ALL eligible
## HP hits of ONE EnemyAction. Damage coefficient deliberately M5-only.
const COST_RP: int = 1
const HP_DAMAGE_TYPES: Array[String] = ["PHYSICAL", "MAGICAL", "HP"]

static func check(core: Dictionary, action: Dictionary, window: Dictionary,
		actor_id: String, action_active: bool = true) -> Dictionary:
	if not action_active:
		return {"ok": false, "error": "TRIGGER_GONE"}
	var battle: Dictionary = core["battle"]
	if not battle["allies"].has(actor_id):
		return {"ok": false, "error": "ACTOR_NOT_FOUND"}
	var actor: Dictionary = battle["actors"][actor_id]
	if int(actor.get("hp", 0)) <= 0 or str(actor.get("status", "")) in ["INCAPACITATED", "EXHAUSTED"]:
		return {"ok": false, "error": "ACTOR_UNAVAILABLE"}
	if str(actor.get("status", "")) != "ACTIVE":
		return {"ok": false, "error": "CONCENTRATING_UNSUPPORTED_M4"}
	var intent: Dictionary = action.get("public_intent", {})
	if not HP_DAMAGE_TYPES.has(str(intent.get("damage_type", ""))) or bool(intent.get("direct_casting_disruption", false)):
		return {"ok": false, "error": "NO_ELIGIBLE_HP_HIT"}
	if not intent.get("hit_count", null) is int or int(intent["hit_count"]) <= 0:
		return {"ok": false, "error": "INVALID_HIT_COUNT"}
	var targets: Array = intent.get("target_ids", []).duplicate()
	var recipient: String = str(window.get("damage_recipient_actor_id", ""))
	if not recipient.is_empty() and str(intent.get("target_scope", "")) == "SINGLE":
		targets = [recipient]
	if not targets.has(actor_id):
		return {"ok": false, "error": "NOT_CURRENT_DAMAGE_RECIPIENT"}
	if int(battle["party_resources"]["rp"]) < COST_RP:
		return {"ok": false, "error": "INSUFFICIENT_RP"}
	return {"ok": true, "error": "", "rp_cost": COST_RP, "mp_cost": 0,
		"effect": "BASIC_GUARD", "definition_id": "", "requires_active_enemy_action": true}

static func apply(window: Dictionary, actor_id: String, action: Dictionary) -> Dictionary:
	if window.get("guard_actor_ids", null) is not Array:
		return {"ok": false, "error": "MISSING_GUARD_STATE"}
	if window["guard_actor_ids"].has(actor_id):
		return {"ok": false, "error": "GUARD_ALREADY_REGISTERED"}
	var next: Dictionary = window.duplicate(true)
	next["guard_actor_ids"].append(actor_id)
	return {"ok": true, "error": "", "window": next,
		"effect": {"kind": "GuardCoverageRegistered",
			"actor_id": actor_id, "enemy_action_id": str(action["enemy_action_id"]),
			"coverage": "ALL_ELIGIBLE_HP_HITS", "hit_count": int(action["public_intent"]["hit_count"]),
			"damage_coefficient": "DEFERRED_M5_PROVISIONAL_40_NOT_CANON"}}
