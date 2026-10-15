extends SceneTree
const Scene = preload("res://scenes/battle/battle_screen.tscn")
const Encounter = preload("res://tests/fixtures/m5_full_battle_fixture.gd")
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const M5 = preload("res://scripts/domain/m5/integration/m5_domain_resolver.gd")
var failures: int = 0
var executed: int = 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, id: String) -> void:
	executed += 1
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ")+id)
func run() -> void:
	var screen: Control = Scene.instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame
	check(screen.hud.get_node("TopBar").size.y <= 64, "P42-TOPBAR-NO-EXPANSION")
	check(screen.hud.details.text != "BATTLE_SELECT", "P42-FIRST-FRAME-LOCALIZED")
	var original: String = Model.state_hash(screen.snapshot)
	for actor: String in ["A","B","C"]:
		screen.select_actor(actor)
		check(screen.hud.card_views.size() == 4, "P42-HAND-FOUR-"+actor)
		var seen: Dictionary = {}
		for card: Control in screen.hud.card_views:
			seen[card.instance_id] = true
			check(screen.snapshot["core"]["cards"]["actors"][actor]["zones"]["hand"].has(card.instance_id), "P42-OWNED-"+card.instance_id)
		check(seen.size() == 4, "P42-UNIQUE-"+actor)
	check(Model.state_hash(screen.snapshot) == original, "P42-SELECTION-IS-UI-ONLY")
	screen.select_actor("A")
	screen.select_card(str(screen.hud.card_views[0].instance_id))
	check(screen.pending_card != "", "P42-SELECT-CARD")
	check(Model.state_hash(screen.snapshot) == original, "P42-PREVIEW-NO-MUTATION")
	screen.set_locale("en")
	check(screen.hud.end_button.text == "End phase", "P42-ENGLISH")
	screen.set_locale("zh_TW")
	check(screen.hud.end_button.text == "結束階段", "P42-CHINESE")
	var eight: Dictionary = Encounter.initial()
	var own: Dictionary = eight["core"]["cards"]["actors"]["A"]["zones"]
	# UI fixture only: preserve all 12 unique instances; no production fake hand.
	for i: int in 4: own["hand"].append(own["draw"].pop_back())
	screen.present(eight)
	check(screen.hud.card_views.size() == 8, "P42-EIGHT-CARDS")
	for dims: Vector2i in [Vector2i(1280,720),Vector2i(1920,1080)]:
		root.size = dims
		await process_frame
		var fits: bool = true
		for card: Control in screen.hud.card_views:
			fits = fits and card.position.x >= 0 and card.position.x + card.size.x <= screen.hud.hand.size.x and card.position.y + card.size.y <= screen.hud.hand.size.y
		check(fits, "P42-SAFE-AREA-"+str(dims.x))
	own["draw"].append_array(own["hand"])
	own["hand"].clear()
	screen.present(eight)
	check(screen.hud.card_views.is_empty(), "P42-EMPTY-HAND")
	var unavailable: Dictionary = Encounter.initial()
	unavailable["core"]["battle"]["actors"]["A"]["status"] = "EXHAUSTED"
	screen.present(unavailable)
	check(not screen.hud.card_views[0].legal, "P42-EXHAUSTED-DISABLED")
	unavailable["core"]["battle"]["actors"]["A"]["status"] = "INCAPACITATED"
	unavailable["core"]["battle"]["actors"]["A"]["hp"] = 0
	screen.present(unavailable)
	check(not screen.hud.card_views[0].legal, "P42-INCAPACITATED-DISABLED")
	var enemy: Dictionary = Encounter.initial()
	var config: Dictionary = Encounter.config()
	for kind: String in ["END_PLAYER_PHASE","DECLARE_NEXT_ENEMY_ACTION","OPEN_REACTION_WINDOW"]:
		var command: Dictionary = {"type":kind,"command_id":"hud:"+kind,"expected_event_seq":int(enemy["event_seq"])}
		if kind == "OPEN_REACTION_WINDOW": command["enemy_action_id"] = enemy["active_enemy_action_id"]
		var result: Dictionary = M5.apply(enemy,command,config)
		check(result["accepted"], "P42-REACTION-SETUP-"+kind)
		enemy = result["state"]
	screen.present(enemy)
	check(screen.hud.reaction_panel.visible, "P42-REACTION-MANUAL-UI")
	var paused: String = Model.state_hash(screen.snapshot)
	await create_timer(0.1).timeout
	check(Model.state_hash(screen.snapshot) == paused, "P42-NO-AUTO-PASS")
	screen.queue_free()
	await process_frame
	print("P4_2_REPORT executed=%d passed=%d failed=%d" % [executed,executed-failures,failures])
	quit(0 if failures == 0 else 1)
