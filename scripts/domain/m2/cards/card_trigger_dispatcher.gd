extends RefCounted
## M2.4 deterministic CardDiscarded/CardDrawn effect dispatcher.
## Rules are explicit, versionable content, NOT automatically granted to all
## cards. This isolated headless adapter allows safe, bounded card-zone effects;
## the eventual gameplay effects resolver may add other tagged operations.
const Zones = preload("res://scripts/domain/m2/cards/card_zone_resolver.gd")
const ALLOWED_EVENTS: Array[String] = ["CardDiscarded", "CardDrawn"]
const LIMIT: int = 32

static func validate_rules(rules: Array) -> Dictionary:
	if rules.size() > LIMIT:
		return {"ok": false, "error": "TRIGGER_RULE_LIMIT"}
	var ids: Dictionary = {}
	for item: Variant in rules:
		if not item is Dictionary:
			return {"ok": false, "error": "INVALID_TRIGGER_RULE"}
		var rule: Dictionary = item
		var id: String = str(rule.get("effect_id", ""))
		if id.strip_edges().is_empty() or ids.has(id):
			return {"ok": false, "error": "INVALID_TRIGGER_EFFECT_ID"}
		ids[id] = true
		if not ALLOWED_EVENTS.has(str(rule.get("on", ""))) or str(rule.get("source_definition_id", "")).strip_edges().is_empty():
			return {"ok": false, "error": "INVALID_TRIGGER_MATCH"}
		if str(rule.get("operation", "")) != "MOVE_CARD":
			return {"ok": false, "error": "UNSUPPORTED_TRIGGER_EFFECT"}
		if str(rule.get("actor_id", "")).strip_edges().is_empty() or str(rule.get("instance_id", "")).strip_edges().is_empty():
			return {"ok": false, "error": "INVALID_TRIGGER_TARGET"}
		var from_zone: String = str(rule.get("from_zone", ""))
		var to_zone: String = str(rule.get("to_zone", ""))
		if not Zones.ZONES.has(from_zone) or not Zones.ZONES.has(to_zone):
			return {"ok": false, "error": "INVALID_TRIGGER_ZONE"}
		if from_zone == to_zone or from_zone == "isolated" or to_zone == "isolated":
			return {"ok": false, "error": "PROTECTED_SWAP_ISOLATION"}
	return {"ok": true, "error": ""}

static func dispatch(state: Dictionary, source_event: Dictionary, rules: Array) -> Dictionary:
	if not Zones.validate_state(state):
		return Zones.rejected(state, "INVALID_ZONE_STATE")
	var validation: Dictionary = validate_rules(rules)
	if not validation["ok"]:
		return Zones.rejected(state, str(validation["error"]))
	var kind: String = str(source_event.get("kind", ""))
	if not ALLOWED_EVENTS.has(kind):
		return Zones.accepted(state.duplicate(true))
	var actor_id: String = str(source_event.get("actor_id", ""))
	var details: Variant = source_event.get("details", null)
	if not details is Dictionary or not state["actors"].has(actor_id):
		return Zones.rejected(state, "INVALID_CARD_EVENT")
	var instance_id: String = str(details.get("instance_id", ""))
	var instances: Dictionary = state["actors"][actor_id]["instances"]
	if not instances.has(instance_id):
		return Zones.rejected(state, "INVALID_CARD_EVENT_INSTANCE")
	var definition_id: String = str(instances[instance_id]["definition_id"])
	var next_state: Dictionary = state.duplicate(true)
	var emitted: Array = []
	# Input order is deterministic, limited and non-recursive; zone-change
	# events emitted by effects do not recursively dispatch themselves.
	for item: Variant in rules:
		var rule: Dictionary = item
		if str(rule["on"]) != kind or str(rule["source_definition_id"]) != definition_id:
			continue
		if rule.has("source_actor_id") and str(rule["source_actor_id"]) != actor_id:
			continue
		var move: Dictionary = Zones.move(next_state, str(rule["actor_id"]),
			str(rule["instance_id"]), str(rule["from_zone"]), str(rule["to_zone"]))
		if not move["accepted"]:
			# A previous legal trigger may have moved its target already.
			# Keep earlier effects; never resurrect / duplicate that card.
			var skipped: Dictionary = Zones.emit(next_state, "CardTriggerSkipped", actor_id,
				{"effect_id": str(rule["effect_id"]), "source_event_seq": int(source_event["event_seq"]),
				"reason": str(move["error"])})
			emitted.append(skipped)
			continue
		next_state = move["state"]
		emitted.append_array(move["events"])
		var resolved: Dictionary = Zones.emit(next_state, "CardTriggerResolved", actor_id,
			{"effect_id": str(rule["effect_id"]), "source_event_seq": int(source_event["event_seq"]),
			"target_instance_id": str(rule["instance_id"])})
		emitted.append(resolved)
	if not Zones.validate_state(next_state):
		return Zones.rejected(state, "TRIGGER_ZONE_CONSERVATION")
	return Zones.accepted(next_state, emitted)
