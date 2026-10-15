extends SceneTree
const Scene = preload("res://scenes/battle/battle_screen.tscn")
const F = preload("res://tests/fixtures/m5_full_battle_fixture.gd")
const Driver = preload("res://tests/fixtures/m5_full_battle_driver.gd")
const Mapper = preload("res://scripts/battle/presentation/battle_cue_mapper.gd")
const Factory = preload("res://scripts/battle/battle_command_factory.gd")
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const M5 = preload("res://scripts/domain/m5/integration/m5_domain_resolver.gd")
var executed: int = 0
var failed: int = 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, id: String) -> void:
	executed += 1
	if not ok: failed += 1
	print(("PASS " if ok else "FAIL ")+id)
func card_id(state: Dictionary, actor: String, definition: String) -> String:
	var own: Dictionary = state["core"]["cards"]["actors"][actor]
	for id: String in own["zones"]["hand"]:
		if own["instances"][id]["definition_id"] == definition: return id
	return ""
func cue_kinds(screen: Control) -> Array:
	return screen.director.presented_cues.map(func(cue: Dictionary) -> String: return str(cue["kind"]))
func run() -> void:
	# These are mapper unit cases, not fabricated live battle state.
	for kind: String in Mapper.KINDS:
		var cue: Array[Dictionary] = Mapper.map_events([{"kind":kind,"details":{"actor_id":"A"},"command_id":"map-test","event_seq":1}])
		check(cue.size() == 1 and cue[0]["kind"] == Mapper.KINDS[kind],"P44-MAP-"+kind)
	var screen: Control = Scene.instantiate()
	root.add_child(screen)
	await process_frame
	screen._command_requested("REDUCED_MOTION",{"enabled":true})
	screen._command_requested("MUTE_AUDIO",{"enabled":true})
	var state: Dictionary = screen.controller.snapshot()
	var spell: String = card_id(state,"C","regular")
	check(not spell.is_empty(),"P44-REAL-SPELL-OWNED")
	check(screen.controller.submit(Factory.card(state,"C",spell,"Boss","FULL")),"P44-REAL-FULL-CHANT")
	check(screen.get_node("Design/Arena/C").cast_active,"P44-CONCENTRATION-LOOP")
	check(cue_kinds(screen).has("CAST_START"),"P44-CAST-START-EVENT")
	screen._command_requested("END_PLAYER_PHASE",{})
	var choices: Array = screen._reaction_choices()
	check(choices.any(func(choice: Dictionary) -> bool: return choice["entry"]["kind"] == "BASIC_PROTECT"),"P44-PROTECT-FROM-PUBLIC-TARGET")
	screen._command_requested("QUEUE_REACTION",{"entry":{"kind":"BASIC_GUARD","actor_id":"A","target_actor_id":"A"}})
	screen._command_requested("QUEUE_REACTION",{"entry":{"kind":"BASIC_PROTECT","actor_id":"B","target_actor_id":"A"}})
	check(screen.snapshot["reaction_window"]["draft"].size() == 2,"P44-TWO-DRAFTS")
	screen._command_requested("CONFIRM_REACTIONS",{})
	check(cue_kinds(screen).has("GUARD") and cue_kinds(screen).has("PROTECT"),"P44-REAL-GUARD-PROTECT-CUES")
	check(cue_kinds(screen).has("CAST_RELEASE"),"P44-DUE-RELEASE-CUE")
	var boss_hits: Array = screen.director.presented_damage.filter(func(d: Dictionary) -> bool: return d["source_actor_id"] == "Boss")
	check(not boss_hits.is_empty() and boss_hits.all(func(d: Dictionary) -> bool: return d["recipient_id"] == "B"),"P44-ACTUAL-REDIRECTED-RECIPIENT")
	var before: String = Model.state_hash(screen.controller.snapshot())
	var count: int = screen.director.presented_cues.size()
	screen.director.enqueue(screen.snapshot["events"],{"type":"NO_VISUAL_COMMAND"})
	check(screen.director.presented_cues.size() == count,"P44-EVENT-DEDUPLICATION")
	screen.director.skip_all()
	check(Model.state_hash(screen.controller.snapshot()) == before,"P44-SKIP-STATE-UNCHANGED")
	check(screen.controller.replay_receipt()["matches"],"P44-SKIP-REPLAY")
	var golden: Dictionary = Driver.run(F.SEED)
	check(golden["ok"],"P44-GOLDEN-DOMAIN-BATTLE")
	var s: Dictionary = golden["initial"]
	screen.director.reset_session()
	for command: Dictionary in golden["tape"]:
		var result: Dictionary = M5.apply(s,command,golden["config"])
		s = result["state"]
		screen.present(s)
		screen.director.enqueue(result["events"],command)
		screen.director.skip_all()
	for cue: String in ["LAST_START","LAST_RELEASE","EXHAUSTED","BREAK","EXPOSED","COMBO","VICTORY"]:
		check(cue_kinds(screen).has(cue),"P44-GOLDEN-"+cue)
	check(screen.hud.result_panel.visible,"P44-RESULT-OVERLAY")
	check(Model.state_hash(s) == golden["final_hash"],"P44-PRESENTATION-EQUIVALENCE")
	var danger: Dictionary = F.initial()
	danger["core"]["battle"]["actors"]["A"]["hp"] = 1
	var cfg: Dictionary = F.config()
	cfg["m5_enemy_profiles"]["boss_strike"]["hit_mode"] = "GUARANTEED"
	screen.director.reset_session()
	screen.config = cfg
	screen.controller.begin(danger,cfg)
	screen.present(danger)
	check(screen.controller.submit(Factory.build(danger,"ACTIVATE_LAST_SPELL_M4",{"actor_id":"A","target_actor_id":"Boss","casting_mode":"FULL","confirmed":true})),"P44-LAST-HP0-SETUP")
	screen._command_requested("END_PLAYER_PHASE",{})
	screen._command_requested("PASS_REACTION",{})
	check(cue_kinds(screen).has("LAST_INVALID") and not cue_kinds(screen).has("LAST_RELEASE"),"P44-HP0-NO-LAST-RELEASE")
	screen.queue_free()
	await process_frame
	await create_timer(0.65).timeout
	print("P4_4_REPORT executed=%d passed=%d failed=%d" % [executed,executed-failed,failed])
	quit(0 if failed == 0 else 1)
