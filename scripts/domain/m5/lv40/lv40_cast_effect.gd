extends RefCounted
## Effect extension at M4's existing sorted release boundary.
const M2 = preload("res://scripts/domain/m2/integration/m2_domain_resolver.gd")
const Last = preload("res://scripts/domain/m4/last_spell/last_spell_resolver.gd")
const Damage = preload("res://scripts/domain/m5/damage/damage_pipeline_resolver.gd")
const Effects = preload("res://scripts/domain/m5/lv40/lv40_effects.gd")
const LastTargets = preload("res://scripts/domain/m5/lv40/last_spell_targeting.gd")

static func settle(core: Dictionary, cast: Dictionary, round_id: int,
		config: Dictionary, command_id: String) -> Dictionary:
	var next: Dictionary = core.duplicate(true)
	var actor: String = str(cast["caster_id"])
	var target: String = str(cast["target_snapshot"]["actor_id"])
	var spell: String = str(cast["spell_id"])
	var records: Array = []
	var is_last: bool = str(cast.get("kind","")) == "LAST_SPELL"
	var retire_after_effect: bool = is_last and bool(config.get("last_spell_retirement_v1", false))
	var exhaustion: Dictionary = {}
	if int(next["battle"]["actors"][actor]["hp"]) <= 0:
		return {"ok":false,"error":"LV40_CASTER_HP0_RELEASE_FORBIDDEN"}
	if is_last:
		var release_cast: Dictionary = cast.duplicate(true)
		var current_targets: Array[String] = []
		for candidate: String in LastTargets.recipients(next, actor, target, config):
			current_targets.append(candidate)
		var target_definition: Dictionary = LastTargets.definition(config, actor)
		if target_definition.get("scope", "") == "ALL" and not target_definition.get("legacy", false) and not current_targets.is_empty():
			# An AoE anchor is a command compatibility field, not a selected victim.
			# A dead anchor must not prevent release on the other living recipients.
			release_cast["target_snapshot"]["actor_id"] = current_targets[0]
		var settled: Dictionary = Last.settle(next,release_cast,round_id)
		if not settled["ok"]:
			return settled
		next = settled["core"]
		records.append(settled["timeline"][0])
		exhaustion = settled["timeline"][2].duplicate(true)
		if not retire_after_effect:
			records.append(exhaustion)
	else:
		var moved: Dictionary = M2.apply(next,{"type":"SETTLE_CASTING_CARD_M4",
			"actor_id":actor,"card_instance_id":str(cast["card_instance_id"]),
			"command_id":command_id+":"+str(cast["casting_id"]),
			"expected_event_seq":int(next["event_seq"])},config)
		if not moved["accepted"]:
			return {"ok":false,"error":moved["error"]}
		next = moved["state"]
		for e: Dictionary in moved["events"]:
			records.append({"kind":"core_event","raw":e})
		next["battle"]["casting_instances"].erase(str(cast["casting_id"]))
		next["battle"]["actors"][actor]["status"] = "ACTIVE"
		records.append({"kind":"CastingReleased","casting_id":cast["casting_id"],"caster_id":actor,
			"card_instance_id":cast["card_instance_id"],"cost_repaid":false,"planned_round":round_id})
	var numerator: int = int(cast.get("outcome_modifier_numerator",1))
	var denominator: int = int(cast.get("outcome_modifier_denominator",1))
	var recipients: Array[String] = []
	if is_last:
		for candidate: String in LastTargets.recipients(next, actor, target, config):
			recipients.append(candidate)
	else:
		recipients.append(target)
	if not is_last and bool(next["battle"].get("retired_from_field_by_actor", {}).get(target, false)):
		records.append({"kind":"CastingEffectFizzled", "casting_id":cast["casting_id"], "reason":"TARGET_RETIRED_FROM_FIELD"})
		return {"ok":true,"core":next,"timeline":records}
	var last_effect: Dictionary = config.get("last_spell_effects", {}).get(spell, {}) if is_last else {}
	if is_last and str(last_effect.get("kind","")) == "HEAL_BARRIER":
		for ally: String in recipients:
			if int(next["battle"]["actors"][ally]["hp"]) <= 0:
				continue
			var amount: int = int(int(next["battle"]["actors"][ally]["max_hp"])*int(last_effect["heal_max_hp_bp"])*numerator/(10000*denominator))
			var healed: Dictionary = Effects.heal(next,ally,amount)
			if not healed["ok"]:
				return healed
			next = healed["core"]
			records.append_array(healed["timeline"])
			var shield: Dictionary = Effects.barrier(next,ally,int(int(last_effect["barrier_amount"])*numerator/denominator),round_id)
			next = shield["core"]
			records.append_array(shield["timeline"])
	else:
		var p: Dictionary = config["m5_spell_profiles"][spell].duplicate(true) if is_last else config["lv40_cards"][spell]["full_profile"].duplicate(true)
		p["skill_multiplier_bp"] = int(int(p["skill_multiplier_bp"])*numerator/denominator)
		if not is_last:
			p["skill_multiplier_bp"] = int(int(p["skill_multiplier_bp"])*int(cast.get("lv40_power_bp",10000))/10000)
			var full_passive: Dictionary = config.get("lv40_full_chant_passives", {}).get(actor, {})
			if str(full_passive.get("kind", "")) == "FULL_CHANT_HP_MULTIPLIER":
				var bonus_bp: int = int(full_passive["multiplier_bp"])
				p["skill_multiplier_bp"] = int(int(p["skill_multiplier_bp"])*bonus_bp/10000)
				records.append({"kind":"PassiveTriggered","actor_id":actor,
					"passive_id":str(full_passive["id"]),"multiplier_bp":bonus_bp})
		for recipient: String in recipients:
			var hit: Dictionary = Damage.resolve(next,actor,recipient,p,{},config,command_id)
			if not hit["ok"]:
				return hit
			next = hit["core"]
			records.append_array(hit["timeline"])
			if is_last and int(last_effect.get("break_on_hit",0)) > 0:
				for trace: Dictionary in hit["timeline"]:
					if str(trace.get("kind","")) == "DamageTrace" and bool(trace.get("hit",false)):
						var broken: Dictionary = Effects.break_damage(next,int(last_effect["break_on_hit"]),str(cast["casting_id"]))
						next = broken["core"]
						records.append_array(broken["timeline"])
						break
	if retire_after_effect:
		# A support Last Spell completes its effects before its caster leaves.
		# Outcome is evaluated by the existing phase/action boundary afterwards.
		next = Last.mark_retired(next, actor)
		exhaustion["still_targetable"] = false
		exhaustion["retired_from_field"] = true
		records.append(exhaustion)
	return {"ok":true,"core":next,"timeline":records}
