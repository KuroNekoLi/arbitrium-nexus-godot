extends RefCounted
## M3.2 draft/preview/reorder/confirm/pass. Only explicit Confirm executes
## actual M2 RP+MP+CardInstance transactions. No timers or UI state.
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const Eligibility = preload("res://scripts/domain/m3/reaction/reaction_eligibility.gd")
const M2 = preload("res://scripts/domain/m2/integration/m2_domain_resolver.gd")

static func _fail(state: Dictionary, reason: String) -> Dictionary:
	return {"ok": false, "error": reason, "state": state.duplicate(true), "records": []}

static func _record(name: String, details: Dictionary = {}) -> Dictionary:
	return {"kind": name, "details": details}

static func _action(state: Dictionary) -> Dictionary:
	var cursor: int = int(state["enemy_cursor"])
	if cursor < 0 or cursor >= state["enemy_actions"].size():
		return {}
	return state["enemy_actions"][cursor]

static func preview(state: Dictionary, definition_catalogue: Dictionary) -> Dictionary:
	var action: Dictionary = _action(state)
	var window: Dictionary = state["reaction_window"]
	if window.is_empty() or str(window.get("status", "")) != "DRAFTING":
		return {"ok": false, "error": "WINDOW_NOT_DRAFTING"}
	var total_rp: int = 0
	var mp_by_actor: Dictionary = {}
	var cards_by_actor: Dictionary = {}
	for entry: Dictionary in window["draft"]:
		var validation: Dictionary = Eligibility.check(state["core"], action, entry,
			definition_catalogue, bool(window["action_active"]))
		if not validation["ok"]:
			return {"ok": false, "error": str(validation["error"]),
				"invalid_actor_id": str(entry["actor_id"])}
		total_rp += int(validation["rp_cost"])
		var actor_id: String = str(entry["actor_id"])
		mp_by_actor[actor_id] = int(mp_by_actor.get(actor_id, 0)) + int(validation["mp_cost"])
		var card_id: String = str(entry["card_instance_id"])
		if cards_by_actor.has(card_id):
			return {"ok": false, "error": "DUPLICATE_CARD_INSTANCE"}
		cards_by_actor[card_id] = true
	if total_rp > int(state["core"]["battle"]["party_resources"]["rp"]):
		return {"ok": false, "error": "INSUFFICIENT_RP_DRAFT"}
	for actor_key: Variant in mp_by_actor:
		if int(mp_by_actor[actor_key]) > int(state["core"]["battle"]["actors"][actor_key]["mp"]):
			return {"ok": false, "error": "INSUFFICIENT_MP_DRAFT"}
	return {"ok": true, "error": "", "estimated_rp": total_rp,
		"estimated_mp_by_actor": mp_by_actor,
		"draft_actor_order": window["draft"].map(func(d: Dictionary) -> String: return str(d["actor_id"]))}

static func apply(state: Dictionary, instruction: Dictionary,
		config: Dictionary) -> Dictionary:
	if not state.get("reaction_window", null) is Dictionary:
		return _fail(state, "INVALID_REACTION_WINDOW_STATE")
	var window: Dictionary = state["reaction_window"]
	if window.is_empty():
		return _fail(state, "NO_REACTION_WINDOW")
	if str(instruction.get("window_id", "")) != str(window["window_id"]):
		return _fail(state, "STALE_WINDOW_ID")
	if str(window["status"]) != "DRAFTING":
		return _fail(state, "REACTION_WINDOW_CLOSED")
	var catalogue: Variant = config.get("reaction_definitions", null)
	if not catalogue is Dictionary:
		return _fail(state, "MISSING_REACTION_CATALOGUE")
	var kind: String = str(instruction.get("type", ""))
	var updated: Dictionary = state.duplicate(true)
	var w: Dictionary = updated["reaction_window"]
	var records: Array = []
	var action: Dictionary = _action(updated)
	match kind:
		"QUEUE_REACTION":
			if not instruction.get("entry", null) is Dictionary:
				return _fail(state, "INVALID_DRAFT_ENTRY")
			var entry: Dictionary = instruction["entry"].duplicate(true)
			var check: Dictionary = Eligibility.check(updated["core"], action, entry, catalogue)
			if not check["ok"]:
				return _fail(state, str(check["error"]))
			# Retain exactly one DRAFT per actor. Replacing a draft preserves
			# relative order, without consuming the actor's execution quota.
			var replaced: bool = false
			for i: int in range(w["draft"].size()):
				if str(w["draft"][i]["actor_id"]) == str(entry["actor_id"]):
					w["draft"][i] = entry
					replaced = true
					break
			if not replaced:
				w["draft"].append(entry)
			records.append(_record("ReactionQueued", {"window_id": str(w["window_id"]),
				"actor_id": str(entry["actor_id"]), "card_instance_id": str(entry["card_instance_id"]),
				"replaced": replaced}))
		"REMOVE_REACTION":
			var actor_id: String = str(instruction.get("actor_id", ""))
			var found: bool = false
			for i: int in range(w["draft"].size()):
				if str(w["draft"][i]["actor_id"]) == actor_id:
					w["draft"].remove_at(i)
					found = true
					break
			if not found:
				return _fail(state, "ACTOR_NOT_QUEUED")
			records.append(_record("ReactionDraftRemoved", {"window_id": str(w["window_id"]), "actor_id": actor_id}))
		"REORDER_REACTIONS":
			var order: Variant = instruction.get("actor_order", null)
			if not order is Array or order.size() != w["draft"].size():
				return _fail(state, "INVALID_REORDER")
			var arranged: Array = []
			var seen: Dictionary = {}
			for actor: Variant in order:
				if not actor is String or seen.has(actor):
					return _fail(state, "INVALID_REORDER")
				seen[actor] = true
				var matched: bool = false
				for existing: Dictionary in w["draft"]:
					if str(existing["actor_id"]) == str(actor):
						arranged.append(existing)
						matched = true
						break
				if not matched:
					return _fail(state, "INVALID_REORDER")
			w["draft"] = arranged
			records.append(_record("ReactionDraftReordered",
				{"window_id": str(w["window_id"]), "actor_order": order.duplicate(true)}))
		"PASS_REACTION":
			w["status"] = "CLOSED"
			w["closure_reason"] = "PLAYER_PASSED"
			records.append(_record("ReactionPassed", {"window_id": str(w["window_id"])}))
			records.append(_record("ReactionWindowClosed",
				{"window_id": str(w["window_id"]), "reason": "PLAYER_PASSED"}))
		"CONFIRM_REACTIONS":
			var overview: Dictionary = preview(updated, catalogue)
			if not overview["ok"]:
				return _fail(state, str(overview["error"]))
			w["status"] = "RESOLVING"
			records.append(_record("ReactionConfirmed",
				{"window_id": str(w["window_id"]), "actor_order": overview["draft_actor_order"]}))
			for i: int in range(w["draft"].size()):
				var reaction: Dictionary = w["draft"][i]
				var actor_id: String = str(reaction["actor_id"])
				var can: Dictionary = Eligibility.check(updated["core"], action, reaction,
					catalogue, bool(w["action_active"]))
				if w["executed_actor_ids"].has(actor_id):
					can = {"ok": false, "error": "ACTOR_ALREADY_REACTED"}
				if not can["ok"]:
					# PRE3-R04: no free cancellation of ALREADY EXECUTED
					# effects; only still-pending entries are skipped.
					records.append(_record("ReactionSkipped", {"window_id": str(w["window_id"]),
						"actor_id": actor_id, "reason": str(can["error"]),
						"card_instance_id": str(reaction["card_instance_id"])}))
					continue
				var paid: Dictionary = M2.apply(updated["core"], {
					"type": "COMMIT_REACTION_SP_FIXTURE",
					"command_id": str(instruction["command_id"]) + ":reaction:" + str(i),
					"expected_event_seq": int(updated["core"]["event_seq"]),
					"actor_id": actor_id,
					"card_instance_id": str(reaction["card_instance_id"])
				}, config)
				if not paid["accepted"]:
					records.append(_record("ReactionSkipped", {"window_id": str(w["window_id"]),
						"actor_id": actor_id, "reason": str(paid["error"]),
						"card_instance_id": str(reaction["card_instance_id"])}))
					continue
				updated["core"] = paid["state"]
				records.append({"kind": "CORE_EVENTS", "events": paid["events"]})
				w["executed_actor_ids"].append(actor_id)
				records.append(_record("ReactionExecuted",
					{"window_id": str(w["window_id"]), "actor_id": actor_id,
						"card_instance_id": str(reaction["card_instance_id"]),
						"rp_paid": int(can["rp_cost"]), "mp_paid": int(can["mp_cost"]),
						"fixture_effect": str(can["effect"])}))
				if str(can["effect"]) == "CANCEL_ACTION_FIXTURE":
					w["action_active"] = false
					records.append(_record("EnemyActionCancelledFixture", {
						"enemy_action_id": str(w["enemy_action_id"]),
						"reason": "REACTION_COUNTER_FIXTURE_ONLY"}))
			w["status"] = "CLOSED"
			w["closure_reason"] = "CONFIRMED_AND_RESOLVED"
			records.append(_record("ReactionWindowClosed",
				{"window_id": str(w["window_id"]), "reason": "CONFIRMED_AND_RESOLVED"}))
		_:
			return _fail(state, "UNKNOWN_REACTION_COMMAND")
	return {"ok": true, "error": "", "state": updated, "records": records}
