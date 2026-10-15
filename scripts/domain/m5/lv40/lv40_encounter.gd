extends RefCounted
## Lv40 content composition; uses the existing M1 state, M2 cards and M3 envelope.
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const Draw = preload("res://scripts/domain/m2/cards/draw_resolver.gd")
const M2 = preload("res://scripts/domain/m2/integration/m2_domain_resolver.gd")
const Phase = preload("res://scripts/domain/m3/phase/phase_engine.gd")
const Boss = preload("res://scripts/domain/m5/lv40/lv40_boss.gd")
const Content = preload("res://scripts/domain/m5/lv40/lv40_content.gd")
const VERSION: String = "lv40-starter-v0.3-boss-v0.2-A-provisional-1"
const LOADOUTS: Dictionary = {
	"A":["U01","U02","U03","U04","U05","R01","R02","R03","R05","R06","R07","R08"],
	"B":["U01","U02","U03","U04","U05","A01","A02","A03","A04","A05","A06","A07"],
	"C":["U01","U02","U03","U04","U05","T01","T03","T04","T05","T06","T09","T10"]}
const CHARACTERS: Dictionary = {"A":"ren","B":"akane","C":"tsumugi"}
const VARIANTS: Dictionary = {"A":"ren_swordsman_v1","B":"akane_burst_mage_v1","C":"tsumugi_healer_v1"}

static func config() -> Dictionary:
	return Content.config(VERSION)

static func initial(seed: int = 20261014) -> Dictionary:
	if seed <= 0:
		return {}
	var c: Dictionary = config()
	var contexts: Dictionary = {}
	var owned: Dictionary = {}
	var catalogue: Dictionary = {}
	for actor: String in LOADOUTS:
		contexts[actor] = {"actor_id":actor,"character_id":CHARACTERS[actor],
			"variant_id":VARIANTS[actor],"tags":[]}
		owned[actor] = {}
		for card: String in LOADOUTS[actor]:
			owned[actor][card] = 1
			catalogue[card] = {"id":card,"kind":"SP"}
	var dealt: Dictionary = Draw.start_battle(LOADOUTS,contexts,catalogue,owned,seed)
	if not dealt["accepted"]:
		return {}
	var battle: Dictionary = Model.make_state(["A","B","C"],["Boss"],seed)
	for actor: String in ["A","B","C","Boss"]:
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
