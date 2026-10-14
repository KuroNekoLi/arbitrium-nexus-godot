extends RefCounted
## M4.2 fixture-only deterministic interrupt trace. DOES NOT change Boss Break.
const FocusWard = preload("res://scripts/domain/m4/casting/focus_ward_resolver.gd")

static func resolve(instance: Dictionary, effect: Dictionary, context: Dictionary) -> Dictionary:
	if str(instance.get("mode", "")) != "FULL" or str(instance.get("state","")) != "CASTING":
		return {"ok": false, "error": "NOT_ORDINARY_ACTIVE_CAST"}
	if str(effect.get("authority", "")) != "BALANCE_PROVISIONAL":
		return {"ok": false, "error": "MISSING_DISRUPTION_FIXTURE_AUTHORITY"}
	if not effect.get("disruption_power",null) is int or int(effect["disruption_power"]) <= 0:
		return {"ok": false, "error": "INVALID_DISRUPTION_POWER"}
	if not instance.get("current_stability",null) is int or int(instance["current_stability"]) <= 0:
		return {"ok": false, "error": "INVALID_CASTING_STABILITY"}
	var channel: String = str(context.get("channel",""))
	if not ["DIRECT_CASTING_INSTANCE","ON_HIT_CASTING"].has(channel):
		return {"ok": false, "error": "UNSUPPORTED_DISRUPTION_CHANNEL"}
	var absorber: Dictionary = FocusWard.absorb(instance, int(effect["disruption_power"]))
	if not absorber["ok"]:
		return absorber
	var after: Dictionary = absorber["instance"]
	var before: int = int(after["current_stability"])
	var lost: int = min(before,int(absorber["remaining"]))
	after["current_stability"] = before - lost
	var trace: Dictionary = {"casting_id": str(instance["casting_id"]),
		"channel": channel, "source_enemy_action_id": str(context["source_enemy_action_id"]),
		"effect_id": str(context["effect_id"]), "hit_index": int(context.get("hit_index",0)),
		"power": int(effect["disruption_power"]),
		"ward_before": int(absorber["ward_before"]), "ward_absorbed": int(absorber["absorbed"]),
		"ward_after": int(absorber["ward_after"]),
		"stability_before": before, "stability_lost": lost,
		"stability_after": before-lost, "interrupted": before-lost == 0}
	after["disruption_events"].append(trace.duplicate(true))
	return {"ok": true, "instance": after, "trace": trace,
		"interrupted": before-lost == 0}
