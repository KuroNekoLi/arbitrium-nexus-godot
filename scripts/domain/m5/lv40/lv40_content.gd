extends RefCounted
## docs25/26/27 with docs29 candidate A. Every numeric value is provisional.
const Model = preload("res://scripts/domain/m1/combat_model.gd")

static func profile(kind: String, multiplier: int, hits: int = 1,
		mode: String = "GUARANTEED", element: String = "NEUTRAL") -> Dictionary:
	return {"damage_kind":kind,"skill_multiplier_bp":multiplier,"flat_bonus":0,
		"hit_count":hits,"hit_mode":mode,"crit_eligible":kind == "PHYSICAL",
		"element_id":element}

static func config(version: String) -> Dictionary:
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
	var rows: Dictionary = {
		"A":[1500,8,135,70,110,90,105,95,1000],
		"B":[950,14,60,175,65,85,95,90,800],
		"C":[1200,12,55,105,80,110,95,95,500],
		"Boss":[2700,0,417,434,90,85,105,90,0]}
	c["m5_actor_stats"] = {}
	c["lv40_actor_definitions"] = {}
	c["m5_element_resistance"] = {}
	for actor: String in rows:
		var r: Array = rows[actor]
		c["m5_actor_stats"][actor] = {"patk":r[2],"matk":r[3],"pdef":r[4],"mdef":r[5],
			"accuracy":r[6],"evasion":r[7],"crit_rate_bp":r[8],"crit_bonus_bp":5000}
		c["lv40_actor_definitions"][actor] = {"max_hp":r[0],"max_mp":r[1],
			"character_id":{"A":"ren","B":"akane","C":"tsumugi","Boss":"TEST_BOSS_ARCANE_SENTRY"}[actor],
			"name_key":"actor."+actor.to_lower()+".name","level":40}
		c["m5_element_resistance"][actor] = {"NEUTRAL":10000,"FIRE":11500 if actor == "Boss" else 10000,
			"ARCANE":9000 if actor == "Boss" else 10000}
	c["m5_basic_attack_profile"] = profile("PHYSICAL",10000,1,"RANDOM_PERCENT")
	var prices: Dictionary = {"U01":[1,2],"U02":[1,2],"U03":[1,1],"U04":[1,0],"U05":[1,2],
		"R01":[1,0],"R02":[2,0],"R03":[1,1],"R05":[0,1],"R06":[2,2],"R07":[1,1],"R08":[1,2],
		"A01":[1,2],"A02":[2,4],"A03":[1,1],"A04":[2,5],"A05":[1,2],"A06":[2,5],"A07":[1,3],
		"T01":[1,2],"T03":[2,4],"T04":[1,2],"T05":[0,2],"T06":[2,4],"T09":[1,2],"T10":[1,3]}
	for card: String in prices:
		c["definitions"][card] = {"card_id":card,"ap_cost":prices[card][0],"mp_cost":prices[card][1]}
		c["lv40_cards"][card] = {"name_key":"card."+card.to_lower()+".name",
			"description_key":"card."+card.to_lower()+".description",
			"owner":"*" if card.begins_with("U") else {"R":"A","A":"B","T":"C"}[card.left(1)],
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
	for actor: String in ["A","B","C"]:
		var spell: String = {"A":"LS_REN_SWORD_V1","B":"LS_AKANE_MAGE_V1","C":"LS_TSUMUGI_HEAL_V1"}[actor]
		c["last_spell_slots"][actor] = {"spell_id":spell,"unlocked":true,"planned_delay_rounds":2,"base_stability":10}
		c["last_spell_cost_definitions"][spell] = {"card_id":spell,"ap_cost":3,"mp_cost":{"A":5,"B":9,"C":7}[actor]}
		c["m5_spell_profiles"][spell] = profile("PHYSICAL" if actor == "A" else "MAGICAL",
			65000 if actor == "A" else 68000,1,"RANDOM_PERCENT" if actor == "A" else "GUARANTEED","FIRE" if actor == "B" else "NEUTRAL")
	c["actorDisplayNames"] = {"A":"朝霧蓮","B":"九條朱音","C":"白石紬"}
	c["actor_name_keys"] = {"A":"actor.ren.name","B":"actor.akane.name","C":"actor.tsumugi.name"}
	c["bossname"] = "秘紋守衛・零式"
	c["boss_name_key"] = "actor.arcane_sentry.name"
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
