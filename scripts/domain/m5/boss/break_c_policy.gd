extends RefCounted
## BKC-02 — deterministic opt-in policy. No RNG, AP, casting or UI state.
static func enabled(config: Dictionary) -> bool:
	return bool(config.get("m5_break_c_enabled",false))

static func add_exposed(core: Dictionary, command_id: String, card_id: String,
		actor_id: String, source: String, _config: Dictionary) -> Dictionary:
	var next: Dictionary = core.duplicate(true)
	var boss: Dictionary = next["battle"]["m53"]
	if not boss["exposed"].is_empty():
		return {"ok":true,"core":next,"timeline":[{"kind":"ExposedRefreshIgnored",
			"target_id":str(boss["boss_id"]),"source":source}]}
	var round_id: int = int(next["battle"]["round"])
	boss["exposed"] = {"target_id":str(boss["boss_id"]),"created_command_id":command_id,
		"created_round":round_id,"expires_round":round_id+1,
		"source_actor_id":actor_id,"source_card_instance_id":card_id,
		"source":source}
	return {"ok":true,"core":next,"timeline":[{"kind":"ExposedApplied",
		"target_id":str(boss["boss_id"]),"expires_round":round_id+1,
		"one_use":true,"source":source}]}

static func apply_break(core: Dictionary, amount: int, command_id: String,
		card_id: String, actor_id: String, config: Dictionary) -> Dictionary:
	var next: Dictionary = core.duplicate(true)
	var boss: Dictionary = next["battle"]["m53"]
	var events: Array = []
	if amount <= 0:
		return {"ok":true,"core":next,"timeline":events}
	if bool(boss["break_locked"]):
		events.append({"kind":"BreakDamageIgnoredLocked","amount":amount})
		return {"ok":true,"core":next,"timeline":events}
	if int(boss.get("break_resilience_round",-1)) == int(next["battle"]["round"]):
		events.append({"kind":"BreakDamageIgnoredResilient","amount":amount})
		return {"ok":true,"core":next,"timeline":events}
	var before: int = int(boss["break_gauge"])
	boss["break_gauge"] = maxi(0,before-amount)
	events.append({"kind":"BreakGaugeChanged","before":before,
		"after":int(boss["break_gauge"]),"amount":amount})
	if before > 0 and int(boss["break_gauge"]) == 0:
		boss["break_locked"] = true
		events.append({"kind":"BreakPending","source_card_instance_id":card_id})
		events.append({"kind":"BreakTriggered","source_card_instance_id":card_id,
			"next_action_control":"CANCEL_OR_DOWNGRADE","stability_unmodified":true})
		if bool(config.get("m5_3_boss",{}).get("exposed_rules",{}).get("on_break",true)):
			var new_exposed: Dictionary = add_exposed(next,command_id,card_id,
				actor_id,"BREAK",config)
			next = new_exposed["core"]
			events.append_array(new_exposed["timeline"])
	return {"ok":true,"core":next,"timeline":events}

## Consumes exactly one Break control and prevents back-to-back cancels.
static func recover(core: Dictionary, action_id: String, controlled: bool) -> Dictionary:
	var next: Dictionary = core.duplicate(true)
	var boss: Dictionary = next["battle"]["m53"]
	if not bool(boss["break_locked"]):
		return {"ok":true,"core":next,"timeline":[]}
	boss["break_locked"] = false
	boss["break_gauge"] = int(boss["break_max"])
	boss["break_resilience_round"] = int(next["battle"]["round"])+1 if controlled else -1
	return {"ok":true,"core":next,"timeline":[{"kind":"BossBreakRecovered",
		"enemy_action_id":action_id,"break_gauge_restored":int(boss["break_max"]),
		"resilience_round":int(boss["break_resilience_round"]),
		"controlled":controlled}]}
