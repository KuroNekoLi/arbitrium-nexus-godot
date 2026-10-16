extends RefCounted
## V2 intent transaction. The supplied reducer is the existing Lv40 entry.
## No live snapshot, config or RNG is mutated, including failed candidates.
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const Cost = preload("res://scripts/domain/m2/economy/cost_resolver.gd")

static func recipes() -> Dictionary:
	return {
		"COMBO_REN_AKANE_01":{"setup":["R01","R07"],"finisher":["A06"],
			"name_key":"CP2_OFFENSE","opportunity":"OFFENSE","shared_target":true},
		"COMBO_REN_TSUMUGI_01":{"setup":["R08"],"finisher":["T04"],
			"name_key":"CP2_DEFENSE","opportunity":"DEFENSE","shared_target":false}}

static func definition(state: Dictionary, actor: String, card: String) -> String:
	return str(state.get("core",{}).get("cards",{}).get("actors",{}).get(actor,{}).get("instances",{}).get(card,{}).get("definition_id",""))

static func active(state: Dictionary, actor: String) -> bool:
	var battle: Dictionary = state.get("core",{}).get("battle",{})
	var unit: Dictionary = battle.get("actors",{}).get(actor,{})
	return battle.get("allies",[]).has(actor) and int(unit.get("hp",0)) > 0 and unit.get("status","") == "ACTIVE" and not bool(battle.get("retired_from_field_by_actor",{}).get(actor,false))

static func potentials(state: Dictionary, actor: String, card: String) -> Array:
	var result: Array = []
	if state.get("phase","") != "PLAYER_PHASE" or state["core"]["battle"]["outcome"] != "ONGOING" or not active(state,actor): return result
	var own: Dictionary = state["core"]["cards"]["actors"][actor]
	if not own["zones"]["hand"].has(card): return result
	var setup: String = definition(state,actor,card)
	var catalogue: Dictionary = recipes()
	for partner: String in state["core"]["battle"]["allies"]:
		if partner == actor or not active(state,partner): continue
		for instance: String in state["core"]["cards"]["actors"][partner]["zones"]["hand"]:
			for recipe: String in catalogue:
				if catalogue[recipe]["setup"].has(setup) and catalogue[recipe]["finisher"].has(definition(state,partner,instance)):
					result.append({"actor_id":partner,"card_instance_id":instance,"recipe_id":recipe,"name_key":catalogue[recipe]["name_key"]})
	return result

static func denied(state: Dictionary, error: String) -> Dictionary:
	return {"accepted":false,"error":error,"state":state.duplicate(true),"events":[],
		"state_hash":Model.state_hash(state),"event_hash":Model.event_hash([])}

static func card_command(state: Dictionary, id: String, actor: String, card: String, target: String, combo: bool) -> Dictionary:
	return {"type":"PLAY_LV40_CARD","command_id":id,"expected_event_seq":int(state["event_seq"]),
		"actor_id":actor,"card_instance_id":card,"target_actor_id":target,"casting_mode":"CHANTLESS","combo_mode":"COMBO" if combo else "NORMAL"}

static func quote(state: Dictionary, actor: String, card: String, config: Dictionary) -> Dictionary:
	return Cost.quote(state["core"]["battle"],{"actor_id":actor,"card":config["definitions"].get(definition(state,actor,card),{}),"casting_mode":"CHANTLESS"},config["costs"])

static func resolve(state: Dictionary, command: Dictionary, config: Dictionary, reducer: Callable) -> Dictionary:
	for key: String in command:
		if not ["type","command_id","expected_event_seq","setup_actor_id","setup_card_instance_id","setup_target_ids","finisher_actor_id","finisher_card_instance_id","finisher_target_ids","recipe_id"].has(key):
			return denied(state,"CP2_INVALID_PAYLOAD")
	for key: String in ["setup_target_ids","finisher_target_ids"]:
		if not command.get(key) is Array or command[key].size() != 1 or not command[key][0] is String:
			return denied(state,"CP2_TARGET_ANCHOR_REQUIRED")
	var a: String = str(command.get("setup_actor_id",""))
	var b: String = str(command.get("finisher_actor_id",""))
	var ac: String = str(command.get("setup_card_instance_id",""))
	var bc: String = str(command.get("finisher_card_instance_id",""))
	var rid: String = str(command.get("recipe_id",""))
	var registry: Dictionary = recipes()
	if a == b or ac == bc or not active(state,a) or not active(state,b): return denied(state,"CP2_ACTOR_UNAVAILABLE")
	if not registry.has(rid): return denied(state,"CP2_UNKNOWN_RECIPE")
	var recipe: Dictionary = registry[rid]
	if not recipe["setup"].has(definition(state,a,ac)) or not recipe["finisher"].has(definition(state,b,bc)):
		return denied(state,"CP2_RECIPE_MISMATCH")
	if recipe["shared_target"] and command["setup_target_ids"] != command["finisher_target_ids"]:
		return denied(state,"CP2_SHARED_TARGET_REQUIRED")
	var id: String = str(command["command_id"])
	var aq: Dictionary = quote(state,a,ac,config)
	var first: Dictionary = reducer.call(state.duplicate(true),card_command(state,id+":setup",a,ac,command["setup_target_ids"][0],false),config)
	if not first["accepted"]: return denied(state,"CP2_SETUP:"+str(first["error"]))
	var candidate: Dictionary = first["state"]
	if candidate["core"]["battle"]["outcome"] != "ONGOING": return denied(state,"CP2_SETUP_ENDED_BATTLE")
	var opportunity: Dictionary = candidate["core"]["battle"]["m53"]["combo"] if recipe["opportunity"] == "OFFENSE" else candidate["core"]["battle"]["lv40"]["defense_combo"]
	# Require a newly offered opportunity from this action, not a stale previous one.
	var offered: bool = false
	for event: Dictionary in first["events"]:
		if event["kind"] == "ComboOpportunityOffered": offered = true
	if recipe["opportunity"] == "DEFENSE":
		offered = definition(state,a,ac) == "R08" and opportunity.get("source_actor_id","") == a
	if not offered or opportunity.get("source_actor_id","") != a: return denied(state,"CP2_SETUP_NO_OPPORTUNITY")
	var bq: Dictionary = quote(candidate,b,bc,config)
	var second: Dictionary = reducer.call(candidate,card_command(candidate,id+":finisher",b,bc,command["finisher_target_ids"][0],true),config)
	if not second["accepted"]: return denied(state,"CP2_FINISHER:"+str(second["error"]))
	var executed: bool = false
	for event: Dictionary in second["events"]:
		if event["kind"] == "ComboExecuted": executed = true
	if not executed: return denied(state,"CP2_COMBO_NOT_EXECUTED")
	var next: Dictionary = second["state"]
	for event: Dictionary in second["events"]:
		if event["kind"] == "ComboExecuted":
			event["details"]["setup_actor_id"] = a
			event["details"]["recipe_id"] = rid
			event["details"]["name_key"] = recipe["name_key"]
	next["seen_command_ids"].append(id)
	var events: Array = first["events"].duplicate(true)
	events.append_array(second["events"])
	return {"accepted":true,"error":"","state":next,"events":events,"state_hash":Model.state_hash(next),
		"event_hash":Model.event_hash(events),"quotes":{"setup":aq,"finisher":bq,"extra_ap":0}}
