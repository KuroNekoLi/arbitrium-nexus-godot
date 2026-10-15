extends SceneTree
## Headless V3 merge boundaries; no input injection or historical GUI reruns.
const Scene = preload("res://scenes/battle/battle_screen.tscn")
const Fixture = preload("res://tests/fixtures/m5_full_battle_fixture.gd")
const Model = preload("res://scripts/domain/m1/combat_model.gd")
var executed: int = 0
var failed: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, id: String) -> void:
	executed += 1
	if not ok:
		failed += 1
	print(("PASS " if ok else "FAIL ") + id)

func _labels_fit(card: Control) -> bool:
	var face: Control = card.face
	var local_bounds := Rect2(Vector2.ZERO, face.size).grow(1.0)
	for path: String in ["CostRow/CostBadge/CostLabel", "CardName", "CardDescription"]:
		var item: Control = face.get_node("CardContents/" + path)
		var transform: Transform2D = face.get_global_transform().affine_inverse() * item.get_global_transform()
		for point: Vector2 in [Vector2.ZERO, Vector2(item.size.x, 0), item.size, Vector2(0, item.size.y)]:
			if not local_bounds.has_point(transform * point):
				return false
	return true

func run() -> void:
	var screen: Control = Scene.instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame
	for locale: String in ["zh_TW", "en"]:
		screen.set_locale(locale)
		for resolution: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
			root.size = resolution
			for active: bool in [true, false]:
				var state: Dictionary = Fixture.initial()
				if not active:
					state["core"]["battle"]["actors"]["A"]["status"] = "EXHAUSTED"
				screen.present(state)
				await create_timer(0.35).timeout
				var before: String = Model.state_hash(screen.snapshot)
				var card: Control = screen.hud.card_views[0]
				var prefix: String = "V3-MERGE-%s-%d-%s-" % [locale, resolution.x, str(active)]
				check(card.legal == active, prefix + "TRUE-LEGALITY")
				check(card.face.size.x <= 164.0 and card.face.size.y <= 218.0, prefix + "BOUNDED-FACE")
				check(_labels_fit(card), prefix + "LABELS-WITHIN-FACE")
				check(card.tooltip_text.contains(card.tr(card.appearance.description_key)), prefix + "FULL-DESCRIPTION")
				var reason: Label = card.face.get_node_or_null("CardContents/UnavailableReason")
				check(reason == null if active else reason != null and reason.tooltip_text == card.unavailable_reason,
					prefix + "UNAVAILABLE-REASON")
				card.set_selected_visual(true)
				card.set_selected_visual(false)
				check(card._style.border_color == card._idle_style.border_color, prefix + "IDLE-BORDER-RESTORED")
				check(card._style.shadow_size == card._idle_style.shadow_size and
					card._style.shadow_color == card._idle_style.shadow_color, prefix + "IDLE-SHADOW-RESTORED")
				# Layout-only stress fixture: labels are not authoritative content.
				for path: String in ["CostRow/CostBadge/CostLabel", "CardName", "CardDescription"]:
					var label: Label = card.face.get_node("CardContents/" + path)
					label.text = label.text.repeat(16)
				await create_timer(0.20).timeout
				check(card.face.size.x <= 164.0 and card.face.size.y <= 218.0, prefix + "LONG-FACE")
				check(_labels_fit(card), prefix + "LONG-LABELS")
				check(Model.state_hash(screen.snapshot) == before, prefix + "DOMAIN-UNCHANGED")
	screen.queue_free()
	await process_frame
	print("V3_MERGE_REPORT executed=%d passed=%d failed=%d" % [executed, executed - failed, failed])
	quit(0 if failed == 0 else 1)
