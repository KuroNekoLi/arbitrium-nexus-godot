extends SceneTree
## V2.1 layout contract: geometry + UI-only state, not a visual-similarity claim.
const Scene = preload("res://scenes/battle/battle_screen.tscn")
const Encounter = preload("res://tests/fixtures/m5_full_battle_fixture.gd")
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

func _screen_rect(node: Control, view_size: Vector2i) -> bool:
	var xf: Transform2D = node.get_global_transform()
	for corner: Vector2 in [Vector2.ZERO, Vector2(node.size.x, 0), node.size, Vector2(0, node.size.y)]:
		var point: Vector2 = xf * corner
		if point.x < -1.0 or point.y < -1.0 or point.x > view_size.x + 1.0 or point.y > view_size.y + 1.0:
			return false
	return true

func run() -> void:
	root.size = Vector2i(1280, 720)
	var screen: Control = Scene.instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame
	var hud: Control = screen.hud
	var top: Control = hud.get_node("TopBar")
	var ap: Control = top.get_node("ResourcePanel")
	var phase: Control = top.get_node("PhasePanel")
	var tools: Control = top.get_node("UtilityPanel")
	check(top.size.y <= 64, "V2-HEADER-STAYS-COMPACT")
	check(ap.position.x + ap.size.x < phase.position.x, "V2-AP-PHASE-SEPARATED")
	check(phase.position.x + phase.size.x < tools.position.x, "V2-PHASE-TOOLS-SEPARATED")
	check(hud.resources.is_ancestor_of(ap) == false and ap.is_ancestor_of(hud.resources), "V2-AP-FACADE")
	check(phase.is_ancestor_of(hud.header), "V2-PHASE-FACADE")
	check(hud.hand.position.y >= 468, "V2-HAND-MOVED-DOWN")
	check(hud.hand.position.y + hud.hand.size.y <= 712, "V2-HAND-BOTTOM-INSET")
	check(hud.get_node("Commands").get_rect().end.y <= 704, "V2-COMMANDS-BOUNDS")
	check(hud.get_node("EnemyStatus").get_rect().end.y < hud.get_node("Context").get_rect().position.y, "V2-BOSS-CONTEXT-GAP")
	var original: String = Model.state_hash(screen.snapshot)
	screen.select_actor("B")
	check(Model.state_hash(screen.snapshot) == original, "V2-SELECT-NONMUTATING")
	check(screen.hud.card_views.size() == 4, "V2-FOUR-CARDS")
	var eight: Dictionary = Encounter.initial()
	var zones: Dictionary = eight["core"]["cards"]["actors"]["A"]["zones"]
	while zones["hand"].size() < 8:
		zones["hand"].append(zones["draw"].pop_back())
	screen.select_actor("A")
	screen.present(eight)
	check(hud.card_views.size() == 8, "V2-EIGHT-CARDS")
	for view_size: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = view_size
		await process_frame
		check(_screen_rect(hud.hand, view_size), "V2-HAND-CONTAINER-" + str(view_size.x))
		var visible_corners: bool = true
		for card: Control in hud.card_views:
			visible_corners = visible_corners and _screen_rect(card, view_size)
		check(visible_corners, "V2-CARD-CORNERS-" + str(view_size.x))
	screen.set_locale("en")
	check(screen.hud.resources != null and screen.hud.header != null, "V2-EN-HEADER-REBUILT")
	screen.set_locale("zh_TW")
	check(screen.hud.get_node("TopBar/PhasePanel") != null, "V2-ZHTW-PHASE-REBUILT")
	screen.queue_free()
	await process_frame
	print("V2_LAYOUT_REPORT executed=%d passed=%d failed=%d" % [executed, executed - failures, failures])
	quit(0 if failures == 0 else 1)
