extends RefCounted
## M4.2: Focus Ward protects Casting Stability ONLY; never HP/Barrier.
## Pure per-instance manipulation. Content amount is server-side fixture config.
static func grant(instance: Dictionary, amount: int) -> Dictionary:
	if str(instance.get("state","")) != "CASTING" or amount <= 0:
		return {"ok": false, "error": "INVALID_FOCUS_WARD_GRANT"}
	if int(instance.get("focus_ward",-1)) < 0:
		return {"ok": false, "error": "INVALID_FOCUS_WARD_STATE"}
	var changed: Dictionary = instance.duplicate(true)
	var before: int = int(changed["focus_ward"])
	changed["focus_ward"] = before + amount
	return {"ok": true, "instance": changed, "before": before, "after": before + amount}

static func absorb(instance: Dictionary, incoming: int) -> Dictionary:
	if str(instance.get("state","")) != "CASTING" or incoming < 0 or int(instance.get("focus_ward",-1)) < 0:
		return {"ok": false, "error": "INVALID_FOCUS_WARD_OR_DISRUPTION"}
	var current: int = int(instance["focus_ward"])
	var absorbed: int = min(current, incoming)
	var new_instance: Dictionary = instance.duplicate(true)
	new_instance["focus_ward"] = current - absorbed
	return {"ok": true, "instance": new_instance, "absorbed": absorbed,
		"remaining": incoming - absorbed, "ward_before": current,
		"ward_after": current - absorbed}
