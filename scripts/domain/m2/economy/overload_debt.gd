extends RefCounted
## M2.2 / M-D02..M-D09 — independent AP debt, no negative CurrentAP.
## This helper never mutates its arguments. M-D04 cross-round carry is PROVISIONAL.

static func _nonnegative_integral(v: Variant) -> bool:
	if v is int:
		return int(v) >= 0
	if v is float:
		return v >= 0.0 and v < 9007199254740992.0 and v == floor(v)
	return false

static func borrow_quote(shortfall: int, card: Dictionary, resources: Dictionary, config: Dictionary) -> Dictionary:
	if shortfall < 0:
		return {"ok": false, "error": "INVALID_SHORTFALL"}
	if shortfall == 0:
		return {"ok": true, "borrow": 0, "error": ""}
	if not bool(card.get("overload_eligible", false)):
		return {"ok": false, "error": "INSUFFICIENT_AP"}
	if not card.get("max_borrow_per_card", null) is int or int(card["max_borrow_per_card"]) < 0:
		return {"ok": false, "error": "INVALID_CARD_BORROW_LIMIT"}
	if shortfall > int(card["max_borrow_per_card"]):
		return {"ok": false, "error": "CARD_BORROW_LIMIT"}
	if config.get("authority", "") != "BALANCE_PROVISIONAL":
		return {"ok": false, "error": "MISSING_PROVISIONAL_RULESET"}
	if not _nonnegative_integral(config.get("max_ap_debt", null)):
		return {"ok": false, "error": "INVALID_TEAM_DEBT_LIMIT"}
	var limit: int = int(config["max_ap_debt"])
	var existing: int = int(resources.get("ap_debt", 0))
	if shortfall > limit or existing > limit - shortfall:
		return {"ok": false, "error": "TEAM_DEBT_LIMIT"}
	return {"ok": true, "borrow": shortfall, "error": ""}

static func open_player_phase(resources: Dictionary, config: Dictionary) -> Dictionary:
	# Phase ordering/ticks/hand draw belong to M3; this only returns resource math.
	var prior: int = int(resources.get("ap_debt", -1))
	var base: int = int(resources.get("base_ap", -1))
	var next_bonus: int = int(resources.get("next_player_ap_bonus", 0))
	if prior < 0 or base < 0 or next_bonus < 0:
		return {"ok": false, "error": "INVALID_RESOURCE_STATE"}
	if prior > 0 and (config.get("authority", "") != "BALANCE_PROVISIONAL"
			or config.get("ap_debt_policy", "") != "PROVISIONAL_MULTI_PHASE"):
		return {"ok": false, "error": "DEFERRED_TO_M2_2_AP_DEBT"}
	if next_bonus > 9223372036854775807 - base:
		return {"ok": false, "error": "AP_OVERFLOW"}
	var pool: int = base + next_bonus
	var repaid: int = min(pool, prior)
	return {"ok": true, "pool": pool, "repaid": repaid,
		"current_ap": pool - repaid, "ap_debt": prior - repaid, "error": ""}
