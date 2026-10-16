extends RefCounted
## Explicit QA fixture only: exchange owned instances between zones, never
## synthesize extra cards or alter the playable encounter's default seed/deal.
const Encounter = preload("res://scripts/domain/m5/lv40/lv40_encounter.gd")
const Factory = preload("res://scripts/battle/battle_command_factory.gd")

static func in_hand(state: Dictionary, actor: String, definition: String) -> String:
	var cards: Dictionary = state["core"]["cards"]["actors"][actor]
	for id: String in cards["instances"]:
		if cards["instances"][id]["definition_id"] != definition: continue
		if cards["zones"]["hand"].has(id): return id
		for zone: String in ["draw","discard"]:
			if cards["zones"][zone].has(id):
				var old: String = cards["zones"]["hand"].pop_back()
				cards["zones"][zone].erase(id)
				cards["zones"][zone].append(old)
				cards["zones"]["hand"].append(id)
				return id
	return ""

static func make(offense: bool = false, seed: int = 20261014) -> Dictionary:
	var state: Dictionary = Encounter.initial(seed)
	var a: String = in_hand(state,"A","R01" if offense else "R08")
	var b: String = in_hand(state,"B" if offense else "C","A06" if offense else "T04")
	if offense: state["core"]["battle"]["lv40"]["core_open"] = true
	return {"state":state,"config":Encounter.config(),"setup":a,"finisher":b,"partner":"B" if offense else "C"}

static func command(rig: Dictionary) -> Dictionary:
	var offense: bool = rig["partner"] == "B"
	return Factory.build(rig["state"],"COMMIT_PREPARED_COMBO_V2",{
		"setup_actor_id":"A","setup_card_instance_id":rig["setup"],"setup_target_ids":["Boss" if offense else "B"],
		"finisher_actor_id":rig["partner"],"finisher_card_instance_id":rig["finisher"],"finisher_target_ids":["Boss" if offense else "C"],
		"recipe_id":"COMBO_REN_AKANE_01" if offense else "COMBO_REN_TSUMUGI_01"})
