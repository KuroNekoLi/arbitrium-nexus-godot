extends RefCounted
## M5.3: one truly M2-paid SP -> M5.1 damage -> whole-SP tactical effects.
## Data is BALANCE_PROVISIONAL, not an approved card or Boss balance.
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const M2 = preload("res://scripts/domain/m2/integration/m2_domain_resolver.gd")
const Zones = preload("res://scripts/domain/m2/cards/card_zone_resolver.gd")
const Damage = preload("res://scripts/domain/m5/damage/damage_pipeline_resolver.gd")
const Boss = preload("res://scripts/domain/m5/boss/boss_ai_policy.gd")
const HP = preload("res://scripts/domain/m5/status/hp_lifecycle_bridge.gd")
const BreakC = preload("res://scripts/domain/m5/boss/break_c_policy.gd")

static func _error(code: String) -> Dictionary:
	return {"ok":false,"error":code,"core":{},"timeline":[]}

static func _can_consume_exposed(exposed: Dictionary, target: String,
		command_id: String, round_id: int) -> bool:
	return not exposed.is_empty() and str(exposed.get("target_id","")) == target 		and str(exposed.get("created_command_id","")) != command_id 		and int(exposed.get("expires_round",-1)) >= round_id

static func _hits(timeline: Array) -> bool:
	for value: Dictionary in timeline:
		if str(value.get("kind","")) == "DamageTrace" and bool(value.get("hit",false)):
			return true
	return false

static func resolve(original: Dictionary, command: Dictionary,
		config: Dictionary) -> Dictionary:
	var id: String = str(command.get("command_id",""))
	var actor: String = str(command.get("actor_id",""))
	var target: String = str(command.get("target_actor_id",""))
	var card: String = str(command.get("card_instance_id",""))
	var mode: String = str(command.get("combo_mode","NORMAL"))
	if not ["NORMAL","COMBO"].has(mode):
		return _error("M53_INVALID_COMBO_MODE")
	if str(command.get("casting_mode","CHANTLESS")) != "CHANTLESS":
		return _error("M53_UNSUPPORTED_FULL_CHANT_TACTICAL")
	if actor.is_empty() or target.is_empty() or card.is_empty() or id.is_empty():
		return _error("M53_MISSING_COMMAND_FIELDS")
	var core: Dictionary = original["core"]
	var battle: Dictionary = core["battle"]
	if not battle["allies"].has(actor) or not battle["enemies"].has(target):
		return _error("M53_INVALID_TARGET_TEAM")
	if not battle["actors"].has(actor) or not battle["actors"].has(target) or 			int(battle["actors"][target]["hp"]) <= 0 or 			int(battle["actors"][actor]["hp"]) <= 0 or 			str(battle["actors"][actor]["status"]) != "ACTIVE":
		return _error("M53_TARGET_OR_CASTER_UNAVAILABLE")
	if Zones.location(core["cards"],actor,card) != "hand":
		return _error("M53_CARD_NOT_OWNED_IN_HAND")
	var definition: String = str(core["cards"]["actors"][actor]["instances"][card]["definition_id"])
	var catalogue: Variant = config.get("m5_3_sp_effects",null)
	if not catalogue is Dictionary or not catalogue.has(definition) 			or not catalogue[definition] is Dictionary:
		return _error("M53_UNREGISTERED_TACTICAL_SP")
	var effect: Dictionary = catalogue[definition]
	if not effect.get("damage_profile",null) is Dictionary or 			not effect.get("break_damage",null) is int:
		return _error("M53_INVALID_TACTICAL_CONTENT")
	if int(effect["break_damage"]) < 0:
		return _error("M53_INVALID_BREAK_DAMAGE")
	# Recoil is trusted versioned ContentConfig, never a user-supplied
	# HP modification. Reject bad fixture data BEFORE M2 reserves cost.
	if config.get("m5_4_outcome_enabled",false) == true and effect.has("recoil_hp"):
		if not effect["recoil_hp"] is int or int(effect["recoil_hp"]) <= 0 or \
				not ["ABSORB","BYPASS"].has(str(effect.get("recoil_barrier_mode",""))):
			return _error("M54_INVALID_RECOIL_PROFILE")
	var prepared: Dictionary = Boss.ensure(core,config)
	if not prepared["ok"]:
		return _error(str(prepared["error"]))
	var next: Dictionary = prepared["core"]
	var tactical: Dictionary = next["battle"]["m53"]
	var previous_exposed: Dictionary = tactical["exposed"].duplicate(true)
	var offered: Dictionary = tactical["combo"].duplicate(true)
	var round_id: int = int(next["battle"]["round"])
	var valid_exposed: bool = _can_consume_exposed(previous_exposed,target,id,round_id)
	var using_exposed: bool = bool(effect.get("consume_exposed",false)) and valid_exposed
	if mode == "COMBO":
		if offered.is_empty() or 				str(offered.get("source_actor_id","")) == actor or 				str(offered.get("target_id","")) != target or 				str(offered.get("source_command_id","")) == id or 				int(offered.get("expires_round",-1)) < round_id:
			return _error("M53_COMBO_OPPORTUNITY_NOT_ELIGIBLE")
		var offered_tags: Variant = offered.get("finisher_tags",[])
		var card_tags: Variant = effect.get("tags",[])
		if not offered_tags is Array or not card_tags is Array:
			return _error("M53_INVALID_COMBO_TAGS")
		var tag_match: bool = false
		for value: Variant in card_tags:
			if offered_tags.has(value):
				tag_match = true
				break
		if not tag_match or not effect.get("combo_bonus_profile",null) is Dictionary:
			return _error("M53_COMBO_CARD_NOT_ELIGIBLE")
	# No transaction succeeds unless the actual owner pays the real M2 costs
	# and this exact CardInstance leaves hand for discard.
	var payment: Dictionary = M2.apply(next,{
		"type":"COMMIT_SP_CARD_FIXTURE","command_id":id,
		"expected_event_seq":int(next["event_seq"]),
		"actor_id":actor,"card_instance_id":card,"casting_mode":"CHANTLESS"
	},config)
	if not payment["accepted"]:
		return _error(str(payment["error"]))
	next = payment["state"]
	var timeline: Array = []
	for wrapped: Dictionary in payment["events"]:
		timeline.append({"kind":"core_event","raw":wrapped,"proven_payment":true})
	var dealt: Dictionary = Damage.resolve(next,actor,target,effect["damage_profile"],
		{},config,id)
	if not dealt["ok"]:
		return _error(str(dealt["error"]))
	next = dealt["core"]
	timeline.append_array(dealt["timeline"])
	var success: bool = _hits(dealt["timeline"])
	tactical = next["battle"]["m53"]
	var break_amount: int = int(effect["break_damage"]) if success else 0
	# Bonus damage is a separate *guaranteed* payload, only after the actual
	# eligible finisher hit. It never performs an extra hit RNG roll.
	if mode == "COMBO" and success:
		if int(next["battle"]["actors"][target]["hp"]) > 0:
			var bonus_profile: Dictionary = effect["combo_bonus_profile"]
			if str(bonus_profile.get("hit_mode","")) != "GUARANTEED":
				return _error("M53_COMBO_BONUS_MUST_BE_GUARANTEED")
			var bonus: Dictionary = Damage.resolve(next,actor,target,bonus_profile,{},config,id+":combo")
			if not bonus["ok"]:
				return _error(str(bonus["error"]))
			next = bonus["core"]
			timeline.append_array(bonus["timeline"])
		tactical = next["battle"]["m53"]
		tactical["combo"] = {}
		break_amount += int(effect.get("combo_bonus_break",0))
		timeline.append({"kind":"ComboExecuted","source_actor_id":offered["source_actor_id"],
			"finisher_actor_id":actor,"target_id":target,"card_instance_id":card,
			"source_card_instance_id":offered["source_card_instance_id"],
			"extra_ap":0,"second_card_paid":true})
	elif mode == "COMBO":
		timeline.append({"kind":"ComboFinisherMissed","target_id":target,
			"opportunity_preserved":true})
	# P2-D15 / CORE-01: a single legal card may resolve enemy damage
	# and a registered self-cost. Do NOT evaluate outcome between them.
	if config.get("m5_4_outcome_enabled",false) == true and success and effect.has("recoil_hp"):
		var recoil: Dictionary = HP.registered_recoil(next,actor,int(effect["recoil_hp"]),
			str(effect["recoil_barrier_mode"]),config,id+":recoil")
		if not recoil["ok"]:
			return _error(str(recoil["error"]))
		next = recoil["core"]
		timeline.append_array(recoil["timeline"])
	if using_exposed and success:
		tactical = next["battle"]["m53"]
		tactical["exposed"] = {}
		break_amount += int(effect.get("exposed_bonus_break",0))
		timeline.append({"kind":"ExposedConsumed","target_id":target,
			"created_command_id":previous_exposed["created_command_id"],
			"consumed_command_id":id,"whole_sp":true})
	# Process all regular and bonus hit effects FIRST. Break is not live at a
	# hit_index boundary and does not retroactively change this SP's attacks.
	tactical = next["battle"]["m53"]
	if break_amount > 0 and BreakC.enabled(config):
		var change: Dictionary = BreakC.apply_break(next,break_amount,id,card,actor,config)
		next = change["core"]
		timeline.append_array(change["timeline"])
	elif break_amount > 0:
		if bool(tactical["break_locked"]):
			timeline.append({"kind":"BreakDamageIgnoredLocked","amount":break_amount})
		else:
			var before: int = int(tactical["break_gauge"])
			tactical["break_gauge"] = maxi(0,before-break_amount)
			timeline.append({"kind":"BreakGaugeChanged","before":before,
				"after":tactical["break_gauge"],"amount":break_amount})
			if before > 0 and int(tactical["break_gauge"]) == 0:
				timeline.append({"kind":"BreakPending","source_card_instance_id":card})
				tactical["break_locked"] = true
				timeline.append({"kind":"BreakTriggered","source_card_instance_id":card,
					"next_action_fallback":true,"stability_unmodified":true})
	# Exposed is a separate, single, timed opportunity. Existing Exposed
	# ignores refresh, and this SP can never consume what it just created.
	var exposing: bool = bool(effect.get("create_exposed",false)) and success
	if exposing:
		tactical = next["battle"]["m53"]
		if tactical["exposed"].is_empty():
			tactical["exposed"] = {"target_id":target,"created_command_id":id,
				"created_round":round_id,"expires_round":round_id+1,
				"source_actor_id":actor,"source_card_instance_id":card}
			timeline.append({"kind":"ExposedApplied","target_id":target,
				"expires_round":round_id+1,"one_use":true})
		else:
			timeline.append({"kind":"ExposedRefreshIgnored","target_id":target})
	var creation_tags: Variant = effect.get("creates_combo_tags",[])
	if creation_tags is Array and not creation_tags.is_empty() and success:
		tactical = next["battle"]["m53"]
		tactical["combo"] = {"source_actor_id":actor,
			"source_card_instance_id":card,"source_command_id":id,
			"target_id":target,"finisher_tags":creation_tags.duplicate(true),
			"expires_round":round_id}
		timeline.append({"kind":"ComboOpportunityOffered","source_actor_id":actor,
			"target_id":target,"finisher_tags":creation_tags.duplicate(true)})
	return {"ok":true,"error":"","core":next,"timeline":timeline,
		"card_definition_id":definition,"successful_hit":success}
