extends SceneTree
const Factory = preload("res://scripts/battle/battle_command_factory.gd")
const Adapter = preload("res://scripts/battle/presentation/battle_presentation_adapter.gd")
const Encounter = preload("res://scripts/domain/m5/lv40/lv40_encounter.gd")
const Legacy = preload("res://tests/fixtures/m5_full_battle_fixture.gd")
const Model = preload("res://scripts/domain/m1/combat_model.gd")
var passed: int = 0
var failed: int = 0
func check(value: bool, label: String) -> void:
	if value:
		passed += 1
		print("PASS ",label)
	else:
		failed += 1
		push_error("FAIL "+label)

func first_card(s: Dictionary, actor: String) -> String:
	return str(s["core"]["cards"]["actors"][actor]["zones"]["hand"][0])

func _initialize() -> void:
	var state: Dictionary = Encounter.initial(20261014)
	var config: Dictionary = Encounter.config()
	check(not state.is_empty(),"P4-RM-01-LV40-CONTENT")
	var original: String = Model.state_hash(state)
	var actor: String = "A"
	var instance: String = first_card(state,actor)
	var definition: String = str(state["core"]["cards"]["actors"][actor]["instances"][instance]["definition_id"])
	var command: Dictionary = Factory.card(state,actor,instance,"Boss","FULL",false,config)
	check(command["type"] == "PLAY_LV40_CARD" and command["actor_id"] == actor and command["card_instance_id"] == instance and command["target_actor_id"] == "Boss","P4-RM-02-PUBLIC-COMMAND")
	check(command["casting_mode"] == "FULL" and command["combo_mode"] == "NORMAL"
		and command["expected_event_seq"] == state["event_seq"],"P4-RM-03-MODE-AND-REVISION")
	for forbidden: String in ["damage","final_damage","cost","ap_cost","mp_cost","effect","skill_id","public_intent"]:
		check(not command.has(forbidden),"P4-RM-04-NO-TRUSTED-PAYLOAD-"+forbidden)
	var combo: Dictionary = Factory.card(state,actor,instance,"Boss","CHANTLESS",true,config)
	check(combo["combo_mode"] == "COMBO","P4-RM-05-COMBO-INTENT")
	var foreign: Dictionary = Factory.card(state,"B",instance,"Boss","CHANTLESS",false,config)
	check(foreign["type"] == "PLAY_LV40_CARD" and foreign["card_instance_id"] == instance,"P4-RM-06-FOREIGN-SAFE-SHAPE")
	var absent: Dictionary = Factory.card(state,actor,"not-a-card","Boss","CHANTLESS",false,config)
	check(absent["type"] == "PLAY_LV40_CARD" and absent["card_instance_id"] == "not-a-card","P4-RM-07-MISSING-SAFE-SHAPE")
	var preview: Dictionary = Factory.preview(state,absent,config)
	check(not preview.get("accepted",false),"P4-RM-08-M5-REJECTS-MISSING")
	check(Model.state_hash(state) == original,"P4-RM-09-PREVIEW-STATE-PURE")
	check(Factory.build(state,"END_PLAYER_PHASE",{},7)["command_id"] == "p4:0:7:END_PLAYER_PHASE","P4-RM-10-STABLE-COMMAND-ID")
	var vm: Dictionary = Adapter.project(state,config)
	check(Model.state_hash(state) == original,"P4-RM-11-PROJECTION-PURE")
	check(vm["actor_name_keys"]["A"] == "actor.ren.name" and vm["actor_name_keys"]["B"] == "actor.akane.name" and vm["actor_name_keys"]["C"] == "actor.tsumugi.name" and vm["actor_name_keys"]["Boss"] == "actor.arcane_sentry.name","P4-RM-12-ACTOR-METADATA")
	check(vm["public_intent_labels"].size() == 1 and vm["public_intent_labels"][0]["skill_id"] == "B01","P4-RM-13-PUBLIC-INTENT")
	check(vm["public_intent_labels"][0]["name_key"] == "intent.b01.name" and vm["public_intent_labels"][0]["target_scope"] == "SINGLE","P4-RM-14-PUBLIC-KEY-SCOPE")
	check(not vm.has("pending_cast") and not vm.has("lv40") and not vm["boss_cast_public"].has("hidden_policy"),"P4-RM-15-NO-PRIVATE-FSM")
	check(vm["hand_cards"]["A"].size() == 4 and vm["hand_cards"]["B"].size() == 4 and vm["hand_cards"]["C"].size() == 4,"P4-RM-16-REAL-HANDS")
	var first: Dictionary = vm["hand_cards"]["A"][0]
	check(first["card_instance_id"] == instance and first["definition_id"] == definition and first["name_key"] == config["lv40_cards"][definition]["name_key"],"P4-RM-17-INSTANCE-AND-LOCALIZATION")
	check(first["ap_cost"] == config["definitions"][definition]["ap_cost"] and first["mp_cost"] == config["definitions"][definition]["mp_cost"],"P4-RM-18-AUTHORITATIVE-COSTS")
	vm["actors"]["A"]["hp"] = 0
	vm["hands"]["A"]["zones"]["hand"].clear()
	vm["hand_cards"]["A"][0]["name_key"] = "tampered"
	vm["public_intent_labels"][0]["target_ids"].clear()
	check(Model.state_hash(state) == original and config["lv40_cards"][definition]["name_key"] != "tampered","P4-RM-19-DETACHED-VM")
	var legacy: Dictionary = Legacy.initial()
	var old_vm: Dictionary = Adapter.project(legacy)
	check(old_vm["actors"].has("A") and old_vm["hands"].has("A") and old_vm["hand_cards"].is_empty(),"P4-RM-20-LEGACY-PROJECTION")
	var old_card: String = first_card(legacy,"C")
	var regular: Dictionary = Factory.card(legacy,"C",old_card,"Boss")
	check(regular["type"] == "CAST_SPELL_M4" and regular["casting_mode"] == "CHANTLESS" or regular["type"] == "USE_EFFECT_SP_M5","P4-RM-21-LEGACY-CARD-KIND")
	var legacy_copy: String = Model.state_hash(legacy)
	var old_preview: Dictionary = Factory.preview(legacy,Factory.card(legacy,"C","missing","Boss"),Legacy.config())
	check(not old_preview.get("accepted",false) and Model.state_hash(legacy) == legacy_copy,"P4-RM-22-LEGACY-PREVIEW-PURE")
	print("P4_READMODEL_REPORT executed=",passed+failed," passed=",passed," failed=",failed)
	quit(1 if failed else 0)
