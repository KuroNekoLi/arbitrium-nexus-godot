extends SceneTree
## V2.2 regression: context stays usable while the log is independent.
const Scene = preload("res://scenes/battle/battle_screen.tscn")
const Model = preload("res://scripts/domain/m1/combat_model.gd")
var executed: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, id: String) -> void:
	executed += 1
	if not ok:
		failures += 1
	print(("PASS " if ok else "FAIL ") + id)

func _visible_within(inner: Control, outer: Control) -> bool:
	var a: Rect2 = inner.get_global_rect()
	var b: Rect2 = outer.get_global_rect()
	return a.position.x >= b.position.x - 1.0 and a.position.y >= b.position.y - 1.0 \
		and a.end.x <= b.end.x + 1.0 and a.end.y <= b.end.y + 1.0

func run() -> void:
	root.size = Vector2i(1280, 720)
	var screen: Control = Scene.instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame
	var hud: Control = screen.hud
	var ctx: Control = hud.get_node("Context")
	var log_panel: Control = hud.get_node("BattleLogPanel")
	var commands: Control = hud.get_node("Commands")
	var party: Control = hud.get_node("PartyStatusPanel")
	check(log_panel.is_ancestor_of(hud.log_label), "V22-LOG-OWNERSHIP")
	check(not ctx.is_ancestor_of(hud.log_label), "V22-LOG-NOT-IN-CONTEXT")
	check(ctx.is_ancestor_of(hud.details), "V22-DETAILS-OWNERSHIP")
	check(ctx.is_ancestor_of(hud.confirm_button), "V22-CONFIRM-OWNERSHIP")
	check(ctx.detail_scroll.is_ancestor_of(hud.details), "V22-DETAIL-SCROLLABLE")
	check(not ctx.detail_scroll.is_ancestor_of(hud.confirm_button), "V22-CONFIRM-STICKY")
	check(not ctx.detail_scroll.is_ancestor_of(hud.feedback), "V22-FEEDBACK-STICKY")
	check(log_panel.position.y >= ctx.position.y + ctx.size.y + 8.0, "V22-DETAIL-LOG-GAP")
	check(log_panel.position.y + log_panel.size.y <= 704.0, "V22-LOG-SAFE-BOTTOM")
	check(commands.position.y >= party.position.y + party.size.y + 8.0, "V22-LEFT-VERTICAL-GAP")
	check(commands.position.x + commands.size.x < hud.hand.position.x, "V22-LEFT-HAND-GAP")
	check(hud.confirm_button != null and hud.end_button != null, "V22-LEGACY-FACADE")
	check(hud.mode != null and hud.combo != null and hud.reduced_toggle != null and hud.mute_toggle != null, "V22-CONTROLS-PRESERVED")
	var before: String = Model.state_hash(screen.snapshot)
	screen.select_card(str(hud.card_views[0].instance_id))
	await process_frame
	check(_visible_within(hud.confirm_button, ctx), "V22-CARD-CONFIRM-VISIBLE")
	check(Model.state_hash(screen.snapshot) == before, "V22-PREVIEW-NO-DOMAIN-MUTATION")
	hud.log_label.text = "seq 1\nseq 2\nseq 3"
	check(hud.log_label.text.contains("seq 3"), "V22-LOG-WRITABLE-VIA-FACADE")
	for dims: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = dims
		await process_frame
		check(_visible_within(hud.confirm_button, ctx), "V22-CONFIRM-ON-SCREEN-" + str(dims.x))
		check(_visible_within(log_panel, hud), "V22-LOG-ON-SCREEN-" + str(dims.x))
	screen.set_locale("en")
	hud = screen.hud
	check(hud.get_node("BattleLogPanel").is_ancestor_of(hud.log_label), "V22-EN-LOG-REBUILT")
	check(hud.confirm_button != null and hud.reaction_panel != null, "V22-EN-ALIASES-REBUILT")
	screen.set_locale("zh_TW")
	check(screen.hud.get_node("Context").action_row != null, "V22-ZHTW-ACTIONS-REBUILT")
	screen.queue_free()
	await process_frame
	print("V2_CONTEXT_REPORT executed=%d passed=%d failed=%d" % [executed, executed - failures, failures])
	quit(0 if failures == 0 else 1)
