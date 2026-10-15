extends SceneTree
const Scene = preload("res://scenes/battle/battle_screen.tscn")
const Encounter = preload("res://tests/fixtures/m5_full_battle_fixture.gd")
const Model = preload("res://scripts/domain/m1/combat_model.gd")
var executed: int = 0
var failed: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, case_id: String) -> void:
	executed += 1
	if not condition:
		failed += 1
	print(("PASS " if condition else "FAIL ") + case_id)

func _case(count: int) -> Dictionary:
	var state: Dictionary = Encounter.initial()
	var zones: Dictionary = state["core"]["cards"]["actors"]["A"]["zones"]
	while zones["hand"].size() > count:
		zones["draw"].append(zones["hand"].pop_back())
	while zones["hand"].size() < count and not zones["draw"].is_empty():
		zones["hand"].append(zones["draw"].pop_back())
	return state

func run() -> void:
	root.size = Vector2i(1280, 720)
	var screen: Control = Scene.instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame
	var hud: Control = screen.hud
	var hand: Control = hud.hand
	screen.present(_case(0))
	var empty: Label = hand.get_node("EmptyState")
	check(empty.visible and hud.card_views.is_empty(), "V24-EMPTY-VISIBLE")
	check(empty.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER, "V24-EMPTY-CENTERED")
	check(empty.autowrap_mode == TextServer.AUTOWRAP_OFF, "V24-EMPTY-NO-VERTICAL-WRAP")
	check(empty.size.x >= 600.0 and empty.size.y > 200.0, "V24-EMPTY-FULL-RECT")
	check(not empty.text.is_empty(), "V24-EMPTY-TEXT")
	screen.present(_case(4))
	check(not empty.visible and hud.card_views.size() == 4, "V24-FOUR-CARDS")
	var initial_hash: String = Model.state_hash(screen.snapshot)
	var first: Control = hud.card_views[0]
	screen.select_card(first.instance_id)
	check(first.selected_visual and hand.selected_instance == first.instance_id, "V24-SELECTED-PERSISTENT")
	check(first.z_index >= 50, "V24-SELECTED-ON-TOP")
	await create_timer(0.20).timeout
	check(first.face.position.y <= -30.0, "V24-SELECTED-LIFT")
	check(first.face.scale.x > 1.02, "V24-SELECTED-ENLARGE")
	check(Model.state_hash(screen.snapshot) == initial_hash, "V24-SELECT-NO-DOMAIN-WRITE")
	screen.present(_case(4))
	check(hud.card_views[0].selected_visual, "V24-SELECTION-SURVIVES-RENDER")
	screen.cancel_action()
	check(hand.selected_instance.is_empty() and not hud.card_views[0].selected_visual, "V24-CANCEL-REMOVES-SELECTION")
	screen.present(_case(1))
	check(hud.card_views.size() == 1, "V24-ONE-CARD")
	# CardInstance transition uses the original 0.18s SimpleCards tween; measure settled pose.
	await create_timer(0.22).timeout
	check(absf((hud.card_views[0].position.x + hud.card_views[0].size.x * 0.5) - hand.size.x * 0.5) < 12.0, "V24-ONE-CARD-CENTERED")
	screen.present(_case(8))
	check(hud.card_views.size() == 8, "V24-EIGHT-CARDS")
	var eight_hash: String = Model.state_hash(screen.snapshot)
	var seen: Dictionary = {}
	for i: int in hud.card_views.size():
		var c: Control = hud.card_views[i]
		seen[c.instance_id] = true
		check(c.focus_mode != Control.FOCUS_NONE, "V24-FOCUSABLE-%d" % i)
		screen.select_card(c.instance_id)
		check(c.selected_visual and c.z_index >= 50, "V24-REVEAL-ALL-%d" % i)
	check(seen.size() == 8, "V24-EIGHT-UNIQUE")
	check(Model.state_hash(screen.snapshot) == eight_hash, "V24-EIGHT-NO-DOMAIN-WRITE")
	for dimensions: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = dimensions
		await process_frame
		var safe: bool = true
		for card: Control in hud.card_views:
			safe = safe and card.position.x >= 0.0 \
				and card.position.x + card.size.x <= hud.hand.size.x + 1.0 \
				and card.position.y >= 0.0 and card.position.y + card.size.y <= hud.hand.size.y + 1.0
		check(safe, "V24-EIGHT-SAFE-RECT-%d" % dimensions.x)
	screen.set_locale("en")
	check(screen.hud.hand.get_node("EmptyState") != null, "V24-EN-EMPTY-READY")
	screen.set_locale("zh_TW")
	check(screen.hud.hand.get_node("EmptyState") != null, "V24-ZH-EMPTY-READY")
	screen.select_actor("B")
	check(screen.pending_card.is_empty() and screen.hud.hand.selected_instance.is_empty(), "V24-SWITCH-CLEARS")
	screen.queue_free()
	await process_frame
	print("V24_HAND_REPORT executed=%d passed=%d failed=%d" % [executed, executed - failed, failed])
	quit(0 if failed == 0 else 1)

