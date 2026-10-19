extends RefCounted
## Pure detached projection: the presentation must not mutate the authoritative
## BattleState, consume cards, roll RNG, or infer unseen Boss FSM decisions.

## Optional versioned content enables additive Lv40 fields while project(state)
## remains valid for the existing P4.3 fixture client.
static func project(state: Dictionary, config: Dictionary = {}) -> Dictionary:
	var core: Dictionary = state["core"]
	var battle: Dictionary = core["battle"]
	var cards: Dictionary = core["cards"]["actors"]
	var view: Dictionary = {"actors":battle["actors"].duplicate(true),
		"resources":battle["party_resources"].duplicate(true),
		"hands":cards.duplicate(true),
		"phase":str(state["phase"]), "round":int(battle["round"]),
		"outcome":str(battle["outcome"]), "event_seq":int(state["event_seq"]),
		"intent":state["published_intents"].duplicate(true),
		"reaction":state["reaction_window"].duplicate(true),
		"barriers":battle.get("hp_barriers",{}).duplicate(true),
		"casts":battle["casting_instances"].duplicate(true),
		"tactical":battle.get("m53",{}).duplicate(true),
		"actor_name_keys":{}, "hand_cards":{}, "public_intent_labels":[],
		"boss_cast_public":{}}
	for actor_id: String in view["actors"]:
		view["actors"][actor_id]["retired_from_field"] = bool(battle.get("retired_from_field_by_actor", {}).get(actor_id, false))
	if config.get("m5_lv40_enabled",false) != true:
		return view
	var name_keys: Dictionary = config.get("actor_name_keys",{})
	for id: String in battle["actors"]:
		var metadata: Dictionary = battle["actors"][id].get("meta",{})
		var fallback: String = str(metadata.get("name_key",""))
		if id == "Boss":
			fallback = str(config.get("boss_name_key",fallback))
		view["actor_name_keys"][id] = str(name_keys.get(id,fallback))
	# Export only names, target data and timing that were PUBLICLY committed;
	# never expose core.battle.lv40.pending_cast or other private FSM state.
	for published: Dictionary in state["published_intents"]:
		var item: Dictionary = {"enemy_id":str(published.get("enemy_id","")),
			"intent_id":str(published.get("intent_id","")),
			"skill_id":str(published.get("skill_id","")),
			"name_key":str(published.get("name_key",config.get("intent_name_keys",{}).get(str(published.get("skill_id","")),""))),
			"target_scope":str(published.get("target_scope","")),
			"target_ids":published.get("target_ids",[]).duplicate(true),
			"hit_count":int(published.get("hit_count",0)),
			"requires_reaction_window":bool(published.get("requires_reaction_window",false)),
			"windup_progress":int(published.get("windup_progress",0)),
			"expected_execute_phase":str(published.get("expected_execute_phase","")),
			"break_response":str(published.get("break_response","NOT_ELIGIBLE")),
			"break_fallback_skill_id":str(published.get("break_fallback_skill_id","")),
			"break_c_result":str(published.get("break_c_result",""))}
		view["public_intent_labels"].append(item)
		if str(item["enemy_id"]) == "Boss":
			view["boss_cast_public"] = {
				"casting_id":str(published.get("casting_id","")),
				"windup_progress":item["windup_progress"],
				"charge_release_skill":str(published.get("charge_release_skill","")),
				"expected_execute_phase":item["expected_execute_phase"]}
			# Only reveal Stability if the specific cast has a public id in
			# this phase's published release Intent. Never leak hidden plans.
			var public_cast_id: String = str(published.get("casting_id",""))
			var pending_cast: Dictionary = battle.get("lv40",{}).get("pending_cast",{})
			if not public_cast_id.is_empty() and \
					str(pending_cast.get("casting_id","")) == public_cast_id and \
					not bool(pending_cast.get("interrupted",false)):
				view["boss_cast_public"]["current_stability"] = int(pending_cast.get("current_stability",0))
				view["boss_cast_public"]["base_stability"] = int(pending_cast.get("base_stability",0))
				view["boss_cast_public"]["focus_ward"] = int(pending_cast.get("focus_ward",0))
	var catalogue: Dictionary = config.get("lv40_cards",{})
	var definitions: Dictionary = config.get("definitions",{})
	for actor: String in cards:
		var entries: Array = []
		var owned: Dictionary = cards[actor]
		for instance: Variant in owned.get("zones",{}).get("hand",[]):
			var instance_id: String = str(instance)
			var definition_id: String = str(owned.get("instances",{}).get(instance_id,{}).get("definition_id",""))
			var metadata: Dictionary = catalogue.get(definition_id,{})
			var cost: Dictionary = definitions.get(definition_id,{})
			entries.append({"actor_id":actor,"card_instance_id":instance_id,
				"definition_id":definition_id,
				"name_key":str(metadata.get("name_key","")),
				"description_key":str(metadata.get("description_key","")),
				"kind":str(metadata.get("kind","")),
				"casting_mode":str(metadata.get("mode","")),
				"ap_cost":cost.get("ap_cost",null),
				"mp_cost":cost.get("mp_cost",null)})
		view["hand_cards"][actor] = entries
	return view
