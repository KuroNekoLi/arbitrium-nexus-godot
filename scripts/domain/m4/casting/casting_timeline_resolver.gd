extends RefCounted
## M4.1 due Full Chant release at start of NEXT Player Phase.
## Runs BEFORE M3 outcome, AP renewal, swap reset and draw-to-four.
const Instance = preload("res://scripts/domain/m4/casting/casting_instance_resolver.gd")
const M2 = preload("res://scripts/domain/m2/integration/m2_domain_resolver.gd")
const Zones = preload("res://scripts/domain/m2/cards/card_zone_resolver.gd")
const LastSpell = preload("res://scripts/domain/m4/last_spell/last_spell_resolver.gd")
const Damage = preload("res://scripts/domain/m5/damage/damage_pipeline_resolver.gd")
const HP = preload("res://scripts/domain/m5/status/hp_lifecycle_bridge.gd")

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
		if str(cast.get("kind","")) == "LAST_SPELL":
			var last_release: Dictionary = LastSpell.settle(source,cast,next_round)
			if not last_release["ok"]:
				return {"ok":false,"error":str(last_release["error"])}
			source = last_release["core"]
			if config.get("m5_damage_enabled",false) == true:
				var last_profile: Variant = config.get("m5_spell_profiles",{}).get(str(cast["spell_id"]),null)
				if not last_profile is Dictionary:
					return {"ok":false,"error":"M51_MISSING_LAST_EFFECT"}
				var last_hit: Dictionary = Damage.resolve(source,str(cast["caster_id"]),
					str(cast["target_snapshot"]["actor_id"]),last_profile,{},config,command_id)
				if not last_hit["ok"]:
					return {"ok":false,"error":str(last_hit["error"])}
				timeline.append(last_release["timeline"][0])
				if config.get("m5_4_outcome_enabled",false) == true:
					# Release is committed before any later HP0; Exhausted
					# is already lifetime-sticky and cannot be rolled back.
					timeline.append(last_release["timeline"][2])
				source = last_hit["core"]
				timeline.append_array(last_hit["timeline"])
				if config.get("m5_4_outcome_enabled",false) == true:
					var recoil_table: Variant = config.get("m5_4_last_release_recoil",{})
					if not recoil_table is Dictionary:
						return {"ok":false,"error":"M54_INVALID_LAST_RECOIL_CATALOGUE"}
					var recoil_spec: Variant = recoil_table.get(str(cast["spell_id"]),null)
					if recoil_spec != null:
						if not recoil_spec is Dictionary or not recoil_spec.get("amount",null) is int or \
								int(recoil_spec["amount"]) <= 0 or \
								not ["ABSORB","BYPASS"].has(str(recoil_spec.get("barrier_mode",""))):
							return {"ok":false,"error":"M54_INVALID_LAST_RECOIL_PROFILE"}
						var recoil: Dictionary = HP.registered_recoil(source,str(cast["caster_id"]),
							int(recoil_spec["amount"]),str(recoil_spec["barrier_mode"]),config,
							command_id+":last-recoil")
						if not recoil["ok"]:
							return {"ok":false,"error":str(recoil["error"])}
						source = recoil["core"]
						timeline.append_array(recoil["timeline"])
				else:
					timeline.append(last_release["timeline"][2])
			else:
				timeline.append_array(last_release["timeline"])
			continue
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
		if config.get("m5_damage_enabled",false) == true:
			var spell_profile: Variant = config.get("m5_spell_profiles",{}).get(str(cast["spell_id"]),null)
			if not spell_profile is Dictionary:
				return {"ok":false,"error":"M51_MISSING_SPELL_EFFECT"}
			var hit: Dictionary = Damage.resolve(source,actor,target,spell_profile,{},config,command_id)
			if not hit["ok"]:
				return {"ok":false,"error":str(hit["error"])}
			source = hit["core"]
			timeline.append_array(hit["timeline"])
		else:
			timeline.append({"kind": "SpellEffectDeferredToM5", "casting_id": id,
				"spell_id": cast["spell_id"], "mode": "FULL",
				"target_snapshot": cast["target_snapshot"].duplicate(true),
				"effect_execution": "NOT_IMPLEMENTED_M5", "hp_delta": 0})
	return {"ok": true, "error": "", "core": source, "timeline": timeline,
		"resolved_count": due.size()}
