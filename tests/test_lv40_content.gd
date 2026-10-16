extends SceneTree
const Encounter = preload("res://scripts/domain/m5/lv40/lv40_encounter.gd")
const M4 = preload("res://scripts/domain/m4/integration/m4_domain_resolver.gd")
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const Boss = preload("res://scripts/domain/m5/lv40/lv40_boss.gd")
const Status = preload("res://scripts/domain/m5/status/status_resolver.gd")
var passed: int = 0
var failed: int = 0

func check(value: bool, id: String) -> void:
	if value:
		passed += 1
		print("PASS ",id)
	else:
		failed += 1
		push_error("FAIL "+id)

func _initialize() -> void:
	var c: Dictionary = Encounter.config()
	var s: Dictionary = Encounter.initial()
	check(not s.is_empty(),"DEMO-01-CONTENT-INITIAL")
	if s.is_empty():
		quit(1)
		return
	check(M4.validate_state(s),"DEMO-01-CONTENT-M4-SCHEMA")
	check(bool(c.get("m5_lv40_enabled",false)) and str(s["core"]["battle"]["lv40"]["version"]) == str(c["m5_lv40_content_version"]), "DEMO-01-VERSIONED-OPT-IN")
	check(str(c["m5_status_definitions"]["SCORCH_TEST"]["tick_trigger"]) == "ENEMY_PHASE_END", "DEMO-10-SCORCH-REGISTERED-BOUNDARY")
	var granted: Dictionary = Status.grant(s["core"],"B","Boss","SCORCH_TEST","content-tick",c)
	check(granted.get("ok",false) and Status.validate(granted["core"],c), "DEMO-10-REAL-STATUS-SCHEMA")
	if granted.get("ok",false):
		var early: Dictionary = Status.tick(granted["core"],2,c,"content-no-early","NEXT_PLAYER_PHASE")
		check(early.get("ok",false) and early["timeline"].is_empty() and early["core"]["battle"]["statuses"] == granted["core"]["battle"]["statuses"], "DEMO-10-NO-PLAYER-PHASE-SCORCH-TICK")
		var due: Dictionary = Status.tick(granted["core"],2,c,"content-enemy-tick","ENEMY_PHASE_END")
		check(due.get("ok",false) and due["timeline"].size() > 0 and int(due["core"]["battle"]["statuses"][0]["remaining_ticks"]) == 1, "DEMO-10-SCORCH-ENEMY-END-ONLY")
	check(s["core"]["battle"]["enemies"] == ["Boss"],"DEMO-01-SINGLE-BOSS")
	check(int(s["core"]["battle"]["party_resources"]["current_ap"]) == 6,"DEMO-01-AP6")
	for actor: String in Encounter.loadouts():
		var cards: Dictionary = s["core"]["cards"]["actors"][actor]
		check(cards["instances"].size() == 12,"DEMO-01-INSTANCES-"+actor)
		check(cards["zones"]["hand"].size() == 4,"DEMO-01-HAND-"+actor)
		var actual: Array = []
		for instance: Dictionary in cards["instances"].values():
			actual.append(instance["definition_id"])
		actual.sort()
		var expected: Array = Encounter.loadouts()[actor].duplicate()
		expected.sort()
		check(actual == expected,"DEMO-01-EXACT-DECK-"+actor)
		check(s["core"]["battle"]["actors"][actor]["meta"]["character_id"] == Encounter.characters()[actor],"DEMO-01-CHARACTER-"+actor)
	check(int(s["core"]["battle"]["actors"]["Boss"]["max_hp"]) == 2700,"DEMO-01-DOC29-HP")
	check(c["m5_actor_stats"]["Boss"]["patk"] == 417 and c["m5_actor_stats"]["Boss"]["matk"] == 434,"DEMO-01-DOC29-ATTACK")
	check(s["core"]["battle"]["m53"]["break_gauge"] == 22,"DEMO-09-DOC29-BREAK")
	check(Model.state_hash(s) == Model.state_hash(Encounter.initial()),"DEMO-13-INITIAL-REPLAY")
	check(Model.state_hash(s) != Model.state_hash(Encounter.initial(20261015)),"DEMO-13-DIFFERENT-SEED")
	check(Encounter.initial(0).is_empty(),"DEMO-13-INVALID-SEED")
	var beam: Dictionary = Boss.intent(s["core"],"B05",c)
	var charged: Dictionary = Boss.resolve(s["core"],beam,{},c,"content-charge")
	check(charged["ok"],"DEMO-03-CHARGE-RESOLVED")
	check(charged["core"]["battle"]["actors"] == s["core"]["battle"]["actors"],"DEMO-03-CHARGE-ZERO-HP")
	check(charged["core"]["battle"]["lv40"]["pending_cast"]["current_stability"] == 9,"DEMO-03-STABILITY9")
	var interrupted: Dictionary = Boss.interrupt(charged["core"],9,"content-A05")
	check(interrupted["ok"] and interrupted["core"]["battle"]["lv40"]["pending_cast"]["interrupted"],"DEMO-04-M4-INTERRUPT")
	check(interrupted["core"]["battle"]["m53"]["break_gauge"] == 22,"DEMO-04-BREAK-SEPARATE")
	check(Boss.publish(interrupted["core"],c)["intent"]["skill_id"] == "B10","DEMO-04-COOLDOWN-PUBLISHED")
	check(not Boss.interrupt(s["core"],9,"no-cast")["ok"],"DEMO-04-NO-CAST-REJECT")
	var release: Dictionary = Boss.intent(s["core"],"B06",c)
	check(not Boss.resolve(s["core"],release,{},c,"no-pending")["ok"],"DEMO-03-NO-FREE-RELEASE")
	for skill: String in ["B04","B09"]:
		var aoe: Dictionary = Boss.intent(s["core"],skill,c)
		check(aoe["target_scope"] == "ALL" and aoe["unprotectable"] and aoe["targeting_mode"] == "ALL_ELIGIBLE_AT_RESOLVE","DEMO-05-AOE-"+skill)
	print("LV40_CONTENT_REPORT executed=",passed+failed," passed=",passed," failed=",failed)
	quit(1 if failed else 0)
