extends RefCounted
## docs25/26/27 with docs29 candidate A. Every numeric value is provisional.
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const Roster = preload("res://scripts/domain/m5/lv40/lv40_party_catalog.gd")

static func profile(kind: String, multiplier: int, hits: int = 1,
		mode: String = "GUARANTEED", element: String = "NEUTRAL") -> Dictionary:
	return {"damage_kind":kind,"skill_multiplier_bp":multiplier,"flat_bonus":0,
		"hit_count":hits,"hit_mode":mode,"crit_eligible":kind == "PHYSICAL",
		"element_id":element}

static func config(version: String) -> Dictionary:
	var roster: Dictionary = Roster.read()
	if roster.is_empty():
		return {}
	var costs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://resources/combat/rulesets/m2_2_provisional_costs.json"))
	var economy: Dictionary = costs.duplicate(true)
	economy["basic_attack_ap_cost"] = 1
	economy["basic_attack_mp_gain"] = 2
	var c: Dictionary = {"m5_lv40_enabled":true,"m5_lv40_content_version":version,
		"content_version":version,"authority":"BALANCE_PROVISIONAL",
		"costs":costs,"resources":economy,"trigger_rules":[],
		"m5_damage_enabled":true,"m5_balance_authority":"BALANCE_PROVISIONAL",
		"m5_2_status_enabled":true,"m5_3_enabled":true,"m5_4_outcome_enabled":true,
		"m4_dual_cast_enabled":true,"m4_2_internal_refund":true,
		"m5_balance":{"defense_k":200,"variance_bp":500,"guard_reduction_bp":4000,
			"base_hit_bp":8500,"accuracy_step_bp":20},
		"definitions":{},"lv40_cards":{},"casting_profiles":{},
		"m5_spell_profiles":{},"m5_3_sp_effects":{},"m5_status_definitions":{},
		"m5_status_version":version,"m5_enemy_on_hit_status":{},
		"last_spell_slots":{},"last_spell_cost_definitions":{},
		"last_spell_instability":{"authority":"BALANCE_PROVISIONAL","stability_reset":10,
			"weaken_numerator":4,"weaken_denominator":5},
		"casting_interrupt_refund":{"authority":"BALANCE_PROVISIONAL","numerator":1,
			"denominator":2,"rounding":"FLOOR_FIXTURE"},
		"m5_4_last_release_recoil":{},
		"m5_3_boss":{"boss_id":"Boss","break_max":22,"fallback_skill_id":"B11"}}
	c["m5_actor_stats"] = {}
	c["lv40_actor_definitions"] = {}
	c["m5_element_resistance"] = {}
	var party_ids: Array[String] = Roster.party_ids(roster)
	var all_actors: Array[String] = party_ids.duplicate()
	all_actors.append("Boss")
	for actor: String in all_actors:
		var r: Dictionary = roster["boss"] if actor == "Boss" else roster["actors"][actor]
		c["m5_actor_stats"][actor] = {"patk":int(r["patk"]),"matk":int(r["matk"]),
			"pdef":int(r["pdef"]),"mdef":int(r["mdef"]),
			"accuracy":int(r["accuracy"]),"evasion":int(r["evasion"]),
			"crit_rate_bp":int(r["crit_rate_bp"]),"crit_bonus_bp":int(r["crit_bonus_bp"])}
		c["lv40_actor_definitions"][actor] = {"max_hp":int(r["max_hp"]),"max_mp":int(r["max_mp"]),
			"character_id":str(r["character_id"]),"name_key":str(r["name_key"]),"level":40}
		c["m5_element_resistance"][actor] = {"NEUTRAL":10000,"FIRE":11500 if actor == "Boss" else 10000,
			"ARCANE":9000 if actor == "Boss" else 10000}
	c["m5_basic_attack_profile"] = profile("PHYSICAL",10000,1,"RANDOM_PERCENT")
	var card_owners: Dictionary = {}
	for active_actor: String in party_ids:
		for assigned_card: String in roster["actors"][active_actor]["loadout"]:
			if assigned_card.begins_with("U"):
				continue
			if card_owners.has(assigned_card) and card_owners[assigned_card] != active_actor:
				card_owners[assigned_card] = "*"
			elif not card_owners.has(assigned_card):
				card_owners[assigned_card] = active_actor
	var prices: Dictionary = {"U01":[1,2],"U02":[1,2],"U03":[1,1],"U04":[1,0],"U05":[1,2],
		"R01":[1,0],"R02":[2,0],"R03":[1,1],"R05":[0,1],"R06":[2,2],"R07":[1,1],"R08":[1,2],
		"A01":[1,2],"A02":[2,4],"A03":[1,1],"A04":[2,5],"A05":[1,2],"A06":[2,5],"A07":[1,3],
		"T01":[1,2],"T03":[2,4],"T04":[1,2],"T05":[0,2],"T06":[2,4],"T09":[1,2],"T10":[1,3]}
	for card: String in prices:
		c["definitions"][card] = {"card_id":card,"ap_cost":prices[card][0],"mp_cost":prices[card][1]}
		c["lv40_cards"][card] = {"name_key":"LV40_"+card+"_NAME",
			"description_key":"LV40_"+card+"_DESC",
			"owner":"*" if card.begins_with("U") else str(card_owners.get(card, "")),
			"kind":"SUPPORT","mode":"INSTANT"}
	var magic: Dictionary = {"U01":[8500,14500,"ARCANE"],"A01":[10000,16500,"FIRE"],
		"A02":[6800,11500,"FIRE"],"A04":[14500,21500,"FIRE"],
		"A06":[15500,23500,"FIRE"],"A07":[6500,6500,"FIRE"],
		"T09":[9000,14000,"NEUTRAL"],"T10":[8000,8000,"NEUTRAL"]}
	for card: String in magic:
		var r: Array = magic[card]
		c["lv40_cards"][card].merge({"kind":"MAGIC","mode":"DUAL" if r[0] != r[1] else "INSTANT",
			"chantless_profile":profile("MAGICAL",r[0],1,"GUARANTEED",r[2]),
			"full_profile":profile("MAGICAL",r[1],1,"GUARANTEED",r[2])},true)
		c["m5_spell_profiles"][card] = profile("MAGICAL",r[0],1,"GUARANTEED",r[2])
		c["casting_profiles"][card] = {"spell_id":card,"allowed_modes":["CHANTLESS","FULL"],"base_stability":9 if card.begins_with("A") else 12}
	var physical: Dictionary = {"R01":[10000,1,6],"R02":[7200,2,0],"R03":[11500,1,0],
		"R06":[17500,1,5],"R07":[7500,1,0]}
	for card: String in physical:
		var r: Array = physical[card]
		c["lv40_cards"][card]["kind"] = "PHYSICAL"
		c["m5_3_sp_effects"][card] = {"damage_profile":profile("PHYSICAL",r[0],r[1],"RANDOM_PERCENT"),"break_damage":r[2]}
	for card: String in ["U05","T01","T03","T06"]:
		c["lv40_cards"][card]["kind"] = "HEAL"
	for card: String in ["R05","T05"]:
		c["lv40_cards"][card]["kind"] = "REACTION"
	c["reaction_definitions"] = {
		"R05":{"kind":"REACTION_SP","reaction_trigger":"ENEMY_ACTION","rp_cost":2,"mp_cost":1,
			"fixture_effect":"LV40_PROTECT_COUNTER","target_scope":"SINGLE","requires_active_enemy_action":true},
		"T05":{"kind":"REACTION_SP","reaction_trigger":"ENEMY_ACTION","rp_cost":1,"mp_cost":2,
			"fixture_effect":"LV40_BARRIER","target_scope":"SINGLE","requires_active_enemy_action":true}}
	c["m5_status_definitions"]["SCORCH_TEST"] = {"kind":"DOT","stack_policy":"REFRESH","priority":10,
		"duration_ticks":2,"stack_cap":1,"tick_trigger":"ENEMY_PHASE_END","tick_amount":45,
		"barrier_mode":"ABSORB","dispel_tags":["CLEANSE_FIRE","DISPELLABLE"]}
	c["m5_enemy_profiles"] = {}
	var bosses: Dictionary = {"B01":["PHYSICAL",13500,1],"B02":["PHYSICAL",8000,2],
		"B03":["MAGICAL",13500,1],"B04":["MAGICAL",10500,1],
		"B06":["MAGICAL",23500,1],"B09":["MAGICAL",15000,1],"B11":["PHYSICAL",6000,1]}
	for skill: String in bosses:
		var r: Array = bosses[skill]
		var p: Dictionary = profile(r[0],r[1],r[2],"GUARANTEED" if ["B06","B09"].has(skill) else "RANDOM_PERCENT")
		p["crit_eligible"] = false
		c["m5_enemy_profiles"][skill] = p
	for actor: String in party_ids:
		var actor_data: Dictionary = roster["actors"][actor]
		var spell: String = str(actor_data["last_spell_id"])
		c["last_spell_slots"][actor] = {"spell_id":spell,"unlocked":true,
			"planned_delay_rounds":2,"base_stability":10}
		c["last_spell_cost_definitions"][spell] = {"card_id":spell,
			"ap_cost":3,"mp_cost":int(actor_data["last_spell_mp_cost"])}
		c["m5_spell_profiles"][spell] = profile("PHYSICAL" if spell == "LS_REN_SWORD_V1" else "MAGICAL",
			65000 if spell == "LS_REN_SWORD_V1" else 68000,1,
			"RANDOM_PERCENT" if spell == "LS_REN_SWORD_V1" else "GUARANTEED",
			"FIRE" if spell == "LS_AKANE_MAGE_V1" else "NEUTRAL")
	c["last_spell_targeting"] = {
		"LS_REN_SWORD_V1":{"team":"ENEMY","scope":"SINGLE","description_key":"LAST_REN_DESCRIPTION","artwork_path":"res://assets/ui/v35/cmd_basic.svg"},
		"LS_AKANE_MAGE_V1":{"team":"ENEMY","scope":"ALL","description_key":"LAST_AKANE_DESCRIPTION","appearance_id":"A06"},
		"LS_TSUMUGI_HEAL_V1":{"team":"ALLY","scope":"ALL","description_key":"LAST_TSUMUGI_DESCRIPTION","artwork_path":"res://assets/ui/v35/status_barrier.svg"}}
	c["actorDisplayNames"] = {}
	c["actor_name_keys"] = {}
	for actor: String in party_ids:
		c["actorDisplayNames"][actor] = str(roster["actors"][actor].get("display_zh", actor))
		c["actor_name_keys"][actor] = str(roster["actors"][actor]["name_key"])
	c["bossname"] = str(roster["boss"]["display_zh"])
	c["boss_name_key"] = str(roster["boss"]["name_key"])
	c["intent_name_keys"] = {}
	for index: int in range(1,12):
		var skill: String = "B%02d" % index
		c["intent_name_keys"][skill] = "intent."+skill.to_lower()+".name"
	for card: String in c["lv40_cards"]:
		var data: Dictionary = c["lv40_cards"][card]
		c["definitions"][card].merge({"type":data["kind"],"dualMode":data["mode"] == "DUAL",
			"namekey":data["name_key"],"descriptionkey":data["description_key"]})
		data.merge({"type":data["kind"],"dualMode":data["mode"] == "DUAL",
			"namekey":data["name_key"],"descriptionkey":data["description_key"]})
	for actor: String in c["actor_name_keys"]:
		c["lv40_actor_definitions"][actor]["name_key"] = c["actor_name_keys"][actor]
	c["lv40_actor_definitions"]["Boss"]["name_key"] = c["boss_name_key"]
	return c
