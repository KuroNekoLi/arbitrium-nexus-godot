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
	if int(next["battle"]["actors"][actor]["hp"]) <= 0:
		return {"ok":false,"error":"LV40_CASTER_HP0_RELEASE_FORBIDDEN"}
	if is_last:
		var release_cast: Dictionary = cast.duplicate(true)
		var current_targets: Array[String] = LastTargets.recipients(next, actor, target, config)
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
		records.append(settled["timeline"][2])
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
	var recipients: Array[String] = LastTargets.recipients(next, actor, target, config) if is_last else [target]
	if spell == "LS_TSUMUGI_HEAL_V1":
		for ally: String in recipients:
			if int(next["battle"]["actors"][ally]["hp"]) <= 0:
				continue
			var amount: int = int(int(next["battle"]["actors"][ally]["max_hp"])*35*numerator/(100*denominator))
			var healed: Dictionary = Effects.heal(next,ally,amount)
			if not healed["ok"]:
				return healed
			next = healed["core"]
			records.append_array(healed["timeline"])
			var shield: Dictionary = Effects.barrier(next,ally,int(260*numerator/denominator),round_id)
			next = shield["core"]
			records.append_array(shield["timeline"])
	else:
		var p: Dictionary = config["m5_spell_profiles"][spell].duplicate(true) if is_last else config["lv40_cards"][spell]["full_profile"].duplicate(true)
		p["skill_multiplier_bp"] = int(int(p["skill_multiplier_bp"])*numerator/denominator)
		if not is_last:
			p["skill_multiplier_bp"] = int(int(p["skill_multiplier_bp"])*int(cast.get("lv40_power_bp",10000))/10000)
			if actor == "B":
				p["skill_multiplier_bp"] = int(int(p["skill_multiplier_bp"])*110/100)
				records.append({"kind":"PassiveTriggered","actor_id":actor,"passive_id":"AKANE_P01","multiplier_bp":11000})
		for recipient: String in recipients:
			var hit: Dictionary = Damage.resolve(next,actor,recipient,p,{},config,command_id)
			if not hit["ok"]:
				return hit
			next = hit["core"]
			records.append_array(hit["timeline"])
			if spell == "LS_REN_SWORD_V1":
				for trace: Dictionary in hit["timeline"]:
					if str(trace.get("kind","")) == "DamageTrace" and bool(trace.get("hit",false)):
						var broken: Dictionary = Effects.break_damage(next,24,str(cast["casting_id"]))
						next = broken["core"]
						records.append_array(broken["timeline"])
						break
	return {"ok":true,"core":next,"timeline":records}
