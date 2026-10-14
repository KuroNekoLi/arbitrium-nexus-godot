extends RefCounted
## Phase 3 / M2.1 — deterministic resource ledger, no UI/Node/timer.
## Authority: P1-D01, P1-D09, M-D08/09/18/19/20/31, PRE3-R05.
## NOTE: This is an INTERNAL transition API for the future battle reducer.
## BASIC_ATTACK_RESOURCE_ONLY does not resolve attacks or apply damage (M5).
## Boundary steps only update resources; M3 owns full phase/status/casting sequencing.
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const BasicAttackMP = preload("res://scripts/domain/m2/economy/basic_attack_mp_policy.gd")
const Debt = preload("res://scripts/domain/m2/economy/overload_debt.gd")
const KINDS: Array[String] = [
	"SPEND_AP", "GRANT_AP", "PAY_MP", "RECOVER_MP",
	"BASIC_ATTACK_RESOURCE_ONLY", "CONVERT_AP_TO_RP",
	"SPEND_RP", "GRANT_RP", "PAY_REACTION_COST_FIXTURE", "EXPIRE_RP", "START_PLAYER_RESOURCES"
]

static func _reject(state: Dictionary, reason: String) -> Dictionary:
	var original: Dictionary = Model.snapshot(state)
	return {"accepted": false, "error": reason, "state": original, "events": [],
		"state_hash": Model.state_hash(original), "event_hash": Model.event_hash([])}

static func _finish(next_state: Dictionary, instruction: Dictionary, event_name: String, details: Dictionary) -> Dictionary:
	next_state["action_seq"] = int(next_state["action_seq"]) + 1
	next_state["event_seq"] = int(next_state["event_seq"]) + 1
	var used_ids: Array = next_state["seen_command_ids"]
	used_ids.append(str(instruction["command_id"]))
	var event: Dictionary = {
		"event_seq": int(next_state["event_seq"]),
		"action_id": int(next_state["action_seq"]),
		"command_id": str(instruction["command_id"]),
		"kind": event_name,
		"phase": str(next_state["phase"]),
		"rng_draw_index": int(next_state["rng"]["draw_index"]),
		"details": details
	}
	var log: Array = next_state["events"]
	log.append(event)
	return {"accepted": true, "error": "", "state": next_state, "events": [event],
		"state_hash": Model.state_hash(next_state), "event_hash": Model.event_hash([event])}

static func _valid_actor(state: Dictionary, actor_id: String) -> bool:
	if not state["allies"].has(actor_id):
		return false
	if not state["actors"].has(actor_id):
		return false
	return true

static func _can_act(state: Dictionary, actor_id: String) -> bool:
	if not _valid_actor(state, actor_id):
		return false
	var actor: Dictionary = state["actors"][actor_id]
	return str(actor.get("status", "")) == "ACTIVE" and int(actor.get("hp", 0)) > 0

static func _valid_amount(instruction: Dictionary) -> bool:
	return instruction.has("amount") and instruction["amount"] is int and int(instruction["amount"]) >= 0

static func apply(state: Dictionary, instruction: Dictionary, provisional: Dictionary = {}) -> Dictionary:
	if not Model.validate_shell(state):
		return _reject(state, "INVALID_STATE")
	if state.get("outcome", "") != "ONGOING":
		return _reject(state, "BATTLE_ENDED")
	var kind: String = str(instruction.get("type", ""))
	if not KINDS.has(kind):
		return _reject(state, "UNKNOWN_RESOURCE_OPERATION")
	var id: String = str(instruction.get("command_id", ""))
	if id.strip_edges().is_empty():
		return _reject(state, "INVALID_COMMAND_ID")
	if state["seen_command_ids"].has(id):
		return _reject(state, "DUPLICATE_COMMAND")
	if not instruction.has("expected_event_seq") or not instruction["expected_event_seq"] is int:
		return _reject(state, "INVALID_EXPECTED_EVENT_SEQ")
	if int(instruction["expected_event_seq"]) != int(state["event_seq"]):
		return _reject(state, "STALE_STATE")

	var phase: String = str(state["phase"])
	var actor_id: String = str(instruction.get("actor_id", ""))
	var r: Dictionary = state["party_resources"]
	var next_state: Dictionary = {}
	var amount: int = 0
	var before: int = 0
	var after: int = 0

	match kind:
		"SPEND_AP", "GRANT_AP":
			if phase != "PLAYER_PHASE":
				return _reject(state, "INVALID_PHASE")
			if not _valid_amount(instruction):
				return _reject(state, "INVALID_AMOUNT")
			amount = int(instruction["amount"])
			if kind == "SPEND_AP" and int(r["current_ap"]) < amount:
				return _reject(state, "INSUFFICIENT_AP")
			if kind == "GRANT_AP" and amount > 0 and int(r["current_ap"]) + amount < int(r["current_ap"]):
				return _reject(state, "AMOUNT_OVERFLOW")
			next_state = Model.snapshot(state)
			before = int(r["current_ap"])
			after = before - amount if kind == "SPEND_AP" else before + amount
			next_state["party_resources"]["current_ap"] = after
			return _finish(next_state, instruction,
				"APSpent" if kind == "SPEND_AP" else "APGranted",
				{"amount": amount, "before": before, "after": after, "source": "M2_1_INTERNAL"})
		"PAY_MP", "RECOVER_MP":
			if not _valid_actor(state, actor_id):
				return _reject(state, "ACTOR_NOT_FOUND")
			if kind == "PAY_MP" and (phase != "PLAYER_PHASE" or not _can_act(state, actor_id)):
				return _reject(state, "ACTOR_UNAVAILABLE_OR_PHASE")
			if not _valid_amount(instruction):
				return _reject(state, "INVALID_AMOUNT")
			amount = int(instruction["amount"])
			var actor: Dictionary = state["actors"][actor_id]
			before = int(actor["mp"])
			if kind == "PAY_MP" and before < amount:
				return _reject(state, "INSUFFICIENT_MP")
			next_state = Model.snapshot(state)
			after = before - amount if kind == "PAY_MP" else min(int(actor["max_mp"]), before + amount)
			next_state["actors"][actor_id]["mp"] = after
			return _finish(next_state, instruction,
				"MPSpent" if kind == "PAY_MP" else "MPRestored",
				{"actor_id": actor_id, "requested": amount, "actual": abs(after - before),
					"before": before, "after": after, "source": "M2_1_INTERNAL"})
		"BASIC_ATTACK_RESOURCE_ONLY":
			if phase != "PLAYER_PHASE":
				return _reject(state, "INVALID_PHASE")
			if not _can_act(state, actor_id):
				return _reject(state, "ACTOR_UNAVAILABLE")
			# No implicit numbers: both the AP cost and MP gain come from
			# an explicitly versioned BALANCE_PROVISIONAL profile.
			var quote: Dictionary = BasicAttackMP.quote(state, actor_id, provisional, Model.RULESET_VERSION)
			if not quote["accepted"]:
				return _reject(state, str(quote["error"]))
			var cost: int = int(quote["ap_cost"])
			var actual_gain: int = int(quote["mp_restored"])
			var already_used: bool = not bool(quote["first_success_this_player_phase"])
			if int(r["current_ap"]) < cost:
				return _reject(state, "INSUFFICIENT_AP")
			var current_mp: int = int(state["actors"][actor_id]["mp"])
			next_state = Model.snapshot(state)
			next_state["party_resources"]["current_ap"] = int(r["current_ap"]) - cost
			next_state["actors"][actor_id]["mp"] = current_mp + actual_gain
			next_state["basic_attack_mp_restore_used_by_actor"][actor_id] = true
			return _finish(next_state, instruction, "BasicAttackResourceCommitted",
				{"actor_id": actor_id, "ap_paid": cost, "mp_restored": actual_gain,
					"first_success_this_player_phase": not already_used,
					"attack_effect_status": "DEFERRED_TO_M5",
					"balance_authority": "BALANCE_PROVISIONAL"})
		"CONVERT_AP_TO_RP":
			if phase != "PLAYER_PHASE":
				return _reject(state, "INVALID_PHASE")
			before = int(r["current_ap"])
			after = min(before, int(r["rp_cap"]))
			next_state = Model.snapshot(state)
			next_state["party_resources"]["current_ap"] = 0
			next_state["party_resources"]["rp"] = after
			next_state["phase"] = "ENEMY_PHASE"
			return _finish(next_state, instruction, "PlayerResourcesClosed",
				{"ap_remaining": before, "rp_created": after, "ap_overflow_lost": before - after,
					"rp_cap": int(r["rp_cap"])})
		"SPEND_RP", "GRANT_RP":
			if phase != "ENEMY_PHASE":
				return _reject(state, "INVALID_PHASE")
			if not _valid_amount(instruction):
				return _reject(state, "INVALID_AMOUNT")
			amount = int(instruction["amount"])
			before = int(r["rp"])
			if kind == "SPEND_RP" and amount > before:
				return _reject(state, "INSUFFICIENT_RP")
			next_state = Model.snapshot(state)
			after = before - amount if kind == "SPEND_RP" else min(int(r["rp_cap"]), before + amount)
			next_state["party_resources"]["rp"] = after
			return _finish(next_state, instruction, "RPSpent" if kind == "SPEND_RP" else "RPGranted",
				{"requested": amount, "actual": abs(after - before), "before": before, "after": after})
		"PAY_REACTION_COST_FIXTURE":
			# Exact RP+MP in one transaction; no extra reaction economy.
			# Caller must separately validate Window/target/card eligibility.
			if phase != "ENEMY_PHASE":
				return _reject(state, "INVALID_PHASE")
			if not _can_act(state, actor_id):
				return _reject(state, "ACTOR_UNAVAILABLE")
			if not instruction.get("rp_cost", null) is int or not instruction.get("mp_cost", null) is int:
				return _reject(state, "INVALID_REACTION_COST")
			var rp_cost: int = int(instruction["rp_cost"])
			var mp_cost: int = int(instruction["mp_cost"])
			if rp_cost < 0 or mp_cost < 0:
				return _reject(state, "INVALID_REACTION_COST")
			if rp_cost > int(r["rp"]):
				return _reject(state, "INSUFFICIENT_RP")
			if mp_cost > int(state["actors"][actor_id]["mp"]):
				return _reject(state, "INSUFFICIENT_MP")
			next_state = Model.snapshot(state)
			next_state["party_resources"]["rp"] = int(r["rp"]) - rp_cost
			next_state["actors"][actor_id]["mp"] = int(state["actors"][actor_id]["mp"]) - mp_cost
			return _finish(next_state, instruction, "ReactionResourcesCommitted",
				{"actor_id": actor_id, "rp_paid": rp_cost, "mp_paid": mp_cost,
					"source": "M3_2_REACTION_SP_FIXTURE"})
		"EXPIRE_RP":
			if phase != "ENEMY_PHASE":
				return _reject(state, "INVALID_PHASE")
			next_state = Model.snapshot(state)
			before = int(r["rp"])
			next_state["party_resources"]["rp"] = 0
			next_state["phase"] = "AWAITING_PLAYER_START"
			return _finish(next_state, instruction, "EnemyResourcesClosed",
				{"rp_expired": before})
		"START_PLAYER_RESOURCES":
			if phase != "AWAITING_PLAYER_START":
				return _reject(state, "INVALID_PHASE")
			var opened: Dictionary = Debt.open_player_phase(r, provisional)
			if not opened["ok"]:
				return _reject(state, str(opened["error"]))
			next_state = Model.snapshot(state)
			next_state["phase"] = "PLAYER_PHASE"
			next_state["round"] = int(state["round"]) + 1
			next_state["party_resources"]["current_ap"] = int(opened["current_ap"])
			next_state["party_resources"]["ap_debt"] = int(opened["ap_debt"])
			next_state["party_resources"]["next_player_ap_bonus"] = 0
			next_state["party_resources"]["rp"] = 0
			for ally_id: String in state["allies"]:
				next_state["basic_attack_mp_restore_used_by_actor"][ally_id] = false
			return _finish(next_state, instruction, "PlayerResourcesOpened",
				{"round": int(next_state["round"]), "base_ap": int(r["base_ap"]),
					"pool": int(opened["pool"]), "old_debt_repaid": int(opened["repaid"]),
					"debt_carried": int(opened["ap_debt"]),
					"note": "M3_TICK_AND_DRAW_NOT_IMPLEMENTED"})
	return _reject(state, "UNKNOWN_RESOURCE_OPERATION")

static func replay(initial_state: Dictionary, tape: Array[Dictionary], provisional: Dictionary = {}) -> Dictionary:
	var state: Dictionary = Model.snapshot(initial_state)
	var log: Array = []
	for instruction: Dictionary in tape:
		var result: Dictionary = apply(state, instruction, provisional)
		if not result["accepted"]:
			return {"accepted": false, "error": result["error"], "state": state, "events": log,
				"state_hash": Model.state_hash(state), "event_hash": Model.event_hash(log)}
		state = result["state"]
		log.append_array(result["events"])
	return {"accepted": true, "error": "", "state": state, "events": log,
		"state_hash": Model.state_hash(state), "event_hash": Model.event_hash(log)}
