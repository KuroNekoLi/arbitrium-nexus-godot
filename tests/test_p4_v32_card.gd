extends SceneTree
## V3.2 visual source contract. No Gameplay operation and no gameplay snapshots fabricated.
const Scene = preload("res://scenes/battle/battle_screen.tscn")
const Encounter = preload("res://tests/fixtures/m5_full_battle_fixture.gd")
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const Frame = preload("res://scripts/battle/ui/components/battle_card_frame.gd")
var checks: int = 0
var errors: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, id: String) -> void:
	checks += 1
	if not ok:
		errors += 1
	print(("PASS " if ok else "FAIL ") + id)

func _fixture(count: int) -> Dictionary:
	var state: Dictionary = Encounter.initial()
	var zones: Dictionary = state["core"]["cards"]["actors"]["A"]["zones"]
	while zones["hand"].size() > count:
		zones["draw"].append(zones["hand"].pop_back())
	while zones["hand"].size() < count and not zones["draw"].is_empty():
		zones["hand"].append(zones["draw"].pop_back())
	return state

func _assert_frame(card: Control, key: String) -> void:
	var root: PanelContainer = card.face
	var body: Node = root.get_node("CardContents")
	var cost: Label = body.get_node("CostRow/CostBadge/CostLabel")
	var art: TextureRect = body.get_node("ArtworkFrame/Artwork")
	var title: Label = body.get_node("CardName")
	var description: Label = body.get_node("CardDescription")
	check(card is Card, key + "-SIMPLECARDS-SUBCLASS")
	check(root.mouse_filter == Control.MOUSE_FILTER_IGNORE, key + "-FACE-INPUT-TRANSPARENT")
	check(card.drag_threshold == 12, key + "-DRAG-THRESHOLD")
	check(cost.text == card.cost_text, key + "-TRUE-COST")
	check(cost.autowrap_mode == TextServer.AUTOWRAP_OFF, key + "-COST-NO-WRAP")
	check(art.texture == card.appearance.artwork, key + "-TRUE-ARTWORK")
	check(title.text == card.tr(card.appearance.name_key), key + "-I18N-NAME")
	check(description.text == card.tr(card.appearance.description_key), key + "-I18N-DESCRIPTION")
	check(art.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_COVERED, key + "-ART-SCALING")
	check(body.get_node("OrnamentalRule") is PanelContainer, key + "-FRAME-RULE")
	check(body.get_node("CostRow/CostBadge") is PanelContainer, key + "-BADGE-REUSABLE")
	check(root.get_theme_stylebox("panel") == card._style, key + "-EXISTING-SELECT-STYLE")

func run() -> void:
	root.size = Vector2i(1280, 720)
	var screen: Control = Scene.instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame
	var hash: String = Model.state_hash(screen.snapshot)
	var hud: Control = screen.hud
	check(hud.card_views.size() == 4, "V32-FOUR-CARD-HAND")
	_assert_frame(hud.card_views[0], "V32-FIRST")
	_assert_frame(hud.card_views[3], "V32-FOURTH")
	check(hud.card_views[0].face.get_node("CardContents") != null, "V32-ALIAS-PRESENT")
	var first: Control = hud.card_views[0]
	var second: Control = hud.card_views[1]
	check(first._style != second._style, "V32-UNIQUE-MUTABLE-STYLES")
	var selected_id: String = first.instance_id
	screen.select_card(selected_id)
	check(first.selected_visual and first.z_index >= 50, "V32-SELECTED-STILL-WORKS")
	check(second._style.border_color != Color("#FFE8A3"), "V32-SELECTION-ISOLATED")
	await create_timer(0.20).timeout
	check(first.face.position.y <= -30.0, "V32-SELECTED-FACE-LIFT")
	screen.cancel_action()
	check(not first.selected_visual, "V32-CANCEL-CLEARS-VISUAL")
	check(Model.state_hash(screen.snapshot) == hash, "V32-NO-DOMAIN-MUTATION")

	var ready := Frame.outer_frame(Color("#71D5F1"), true)
	var unavailable := Frame.outer_frame(Color("#71D5F1"), false)
	check(ready.border_color != unavailable.border_color, "V32-ILLEGAL-SEMANTIC-STROKE")
	check(Frame.cost_frame(Color("#71D5F1"), true).border_color !=
		Frame.cost_frame(Color("#71D5F1"), false).border_color, "V32-ILLEGAL-COST-BADGE")
	check(Frame.illustration_frame().bg_color != Frame.outer_frame(Color.WHITE, true).bg_color,
		"V32-ART-FRAME-LAYERED")

	screen.present(_fixture(8))
	check(hud.card_views.size() == 8, "V32-EIGHT-INSTANCE-VIEWS")
	var ids: Dictionary = {}
	for card: Control in hud.card_views:
		ids[card.instance_id] = true
		check(card.face.has_node("CardContents/ArtworkFrame/Artwork"), "V32-EIGHT-HAS-ART")
	check(ids.size() == 8, "V32-ALL-CARD-INSTANCE-IDS")
	var eight_hash: String = Model.state_hash(screen.snapshot)
	screen.set_locale("en")
	hud = screen.hud
	check(hud.card_views.size() == 8, "V32-EN-PRESERVES-ACTIVE-HAND")
	_assert_frame(hud.card_views[0], "V32-EN")
	screen.set_locale("zh_TW")
	hud = screen.hud
	check(hud.card_views.size() == 8, "V32-ZHTW-PRESERVES-ACTIVE-HAND")
	_assert_frame(hud.card_views[0], "V32-ZHTW")
	check(Model.state_hash(screen.snapshot) != "", "V32-HASH-AVAILABLE")
	check(eight_hash != "", "V32-EIGHT-HASH-AVAILABLE")
	screen.queue_free()
	await process_frame
	print("V32_CARD_REPORT executed=%d passed=%d failed=%d" % [checks, checks - errors, errors])
	quit(0 if errors == 0 else 1)

