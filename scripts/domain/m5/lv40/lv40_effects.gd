extends RefCounted
## Internal trusted effect helpers. No public command carries effect amounts.
const HP = preload("res://scripts/domain/m5/status/hp_lifecycle_bridge.gd")
const Disruption = preload("res://scripts/domain/m4/casting/casting_disruption_resolver.gd")
const LastInstability = preload("res://scripts/domain/m4/last_spell/last_spell_instability_resolver.gd")
const Refund = preload("res://scripts/domain/m4/casting/casting_refund_policy.gd")
const M2 = preload("res://scripts/domain/m2/integration/m2_domain_resolver.gd")

static func barrier(core: Dictionary, actor: String, amount: int, round_id: int) -> Dictionary:
	var next: Dictionary = core.duplicate(true)
	if not next["battle"].has("hp_barriers"):
		next["battle"]["hp_barriers"] = {}
	var before: float = float(next["battle"]["hp_barriers"].get(actor,0.0))
	var after: float = maxf(before,float(amount))
	next["battle"]["hp_barriers"][actor] = after
	next["battle"]["lv40"]["barrier_expiry"][actor] = round_id
	return {"ok":true,"core":next,"timeline":[{"kind":"HPBarrierGranted",
		"actor_id":actor,"before":before,"after":after,"amount":amount,
		"policy":"REPLACE_IF_HIGHER","expires_enemy_round":round_id}]}

static func heal(core: Dictionary, actor: String, amount: int) -> Dictionary:
	var healed: Dictionary = HP.heal(core,actor,amount)
	if healed.get("ok",false):
		for event: Dictionary in healed["timeline"]:
			event["requested_amount"] = amount
	return healed

static func casting_id(core: Dictionary, actor: String) -> String:
	for key: String in core["battle"]["casting_instances"]:
		if str(core["battle"]["casting_instances"][key]["caster_id"]) == actor:
			return key
	return ""

## Same M4 disruption, refund, card settlement and Last Spell instability rules.
static func disrupt_ally(core: Dictionary, actor: String, power: int,
		command_id: String, config: Dictionary) -> Dictionary:
	var id: String = casting_id(core,actor)
	if id.is_empty():
		return {"ok":true,"core":core.duplicate(true),"timeline":[]}
	var spell: Dictionary = core["battle"]["casting_instances"][id]
	var resolved: Dictionary = Disruption.resolve(spell,{"authority":"BALANCE_PROVISIONAL",
		"disruption_power":power},{"channel":"ON_HIT_CASTING",
		"source_enemy_action_id":command_id,"effect_id":"B03","hit_index":0})
	if not resolved["ok"]:
		return resolved
	var next: Dictionary = core.duplicate(true)
	var records: Array = [{"kind":"CastingDisruptionEvaluated","trace":resolved["trace"]},
		{"kind":"CastingStabilityChanged","casting_id":id,"before":spell["current_stability"],
			"after":resolved["instance"]["current_stability"]}]
	next["battle"]["casting_instances"][id] = resolved["instance"]
	if not resolved["interrupted"]:
		return {"ok":true,"core":next,"timeline":records}
	if str(spell.get("kind","")) == "LAST_SPELL":
		var special: Dictionary = LastInstability.handle(resolved["instance"],config["last_spell_instability"])
		if not special["ok"]:
			return special
		next["battle"]["casting_instances"][id] = special["instance"]
		records.append(special["event"])
	else:
		var quote: Dictionary = Refund.quote(spell,next["battle"]["actors"][actor],config["casting_interrupt_refund"])
		if not quote["ok"]:
			return quote
		for instruction: Dictionary in [
			{"type":"RECOVER_CASTING_INTERRUPT_MP_M4","amount":int(quote["requested"])},
			{"type":"SETTLE_CASTING_CARD_M4","card_instance_id":spell["card_instance_id"]}]:
			instruction.merge({"actor_id":actor,"command_id":command_id+":"+str(instruction["type"]),
				"expected_event_seq":int(next["event_seq"])})
			var paid: Dictionary = M2.apply(next,instruction,config)
			if not paid["accepted"]:
				return {"ok":false,"error":paid["error"]}
			next = paid["state"]
			for item: Dictionary in paid["events"]:
				records.append({"kind":"core_event","raw":item})
		next["battle"]["casting_instances"].erase(id)
		next["battle"]["actors"][actor]["status"] = "ACTIVE"
		records.append({"kind":"CastingInterrupted","casting_id":id,"caster_id":actor,
			"ap_refund":0,"mp_refund":quote["actual"]})
		records.append({"kind":"ScheduledEffectCancelled","casting_id":id,"effect_applied":false})
	return {"ok":true,"core":next,"timeline":records}

static func break_damage(core: Dictionary, amount: int, card_id: String) -> Dictionary:
	var next: Dictionary = core.duplicate(true)
	var boss: Dictionary = next["battle"]["m53"]
	var records: Array = []
	if amount > 0 and not bool(boss["break_locked"]):
		var before: int = int(boss["break_gauge"])
		boss["break_gauge"] = maxi(0,before-amount)
		records.append({"kind":"BreakGaugeChanged","before":before,"after":boss["break_gauge"],"amount":amount})
		if before > 0 and int(boss["break_gauge"]) == 0:
			boss["break_locked"] = true
			records.append({"kind":"BreakPending","source_card_instance_id":card_id})
			records.append({"kind":"BreakTriggered","next_action_fallback":true,"stability_unmodified":true})
	return {"ok":true,"core":next,"timeline":records}
