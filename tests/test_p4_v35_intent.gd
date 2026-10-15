extends SceneTree
## V3.5.3 Top Right: intent icon, public hit-count chip and target badges.
## Badges come only from projection.intent[0].target_ids. Boss AI is untouched;
## MOCK_ONLY projections are display boundaries and never reach the Domain.
const Scene = preload("res://scenes/battle/battle_screen.tscn")
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const Tokens = preload("res://scripts/battle/ui/components/battle_visual_tokens.gd")
var executed: int = 0
var failed: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, id: String) -> void:
	executed += 1
	if not ok:
		failed += 1
	print(("PASS " if ok else "FAIL ") + id)

func encloses(outer: Control, inner: Control) -> bool:
	return outer.get_global_rect().grow(1.0).encloses(inner.get_global_rect())

## Non-empty chips must be at least as wide as their text (catches
## ellipsis-collapsed chips that render as empty capsules, V3.5.5 VIS09).
func text_fits(label: Label) -> bool:
	if label.text.is_empty():
		return true
	var width: float = label.get_theme_font("font").get_string_size(label.text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size")).x
	return label.visible and label.size.x + 0.5 >= width

func sample(targets: Array, hits: int) -> Array:
	return [{"name_key": "BATTLE_ATTACK", "skill_id": "ATTACK", "target_ids": targets, "hit_count": hits}]

func run() -> void:
	root.size = Vector2i(1280, 720)
	var screen: Control = Scene.instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame
	screen._command_requested("REDUCED_MOTION", {"enabled": true})
	var before: String = Model.state_hash(screen.snapshot)
	var panel: Control = screen.hud.get_node("EnemyStatus")

	check(panel.intent_icon != null and panel.intent_icon.texture != null, "V35I-ICON-PRESENT")
	check(panel.intent_icon.mouse_filter == Control.MOUSE_FILTER_IGNORE, "V35I-ICON-NONBLOCKING")
	check(panel.intent_panel.get_node("IntentRow/IntentAccent").color == Tokens.INTENT, "V35I-V33-ACCENT-PRESERVED")

	# MOCK_ONLY: two targets, 2 hits, in two locales × two resolutions.
	for locale: String in ["zh_TW", "en"]:
		screen.set_locale(locale)
		for dim: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
			root.size = dim
			await process_frame
			panel = screen.hud.get_node("EnemyStatus")
			var projection: Dictionary = screen.hud.vm.duplicate(true)
			projection["intent"] = sample(["A", "B"], 2)
			panel.render_enemy(projection)
			await process_frame
			await process_frame
			var tag: String = "%s-%d" % [locale, dim.x]
			check(panel.target_badge_ids() == ["A", "B"], "V35I-MOCK-TARGETS-EXACT-" + tag)
			check(panel.hit_chip.visible and panel.hit_chip.text == "×2", "V35I-MOCK-HIT-CHIP-" + tag)
			var names_ok := true
			var inside := true
			for chip: Label in panel.target_badges.get_children():
				var id: String = str(chip.name).trim_prefix("Target_")
				var expected: String = screen.tr("BATTLE_HERO_" + id)
				names_ok = names_ok and chip.text == expected
				names_ok = names_ok and chip.tooltip_text == screen.tr("BATTLE_INTENT_TARGET") % expected
				inside = inside and encloses(panel, chip) and chip.mouse_filter == Control.MOUSE_FILTER_IGNORE
			check(names_ok, "V35I-MOCK-TARGET-NAMES-" + tag)
			check(inside and encloses(panel, panel.hit_chip) and encloses(panel, panel.intent_icon),
				"V35I-MOCK-INSIDE-PANEL-" + tag)
			check(panel.intent.text.contains("2"), "V35I-V33-DETAIL-KEPT-" + tag)
			var fits := text_fits(panel.hit_chip)
			for chip: Label in panel.target_badges.get_children():
				fits = fits and text_fits(chip)
			check(fits, "V35I-CHIP-TEXT-VISIBLE-" + tag)
	check(Model.state_hash(screen.snapshot) == before, "V35I-MOCK-NO-DOMAIN-CHANGE")

	# Withheld intent / no targets / no hit_count: nothing invented.
	root.size = Vector2i(1280, 720)
	screen.set_locale("zh_TW")
	await process_frame
	panel = screen.hud.get_node("EnemyStatus")
	var empty: Dictionary = screen.hud.vm.duplicate(true)
	empty["intent"] = []
	panel.render_enemy(empty)
	check(not panel.intent_panel.visible and panel.target_badge_ids().is_empty() and not panel.hit_chip.visible,
		"V35I-ABSENT-NO-BADGES")
	var untargeted: Dictionary = screen.hud.vm.duplicate(true)
	untargeted["intent"] = [{"name_key": "BATTLE_ATTACK", "skill_id": "ATTACK", "target_ids": []}]
	panel.render_enemy(untargeted)
	check(panel.intent_panel.visible and panel.target_badge_ids().is_empty() and not panel.target_badges.visible,
		"V35I-NO-TARGETS-NOT-INFERRED")
	check(not panel.hit_chip.visible, "V35I-NO-HITCOUNT-NOT-INFERRED")
	var single: Dictionary = screen.hud.vm.duplicate(true)
	single["intent"] = sample(["C"], 1)
	panel.render_enemy(single)
	check(panel.target_badge_ids() == ["C"] and panel.hit_chip.text == "×1", "V35I-RERENDER-REPLACES")

	# Real Domain intent: end the player phase and read the published intent.
	screen._command_requested("END_PLAYER_PHASE", {})
	await process_frame
	await process_frame
	var published: Array = screen.snapshot.get("published_intents", [])
	check(not published.is_empty(), "V35I-REAL-INTENT-PUBLISHED")
	panel = screen.hud.get_node("EnemyStatus")
	if not published.is_empty():
		var real_targets: Array = []
		for t: Variant in published[0].get("target_ids", []):
			real_targets.append(str(t))
		check(panel.target_badge_ids() == real_targets, "V35I-REAL-TARGETS-MATCH-DOMAIN")
		var view_hits: Variant = screen.view_model["intent"][0].get("hit_count", null)
		check((view_hits == null and not panel.hit_chip.visible) or
			(view_hits != null and panel.hit_chip.text == "×%d" % int(view_hits)), "V35I-REAL-HITS-MATCH-VIEW")
	else:
		check(false, "V35I-REAL-TARGETS-MATCH-DOMAIN")
		check(false, "V35I-REAL-HITS-MATCH-VIEW")
	screen.queue_free()
	await process_frame
	print("V35_INTENT_REPORT executed=%d passed=%d failed=%d" % [executed, executed - failed, failed])
	quit(0 if failed == 0 else 1)
