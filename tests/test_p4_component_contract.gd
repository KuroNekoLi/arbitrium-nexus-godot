extends SceneTree
## V1 structural smoke test; no changes to gameplay or existing test oracles.
const Scene = preload("res://scenes/battle/battle_screen.tscn")
const Model = preload("res://scripts/domain/m1/combat_model.gd")
var failures: int = 0
var executed: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, name: String) -> void:
	executed += 1
	if not ok:
		failures += 1
	print(("PASS " if ok else "FAIL ") + name)

func run() -> void:
	var screen: Control = Scene.instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame
	var hud: Control = screen.hud
	for name: String in ["TopBar", "PartyStatusPanel", "Commands", "EnemyStatus", "Context", "HandView", "TargetHitRegions", "ReactionQueue"]:
		check(hud.has_node(name), "V1-SCENE-" + name)
	check(hud.get_node("TopBar").get_child_count() > 0, "V1-HEADER-CONTENT")
	check(hud.roster.size() == 3, "V1-ROSTER-THREE")
	check(hud.card_views.size() == 4, "V1-HAND-FOUR")
	check(hud.hand == hud.get_node("HandView"), "V1-HAND-ALIAS")
	check(hud.card_views == hud.hand.card_views, "V1-CARDS-ALIAS")
	check(hud.confirm_button != null and hud.details != null and hud.feedback != null and hud.log_label != null, "V1-CONTEXT-FACADE")
	check(hud.reduced_toggle != null and hud.mute_toggle != null, "V1-P44-SETTINGS-FACADE")
	check(hud.result_panel != null and hud.result_label != null, "V1-P44-RESULT-FACADE")
	check(hud.reaction_panel == hud.get_node("ReactionQueue"), "V1-REACTION-ALIAS")
	check(hud.reaction_column == hud.reaction_panel.reaction_column, "V1-REACTION-COLUMN")
	check(hud.target_buttons.size() == 4, "V1-TARGET-ALIAS")
	var before: String = Model.state_hash(screen.snapshot)
	screen.select_actor("B")
	check(screen.selected_actor == "B" and hud.card_views.size() == 4, "V1-ACTOR-SELECTION")
	check(Model.state_hash(screen.snapshot) == before, "V1-ACTOR-ONLY-PRESENTATION")
	screen.set_locale("en")
	hud = screen.hud
	check(hud.end_button.text == "End phase", "V1-LOCALE-EN")
	check(hud.card_views.size() == 4 and hud.reaction_panel != null, "V1-LOCALE-REBIND")
	screen.set_locale("zh_TW")
	check(screen.hud.end_button.text == "結束階段", "V1-LOCALE-ZHTW")
	screen.queue_free()
	await process_frame
	print("V1_COMPONENT_REPORT executed=%d passed=%d failed=%d" % [executed, executed - failures, failures])
	quit(0 if failures == 0 else 1)
