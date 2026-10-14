extends RefCounted
## M3.1 published-intent EnemyAction scheduler. No AI decisions, target changes,
## Reaction resolution, hit or HP effects. Priority from declared action_order;
## stable tie by declared created_seq then explicit template ID.
static func plan(templates: Array, enemy_ids: Array, round_index: int) -> Dictionary:
	if round_index < 1:
		return {"ok": false, "error": "INVALID_ROUND", "actions": []}
	var used: Dictionary = {}
	var result: Array = []
	for item: Variant in templates:
		if not item is Dictionary:
			return {"ok": false, "error": "INVALID_ENEMY_INTENT", "actions": []}
		var intent: Dictionary = item
		var local_id: String = str(intent.get("intent_id", ""))
		var owner: String = str(intent.get("enemy_id", ""))
		if local_id.strip_edges().is_empty() or used.has(local_id):
			return {"ok": false, "error": "DUPLICATE_OR_EMPTY_INTENT_ID", "actions": []}
		if not enemy_ids.has(owner):
			return {"ok": false, "error": "ENEMY_NOT_FOUND", "actions": []}
		if intent.get("publicly_declared", false) != true:
			return {"ok": false, "error": "INTENT_NOT_PUBLIC", "actions": []}
		if not intent.get("action_order", null) is int or not intent.get("created_seq", null) is int:
			return {"ok": false, "error": "INVALID_INTENT_ORDER", "actions": []}
		if int(intent["created_seq"]) < 0:
			return {"ok": false, "error": "INVALID_INTENT_ORDER", "actions": []}
		used[local_id] = true
		result.append({
			"enemy_action_id": "round:" + str(round_index) + ":intent:" + local_id,
			"intent_id": local_id, "enemy_id": owner,
			"action_order": int(intent["action_order"]), "created_seq": int(intent["created_seq"]),
			"public_intent": intent.duplicate(true), "status": "PENDING"
		})
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["action_order"]) != int(b["action_order"]):
			return int(a["action_order"]) < int(b["action_order"])
		if int(a["created_seq"]) != int(b["created_seq"]):
			return int(a["created_seq"]) < int(b["created_seq"])
		return str(a["intent_id"]) < str(b["intent_id"])
	)
	return {"ok": true, "error": "", "actions": result}

static func next_pending(actions: Array, position: int) -> Dictionary:
	if position < 0 or position > actions.size():
		return {}
	if position == actions.size():
		return {}
	if not actions[position] is Dictionary:
		return {}
	return actions[position].duplicate(true)
