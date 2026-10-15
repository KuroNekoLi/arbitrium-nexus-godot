extends RefCounted
## M5.1 LIVE authoritative HP writer for already legal M2/M3/M4 actions.
## No AP/MP/card spend here. All balance numbers remain BALANCE_PROVISIONAL.
const Hit = preload("res://scripts/domain/m5/damage/hit_resolver.gd")
const Crit = preload("res://scripts/domain/m5/damage/critical_resolver.gd")
const RNG = preload("res://scripts/domain/m1/combat_rng.gd")
const Invalidation = preload("res://scripts/domain/m4/casting/casting_invalidation_resolver.gd")

static func _error(code: String) -> Dictionary:
	return {"ok":false,"error":code,"core":{},"timeline":[]}

static func _stats(config: Dictionary, id: String) -> Dictionary:
	var list: Variant = config.get("m5_actor_stats",null)
	if not list is Dictionary or not list.has(id) or not list[id] is Dictionary:
		return {}
	var s: Dictionary = list[id]
	for field: String in ["accuracy","evasion","patk","pdef","matk","mdef",
			"crit_rate_bp","crit_bonus_bp"]:
		if not s.get(field,null) is int or int(s[field]) < 0:
			return {}
	return s

## Buff/Debuff definitions contribute real deterministic effective combat stats.
## No status-specific RNG, and no change to M5.1 when no statuses active.
static func _effective_stats(base: Dictionary, battle: Dictionary,
		id: String, config: Dictionary) -> Dictionary:
	var result: Dictionary = base.duplicate(true)
	var definitions: Variant = config.get("m5_status_definitions",{})
	if not definitions is Dictionary:
		return result
	for entry: Variant in battle.get("statuses",[]):
		if not entry is Dictionary or str(entry.get("target_actor_id","")) != id:
			continue
		var definition: Variant = definitions.get(str(entry.get("status_id","")),null)
		if not definition is Dictionary or not ["BUFF","DEBUFF"].has(
				str(definition.get("kind",""))):
			continue
		var stat: String = str(definition.get("stat_id",""))
		if not result.has(stat):
			continue
		var amount: int = int(definition.get("stat_delta",0)) * \
			int(entry.get("stacks",1))
		result[stat] = maxi(0,int(result[stat])+amount)
	return result

static func _validate(profile: Dictionary, config: Dictionary) -> String:
	if not config.get("m5_damage_enabled",false) == true:
		return "M51_DAMAGE_NOT_ENABLED"
	if str(config.get("m5_balance_authority","")) != "BALANCE_PROVISIONAL":
		return "M51_BALANCE_NOT_VERSIONED"
	if not ["PHYSICAL","MAGICAL"].has(str(profile.get("damage_kind",""))):
		return "M51_INVALID_DAMAGE_KIND"
	if not ["RANDOM_PERCENT","GUARANTEED","CONDITIONAL"].has(str(profile.get("hit_mode",""))):
		return "M51_INVALID_HIT_MODE"
	for field: String in ["skill_multiplier_bp","flat_bonus","hit_count"]:
		if not profile.get(field,null) is int:
			return "M51_MISSING_DAMAGE_PROFILE"
	if int(profile["skill_multiplier_bp"]) < 0 or int(profile["flat_bonus"]) < 0 \
			or int(profile["hit_count"]) < 1 or int(profile["hit_count"]) > 16:
		return "M51_INVALID_DAMAGE_PROFILE"
	if not profile.get("crit_eligible",null) is bool:
		return "M51_CRIT_ELIGIBILITY_REQUIRED"
	for field: String in ["defense_k","variance_bp","guard_reduction_bp",
			"base_hit_bp","accuracy_step_bp"]:
		if not config.get("m5_balance",{}).get(field,null) is int:
			return "M51_MISSING_BALANCE_PARAMETER"
	var bal: Dictionary = config["m5_balance"]
	if int(bal["defense_k"]) <= 0 or int(bal["variance_bp"]) < 0 or \
			int(bal["variance_bp"]) > 10000 or int(bal["guard_reduction_bp"]) < 0 or \
			int(bal["guard_reduction_bp"]) > 10000:
		return "M51_INVALID_BALANCE_PARAMETER"
	return ""

static func resolve(core: Dictionary, source_id: String, declared_target: String,
		profile: Dictionary, context: Dictionary, config: Dictionary,
		command_id: String) -> Dictionary:
	# Caller is the authoritative already-committed action/release.
	# Never accept a final_hp or external damage number.
	var issue: String = _validate(profile,config)
	if not issue.is_empty():
		return _error(issue)
	var source: Dictionary = _effective_stats(_stats(config,source_id),
		core["battle"],source_id,config)
	if source.is_empty() or not core["battle"]["actors"].has(source_id) or \
			int(core["battle"]["actors"][source_id]["hp"]) <= 0:
		return _error("M51_INVALID_DAMAGE_SOURCE")
	var recipient: String = str(context.get("damage_recipient_actor_id",declared_target))
	if recipient.is_empty():
		recipient = declared_target
	if not core["battle"]["actors"].has(declared_target) or \
			not core["battle"]["actors"].has(recipient):
		return _error("M51_INVALID_DAMAGE_TARGET")
	if int(core["battle"]["actors"][recipient]["hp"]) <= 0:
		return _error("M51_TARGET_ALREADY_INCAPACITATED")
	if recipient != declared_target:
		if not bool(context.get("protect_confirmed",false)):
			return _error("M51_UNAUTHORIZED_TARGET_REDIRECT")
		if declared_target == source_id:
			return _error("M51_REDIRECT_INVALID")
	var target_stats: Dictionary = _effective_stats(_stats(config,recipient),
		core["battle"],recipient,config)
	if target_stats.is_empty():
		return _error("M51_MISSING_RECIPIENT_STATS")
	var element: String = str(profile.get("element_id","NEUTRAL"))
	var resistance: Variant = config.get("m5_element_resistance",{}).get(recipient,{})
	if not resistance is Dictionary or not resistance.get(element,null) is int:
		return _error("M51_ELEMENT_NOT_CONFIGURED")
	var resist_bp: int = int(resistance[element])
	if resist_bp < 0 or resist_bp > 20000:
		return _error("M51_INVALID_ELEMENT_MULTIPLIER")
	var current: Dictionary = core.duplicate(true)
	var records: Array = []
	var bal: Dictionary = config["m5_balance"]
	var guard: bool = context.get("guard_actor_ids",[]).has(recipient)
	var hits: int = int(profile["hit_count"])
	for hit_index: int in range(hits):
		if int(current["battle"]["actors"][recipient]["hp"]) == 0:
			records.append({"kind":"HPHitSkipped","hit_index":hit_index,
				"reason":"RECIPIENT_ALREADY_ZERO","recipient_id":recipient})
			continue
		var checked: Dictionary = Hit.resolve(current["battle"]["rng"],profile,source,target_stats,bal)
		if not checked["ok"]:
			return _error(str(checked["error"]))
		current["battle"]["rng"] = checked["rng"]
		var trace: Dictionary = {"kind":"DamageTrace","source_actor_id":source_id,
			"declared_target_id":declared_target,"recipient_id":recipient,
			"action_id":command_id,"hit_index":hit_index,
			"hit_mode":str(profile["hit_mode"]),"hit":bool(checked["hit"]),
			"hit_chance_bp":int(checked["chance_bp"]),
			"hit_roll_bp":int(checked["roll_bp"]),
			"hit_rng_draw_index":int(checked["rng_draw_index"]),
			"element_id":element,"element_multiplier_bp":resist_bp,
			"guard_applied":guard,"barrier_absorbed":0.0,
			"crit":false,"crit_roll_bp":-1,
			"hp_before":int(current["battle"]["actors"][recipient]["hp"]),
			"hp_after":int(current["battle"]["actors"][recipient]["hp"]),
			"hp_damage":0,"damage_unrounded":0.0,"balance_authority":"BALANCE_PROVISIONAL"}
		if not bool(checked["hit"]):
			records.append(trace)
			continue
		var critical: Dictionary = Crit.resolve(current["battle"]["rng"],
			bool(profile["crit_eligible"]),source)
		if not critical["ok"]:
			return _error(str(critical["error"]))
		current["battle"]["rng"] = critical["rng"]
		trace["crit"] = bool(critical["critical"])
		trace["crit_roll_bp"] = int(critical["roll_bp"])
		trace["crit_rng_draw_index"] = int(critical["rng_draw_index"])
		var stat: String = "matk" if profile["damage_kind"] == "MAGICAL" else "patk"
		var defense: String = "mdef" if profile["damage_kind"] == "MAGICAL" else "pdef"
		var base: float = (float(source[stat]) * float(profile["skill_multiplier_bp"]) / 10000.0
			+ float(profile["flat_bonus"])) * float(bal["defense_k"]) / \
			float(int(bal["defense_k"])+int(target_stats[defense]))
		var amount: float = base * float(resist_bp) / 10000.0
		if bool(critical["critical"]):
			amount *= (1.0 + float(source["crit_bonus_bp"])/10000.0)
		var variance: int = int(bal["variance_bp"])
		var variance_roll: int = 0
		if variance > 0:
			var rand: Dictionary = RNG.next_int(current["battle"]["rng"])
			if not rand["accepted"]:
				return _error(str(rand["error"]))
			current["battle"]["rng"] = rand["rng"]
			variance_roll = int(rand["value"]) % (variance*2+1) - variance
			amount *= (1.0 + float(variance_roll)/10000.0)
		trace["variance_roll_bp"] = variance_roll
		if guard:
			amount *= 1.0 - float(bal["guard_reduction_bp"])/10000.0
		# HP Barrier is distinct from casting FocusWard and is never used
		# on a miss. Float kept until the final floor0 damage boundary.
		var barriers: Dictionary = current["battle"].get("hp_barriers",{})
		var ward: float = float(barriers.get(recipient,0.0))
		if ward < 0:
			return _error("M51_INVALID_HP_BARRIER")
		var absorbed: float = minf(ward,maxf(0.0,amount))
		amount = maxf(0.0,amount-absorbed)
		if absorbed > 0:
			if not current["battle"].has("hp_barriers"):
				current["battle"]["hp_barriers"] = {}
			current["battle"]["hp_barriers"][recipient] = ward-absorbed
		trace["barrier_absorbed"] = absorbed
		trace["damage_unrounded"] = amount
		var raw_hp: int = int(current["battle"]["actors"][recipient]["hp"])
		var delta: int = mini(raw_hp,int(floor(amount)))
		current["battle"]["actors"][recipient]["hp"] = raw_hp-delta
		trace["hp_damage"] = delta
		trace["hp_after"] = raw_hp-delta
		records.append(trace)
		if delta > 0:
			records.append({"kind":"HPDamageApplied","recipient_id":recipient,
				"hp_before":raw_hp,"hp_after":raw_hp-delta,"amount":delta,
				"hit_index":hit_index})
		if raw_hp > 0 and raw_hp-delta == 0:
			if current["battle"]["allies"].has(recipient):
				var forced: Dictionary = Invalidation.incapacitate(current,recipient,command_id,config)
				if not forced["ok"]:
					return _error(str(forced["error"]))
				current = forced["core"]
				records.append_array(forced["timeline"])
			else:
				current["battle"]["actors"][recipient]["status"] = "INCAPACITATED"
				records.append({"kind":"ActorIncapacitated","actor_id":recipient,
					"reason":"HP_REACHED_ZERO","hp":0})
	return {"ok":true,"error":"","core":current,"timeline":records,
		"recipient_id":recipient,"resolved_hits":hits}
