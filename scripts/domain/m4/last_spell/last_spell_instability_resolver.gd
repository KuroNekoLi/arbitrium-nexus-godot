extends RefCounted
## Ordinary disruption at threshold NEVER cancels Last Spell or refunds MP.
## First threshold: delay exactly once. Later thresholds: configured
## weakening once, no infinite postponement. Numeric weakening provisional.
static func handle(instance: Dictionary, settings: Dictionary) -> Dictionary:
	if str(instance.get("kind","")) != "LAST_SPELL" or str(instance.get("state","")) != "CASTING" or \
			int(instance.get("current_stability",-1)) != 0:
		return {"ok":false,"error":"NOT_LAST_SPELL_DESTABILIZATION"}
	if str(settings.get("authority","")) != "BALANCE_PROVISIONAL" or \
			not settings.get("stability_reset",null) is int or int(settings["stability_reset"]) <= 0:
		return {"ok":false,"error":"MISSING_PROVISIONAL_LAST_SPELL_INSTABILITY"}
	var result: Dictionary = instance.duplicate(true)
	result["disrupted_count"] = int(result["disrupted_count"]) + 1
	result["current_stability"] = int(settings["stability_reset"])
	result["last_spell_state"] = "DESTABILIZED"
	var kind: String = ""
	if not bool(result["delay_used"]):
		result["planned_resolve_round"] = int(result["planned_resolve_round"]) + 1
		result["delay_used"] = true
		kind = "LastSpellDestabilizedDelayed"
	else:
		if not settings.get("weaken_numerator",null) is int or \
				not settings.get("weaken_denominator",null) is int or \
				int(settings["weaken_denominator"]) <= 0 or \
				int(settings["weaken_numerator"]) <= 0 or \
				int(settings["weaken_numerator"]) >= int(settings["weaken_denominator"]):
			return {"ok":false,"error":"MISSING_PROVISIONAL_LAST_SPELL_WEAKEN"}
		if int(result["outcome_modifier_numerator"]) == 1 and int(result["outcome_modifier_denominator"]) == 1:
			result["outcome_modifier_numerator"] = int(settings["weaken_numerator"])
			result["outcome_modifier_denominator"] = int(settings["weaken_denominator"])
		kind = "LastSpellDestabilizedWeakened"
	return {"ok":true,"instance":result,
		"event":{"kind":kind,"casting_id":str(result["casting_id"]),
			"disrupted_count":int(result["disrupted_count"]),
			"delay_used":true,
			"planned_resolve_round":int(result["planned_resolve_round"]),
			"modifier_numerator":int(result["outcome_modifier_numerator"]),
			"modifier_denominator":int(result["outcome_modifier_denominator"]),
			"balance_authority":"BALANCE_PROVISIONAL",
			"cancellation":false,"mp_refund":0}}
