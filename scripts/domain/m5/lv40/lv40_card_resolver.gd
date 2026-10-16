extends RefCounted
## A paid content action extension, not a second phase/state/RNG engine.
const M2 = preload("res://scripts/domain/m2/integration/m2_domain_resolver.gd")
const M4 = preload("res://scripts/domain/m4/integration/m4_domain_resolver.gd")
const Zones = preload("res://scripts/domain/m2/cards/card_zone_resolver.gd")
const Tactical = preload("res://scripts/domain/m5/combo/tactical_sp_resolver.gd")
const Damage = preload("res://scripts/domain/m5/damage/damage_pipeline_resolver.gd")
const Effects = preload("res://scripts/domain/m5/lv40/lv40_effects.gd")
const Boss = preload("res://scripts/domain/m5/lv40/lv40_boss.gd")
const Focus = preload("res://scripts/domain/m4/casting/focus_ward_resolver.gd")
const Status = preload("res://scripts/domain/m5/status/status_resolver.gd")

static func _error(error: String) -> Dictionary:
	return {"ok":false,"error":error}

static func _hit(records: Array, hp_only: bool = false) -> bool:
	for record: Dictionary in records:
		if str(record.get("kind","")) == "DamageTrace" and bool(record.get("hit",false)):
			if not hp_only or int(record.get("hp_damage",0)) > 0:
				return true
	return false

static func _merge(result: Dictionary, core: Dictionary, timeline: Array) -> Dictionary:
	if result.get("ok",false):
		timeline.append_array(result["timeline"])
		return result["core"]
	return core

static func play(state: Dictionary, command: Dictionary, config: Dictionary) -> Dictionary:
	var core: Dictionary = state["core"]
	var actor: String = str(command.get("actor_id",""))
	var target: String = str(command.get("target_actor_id",""))
	var card: String = str(command.get("card_instance_id",""))
	var id: String = str(command.get("command_id",""))
	var mode: String = str(command.get("casting_mode",""))
	var combo: String = str(command.get("combo_mode","NORMAL"))
	if state["phase"] != "PLAYER_PHASE" or not core["battle"]["allies"].has(actor):
		return _error("LV40_INVALID_PHASE_OR_ACTOR")
	if int(core["battle"]["actors"][actor]["hp"]) <= 0 or str(core["battle"]["actors"][actor]["status"]) != "ACTIVE":
		return _error("LV40_ACTOR_UNAVAILABLE")
	if Zones.location(core["cards"],actor,card) != "hand":
		return _error("LV40_CARD_NOT_IN_OWN_HAND")
	var definition: String = str(core["cards"]["actors"][actor]["instances"][card]["definition_id"])
	if not config["lv40_cards"].has(definition):
		return _error("LV40_UNREGISTERED_CARD")
	var content: Dictionary = config["lv40_cards"][definition]
	if not ["*",actor].has(str(content["owner"])):
		return _error("LV40_INELIGIBLE_OWNER")
	if not ["NORMAL","COMBO"].has(combo):
		return _error("LV40_INVALID_COMBO_MODE")
	if str(content["kind"]) == "REACTION":
		return _error("LV40_REACTION_WINDOW_REQUIRED")
	if str(content["mode"]) == "DUAL":
		if not ["CHANTLESS","FULL"].has(mode):
			return _error("LV40_INVALID_CASTING_MODE")
	elif not ["INSTANT","CHANTLESS"].has(mode):
		return _error("LV40_INSTANT_CARD_MODE_REQUIRED")
	var enemy: bool = ["MAGIC","PHYSICAL"].has(str(content["kind"])) or definition == "A05"
	var team: Array = core["battle"]["enemies"] if enemy else core["battle"]["allies"]
	if not team.has(target) or int(core["battle"]["actors"][target]["hp"]) <= 0 or \
			str(core["battle"]["actors"][target]["status"]) == "EXHAUSTED":
		return _error("LV40_ILLEGAL_TARGET")
	if ["A03"].has(definition) and target != actor:
		return _error("LV40_SELF_TARGET_REQUIRED")
	if ["U05","T01"].has(definition) and int(core["battle"]["actors"][target]["hp"]) == int(core["battle"]["actors"][target]["max_hp"]):
		return _error("LV40_NO_MISSING_HP")
	if definition == "U04" and int(core["battle"]["actors"][target]["mp"]) == int(core["battle"]["actors"][target]["max_mp"]):
		return _error("LV40_NO_MISSING_MP")
	if definition == "U03" and Effects.casting_id(core,target).is_empty():
		return _error("LV40_NO_ALLY_CASTING_INSTANCE")
	if definition == "A05" and (core["battle"]["lv40"]["pending_cast"].is_empty() or bool(core["battle"]["lv40"]["pending_cast"].get("interrupted",false))):
		return _error("LV40_NO_ENEMY_CASTING_INSTANCE")
	if definition == "T03":
		var missing: bool = false
		for ally: String in core["battle"]["allies"]:
			var a: Dictionary = core["battle"]["actors"][ally]
			missing = missing or (int(a["hp"]) > 0 and int(a["hp"]) < int(a["max_hp"]))
		if not missing:
			return _error("LV40_NO_MISSING_HP")
	var next: Dictionary = core.duplicate(true)
	var records: Array = []
	var result: Dictionary
	var trusted: Dictionary = config.duplicate(true)
	if content["kind"] == "MAGIC":
		if combo == "COMBO":
			var exposed: Dictionary = next["battle"]["m53"]["exposed"]
			var offered: Dictionary = next["battle"]["m53"]["combo"]
			if definition != "A06" or mode != "CHANTLESS" or exposed.is_empty() or offered.is_empty() or str(offered.get("source_actor_id","")) == actor or str(offered.get("target_id","")) != target:
				return _error("LV40_COMBO_NOT_ELIGIBLE")
		var p: Dictionary = content["chantless_profile"].duplicate(true)
		if combo == "COMBO":
			p["skill_multiplier_bp"] = int(int(p["skill_multiplier_bp"])*120/100)
		var power: Dictionary = next["battle"]["lv40"]["spell_power"].get(actor,{})
		if not power.is_empty():
			p["skill_multiplier_bp"] = int(int(p["skill_multiplier_bp"])*120/100)
		trusted["m5_spell_profiles"][definition] = p
		var instruction: Dictionary = command.duplicate(true)
		instruction["type"] = "CAST_SPELL_M4"
		instruction["casting_mode"] = "CHANTLESS" if mode == "INSTANT" else mode
		result = M4.apply(state,instruction,trusted)
		if not result["accepted"]:
			return _error(str(result["error"]))
		next = result["state"]["core"]
		# M4 supplies the real payment, scheduled instance and event order.
		for e: Dictionary in result["events"]:
			if e["kind"] != "BattleOutcomeEvaluated" and e["kind"] != "PlayerActionSettled":
				var raw: Dictionary = e["details"].duplicate(true)
				raw["kind"] = e["kind"]
				records.append(raw)
		if mode == "FULL":
			var cast_id: String = Effects.casting_id(next,actor)
			next["battle"]["casting_instances"][cast_id]["lv40_power_bp"] = 12000 if not power.is_empty() else 10000
			next["battle"]["lv40"]["spell_power"].erase(actor)
		else:
			if _hit(records):
				next["battle"]["lv40"]["spell_power"].erase(actor)
				if definition == "A07":
					if int(next["battle"]["actors"][target]["hp"]) > 0:
						var scorch: Dictionary = Status.grant(next,actor,target,"SCORCH_TEST",id,config)
						if not scorch["ok"]:
							return scorch
						next = _merge(scorch,next,records)
			if definition == "T10" and _hit(records,true):
				var lowest: String = _lowest_ratio(next)
				if not lowest.is_empty():
					next = _merge(Effects.heal(next,lowest,80),next,records)
			if ["A04","A06"].has(definition) and _hit(records) and not next["battle"]["m53"]["exposed"].is_empty():
				next["battle"]["m53"]["exposed"] = {}
				records.append({"kind":"ExposedConsumed","target_id":target,"consumed_command_id":id,"whole_sp":true})
			if combo == "COMBO" and _hit(records):
				next["battle"]["m53"]["combo"] = {}
				records.append({"kind":"ComboExecuted","finisher_actor_id":actor,"target_id":target,"extra_ap":0,"second_card_paid":true})
	elif content["kind"] == "PHYSICAL":
		var effect: Dictionary = trusted["m5_3_sp_effects"][definition]
		effect["create_exposed"] = ["R01","R07"].has(definition) and bool(next["battle"]["lv40"]["core_open"])
		if effect["create_exposed"]:
			effect["creates_combo_tags"] = ["FIRE"]
		var existing: Dictionary = next["battle"]["m53"]["exposed"]
		if definition == "R03" and not existing.is_empty():
			effect["consume_exposed"] = true
			effect["damage_profile"]["skill_multiplier_bp"] = 14375
		if combo == "COMBO":
			return _error("LV40_NO_REGISTERED_PHYSICAL_COMBO_RECIPE")
		var instruction: Dictionary = command.duplicate(true)
		instruction["casting_mode"] = "CHANTLESS"
		result = Tactical.resolve(state,instruction,trusted)
		if not result["ok"]:
			return result
		next = result["core"]
		records.append_array(result["timeline"])
		var round_id: int = int(next["battle"]["round"])
		if int(effect["break_damage"]) > 0 and not bool(core["battle"]["m53"]["break_locked"]) and bool(result["successful_hit"]) and int(next["battle"]["lv40"]["ren_passive_round"]) != round_id:
			next["battle"]["lv40"]["ren_passive_round"] = round_id
			records.append({"kind":"PassiveTriggered","actor_id":actor,"passive_id":"REN_P01","break_bonus":2})
			next = _merge(Effects.break_damage(next,2,card),next,records)
	else:
		if combo == "COMBO" and definition != "T04":
			return _error("LV40_NO_REGISTERED_SUPPORT_COMBO_RECIPE")
		if combo == "COMBO" and (next["battle"]["lv40"]["defense_combo"].is_empty() or int(next["battle"]["lv40"]["defense_combo"].get("expires_round",0)) < int(next["battle"]["round"])):
			return _error("LV40_DEFENSE_COMBO_NOT_ELIGIBLE")
		result = M2.apply(next,{"type":"COMMIT_SP_CARD_FIXTURE","command_id":id,
			"expected_event_seq":int(next["event_seq"]),"actor_id":actor,
			"card_instance_id":card,"casting_mode":"CHANTLESS"},config)
		if not result["accepted"]:
			return _error(str(result["error"]))
		next = result["state"]
		for e: Dictionary in result["events"]:
			records.append({"kind":"core_event","raw":e})
		match definition:
			"U02","T04","R08":
				var amount: int = {"U02":140,"T04":190,"R08":90}[definition]
				if combo == "COMBO":
					amount += 75
					next["battle"]["lv40"]["defense_combo"] = {}
					records.append({"kind":"ComboExecuted","finisher_actor_id":actor,"extra_ap":0,"second_card_paid":true})
				next = _merge(Effects.barrier(next,target,amount,int(next["battle"]["round"])),next,records)
				if definition == "R08":
					if target == actor:
						return _error("LV40_OTHER_ALLY_REQUIRED")
					next = _merge(Effects.barrier(next,actor,90,int(next["battle"]["round"])),next,records)
					next["battle"]["lv40"]["defense_combo"] = {"source_actor_id":actor,"expires_round":int(next["battle"]["round"])+1}
			"U05","T01","T03","T06":
				var amount: int = {"U05":150,"T01":200,"T03":140,"T06":380}[definition]
				if actor == "C" and int(next["battle"]["lv40"]["tsumugi_passive_round"]) != int(next["battle"]["round"]):
					amount += 60
					next["battle"]["lv40"]["tsumugi_passive_round"] = int(next["battle"]["round"])
					records.append({"kind":"PassiveTriggered","actor_id":actor,"passive_id":"TSUMUGI_P01","heal_bonus":60})
				var targets: Array = next["battle"]["allies"] if definition == "T03" else [target]
				for ally: String in targets:
					if int(next["battle"]["actors"][ally]["hp"]) > 0:
						next = _merge(Effects.heal(next,ally,amount),next,records)
				if definition == "T06":
					next = _merge(Effects.barrier(next,target,100,int(next["battle"]["round"])),next,records)
			"U04":
				var restored: Dictionary = M2.apply(next,{"type":"RECOVER_CASTING_INTERRUPT_MP_M4",
					"command_id":id+":mp","expected_event_seq":int(next["event_seq"]),"actor_id":target,"amount":3},config)
				if not restored["accepted"]:
					return _error(str(restored["error"]))
				next = restored["state"]
				for e: Dictionary in restored["events"]:
					records.append({"kind":"core_event","raw":e})
			"U03":
				var cast_id: String = Effects.casting_id(next,target)
				var ward: Dictionary = Focus.grant(next["battle"]["casting_instances"][cast_id],8)
				if not ward["ok"]:
					return ward
				next["battle"]["casting_instances"][cast_id] = ward["instance"]
				records.append({"kind":"FocusWardGranted","casting_id":cast_id,"amount":8,"before":ward["before"],"after":ward["after"]})
			"A05":
				result = Boss.interrupt(next,9,id)
				if not result["ok"]:
					return result
				next = _merge(result,next,records)
			"A03":
				next["battle"]["lv40"]["spell_power"][actor] = {"expires_round":int(next["battle"]["round"])+1}
				records.append({"kind":"SpellPowerGranted","actor_id":actor,"multiplier_bp":12000})
			_:
				return _error("LV40_EFFECT_NOT_IMPLEMENTED")
	return {"ok":true,"core":next,"timeline":records,"card_definition_id":definition}

static func _lowest_ratio(core: Dictionary) -> String:
	var lowest: String = ""
	for actor: String in core["battle"]["allies"]:
		var a: Dictionary = core["battle"]["actors"][actor]
		if int(a["hp"]) <= 0:
			continue
		if lowest.is_empty():
			lowest = actor
		else:
			var b: Dictionary = core["battle"]["actors"][lowest]
			if int(a["hp"])*int(b["max_hp"]) < int(b["hp"])*int(a["max_hp"]):
				lowest = actor
	return lowest
