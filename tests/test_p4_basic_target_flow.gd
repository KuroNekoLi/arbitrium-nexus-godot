extends SceneTree
## The current scene has one enemy; a second valid enemy is added only in this
## fixture to exercise target memory without introducing new game content.
const Scene = preload("res://scenes/battle/battle_screen.tscn")
const Fixture = preload("res://tests/fixtures/m5_full_battle_fixture.gd")
const Factory = preload("res://scripts/battle/battle_command_factory.gd")
const Model = preload("res://scripts/domain/m1/combat_model.gd")
var executed: int = 0
var failed: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, id: String) -> void:
	executed += 1
	if not condition: failed += 1
	print(("PASS " if condition else "FAIL ") + id)

func run() -> void:
	var screen: Control = Scene.instantiate()
	root.add_child(screen)
	await process_frame
	var before: Dictionary = screen.controller.snapshot()
	screen.hud.get_node("Commands").command_buttons["BATTLE_BASIC"].pressed.emit()
	check(int(screen.snapshot["core"]["battle"]["actors"]["Boss"]["hp"]) <
		int(before["core"]["battle"]["actors"]["Boss"]["hp"]), "BTF-01-SINGLE-CLICK-DOMAIN-DAMAGE")
	check(int(screen.snapshot["core"]["battle"]["party_resources"]["current_ap"]) <
		int(before["core"]["battle"]["party_resources"]["current_ap"]), "BTF-02-SINGLE-CLICK-AP-PAID")
	check(not screen.hud.command_prompt.visible and screen.pending_kind.is_empty(), "BTF-03-NO-CONFIRM-MODAL")
	check(screen.controller.replay_receipt()["matches"], "BTF-04-SINGLE-REPLAY")

	screen._command_requested("RESTART_BATTLE", {})
	var multi: Dictionary = Fixture.initial()
	var cfg: Dictionary = Fixture.config()
	var battle: Dictionary = multi["core"]["battle"]
	battle["enemies"].append("Dummy")
	battle["actors"]["Dummy"] = battle["actors"]["Boss"].duplicate(true)
	battle["actors"]["Dummy"]["id"] = "Dummy"
	cfg["m5_actor_stats"]["Dummy"] = cfg["m5_actor_stats"]["Boss"].duplicate(true)
	cfg["m5_element_resistance"]["Dummy"] = cfg["m5_element_resistance"]["Boss"].duplicate(true)
	var extra_preview: Dictionary = Factory.preview(multi, Factory.build(multi, "BASIC_ATTACK_RESOURCE_ONLY",
		{"actor_id":"A", "target_actor_id":"Dummy"}), cfg)
	if not extra_preview["accepted"]:
		print("BTF_SECOND_TARGET_REASON ", extra_preview.get("error", ""))
	check(extra_preview["accepted"], "BTF-05-SECOND-TARGET-DOMAIN-LEGAL")
	screen.controller.begin(multi, cfg)
	screen.config = cfg
	screen.present(multi)
	var frozen: String = Model.state_hash(screen.snapshot)
	screen._command_requested("BASIC_ATTACK_RESOURCE_ONLY", {})
	check(screen.legal_targets.size() == 2 and screen.selected_target == "Boss" and
		screen.hud.get_node("TargetHitRegions").basic_choices.visible, "BTF-06-MULTI-REMEMBERED-TARGET")
	check(Model.state_hash(screen.snapshot) == frozen and not screen.hud.command_prompt.visible,
		"BTF-07-FIRST-CLICK-ONLY-TARGETING")
	screen.select_target("Dummy")
	check(screen.selected_target == "Dummy" and screen.remembered_attack_target == "Dummy" and
		Model.state_hash(screen.snapshot) == frozen, "BTF-08-OTHER-CLICK-SWITCHES-ONLY")
	screen.cancel_action()
	screen._command_requested("BASIC_ATTACK_RESOURCE_ONLY", {})
	check(screen.selected_target == "Dummy" and Model.state_hash(screen.snapshot) == frozen,
		"BTF-09-NEXT-COMMAND-RECALLS-TARGET")
	screen.select_target("Boss")
	check(screen.selected_target == "Boss" and Model.state_hash(screen.snapshot) == frozen,
		"BTF-10-ALTERNATE-CLICK-RESELECTS")
	screen.select_target("Boss")
	check(int(screen.snapshot["core"]["battle"]["actors"]["Boss"]["hp"]) <
		int(multi["core"]["battle"]["actors"]["Boss"]["hp"]), "BTF-11-SECOND-CLICK-COMMITS")
	check(screen.controller.replay_receipt()["matches"], "BTF-12-MULTI-REPLAY")
	screen.queue_free()
	await process_frame
	print("P4_BASIC_TARGET_FLOW_REPORT executed=%d passed=%d failed=%d" % [executed, executed - failed, failed])
	quit(1 if failed else 0)
