extends RefCounted
## M-D22..24: interruption-only part MP refund. Ratio/rounding NOT CANON.
## Caller must prove a real CastingInterrupted transition, not HP0,
## cancelled spell or target-invalidation. No refund of AP/Overload.
static func quote(instance: Dictionary, actor: Dictionary, config: Dictionary) -> Dictionary:
	if str(instance.get("mode","")) != "FULL" or str(instance.get("state","")) != "CASTING":
		return {"ok": false, "error": "NOT_ORDINARY_FULL_CAST"}
	if not instance.get("paid_mp",null) is int or int(instance["paid_mp"]) < 0:
		return {"ok": false, "error": "MISSING_ACTUAL_PAID_MP"}
	if str(config.get("authority","")) != "BALANCE_PROVISIONAL" or \
			not config.get("numerator",null) is int or not config.get("denominator",null) is int:
		return {"ok": false, "error": "MISSING_PROVISIONAL_REFUND"}
	var num: int = int(config["numerator"])
	var den: int = int(config["denominator"])
	if den <= 0 or num < 0 or num >= den:
		return {"ok": false, "error": "INVALID_PARTIAL_REFUND_RATIO"}
	if str(config.get("rounding","")) != "FLOOR_FIXTURE":
		return {"ok": false, "error": "REFUND_ROUNDING_UNAPPROVED"}
	if not actor.get("mp",null) is int or not actor.get("max_mp",null) is int:
		return {"ok": false, "error": "INVALID_ACTOR_MP"}
	var requested: int = floori(float(int(instance["paid_mp"]) * num) / float(den))
	var actual: int = min(max(0,int(actor["max_mp"]) - int(actor["mp"])), requested)
	return {"ok": true, "requested": requested, "actual": actual,
		"paid_mp": int(instance["paid_mp"]), "ratio": str(num) + "/" + str(den),
		"rounding": "FLOOR_FIXTURE", "balance_authority": "BALANCE_PROVISIONAL"}
