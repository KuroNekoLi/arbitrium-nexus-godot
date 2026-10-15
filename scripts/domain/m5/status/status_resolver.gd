extends RefCounted
## M5.2 versioned real StatusInstances; one array in existing BattleState.
## Only registered paid SP / trusted resolved on-hit effects may call grant.
const HP = preload("res://scripts/domain/m5/status/hp_lifecycle_bridge.gd")
const KINDS: Array[String] = ["DOT","HOT","BUFF","DEBUFF","BARRIER"]
const POLICIES: Array[String] = ["STACK","REPLACE","REFRESH","IGNORE"]

static func _fail(reason: String) -> Dictionary:
	return {"ok":false,"error":reason,"core":{},"timeline":[]}

static func _definition(config: Dictionary, status_id: String) -> Dictionary:
	var all: Variant = config.get("m5_status_definitions",null)
	if not all is Dictionary or not all.has(status_id) or \
			not all[status_id] is Dictionary:
		return {}
	return all[status_id]

static func _legal(d: Dictionary) -> bool:
	if not KINDS.has(str(d.get("kind",""))) or \
			not POLICIES.has(str(d.get("stack_policy",""))) or \
			not ["NEXT_PLAYER_PHASE","ENEMY_PHASE_END"].has(str(d.get("tick_trigger",""))):
		return false
	for field: String in ["priority","duration_ticks","stack_cap","tick_amount"]:
		if not d.get(field,null) is int:
			return false
	if int(d["duration_ticks"]) < 1 or int(d["stack_cap"]) < 1 or \
			int(d["stack_cap"]) > 16 or int(d["tick_amount"]) < 0:
		return false
	if not d.get("dispel_tags",null) is Array:
		return false
	if d["kind"] == "DOT" and not ["ABSORB","BYPASS"].has(str(d.get("barrier_mode",""))):
		return false
	if ["BUFF","DEBUFF"].has(str(d["kind"])):
		if not ["patk","pdef","matk","mdef","accuracy","evasion"].has(
				str(d.get("stat_id",""))) or not d.get("stat_delta",null) is int:
			return false
	if d["kind"] == "BARRIER" and (not d.get("barrier_amount",null) is int or
			int(d["barrier_amount"]) < 1):
		return false
	return true

static func validate(core: Dictionary, config: Dictionary) -> bool:
	var battle: Dictionary = core.get("battle",{})
	if not battle.get("statuses",null) is Array:
		return false
	var ids: Dictionary = {}
	var guards: Dictionary = {}
	for item: Variant in battle["statuses"]:
		if not item is Dictionary:
			return false
		var s: Dictionary = item
		var id: String = str(s.get("status_instance_id",""))
		var target: String = str(s.get("target_actor_id",""))
		var definition: Dictionary = _definition(config,str(s.get("status_id","")))
		if id.is_empty() or ids.has(id) or not battle["actors"].has(target) or \
				not _legal(definition):
			return false
		ids[id] = true
		if not s.get("stacks",null) is int or int(s["stacks"]) < 1 or \
				int(s["stacks"]) > int(definition["stack_cap"]):
			return false
		for field: String in ["remaining_ticks","applied_round","priority"]:
			if not s.get(field,null) is int:
				return false
		if int(s["remaining_ticks"]) < 1 or \
				int(s["remaining_ticks"]) > int(definition["duration_ticks"]) or \
				int(s["applied_round"]) > int(battle["round"]):
			return false
		if s.get("tick_trigger","") != definition.get("tick_trigger",""):
			return false
		if definition["kind"] == "BARRIER":
			if guards.has(target):
				return false
			guards[target] = true
			if float(battle.get("hp_barriers",{}).get(target,-1.0)) < 0.0:
				return false
	return true

static func grant(core: Dictionary, source_actor_id: String,
		target_actor_id: String, status_id: String, command_id: String,
		config: Dictionary) -> Dictionary:
	var d: Dictionary = _definition(config,status_id)
	if not _legal(d):
		return _fail("M52_UNKNOWN_STATUS_DEFINITION")
	if not core["battle"]["actors"].has(source_actor_id) or \
			not core["battle"]["actors"].has(target_actor_id):
		return _fail("M52_INVALID_STATUS_ACTOR")
	if int(core["battle"]["actors"][target_actor_id]["hp"]) <= 0:
		return _fail("M52_STATUS_TARGET_INCAPACITATED")
	if not core["battle"]["statuses"] is Array:
		return _fail("M52_INVALID_STATUS_LIST")
	var s: Dictionary = core.duplicate(true)
	var records: Array = []
	var existing: int = -1
	for i: int in range(s["battle"]["statuses"].size()):
		var prior: Dictionary = s["battle"]["statuses"][i]
		if prior["target_actor_id"] == target_actor_id and prior["status_id"] == status_id:
			existing = i
			break
	if d["kind"] == "BARRIER":
		for other: Dictionary in s["battle"]["statuses"]:
			if other["target_actor_id"] == target_actor_id and \
					other["status_id"] != status_id and \
					str(_definition(config,str(other["status_id"])).get("kind","")) == "BARRIER":
				return _fail("M52_MULTIPLE_BARRIER_TYPES_UNSUPPORTED")
	var policy: String = str(d["stack_policy"])
	var instance_id: String = status_id+":"+command_id
	if existing >= 0:
		var old: Dictionary = s["battle"]["statuses"][existing]
		instance_id = str(old["status_instance_id"])
		if policy == "IGNORE":
			records.append({"kind":"StatusGrantIgnored","status_instance_id":instance_id,
				"reason":"EXISTING_NOT_REFRESHED"})
			return {"ok":true,"core":s,"timeline":records}
		if policy == "STACK":
			old["stacks"] = mini(int(d["stack_cap"]),int(old["stacks"])+1)
		else:
			old["stacks"] = 1 if policy == "REPLACE" else int(old["stacks"])
		old["remaining_ticks"] = int(d["duration_ticks"])
		old["applied_round"] = int(s["battle"]["round"])
		s["battle"]["statuses"][existing] = old
		records.append({"kind":"StatusRefreshed","status_instance_id":instance_id,
			"policy":policy,"stacks":int(old["stacks"]),
			"remaining_ticks":int(old["remaining_ticks"])})
	else:
		for prior: Dictionary in s["battle"]["statuses"]:
			if str(prior["status_instance_id"]) == instance_id:
				return _fail("M52_DUPLICATE_STATUS_INSTANCE_ID")
		s["battle"]["statuses"].append({
			"status_instance_id":instance_id,"status_id":status_id,
			"source_actor_id":source_actor_id,"target_actor_id":target_actor_id,
			"stacks":1,"remaining_ticks":int(d["duration_ticks"]),
			"applied_round":int(s["battle"]["round"]),
			"priority":int(d["priority"]),"tick_trigger":str(d["tick_trigger"]),
			"definition_version":str(config.get("m5_status_version","m5.2-provisional-v1")),
			"dispel_tags":d["dispel_tags"].duplicate(true)
		})
		records.append({"kind":"StatusApplied","status_instance_id":instance_id,
			"status_id":status_id,"target_actor_id":target_actor_id,
			"source_actor_id":source_actor_id,"stack_policy":policy,"stacks":1})
	if d["kind"] == "BARRIER":
		if not s["battle"].has("hp_barriers"):
			s["battle"]["hp_barriers"] = {}
		if policy != "REFRESH" or existing < 0:
			s["battle"]["hp_barriers"][target_actor_id] = float(d["barrier_amount"]) * \
				float(s["battle"]["statuses"][existing]["stacks"] if existing >= 0 else 1)
		records.append({"kind":"HPBarrierGranted","status_instance_id":instance_id,
			"target_actor_id":target_actor_id,
			"capacity":float(s["battle"]["hp_barriers"][target_actor_id])})
	if not validate(s,config):
		return _fail("M52_STATUS_INVARIANT_BROKEN")
	return {"ok":true,"core":s,"timeline":records}

static func dispel(core: Dictionary, target: String, tag: String,
		config: Dictionary) -> Dictionary:
	if tag.is_empty() or not core["battle"]["actors"].has(target):
		return _fail("M52_INVALID_DISPEL")
	var next: Dictionary = core.duplicate(true)
	var remain: Array = []
	var records: Array = []
	for status: Dictionary in next["battle"]["statuses"]:
		if status["target_actor_id"] == target and status["dispel_tags"].has(tag):
			var d: Dictionary = _definition(config,str(status["status_id"]))
			if d["kind"] == "BARRIER":
				next["battle"]["hp_barriers"].erase(target)
			records.append({"kind":"StatusDispelled","status_instance_id":status["status_instance_id"],
				"target_actor_id":target,"tag":tag})
		else:
			remain.append(status)
	next["battle"]["statuses"] = remain
	return {"ok":true,"core":next,"timeline":records}

static func _sort(a: Dictionary, b: Dictionary) -> bool:
	if int(a["priority"]) != int(b["priority"]):
		return int(a["priority"]) < int(b["priority"])
	return str(a["status_instance_id"]) < str(b["status_instance_id"])

static func tick(core: Dictionary, next_round: int, config: Dictionary,
		command_id: String, trigger: String = "NEXT_PLAYER_PHASE") -> Dictionary:
	if not ["NEXT_PLAYER_PHASE","ENEMY_PHASE_END"].has(trigger):
		return _fail("M52_INVALID_TICK_TRIGGER")
	if not validate(core,config):
		return _fail("M52_INVALID_STATUS_INSTANCES")
	var state: Dictionary = core.duplicate(true)
	var ordered: Array = state["battle"]["statuses"].duplicate(true)
	ordered.sort_custom(_sort)
	var remain: Array = []
	var timeline: Array = []
	for status: Dictionary in ordered:
		var target: String = str(status["target_actor_id"])
		var d: Dictionary = _definition(config,str(status["status_id"]))
		if str(status["tick_trigger"]) != trigger or int(status["applied_round"]) >= next_round:
			remain.append(status)
			continue
		timeline.append({"kind":"StatusTickStarted","status_instance_id":status["status_instance_id"],
			"status_id":status["status_id"],"target_actor_id":target,
			"priority":int(status["priority"]),"tick_round":next_round,
			"stacks":int(status["stacks"])})
		var kind: String = str(d["kind"])
		var hp: Dictionary = {}
		if kind == "DOT":
			hp = HP.dot(state,target,int(d["tick_amount"])*int(status["stacks"]),
				str(d["barrier_mode"]),config,command_id)
		elif kind == "HOT":
			if int(state["battle"]["actors"][target]["hp"]) > 0:
				hp = HP.heal(state,target,int(d["tick_amount"])*int(status["stacks"]))
		if not hp.is_empty():
			if not hp["ok"]:
				return _fail(str(hp["error"]))
			state = hp["core"]
			timeline.append_array(hp["timeline"])
		status["remaining_ticks"] = int(status["remaining_ticks"])-1
		if int(status["remaining_ticks"]) <= 0:
			if kind == "BARRIER" and state["battle"].get("hp_barriers",{}).has(target):
				var leftover: float = float(state["battle"]["hp_barriers"][target])
				state["battle"]["hp_barriers"].erase(target)
				timeline.append({"kind":"HPBarrierExpired","target_actor_id":target,
					"expired_capacity":leftover})
			timeline.append({"kind":"StatusExpired","status_instance_id":status["status_instance_id"],
				"target_actor_id":target})
		else:
			remain.append(status)
	state["battle"]["statuses"] = remain
	return {"ok":true,"core":state,"timeline":timeline}
