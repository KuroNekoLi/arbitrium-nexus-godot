extends RefCounted
## One Lv40 encounter, assembled from the versioned roster and M1–M5 Domain.
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const Draw = preload("res://scripts/domain/m2/cards/draw_resolver.gd")
const M2 = preload("res://scripts/domain/m2/integration/m2_domain_resolver.gd")
const Phase = preload("res://scripts/domain/m3/phase/phase_engine.gd")
const Boss = preload("res://scripts/domain/m5/lv40/lv40_boss.gd")
const Content = preload("res://scripts/domain/m5/lv40/lv40_content.gd")
const Roster = preload("res://scripts/domain/m5/lv40/lv40_party_catalog.gd")
const VERSION: String = "lv40-starter-v0.3-boss-v0.2-A-provisional-2"

static func party_ids() -> Array[String]:
	return Roster.party_ids()

static func loadouts() -> Dictionary:
	return Roster.loadouts()

static func characters() -> Dictionary:
	return Roster.characters()

static func variants() -> Dictionary:
	return Roster.variants()

static func config() -> Dictionary:
	return Content.config(VERSION)

static func initial(seed: int = 20261014) -> Dictionary:
	if seed <= 0:
		return {}
	var roster: Dictionary = Roster.read()
	if roster.is_empty():
		return {}
	var c: Dictionary = config()
	if c.is_empty():
		return {}
	var ids: Array[String] = Roster.party_ids(roster)
	var loadout: Dictionary = Roster.loadouts(roster)
	var contexts: Dictionary = {}
	var owned: Dictionary = {}
	var catalogue: Dictionary = {}
	for actor: String in ids:
		var definition: Dictionary = roster["actors"][actor]
		contexts[actor] = {"actor_id":actor,"character_id":definition["character_id"],
			"variant_id":definition["variant_id"],"tags":definition["role_tags"].duplicate()}
		owned[actor] = {}
		for card: String in loadout[actor]:
			if not c["lv40_cards"].has(card) or not c["lv40_card_eligibility"].has(card) or not Roster.eligible(c["lv40_card_eligibility"][card],
					str(definition["character_id"]), definition["role_tags"]):
				return {}
			owned[actor][card] = int(owned[actor].get(card, 0)) + 1
			catalogue[card] = {"id":card,"kind":"SP"}
	var dealt: Dictionary = Draw.start_battle(loadout,contexts,catalogue,owned,seed)
	if not dealt["accepted"]:
		return {}
	var battle: Dictionary = Model.make_state(ids,["Boss"],seed)
	var all_ids: Array[String] = ids.duplicate()
	all_ids.append("Boss")
	for actor: String in all_ids:
		var stats: Dictionary = c["lv40_actor_definitions"][actor]
		battle["actors"][actor]["hp"] = stats["max_hp"]
		battle["actors"][actor]["max_hp"] = stats["max_hp"]
		if actor != "Boss":
			battle["actors"][actor]["mp"] = stats["max_mp"]
			battle["actors"][actor]["max_mp"] = stats["max_mp"]
		battle["actors"][actor]["meta"] = stats.duplicate(true)
	var core: Dictionary = M2.make_state(battle,dealt["state"])
	var prepared: Dictionary = Boss.initialize(core,c)
	return Phase.make_state(prepared["core"],[prepared["intent"]])
