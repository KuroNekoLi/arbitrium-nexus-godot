extends RefCounted
## Isolated versioned test content; no approved retail balance implied.
const M51 = preload("res://tests/fixtures/m5_1_fixture.gd")
const Draw = preload("res://scripts/domain/m2/cards/draw_resolver.gd")
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const M2 = preload("res://scripts/domain/m2/integration/m2_domain_resolver.gd")
const Phase = preload("res://scripts/domain/m3/phase/phase_engine.gd")
const SEED: int = 20261014
const IDS: Array[String] = ["burn","regen","ward","rage","frail","heal","revive","purge","poison"]

static func config() -> Dictionary:
	var c: Dictionary = M51.config()
	c["m5_2_status_enabled"] = true
	c["m5_status_version"] = "m5.2-test-v1"
	c["m5_status_definitions"] = {
		"burn":{"kind":"DOT","stack_policy":"STACK","priority":10,
			"duration_ticks":2,"stack_cap":3,"tick_trigger":"NEXT_PLAYER_PHASE",
			"tick_amount":9,"barrier_mode":"ABSORB","dispel_tags":["NEGATIVE"]},
		"poison":{"kind":"DOT","stack_policy":"REPLACE","priority":2,
			"duration_ticks":2,"stack_cap":1,"tick_trigger":"NEXT_PLAYER_PHASE",
			"tick_amount":120,"barrier_mode":"BYPASS","dispel_tags":["NEGATIVE"]},
		"regen":{"kind":"HOT","stack_policy":"REFRESH","priority":20,
			"duration_ticks":2,"stack_cap":1,"tick_trigger":"NEXT_PLAYER_PHASE",
			"tick_amount":6,"dispel_tags":["POSITIVE"]},
		"ward":{"kind":"BARRIER","stack_policy":"REPLACE","priority":30,
			"duration_ticks":2,"stack_cap":1,"tick_trigger":"NEXT_PLAYER_PHASE",
			"tick_amount":0,"barrier_amount":10,"dispel_tags":["POSITIVE"]},
		"rage":{"kind":"BUFF","stack_policy":"REFRESH","priority":30,
			"duration_ticks":2,"stack_cap":1,"tick_trigger":"NEXT_PLAYER_PHASE",
			"tick_amount":0,"stat_id":"patk","stat_delta":14,"dispel_tags":["POSITIVE"]},
		"frail":{"kind":"DEBUFF","stack_policy":"IGNORE","priority":30,
			"duration_ticks":2,"stack_cap":1,"tick_trigger":"NEXT_PLAYER_PHASE",
			"tick_amount":0,"stat_id":"pdef","stat_delta":-10,"dispel_tags":["NEGATIVE"]}}
	c["m5_status_sp_effects"] = {
		"burn":{"kind":"STATUS","status_id":"burn","target_team":"ENEMY"},
		"poison":{"kind":"STATUS","status_id":"poison","target_team":"ANY"},
		"regen":{"kind":"STATUS","status_id":"regen","target_team":"ALLY"},
		"ward":{"kind":"STATUS","status_id":"ward","target_team":"ALLY"},
		"rage":{"kind":"STATUS","status_id":"rage","target_team":"ALLY"},
		"frail":{"kind":"STATUS","status_id":"frail","target_team":"ENEMY"},
		"heal":{"kind":"HEAL","amount":20,"target_team":"ALLY"},
		"revive":{"kind":"REVIVE","revive_tag":true,"restored_hp":35,"target_team":"ALLY"},
		"purge":{"kind":"DISPEL","dispel_tag":"NEGATIVE","target_team":"ANY"}}
	for id: String in IDS:
		c["definitions"][id] = {"card_id":id,"ap_cost":1,"mp_cost":1}
	c["m5_enemy_on_hit_status"] = {"boss_strike":{
		"status_id":"burn","follows_damage_recipient":true}}
	return c

static func initial(seed: int = SEED, actor_cards: Dictionary = {}) -> Dictionary:
	var choices: Dictionary = {"A":"burn","B":"ward","C":"regen"}
	for k: Variant in actor_cards:
		choices[k] = actor_cards[k]
	var loadout: Dictionary = {}
	var contexts: Dictionary = {}
	var owned: Dictionary = {}
	var catalogue: Dictionary = {}
	for id: String in IDS:
		catalogue[id] = {"id":id,"kind":"SP"}
	for actor: String in ["A","B","C"]:
		var d: Array = []
		for i: int in range(12):
			d.append(str(choices[actor]))
		loadout[actor] = d
		contexts[actor] = {"actor_id":actor,"variant_id":"default","tags":[]}
		owned[actor] = {str(choices[actor]):12}
	var cards: Dictionary = Draw.start_battle(loadout,contexts,catalogue,owned,seed)
	if not cards["accepted"]:
		return {}
	var core: Dictionary = Model.make_state(["A","B","C"],["Boss"],seed)
	for actor: String in ["A","B","C"]:
		core["actors"][actor]["mp"] = 10
		core["actors"][actor]["max_mp"] = 10
	var published: Array = [{
		"intent_id":"boss-status-attack","enemy_id":"Boss",
		"action_order":1,"created_seq":0,"publicly_declared":true,
		"target_scope":"SINGLE","target_ids":["A"],"hit_count":2,
		"skill_id":"boss_strike","damage_type":"PHYSICAL",
		"requires_reaction_window":true}]
	return Phase.make_state(M2.make_state(core,cards["state"]),published)
