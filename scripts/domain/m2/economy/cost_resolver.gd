extends RefCounted
## M2.2 INTERNAL Cost Engine: cost quote + atomic AP/MP + Overload transaction.
## Not a playable SP resolver: no real card instance or spell effects exist yet.
## Authority: Library 18 M-D01..17; 19 M-D18/21; 20 PRE3-R10.
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const Debt = preload("res://scripts/domain/m2/economy/overload_debt.gd")
const Modes: Array[String] = ["CHANTLESS", "FULL"]

static func _nat(v: Variant) -> bool:
	return v is int and int(v) >= 0

static func _eligible(modifier: Dictionary, actor_id: String, card_id: String) -> bool:
	if not _nat(modifier.get("remaining_uses", null)) or int(modifier["remaining_uses"]) == 0:
		return false
	if modifier.get("actor_id", "*") != "*" and modifier.get("actor_id", "") != actor_id:
		return false
	if modifier.get("card_id", "*") != "*" and modifier.get("card_id", "") != card_id:
		return false
	return true

static func _mod_before(a: Dictionary, b: Dictionary) -> bool:
	var ap: int = int(a["priority"])
	var bp: int = int(b["priority"])
	if ap != bp:
		return ap < bp
	var ag: int = int(a["grant_seq"])
	var bg: int = int(b["grant_seq"])
	if ag != bg:
		return ag < bg
	return str(a["instance_id"]) < str(b["instance_id"])

static func quote(state: Dictionary, request: Dictionary, config: Dictionary) -> Dictionary:
	if not Model.validate_shell(state):
		return {"ok": false, "error": "INVALID_STATE"}
	if state.get("phase", "") != "PLAYER_PHASE" or state.get("outcome", "") != "ONGOING":
		return {"ok": false, "error": "INVALID_PHASE"}
	if config.get("authority", "") != "BALANCE_PROVISIONAL" or config.get("ruleset_version", "") != Model.RULESET_VERSION:
		return {"ok": false, "error": "MISSING_PROVISIONAL_RULESET"}
	var actor_id: String = str(request.get("actor_id", ""))
	if not state["allies"].has(actor_id) or not state["actors"].has(actor_id):
		return {"ok": false, "error": "ACTOR_NOT_FOUND"}
	var actor: Dictionary = state["actors"][actor_id]
	if int(actor["hp"]) <= 0 or actor.get("status", "") != "ACTIVE":
		return {"ok": false, "error": "ACTOR_UNAVAILABLE"}
	if not request.get("card", null) is Dictionary:
		return {"ok": false, "error": "INVALID_CARD_FIXTURE"}
	var card: Dictionary = request["card"]
	var card_id: String = str(card.get("card_id", ""))
	if card_id.strip_edges().is_empty():
		return {"ok": false, "error": "INVALID_CARD_FIXTURE"}
	if not _nat(card.get("ap_cost", null)) or not _nat(card.get("mp_cost", null)):
		return {"ok": false, "error": "INVALID_CARD_COST"}
	var chosen: int = int(card["ap_cost"])
	var variable: bool = bool(card.get("variable_ap", false))
	if variable:
		if not _nat(card.get("min_investment", null)) or not _nat(card.get("max_investment", null)):
			return {"ok": false, "error": "INVALID_INVESTMENT_RANGE"}
		if int(card["max_investment"]) < int(card["min_investment"]):
			return {"ok": false, "error": "INVALID_INVESTMENT_RANGE"}
		if not _nat(request.get("chosen_ap_investment", null)):
			return {"ok": false, "error": "MISSING_AP_INVESTMENT"}
		chosen = int(request["chosen_ap_investment"])
		if chosen < int(card["min_investment"]) or chosen > int(card["max_investment"]):
			return {"ok": false, "error": "INVESTMENT_OUT_OF_RANGE"}
	elif request.has("chosen_ap_investment"):
		return {"ok": false, "error": "FIXED_COST_INVESTMENT_FORBIDDEN"}
	var mode: String = str(request.get("casting_mode", "CHANTLESS"))
	if not Modes.has(mode):
		return {"ok": false, "error": "INVALID_CASTING_MODE"}
	# M-D21: same default MP in Full and Chantless. Per-card explicit
	# MP overrides are deferred until card content authoring.
	var mp_cost: int = int(card["mp_cost"])
	if int(actor["mp"]) < mp_cost:
		return {"ok": false, "error": "INSUFFICIENT_MP"}
	if not _nat(card.get("min_ap_cost", 0)):
		return {"ok": false, "error": "INVALID_MINIMUM_COST"}
	var minimum: int = int(card.get("min_ap_cost", 0))
	var modifiers: Array = state.get("cost_modifiers", [])
	var sorted_modifiers: Array[Dictionary] = []
	for item: Variant in modifiers:
		if not item is Dictionary:
			return {"ok": false, "error": "INVALID_MODIFIER"}
		var mod: Dictionary = item
		if not ["SET_COST", "DISCOUNT"].has(str(mod.get("kind", ""))):
			return {"ok": false, "error": "INVALID_MODIFIER"}
		if not _nat(mod.get("value", null)) or not mod.get("priority", null) is int or not _nat(mod.get("grant_seq", null)):
			return {"ok": false, "error": "INVALID_MODIFIER"}
		if not mod.get("remaining_uses", null) is int or int(mod["remaining_uses"]) < 0:
			return {"ok": false, "error": "INVALID_MODIFIER"}
		if str(mod.get("instance_id", "")).strip_edges().is_empty():
			return {"ok": false, "error": "INVALID_MODIFIER"}
		if _eligible(mod, actor_id, card_id):
			sorted_modifiers.append(mod.duplicate(true))
	sorted_modifiers.sort_custom(_mod_before)
	var set_count: int = 0
	var base_cost: int = chosen
	var consumed: Array = []
	for mod: Dictionary in sorted_modifiers:
		if mod["kind"] == "SET_COST":
			set_count += 1
			if set_count > 1:
				return {"ok": false, "error": "MULTIPLE_SET_COST_TBD"}
			base_cost = int(mod["value"])
			consumed.append(str(mod["instance_id"]))
	if minimum > base_cost:
		return {"ok": false, "error": "MINIMUM_EXCEEDS_BASE"}
	var eligible: int = base_cost - minimum
	var applied: int = 0
	var trace: Array = []
	for mod: Dictionary in sorted_modifiers:
		if mod["kind"] != "DISCOUNT" or eligible <= 0:
			continue
		var effective: int = min(eligible, int(mod["value"]))
		if effective == 0:
			continue
		eligible -= effective
		applied += effective
		consumed.append(str(mod["instance_id"]))
		trace.append({"instance_id": mod["instance_id"], "discount_applied": effective})
	var actual_cost: int = base_cost - applied
	var current_ap: int = int(state["party_resources"]["current_ap"])
	var shortfall: int = max(0, actual_cost - current_ap)
	var borrow: Dictionary = Debt.borrow_quote(shortfall, card, state["party_resources"], config)
	if not borrow["ok"]:
		return {"ok": false, "error": str(borrow["error"])}
	# Numeric discounts are capped at minimum and never turn excess into AP refunds.
	return {"ok": true, "error": "", "card_id": card_id, "actor_id": actor_id,
		"chosen_ap_investment": chosen, "casting_mode": mode, "base_ap_after_set": base_cost,
		"eligible_discount_applied": applied, "ap_cost": actual_cost, "mp_cost": mp_cost,
		"ap_paid": actual_cost - shortfall, "ap_borrowed": shortfall,
		"modifiers_consumed": consumed, "discount_trace": trace, "min_ap_cost": minimum}

static func _reject(state: Dictionary, reason: String) -> Dictionary:
	var unchanged: Dictionary = Model.snapshot(state)
	return {"accepted": false, "error": reason, "state": unchanged, "events": [],
		"state_hash": Model.state_hash(unchanged), "event_hash": Model.event_hash([])}

static func apply(state: Dictionary, command: Dictionary, config: Dictionary) -> Dictionary:
	# Private fixture transaction: NEVER call from gameplay/UI as PLAY_SP.
	if not Model.validate_shell(state):
		return _reject(state, "INVALID_STATE")
	if str(command.get("type", "")) != "PAY_SP_COST_ONLY":
		return _reject(state, "INTERNAL_COST_OPERATION_ONLY")
	var command_id: String = str(command.get("command_id", ""))
	if command_id.strip_edges().is_empty():
		return _reject(state, "INVALID_COMMAND_ID")
	if state["seen_command_ids"].has(command_id):
		return _reject(state, "DUPLICATE_COMMAND")
	if not command.get("expected_event_seq", null) is int:
		return _reject(state, "INVALID_EXPECTED_EVENT_SEQ")
	if int(command["expected_event_seq"]) != int(state["event_seq"]):
		return _reject(state, "STALE_STATE")
	var proposed: Dictionary = quote(state, command, config)
	if not proposed["ok"]:
		return _reject(state, str(proposed["error"]))
	var next_state: Dictionary = Model.snapshot(state)
	var resources: Dictionary = next_state["party_resources"]
	var ally: Dictionary = next_state["actors"][proposed["actor_id"]]
	resources["current_ap"] -= int(proposed["ap_paid"])
	resources["ap_debt"] += int(proposed["ap_borrowed"])
	ally["mp"] -= int(proposed["mp_cost"])
	# PRE3-R10: consume only actually contributing discount / SetCost instances.
	for mod: Dictionary in next_state.get("cost_modifiers", []):
		if proposed["modifiers_consumed"].has(str(mod["instance_id"])):
			mod["remaining_uses"] -= 1
	var used_ids: Array = next_state["seen_command_ids"]
	used_ids.append(command_id)
	var paid_ids: Array = next_state["paid_cost_command_ids"]
	paid_ids.append(command_id)
	next_state["action_seq"] += 1
	next_state["event_seq"] += 1
	var detail: Dictionary = proposed.duplicate(true)
	detail.erase("ok")
	detail.erase("error")
	detail["effect_execution"] = "DEFERRED_TO_M3_M4_M5"
	detail["balance_authority"] = "BALANCE_PROVISIONAL"
	var event: Dictionary = {"kind": "SPCostReservedOnly", "command_id": command_id,
		"event_seq": next_state["event_seq"], "action_id": next_state["action_seq"],
		"phase": "PLAYER_PHASE", "rng_draw_index": next_state["rng"]["draw_index"],
		"details": detail}
	var log: Array = next_state["events"]
	log.append(event)
	return {"accepted": true, "error": "", "state": next_state, "events": [event],
		"state_hash": Model.state_hash(next_state), "event_hash": Model.event_hash([event]),
		"quote": proposed}

static func replay(initial_state: Dictionary, tape: Array[Dictionary], config: Dictionary) -> Dictionary:
	var current: Dictionary = Model.snapshot(initial_state)
	var events: Array = []
	for command: Dictionary in tape:
		var result: Dictionary = apply(current, command, config)
		if not result["accepted"]:
			return {"accepted": false, "error": result["error"], "state": current,
				"events": events, "state_hash": Model.state_hash(current),
				"event_hash": Model.event_hash(events)}
		current = result["state"]
		events.append_array(result["events"])
	return {"accepted": true, "error": "", "state": current, "events": events,
		"state_hash": Model.state_hash(current), "event_hash": Model.event_hash(events)}
