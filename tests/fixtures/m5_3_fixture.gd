extends RefCounted
## M5.3 fixture only. No canonical card power or Boss balance.
const Prior = preload("res://tests/fixtures/m5_2_fixture.gd")
const M51 = preload("res://tests/fixtures/m5_1_fixture.gd")
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const Draw = preload("res://scripts/domain/m2/cards/draw_resolver.gd")
const M2 = preload("res://scripts/domain/m2/integration/m2_domain_resolver.gd")
const Phase = preload("res://scripts/domain/m3/phase/phase_engine.gd")
const SEED: int = 20261014
const CARDS: Array[String] = ["setup","finish","blank","break_only"]

static func config() -> Dictionary:
	var c: Dictionary = Prior.config()
	c["m5_3_enabled"] = true
	c["m5_3_content_version"] = "m5.3-provisional-v1"
	for key: String in CARDS:
		c["definitions"][key] = {"card_id":key,"ap_cost":1,"mp_cost":1}
	var setup_profile: Dictionary = M51.profile("PHYSICAL","GUARANTEED",2)
	var finish_profile: Dictionary = M51.profile("MAGICAL","GUARANTEED",1)
	var blank_profile: Dictionary = M51.profile("PHYSICAL","GUARANTEED",1)
	c["m5_3_sp_effects"] = {
		"setup":{"damage_profile":setup_profile,"break_damage":9,
			"create_exposed":true,"creates_combo_tags":["FIRE"]},
		"finish":{"damage_profile":finish_profile,"break_damage":1,
			"consume_exposed":true,"exposed_bonus_break":2,
			"tags":["FIRE"],"combo_bonus_profile":M51.profile("MAGICAL","GUARANTEED",1),
			"combo_bonus_break":2},
		"blank":{"damage_profile":blank_profile,"break_damage":0},
		"break_only":{"damage_profile":setup_profile,"break_damage":9}}
	c["m5_enemy_profiles"]["boss_fallback"] = M51.profile("PHYSICAL","GUARANTEED",1)
	c["m5_3_boss"] = {"boss_id":"Boss","break_max":9,
		"fallback_skill_id":"boss_fallback",
		"skills":{
			"boss_strike":{"priority":10,"target_strategy":"FIRST_ACTIVE",
				"is_protectable":true},
			"boss_fallback":{"priority":-1,"target_strategy":"LOWEST_HP",
				"is_protectable":true}
		}}
	return c

static func initial(seed: int = SEED, choices: Dictionary = {}) -> Dictionary:
	var by_actor: Dictionary = {"A":"setup","B":"finish","C":"blank"}
	for k: Variant in choices:
		by_actor[k] = choices[k]
	var decks: Dictionary = {}
	var contexts: Dictionary = {}
	var owned: Dictionary = {}
	var catalogue: Dictionary = {}
	for card_id: String in CARDS:
		catalogue[card_id] = {"id":card_id,"kind":"SP"}
	for actor: String in ["A","B","C"]:
		if not CARDS.has(str(by_actor[actor])):
			return {}
		var deck: Array = []
		for i: int in range(12):
			deck.append(str(by_actor[actor]))
		decks[actor] = deck
		contexts[actor] = {"actor_id":actor,"variant_id":"default","tags":[]}
		owned[actor] = {str(by_actor[actor]):12}
	var cards: Dictionary = Draw.start_battle(decks,contexts,catalogue,owned,seed)
	if not cards["accepted"]:
		return {}
	var core: Dictionary = Model.make_state(["A","B","C"],["Boss"],seed)
	for actor: String in ["A","B","C"]:
		core["actors"][actor]["mp"] = 10
		core["actors"][actor]["max_mp"] = 10
	var published: Array = [{"intent_id":"bootstrap-m53","enemy_id":"Boss",
		"action_order":1,"created_seq":0,"publicly_declared":true,
		"target_scope":"SINGLE","target_ids":["A"],"hit_count":2,
		"skill_id":"boss_strike","damage_type":"PHYSICAL",
		"requires_reaction_window":true}]
	return Phase.make_state(M2.make_state(core,cards["state"]),published)
