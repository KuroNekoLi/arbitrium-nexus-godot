extends RefCounted
## M4.1 due Full Chant release at start of NEXT Player Phase.
## Runs BEFORE M3 outcome, AP renewal, swap reset and draw-to-four.
const Instance = preload("res://scripts/domain/m4/casting/casting_instance_resolver.gd")
const M2 = preload("res://scripts/domain/m2/integration/m2_domain_resolver.gd")
const Zones = preload("res://scripts/domain/m2/cards/card_zone_resolver.gd")

static func _before(a: Dictionary, b: Dictionary) -> bool:
	if int(a["planned_resolve_round"]) != int(b["planned_resolve_round"]):
		return int(a["planned_resolve_round"]) < int(b["planned_resolve_round"])
	if int(a["started_round"]) != int(b["started_round"]):
		return int(a["started_round"]) < int(b["started_round"])
	return str(a["casting_id"]) < str(b["casting_id"])

static func settle_due(core: Dictionary, next_round: int,
		config: Dictionary, command_id: String) -> Dictionary:
	var source: Dictionary = core.duplicate(true)
	if not Instance.valid(source):
		return {"ok": false, "error": "INVALID_CASTING_INSTANCES"}
	var due: Array[Dictionary] = []
	for value: Variant in source["battle"]["casting_instances"].values():
		var cast: Dictionary = value
		if int(cast["planned_resolve_round"]) < next_round:
			return {"ok": false, "error": "MISSED_CASTING_RELEASE"}
		if int(cast["planned_resolve_round"]) == next_round:
			due.append(cast.duplicate(true))
	due.sort_custom(_before)
	var timeline: Array = []
	for cast: Dictionary in due:
		var actor: String = str(cast["caster_id"])
		var card: String = str(cast["card_instance_id"])
		var id: String = str(cast["casting_id"])
		var target: String = str(cast["target_snapshot"]["actor_id"])
		if int(source["battle"]["actors"][actor]["hp"]) <= 0:
			return {"ok": false, "error": "CASTER_HP0_NEEDS_M4_4_INVALIDATION"}
		# Target death/retarget semantics were NOT approved. Fail closed:
		# no card movement, MP refund, or fictitious effect.
		if not source["battle"]["actors"].has(target) or int(source["battle"]["actors"][target]["hp"]) <= 0:
			return {"ok": false, "error": "RELEASE_TARGET_TBD"}
		if Zones.location(source["cards"], actor, card) != "casting":
			return {"ok": false, "error": "CAST_ZONE_MISMATCH"}
		var settled: Dictionary = M2.apply(source, {
			"type": "SETTLE_CASTING_CARD_M4",
			"actor_id": actor, "card_instance_id": card,
			"command_id": command_id + ":" + id,
			"expected_event_seq": int(source["event_seq"])
		}, config)
		if not settled["accepted"]:
			return {"ok": false, "error": str(settled["error"])}
		source = settled["state"]
		for item: Dictionary in settled["events"]:
			timeline.append({"kind": "core_event", "raw": item})
		source["battle"]["casting_instances"].erase(id)
		source["battle"]["actors"][actor]["status"] = "ACTIVE"
		timeline.append({"kind": "CastingReleased", "casting_id": id,
			"caster_id": actor, "card_instance_id": card,
			"planned_round": next_round, "cost_repaid": false,
			"concentration_cleared": true})
		timeline.append({"kind": "SpellEffectDeferredToM5", "casting_id": id,
			"spell_id": cast["spell_id"], "mode": "FULL",
			"target_snapshot": cast["target_snapshot"].duplicate(true),
			"effect_execution": "NOT_IMPLEMENTED_M5", "hp_delta": 0})
	return {"ok": true, "error": "", "core": source, "timeline": timeline,
		"resolved_count": due.size()}
