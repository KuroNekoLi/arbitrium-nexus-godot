extends RefCounted
## M5.5 encounter ONLY; no retail content/balance approval.
## Three *heterogeneous* independently shuffled 12-card decks; actual
## battle begins in round one with every ally ACTIVE and full Boss HP.
const Previous = preload("res://tests/fixtures/m5_4_fixture.gd")
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const Draw = preload("res://scripts/domain/m2/cards/draw_resolver.gd")
const M2 = preload("res://scripts/domain/m2/integration/m2_domain_resolver.gd")
const Phase = preload("res://scripts/domain/m3/phase/phase_engine.gd")
const SEED: int = 20261014
const CONTENT_VERSION: String = "m5.5-three-party-boss-fixture-v1"
const MAX_ROUNDS: int = 32
const ACTORS: Array[String] = ["A","B","C"]
const LOADOUTS: Dictionary = {
	"A":{"setup":9,"burn":3},
	"B":{"finish":9,"ward":3},
	"C":{"regular":9,"regen":3}
}

static func config() -> Dictionary:
	var c: Dictionary = Previous.config()
	# M5.4 recoil is required in M5.4 independent fixtures only. It is
	# NOT an approved retail property of M5.5 starter skills.
	c["m5_3_sp_effects"]["setup"].erase("recoil_hp")
	c["m5_3_sp_effects"]["setup"].erase("recoil_barrier_mode")
	c["m5_4_last_release_recoil"] = {}
	c["m5_5_content_version"] = CONTENT_VERSION
	c["m5_actor_stats"]["Boss"]["patk"] = 3
	c["m5_actor_stats"]["Boss"]["matk"] = 3
	c["m5_enemy_on_hit_status"] = {}
	c["m5_balance"]["variance_bp"] = 500
	c["m5_basic_attack_profile"]["hit_mode"] = "RANDOM_PERCENT"
	c["m5_basic_attack_profile"]["crit_eligible"] = true
	c["m5_actor_stats"]["B"]["crit_rate_bp"] = 1600
	c["m5_3_sp_effects"]["setup"]["damage_profile"]["hit_mode"] = "GUARANTEED"
	c["m5_3_sp_effects"]["finish"]["damage_profile"]["hit_mode"] = "GUARANTEED"
	c["m5_enemy_profiles"]["boss_strike"]["hit_mode"] = "RANDOM_PERCENT"
	c["m5_enemy_profiles"]["boss_fallback"]["hit_mode"] = "RANDOM_PERCENT"
	# A's Last Spell remains the original approved M4 legal independent
	# slot. Neither Combo nor status may give it free cost.
	return c

static func initial(seed: int = SEED) -> Dictionary:
	if seed <= 0:
		return {}
	var decks: Dictionary = {}
	var contexts: Dictionary = {}
	var ownership: Dictionary = {}
	var catalogue: Dictionary = {}
	var c: Dictionary = config()
	for actor: String in ACTORS:
		var list: Array = []
		var owned: Dictionary = {}
		for skill: Variant in LOADOUTS[actor]:
			var id: String = str(skill)
			owned[id] = int(LOADOUTS[actor][id])
			catalogue[id] = {"id":id,"kind":"SP"}
			for _j: int in range(int(LOADOUTS[actor][id])):
				list.append(id)
		if list.size() != 12:
			return {}
		decks[actor] = list
		ownership[actor] = owned
		contexts[actor] = {"actor_id":actor,"variant_id":"m55-test",
			"tags":["TEST_FIXTURE_ONLY"]}
	var shuffled: Dictionary = Draw.start_battle(decks,contexts,catalogue,ownership,seed)
	if not shuffled["accepted"]:
		return {}
	var battle: Dictionary = Model.make_state(ACTORS,["Boss"],seed)
	if battle.is_empty():
		return {}
	for actor: String in ACTORS:
		battle["actors"][actor]["mp"] = 10
		battle["actors"][actor]["max_mp"] = 10
	battle["actors"]["Boss"]["hp"] = 290
	battle["actors"]["Boss"]["max_hp"] = 290
	var published: Array = [{"intent_id":"m55-bootstrap","enemy_id":"Boss",
		"action_order":1,"created_seq":0,"publicly_declared":true,
		"target_scope":"SINGLE","target_ids":["A"],"hit_count":2,
		"skill_id":"boss_strike","damage_type":"PHYSICAL",
		"requires_reaction_window":true}]
	return Phase.make_state(M2.make_state(battle,shuffled["state"]),published)
