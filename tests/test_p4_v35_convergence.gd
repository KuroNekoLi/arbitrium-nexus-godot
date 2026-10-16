extends SceneTree
## Additive presentation regression; existing V3.5 suites remain unchanged.
const Scene = preload("res://scenes/battle/battle_screen.tscn")
const Model = preload("res://scripts/domain/m1/combat_model.gd")
var executed: int = 0
var failed: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, id: String) -> void:
	executed += 1
	if not ok: failed += 1
	print(("PASS " if ok else "FAIL ") + id)

func run() -> void:
	root.size = Vector2i(1280, 720)
	var screen: Control = Scene.instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame
	var before: String = Model.state_hash(screen.snapshot)
	var context: Control = screen.hud.get_node("Context")
	check(context.artwork.texture != null and not context.cost_badge.visible, "V35C-IDLE-DESIGNED")
	check(not context.visible, "V35C-IDLE-NO-SPELL-DETAILS")
	check(not screen.hud.get_node("TopBar/UtilityPanel").visible, "V35C-NO-BATTLE-UTILITY-BUTTONS")
	check(screen.hud.get_node("EnemyStatus").position.y == 12, "V35C-BOSS-TOP-RIGHT")
	for panel: String in ["Commands", "EnemyStatus", "Context", "BattleLogPanel"]:
		check(screen.hud.get_node(panel).get_node("ArcaneChrome").mouse_filter == Control.MOUSE_FILTER_IGNORE,
			"V35C-ORNAMENT-NONBLOCKING-" + panel)
	var card: Control = screen.hud.card_views[0]
	screen.select_card(card.instance_id)
	check(context.visible, "V35C-CLICK-SHOWS-SPELL-DETAILS")
	check(not context.action_row.visible, "V35C-DETAILS-NO-CONFIRM-FOOTER")
	check(context.artwork.texture == card.appearance.artwork, "V35C-ACTUAL-ARTWORK")
	check(context.action_title.text == screen.tr(card.appearance.name_key), "V35C-ACTUAL-TITLE")
	check(context.cost_badge.text == card.cost_text, "V35C-COST-MATCHES-HAND")
	check(not context.detail_scroll.is_ancestor_of(context.confirm_button), "V35C-STICKY-FOOTER")
	check(screen.hud.confirm_button.disabled, "V35C-NO-TARGET-NO-CONFIRM")
	if not screen.legal_targets.is_empty():
		screen.select_target(screen.legal_targets[0])
		check(context.target_label.text == screen.log_actor_name(screen.selected_target), "V35C-REAL-TARGET")
		check(not screen.hud.confirm_button.disabled, "V35C-LEGAL-CONFIRM")
	check(Model.state_hash(screen.snapshot) == before, "V35C-PREVIEW-NO-DOMAIN-WRITE")
	screen.cancel_action()
	check(not context.visible, "V35C-CANCEL-HIDES-SPELL-DETAILS")
	check(not context.cost_badge.visible and screen.hud.confirm_button.disabled, "V35C-CANCEL-CLEARS")
	check(screen.hud.get_node("EnemyStatus").target_portrait.visible, "V35C-PUBLISHED-TARGET-PORTRAIT")
	var hp_before_basic: int = int(screen.snapshot["core"]["battle"]["actors"]["Boss"]["hp"])
	screen._command_requested("BASIC_ATTACK_RESOURCE_ONLY", {})
	check(not context.visible, "V35C-BASIC-NOT-SPELL-DETAILS")
	check(int(screen.snapshot["core"]["battle"]["actors"]["Boss"]["hp"]) < hp_before_basic,
		"V35C-SINGLE-ENEMY-BASIC-IMMEDIATE")
	check(not screen.hud.command_prompt.visible, "V35C-BASIC-NO-CONFIRM-PROMPT")
	screen.cancel_action()
	check(not screen.hud.command_prompt.visible and not context.visible, "V35C-CANCEL-PROMPT")
	screen.queue_free()
	await process_frame
	print("V35_CONVERGENCE_REPORT executed=%d passed=%d failed=%d" % [executed, executed - failed, failed])
	quit(0 if failed == 0 else 1)
