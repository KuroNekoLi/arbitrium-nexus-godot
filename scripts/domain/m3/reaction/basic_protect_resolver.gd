extends RefCounted
## M3.3 basic Protect: 2 RP, no card. PRE3-R01 redirect BEFORE hit/
## defence; first redirect wins and no redirect chain. No HP calculation.
const COST_RP: int = 2
const HP_DAMAGE_TYPES: Array[String] = ["PHYSICAL", "MAGICAL", "HP"]

static func check(core: Dictionary, action: Dictionary, window: Dictionary,
		actor_id: String, target_id: String, action_active: bool = true) -> Dictionary:
	if not action_active:
		return {"ok": false, "error": "TRIGGER_GONE"}
	var battle: Dictionary = core["battle"]
	if not battle["allies"].has(actor_id) or not battle["allies"].has(target_id):
		return {"ok": false, "error": "ACTOR_OR_TARGET_NOT_FOUND"}
	if actor_id == target_id:
		return {"ok": false, "error": "CANNOT_PROTECT_SELF"}
	if bool(battle.get("retired_from_field_by_actor", {}).get(target_id, false)):
		return {"ok":false,"error":"TARGET_RETIRED_FROM_FIELD"}
	var actor: Dictionary = battle["actors"][actor_id]
	if int(actor.get("hp", 0)) <= 0 or str(actor.get("status", "")) in ["INCAPACITATED", "EXHAUSTED"]:
		return {"ok": false, "error": "ACTOR_UNAVAILABLE"}
	if str(actor.get("status", "")) != "ACTIVE":
		return {"ok": false, "error": "CONCENTRATING_UNSUPPORTED_M4"}
	var intent: Dictionary = action.get("public_intent", {})
	if str(intent.get("target_scope", "")) != "SINGLE":
		return {"ok": false, "error": "PROTECT_REQUIRES_SINGLE_TARGET"}
	if not intent.get("target_ids", null) is Array or intent["target_ids"].size() != 1:
		return {"ok": false, "error": "PROTECT_REQUIRES_SINGLE_TARGET"}
	if not HP_DAMAGE_TYPES.has(str(intent.get("damage_type", ""))):
		return {"ok": false, "error": "NOT_HP_DAMAGE"}
	if bool(intent.get("direct_casting_disruption", false)) or bool(intent.get("unprotectable", false)):
		return {"ok": false, "error": "UNPROTECTABLE_ATTACK"}
	if not intent.get("hit_count", null) is int or int(intent["hit_count"]) <= 0:
		return {"ok": false, "error": "INVALID_HIT_COUNT"}
	if str(intent["target_ids"][0]) != target_id:
		return {"ok": false, "error": "PROTECT_TARGET_MISMATCH"}
	if not str(window.get("protected_by_actor_id", "")).is_empty():
		return {"ok": false, "error": "PROTECT_ALREADY_REDIRECTED"}
	if int(battle["actors"][target_id].get("hp", 0)) <= 0:
		return {"ok": false, "error": "TARGET_INCAPACITATED"}
	# EXHAUSTED ally is a valid object of protection; they cannot
	# themselves execute reactions.
	if int(battle["party_resources"]["rp"]) < COST_RP:
		return {"ok": false, "error": "INSUFFICIENT_RP"}
	return {"ok": true, "error": "", "rp_cost": COST_RP, "mp_cost": 0,
		"effect": "BASIC_PROTECT", "definition_id": "",
		"requires_active_enemy_action": true}

static func apply(window: Dictionary, actor_id: String, target_id: String,
		action: Dictionary) -> Dictionary:
	if not str(window.get("protected_by_actor_id", "")).is_empty():
		return {"ok": false, "error": "PROTECT_ALREADY_REDIRECTED"}
	var next: Dictionary = window.duplicate(true)
	next["protected_by_actor_id"] = actor_id
	next["original_target_actor_id"] = target_id
	next["damage_recipient_actor_id"] = actor_id
	return {"ok": true, "error": "", "window": next,
		"effect": {"kind": "AttackTargetRedirected",
			"enemy_action_id": str(action["enemy_action_id"]),
			"from_actor_id": target_id, "to_actor_id": actor_id,
			"before_hit_roll": true, "hit_count": int(action["public_intent"]["hit_count"]),
			"redirect_chain_allowed": false,
			"status_transfer": "ONLY_EXPLICIT_FOLLOWS_DAMAGE_RECIPIENT",
			"hp_damage": "DEFERRED_M5"}}
