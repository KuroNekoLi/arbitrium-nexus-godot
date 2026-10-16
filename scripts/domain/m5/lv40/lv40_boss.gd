extends RefCounted
## Lv40 extension of the M5 Boss policy; M3 still schedules and closes actions.
const BossAI = preload("res://scripts/domain/m5/boss/boss_ai_policy.gd")
const Damage = preload("res://scripts/domain/m5/damage/damage_pipeline_resolver.gd")
const Effects = preload("res://scripts/domain/m5/lv40/lv40_effects.gd")
const Disruption = preload("res://scripts/domain/m4/casting/casting_disruption_resolver.gd")
const CYCLES: Dictionary = {1:["B01","B05","B06","B04"],2:["B02","B03","B04"],3:["B08","B09","B01","B04"]}

static func initialize(core: Dictionary, config: Dictionary) -> Dictionary:
	var secured: Dictionary = BossAI.ensure(core,config)
	var next: Dictionary = secured["core"]
	next["battle"]["lv40"] = {"version":config["m5_lv40_content_version"],
		"boss_phase":1,"cycle_index":0,"phase2_barrier_used":false,
		"pending_cast":{},"core_open":false,"barrier_expiry":{},
		"break_passive_rounds":{},"healing_passive_rounds":{},"spell_power":{},
		"defense_combo":{},"scorch":{}}
	return publish(next,config)

static func _live(core: Dictionary) -> Array:
	var result: Array = []
	for actor: String in core["battle"]["allies"]:
		if int(core["battle"]["actors"][actor]["hp"]) > 0:
			result.append(actor)
	return result

static func _preferred(core: Dictionary, config: Dictionary) -> String:
	var live: Array = _live(core)
	if live.is_empty():
		return ""
	var preferred_character: String = str(config.get("lv40_boss_target_character_id",""))
	for actor: String in live:
		var identity: String = str(core["battle"]["actors"][actor].get("meta",{}).get("character_id",""))
		if not preferred_character.is_empty() and identity == preferred_character:
			return actor
	return str(live[0])

static func _single(core: Dictionary, skill: String, config: Dictionary) -> String:
	var live: Array = _live(core)
	if live.is_empty():
		return ""
	if skill == "B02":
		var winner: String = str(live[0])
		for actor: String in live:
			var a: Dictionary = core["battle"]["actors"][actor]
			var b: Dictionary = core["battle"]["actors"][winner]
			if int(a["hp"])*int(b["max_hp"]) < int(b["hp"])*int(a["max_hp"]):
				winner = actor
		return winner
	if skill == "B03":
		for actor: String in live:
			if not Effects.casting_id(core,actor).is_empty():
				return actor
		return _preferred(core,config)
	return str(live[0])

static func intent(core: Dictionary, skill: String, config: Dictionary) -> Dictionary:
	var round_id: int = int(core["battle"]["round"])
	var aoe: bool = ["B04","B09"].has(skill)
	var attack: bool = config["m5_enemy_profiles"].has(skill)
	var targets: Array = _live(core) if aoe else [_single(core,skill,config)]
	if skill == "B06":
		targets = core["battle"]["lv40"]["pending_cast"].get("target_ids",[_preferred(core,config)]).duplicate()
	elif not attack:
		targets = ["Boss"]
	var pending: Dictionary = core["battle"]["lv40"]["pending_cast"]
	return {"intent_id":"lv40-r"+str(round_id)+"-"+skill,"enemy_id":"Boss",
		"name_key":str(config.get("intent_name_keys",{}).get(skill,"intent."+skill.to_lower()+".name")),
		"action_order":1,"created_seq":0,"publicly_declared":true,"skill_id":skill,
		"target_scope":"ALL" if aoe else "SINGLE","target_ids":targets,
		"fixed_target_ids":targets.duplicate(),
		"targeting_mode":"ALL_ELIGIBLE_AT_RESOLVE" if aoe else "SINGLE_LOCKED",
		"hit_count":int(config["m5_enemy_profiles"][skill]["hit_count"]) if attack else 0,
		"damage_type":str(config["m5_enemy_profiles"][skill]["damage_kind"]) if attack else "NONE",
		"requires_reaction_window":attack,"is_protectable":attack and not aoe,
		"unprotectable":not attack or aoe,"on_hit_disruption":skill == "B03",
		"direct_casting_disruption":false,"breakable":["B01","B02","B03","B04"].has(skill),
		"break_fallback":skill == "B11","casting_id":str(pending.get("casting_id","")),
		"windup_progress":1 if ["B06","B09"].has(skill) else 0,
		"expected_execute_phase":"EnemyPhase"+str(round_id),
		"conditional_branches":["CAST_INTERRUPTED_TO_B10","INVALID_TARGET_TO_FIZZLE"],
		"charge_release_skill":"B06" if skill == "B05" else ("B09" if skill == "B08" else ""),
		"charge_target_ids":[_preferred(core,config)] if skill == "B05" else (_live(core) if skill == "B08" else [])}

## Called only after the committed action has settled; phase thresholds never
## replace an already public action or an already started casting release.
static func publish(core: Dictionary, config: Dictionary) -> Dictionary:
	var next: Dictionary = core.duplicate(true)
	var fsm: Dictionary = next["battle"]["lv40"]
	var records: Array = []
	var skill: String
	if not fsm["pending_cast"].is_empty():
		skill = "B10" if bool(fsm["pending_cast"].get("interrupted",false)) else str(fsm["pending_cast"]["release_skill"])
	else:
		var boss: Dictionary = next["battle"]["actors"]["Boss"]
		var phase_id: int = 3 if int(boss["hp"])*100 <= int(boss["max_hp"])*30 else (2 if int(boss["hp"])*100 <= int(boss["max_hp"])*65 else 1)
		phase_id = maxi(phase_id,int(fsm["boss_phase"]))
		if phase_id != int(fsm["boss_phase"]):
			records.append({"kind":"BossPhaseChanged","before":fsm["boss_phase"],"after":phase_id})
			fsm["boss_phase"] = phase_id
			fsm["cycle_index"] = 0
		if phase_id == 2 and not bool(fsm["phase2_barrier_used"]):
			skill = "B07"
		else:
			skill = str(CYCLES[phase_id][int(fsm["cycle_index"]) % CYCLES[phase_id].size()])
	var public: Dictionary = intent(next,skill,config)
	next["battle"]["m53"]["last_published_intent"] = public.duplicate(true)
	return {"ok":true,"core":next,"intent":public,"timeline":records}

## Break is evaluated on the next eligible unstarted action, including the
## already announced action. The replacement is explicitly republished.
static func before_end(core: Dictionary, published: Dictionary, config: Dictionary) -> Dictionary:
	var next: Dictionary = core.duplicate(true)
	var public: Dictionary = published.duplicate(true)
	if ["B06","B09"].has(str(public["skill_id"])) and bool(next["battle"]["lv40"]["pending_cast"].get("interrupted",false)):
		public = intent(next,"B10",config)
	if bool(next["battle"]["m53"]["break_locked"]) and bool(public.get("breakable",false)):
		var previous: String = str(public["skill_id"])
		public = intent(next,"B11",config)
		public["replaced_skill_id"] = previous
		public["target_ids"] = published["target_ids"].slice(0,1) if previous != "B04" else [_single(next,"B11",config)]
		public["fixed_target_ids"] = public["target_ids"].duplicate()
	return {"core":next,"intent":public}

static func interrupt(core: Dictionary, power: int, command_id: String) -> Dictionary:
	var next: Dictionary = core.duplicate(true)
	var pending: Dictionary = next["battle"]["lv40"]["pending_cast"]
	if pending.is_empty() or bool(pending.get("interrupted",false)):
		return {"ok":false,"error":"LV40_NO_ENEMY_CASTING_INSTANCE"}
	var result: Dictionary = Disruption.resolve(pending,{"authority":"BALANCE_PROVISIONAL",
		"disruption_power":power},{"channel":"DIRECT_CASTING_INSTANCE",
		"source_enemy_action_id":command_id,"effect_id":"A05","hit_index":0})
	if not result["ok"]:
		return result
	var records: Array = [{"kind":"CastingDisruptionEvaluated","trace":result["trace"]},
		{"kind":"CastingStabilityChanged","casting_id":pending["casting_id"],
			"before":pending["current_stability"],"after":result["instance"]["current_stability"]}]
	next["battle"]["lv40"]["pending_cast"] = result["instance"]
	if result["interrupted"]:
		next["battle"]["lv40"]["pending_cast"]["interrupted"] = true
		next["battle"]["lv40"]["core_open"] = false
		records.append({"kind":"CastingInterrupted","casting_id":pending["casting_id"],"caster_id":"Boss","mp_refund":0})
		records.append({"kind":"ScheduledEffectCancelled","casting_id":pending["casting_id"],"effect_applied":false})
	return {"ok":true,"core":next,"timeline":records}

static func resolve(core: Dictionary, public: Dictionary, defense: Dictionary,
		config: Dictionary, command_id: String) -> Dictionary:
	var next: Dictionary = core.duplicate(true)
	var records: Array = []
	var skill: String = str(public["skill_id"])
	var attack_attempted: bool = false
	var fsm: Dictionary = next["battle"]["lv40"]
	if bool(defense.get("enemy_action_cancelled_fixture",false)):
		return {"ok":true,"core":next,"timeline":[{"kind":"BossActionCancelled","skill_id":skill}]}
	# Consume the published cycle item, not an assumed pointer. Cooldown and
	# Break fallback replace that item; neither may repeat a released charge.
	var consumed_skill: String = str(public.get("replaced_skill_id",skill))
	if skill == "B10":
		consumed_skill = str(fsm["pending_cast"].get("release_skill",consumed_skill))
	var cycle_position: int = CYCLES[int(fsm["boss_phase"])].find(consumed_skill)
	# This is an announced conditional branch, not a new selected action.
	if ["B06","B09"].has(skill) and bool(fsm["pending_cast"].get("interrupted",false)):
		skill = "B10"
	if ["B05","B08"].has(skill):
		var release: String = "B06" if skill == "B05" else "B09"
		var stability: int = 9 if skill == "B05" else 15
		fsm["pending_cast"] = {"casting_id":"boss-cast:"+command_id,"caster_id":"Boss",
			"mode":"FULL","state":"CASTING","release_skill":release,"current_stability":stability,
			"base_stability":stability,"focus_ward":0,"disruption_events":[],
			"target_ids":[_preferred(next,config)] if skill == "B05" else _live(next),
			"due_round":int(next["battle"]["round"])+1,"interrupted":false}
		fsm["core_open"] = true
		records.append({"kind":"BossCastingStarted","casting_id":fsm["pending_cast"]["casting_id"],
			"caster_id":"Boss","stability":stability,"release_skill":release,
			"planned_resolve_round":fsm["pending_cast"]["due_round"],"target_ids":fsm["pending_cast"]["target_ids"]})
	elif skill == "B07":
		var shield: Dictionary = Effects.barrier(next,"Boss",180,-1)
		next = shield["core"]
		records.append_array(shield["timeline"])
		next["battle"]["lv40"]["phase2_barrier_used"] = true
	elif skill == "B10":
		if fsm["pending_cast"].is_empty() or not bool(fsm["pending_cast"].get("interrupted",false)):
			return {"ok":false,"error":"LV40_COOLDOWN_REQUIRES_INTERRUPTED_CAST"}
		records.append({"kind":"BossCooldown","casting_id":fsm["pending_cast"]["casting_id"],"hp_damage":0})
		fsm["pending_cast"] = {}
		fsm["core_open"] = false
	elif config["m5_enemy_profiles"].has(skill):
		if ["B06","B09"].has(skill):
			if fsm["pending_cast"].is_empty() or bool(fsm["pending_cast"].get("interrupted",false)) or int(fsm["pending_cast"].get("due_round",0)) != int(next["battle"]["round"]):
				return {"ok":false,"error":"LV40_RELEASE_REQUIRES_DUE_CAST"}
			records.append({"kind":"BossCastingReleased","casting_id":fsm["pending_cast"]["casting_id"],"skill_id":skill})
			fsm["pending_cast"] = {}
			fsm["core_open"] = false
		var targets: Array = _live(next) if str(public["targeting_mode"]) == "ALL_ELIGIBLE_AT_RESOLVE" else public["target_ids"]
		for target: String in targets:
			if not next["battle"]["actors"].has(target) or int(next["battle"]["actors"][target]["hp"]) <= 0:
				records.append({"kind":"BossActionFizzled","skill_id":skill,"target_actor_id":target,"reason":"INVALID_LOCKED_TARGET"})
				continue
			var context: Dictionary = {"guard_actor_ids":defense.get("guard_actor_ids",[])}
			if str(public["target_scope"]) == "SINGLE":
				context["damage_recipient_actor_id"] = str(defense.get("damage_recipient_actor_id",""))
				context["protect_confirmed"] = not str(defense.get("protected_by_actor_id","")).is_empty()
			var hit: Dictionary = Damage.resolve(next,"Boss",target,config["m5_enemy_profiles"][skill],context,config,command_id)
			if not hit["ok"]:
				return hit
			next = hit["core"]
			attack_attempted = true
			records.append_array(hit["timeline"])
			if skill == "B03":
				for trace: Dictionary in hit["timeline"]:
					if str(trace.get("kind","")) == "DamageTrace" and bool(trace.get("hit",false)):
						var disrupted: Dictionary = Effects.disrupt_ally(next,str(hit["recipient_id"]),5,command_id,config)
						if not disrupted["ok"]:
							return disrupted
						next = disrupted["core"]
						records.append_array(disrupted["timeline"])
		if skill == "B11":
			next["battle"]["m53"]["break_locked"] = false
			next["battle"]["m53"]["break_gauge"] = int(next["battle"]["m53"]["break_max"])
			records.append({"kind":"BossBreakRecovered","break_gauge_restored":next["battle"]["m53"]["break_max"]})
	else:
		return {"ok":false,"error":"LV40_UNKNOWN_BOSS_SKILL"}
	var counter: String = str(defense.get("lv40_counter_actor_id",""))
	if attack_attempted and not counter.is_empty() and int(next["battle"]["actors"][counter]["hp"]) > 0 and int(next["battle"]["actors"]["Boss"]["hp"]) > 0:
		var retaliation: Dictionary = Damage.resolve(next,counter,"Boss",{
			"damage_kind":"PHYSICAL","skill_multiplier_bp":5500,"flat_bonus":0,
			"hit_count":1,"hit_mode":"RANDOM_PERCENT","crit_eligible":true,"element_id":"NEUTRAL"},
			{},config,command_id+":R05")
		if not retaliation["ok"]:
			return retaliation
		next = retaliation["core"]
		records.append({"kind":"ReactionCounterExecuted","actor_id":counter,"card_definition_id":"R05"})
		records.append_array(retaliation["timeline"])
	if skill != "B07":
		next["battle"]["lv40"]["cycle_index"] = cycle_position+1 if cycle_position >= 0 else int(next["battle"]["lv40"]["cycle_index"])+1
	return {"ok":true,"core":next,"timeline":records}
