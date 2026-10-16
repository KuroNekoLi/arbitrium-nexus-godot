extends RefCounted
## M5.3 — deterministic, content-driven Boss intent selection.
## The M3 EnemyAction scheduler remains the only executor of public intents.
const CONTENT_SCHEMA: String = "m5.3-boss-provisional-v1"

static func ensure(core: Dictionary, config: Dictionary) -> Dictionary:
	var settings: Variant = config.get("m5_3_boss", null)
	if not settings is Dictionary:
		return {"ok":false,"error":"M53_BOSS_CONFIG_MISSING"}
	var boss: String = str(settings.get("boss_id",""))
	var limit: Variant = settings.get("break_max",null)
	if boss.is_empty() or not core["battle"]["enemies"].has(boss) or 			not limit is int or int(limit) <= 0:
		return {"ok":false,"error":"M53_INVALID_BOSS_CONFIG"}
	var next: Dictionary = core.duplicate(true)
	if not next["battle"].has("m53"):
		next["battle"]["m53"] = {
			"schema":CONTENT_SCHEMA,"boss_id":boss,"break_max":int(limit),
			"break_gauge":int(limit),"break_locked":false,
			"fallback_started":false,"exposed":{},"combo":{},
			"last_published_intent":{}}
	var status: Dictionary = next["battle"]["m53"]
	if str(status.get("schema","")) != CONTENT_SCHEMA or 			str(status.get("boss_id","")) != boss or 			int(status.get("break_max",-1)) != int(limit) or 			int(status.get("break_gauge",-1)) < 0 or 			int(status.get("break_gauge",0)) > int(limit):
		return {"ok":false,"error":"M53_INVALID_BOSS_STATE"}
	return {"ok":true,"error":"","core":next}

static func _target(core: Dictionary, strategy: String) -> String:
	var candidates: Array[String] = []
	for id: Variant in core["battle"]["allies"]:
		var key: String = str(id)
		if int(core["battle"]["actors"][key]["hp"]) > 0 and \
				not bool(core["battle"].get("retired_from_field_by_actor",{}).get(key,false)):
			candidates.append(key)
	candidates.sort()
	if candidates.is_empty():
		return ""
	if strategy == "LOWEST_HP":
		var winner: String = candidates[0]
		for key: String in candidates:
			if int(core["battle"]["actors"][key]["hp"]) < 					int(core["battle"]["actors"][winner]["hp"]):
				winner = key
		return winner
	if strategy == "FIRST_ACTIVE":
		return candidates[0]
	return ""

static func choose(core: Dictionary, config: Dictionary) -> Dictionary:
	var secured: Dictionary = ensure(core,config)
	if not secured["ok"]:
		return secured
	var next: Dictionary = secured["core"]
	var boss_state: Dictionary = next["battle"]["m53"]
	var settings: Dictionary = config["m5_3_boss"]
	var skills: Variant = settings.get("skills",null)
	var profiles: Variant = config.get("m5_enemy_profiles",null)
	if not skills is Dictionary or not profiles is Dictionary:
		return {"ok":false,"error":"M53_SKILL_CATALOGUE_MISSING"}
	var chosen: String = ""
	var fallback: bool = bool(boss_state["break_locked"])
	if fallback:
		chosen = str(settings.get("fallback_skill_id",""))
		if not skills.has(chosen):
			return {"ok":false,"error":"M53_FALLBACK_NOT_REGISTERED"}
	else:
		var available: Array[String] = []
		for key: Variant in skills.keys():
			var skill_id: String = str(key)
			var row: Variant = skills[skill_id]
			if not row is Dictionary or not row.get("priority",null) is int:
				return {"ok":false,"error":"M53_INVALID_SKILL_POLICY"}
			var hp: int = int(next["battle"]["actors"][str(settings["boss_id"])]["hp"])
			var max_hp: int = int(next["battle"]["actors"][str(settings["boss_id"])]["max_hp"])
			var threshold: int = int(row.get("max_hp_pct",100))
			var floor_pct: int = int(row.get("min_hp_pct",0))
			if max_hp > 0 and hp*100 <= max_hp*threshold and hp*100 >= max_hp*floor_pct:
				available.append(skill_id)
		available.sort_custom(func(a: String, b: String) -> bool:
			if int(skills[a]["priority"]) != int(skills[b]["priority"]):
				return int(skills[a]["priority"]) > int(skills[b]["priority"])
			return a < b
		)
		if available.is_empty():
			return {"ok":false,"error":"M53_NO_ELIGIBLE_BOSS_SKILL"}
		chosen = available[0]
	if not skills.has(chosen) or not profiles.has(chosen) or 			not skills[chosen] is Dictionary or not profiles[chosen] is Dictionary:
		return {"ok":false,"error":"M53_BOSS_SKILL_NOT_REGISTERED"}
	var rule: Dictionary = skills[chosen]
	var profile: Dictionary = profiles[chosen]
	var strategy: String = str(rule.get("target_strategy","FIRST_ACTIVE"))
	var target: String = _target(next,strategy)
	if target.is_empty():
		return {"ok":false,"error":"M53_NO_LEGAL_TARGET"}
	if not profile.get("hit_count",null) is int or int(profile["hit_count"]) < 1:
		return {"ok":false,"error":"M53_INVALID_BOSS_HIT_PROFILE"}
	var round_id: int = int(next["battle"]["round"])
	var intent: Dictionary = {
		"intent_id":"m53-r"+str(round_id)+"-"+chosen,"enemy_id":str(settings["boss_id"]),
		"action_order":1,"created_seq":0,"publicly_declared":true,
		"skill_id":chosen,"target_scope":"SINGLE","target_ids":[target],
		"hit_count":int(profile["hit_count"]),
		"damage_type":str(profile.get("damage_kind","PHYSICAL")),
		"requires_reaction_window":true,
		"is_protectable":bool(rule.get("is_protectable",true)),
		"break_fallback":fallback,"conditional_branches":[],
		"on_hit_disruption":bool(rule.get("on_hit_disruption",false)),
		"direct_casting_disruption":bool(rule.get("direct_casting_disruption",false))}
	boss_state["last_published_intent"] = intent.duplicate(true)
	return {"ok":true,"error":"","core":next,"intents":[intent],
		"intent":intent,"fallback":fallback}

static func settle_fallback(core: Dictionary, declared_intent: Dictionary,
		config: Dictionary) -> Dictionary:
	var secured: Dictionary = ensure(core,config)
	if not secured["ok"]:
		return secured
	var next: Dictionary = secured["core"]
	var status: Dictionary = next["battle"]["m53"]
	if not bool(declared_intent.get("break_fallback",false)):
		return {"ok":true,"error":"","core":next,"recovered":false}
	if not bool(status["break_locked"]) or 			str(declared_intent.get("skill_id","")) != 			str(config["m5_3_boss"].get("fallback_skill_id","")):
		return {"ok":false,"error":"M53_INVALID_FALLBACK_SETTLEMENT"}
	status["break_gauge"] = int(status["break_max"])
	status["break_locked"] = false
	status["fallback_started"] = false
	return {"ok":true,"error":"","core":next,"recovered":true}
