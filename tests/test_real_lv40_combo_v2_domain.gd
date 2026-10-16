extends SceneTree
const Encounter = preload("res://scripts/domain/m5/lv40/lv40_encounter.gd")
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const M5 = preload("res://scripts/domain/m5/integration/m5_domain_resolver.gd")
const Prepared = preload("res://scripts/domain/m5/combo/prepared_combo_resolver.gd")
var executed: int = 0
var failed: int = 0
func check(ok: bool, id: String) -> void:
	executed += 1
	if not ok: failed += 1
	print(("PASS " if ok else "FAIL ")+id)
func card_id(state: Dictionary, actor: String, definition: String) -> String:
	var cards: Dictionary = state["core"]["cards"]["actors"][actor]
	for id: String in cards["zones"]["hand"]:
		if cards["instances"][id]["definition_id"] == definition: return id
	return ""
func _initialize() -> void:
	var seed: int = 6
	var state: Dictionary = Encounter.initial(seed)
	var config: Dictionary = Encounter.config()
	check(not state.is_empty() and str(state["core"]["battle"]["lv40"]["version"]).begins_with("lv40-starter-v0.3"),"REAL-COMBO-01-approved-roster-content-loaded")
	var loadouts: Dictionary = Encounter.loadouts()
	for actor: String in Encounter.party_ids():
		check(loadouts[actor].size() == 12,"REAL-COMBO-02-12-SP-"+actor)
	var setup: String = card_id(state,"A","R08")
	var finisher: String = card_id(state,"C","T04")
	check(not setup.is_empty() and not finisher.is_empty(),"REAL-COMBO-03-natural-opening-hand-R08-T04")
	var potentials: Array = Prepared.potentials(state,"A",setup)
	var found: bool = false
	for option: Dictionary in potentials:
		if option.get("actor_id","") == "C" and option.get("card_instance_id","") == finisher and option.get("recipe_id","") == "COMBO_REN_TSUMUGI_01": found = true
	check(found,"REAL-COMBO-04-recipe-from-live-hand")
	var command := {"type":"COMMIT_PREPARED_COMBO_V2","command_id":"real-lv40-combo-6","expected_event_seq":state["event_seq"],
		"setup_actor_id":"A","setup_card_instance_id":setup,"setup_target_ids":["B"],
		"finisher_actor_id":"C","finisher_card_instance_id":finisher,"finisher_target_ids":["C"],"recipe_id":"COMBO_REN_TSUMUGI_01"}
	var before: String = Model.state_hash(state)
	var result: Dictionary = M5.apply(state,command,config)
	check(result["accepted"] and not result["events"].is_empty(),"REAL-COMBO-05-two-card-action-accepted")
	check(Model.state_hash(state) == before,"REAL-COMBO-06-input-snapshot-unchanged")
	if result["accepted"]:
		var next: Dictionary = result["state"]
		var cards: Dictionary = next["core"]["cards"]["actors"]
		check(cards["A"]["zones"]["discard"].has(setup) and cards["C"]["zones"]["discard"].has(finisher),"REAL-COMBO-07-real-card-instances-paid")
		check(int(next["core"]["battle"]["party_resources"]["current_ap"]) == 4 and int(next["core"]["battle"]["actors"]["A"]["mp"]) == 6 and int(next["core"]["battle"]["actors"]["C"]["mp"]) == 10,"REAL-COMBO-08-real-AP-MP-costs-no-bonus-AP")
		check(float(next["core"]["battle"]["hp_barriers"]["B"]) == 90.0 and float(next["core"]["battle"]["hp_barriers"]["C"]) == 265.0,"REAL-COMBO-09-selected-target-effects")
		var executed_event: bool = false
		for event: Dictionary in result["events"]:
			if event["kind"] == "ComboExecuted": executed_event = true
		check(executed_event,"REAL-COMBO-10-domain-combo-event")
		var replay: Dictionary = M5.replay(state,[command],config)
		check(replay["state_hash"] == result["state_hash"] and replay["event_hash"] == result["event_hash"],"REAL-COMBO-11-replay-equality")
	var low_mp: Dictionary = state.duplicate(true)
	low_mp["core"]["battle"]["actors"]["C"]["mp"] = 0
	var low_hash: String = Model.state_hash(low_mp)
	var rejected: Dictionary = M5.apply(low_mp,command,config)
	check(not rejected["accepted"] and rejected["events"].is_empty() and rejected["state_hash"] == low_hash and Model.state_hash(low_mp) == low_hash,"REAL-COMBO-12-low-MP-atomic-rejection")
	print("REAL_LV40_COMBO_DOMAIN_REPORT executed=%d passed=%d failed=%d seed=%d" % [executed,executed-failed,failed,seed])
	quit(0 if failed == 0 else 1)