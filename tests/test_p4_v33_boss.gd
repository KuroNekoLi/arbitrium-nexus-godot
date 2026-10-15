extends SceneTree
## V3.3 semantic display and layout contract; never modifies battle state.
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

func _sample_intent() -> Array:
	return [{
		"name_key": "BATTLE_ATTACK",
		"skill_id": "ATTACK",
		"target_ids": ["A", "B"],
		"hit_count": 2
	}]

func _layout_safe(panel: Control) -> bool:
	var outer: Rect2 = panel.get_global_rect()
	var nodes: Array[Control] = [
		panel.boss_title, panel.boss_stats, panel.hp_bar,
		panel.intent_panel, panel.intent
	]
	if panel.break_section.visible:
		nodes.append(panel.break_stats)
		nodes.append(panel.break_bar)
	for node: Control in nodes:
		if not node.is_visible_in_tree():
			continue
		var rect: Rect2 = node.get_global_rect()
		if rect.position.x < outer.position.x - 1.0 or rect.end.x > outer.end.x + 1.0:
			return false
		if rect.position.y < outer.position.y - 1.0 or rect.end.y > outer.end.y + 1.0:
			return false
	return true

func run() -> void:
	root.size = Vector2i(1280, 720)
	var screen: Control = Scene.instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame
	var panel: Control = screen.hud.get_node("EnemyStatus")
	var state_hash: String = Model.state_hash(screen.snapshot)
	var projection: Dictionary = screen.hud.vm.duplicate(true)

	check(panel.boss_title != null and panel.boss_stats != null, "V33-V1-BOSS-ALIASES")
	check(panel.hp_bar != null and panel.break_bar != null, "V33-V31-BAR-ALIASES")
	check(panel.break_stats != null and panel.intent != null, "V33-V31-LABEL-ALIASES")
	check(panel.boss_title.name == "BossName", "V33-IDENTITY-NODE")
	check(panel.title_plate.name == "BossTitlePlate", "V33-IDENTITY-PLATE")
	check(panel.get_node("BossContent/BossTitlePlate/IdentityAccent") is ColorRect, "V33-METAL-ACCENT")
	check(panel.get_node("BossContent/HeaderRule") is PanelContainer, "V33-ORNAMENT-RULE")
	check(panel.intent_panel.name == "PublishedIntentPanel", "V33-INTENT-CONTAINER")
	check(panel.intent_panel.get_theme_stylebox("panel") is StyleBoxFlat, "V33-INTENT-STYLE")
	check(panel.intent_panel.get_node("IntentRow/IntentAccent").color == Tokens.INTENT, "V33-WARM-WARNING-ACCENT")
	check(panel.intent.get_parent().name == "IntentContent", "V33-INTENT-INSET-LABEL")
	check(panel.intent.max_lines_visible == 2, "V33-COMPACT-INTENT")
	check(panel.hp_bar.mouse_filter == Control.MOUSE_FILTER_IGNORE and panel.break_bar.mouse_filter == Control.MOUSE_FILTER_IGNORE, "V33-READONLY-BARS")

	# Exact read-model values are rendered as-is, no new target discovery.
	var boss: Dictionary = projection["actors"]["Boss"]
	var max_hp: int = int(boss.get("max_hp", 1))
	boss["hp"] = maxi(0, max_hp / 2)
	projection["tactical"] = {"break_gauge": 24, "break_max": 80, "break_locked": false, "exposed": {}}
	projection["intent"] = _sample_intent()
	panel.render_enemy(projection)
	check(is_equal_approx(float(panel.hp_bar.value), float(boss["hp"])), "V33-HP-PROJECTION")
	check(is_equal_approx(float(panel.hp_bar.max_value), float(maxi(max_hp, 1))), "V33-HP-MAX")
	check(is_equal_approx(float(panel.break_bar.value), 24.0), "V33-BREAK-PROJECTION")
	check(is_equal_approx(float(panel.break_bar.max_value), 80.0), "V33-BREAK-MAX")
	check(panel.break_section.visible and panel.break_stats.visible and panel.break_bar.visible, "V33-BREAK-PRESENT")
	check(panel.intent_panel.visible and not panel.intent.text.is_empty(), "V33-PUBLISHED-INTENT")
	check(panel.intent.text == panel.intent.tooltip_text, "V33-FULL-INTENT-TOOLTIP")
	check(panel.intent.text.contains("2"), "V33-PUBLIC-HIT-COUNT")
	check(Model.state_hash(screen.snapshot) == state_hash, "V33-DOMAIN-UNCHANGED")
	await process_frame
	check(_layout_safe(panel), "V33-1280-FULL-BOUNDS")

	# Withheld Intent must not create inferred targets or filler.
	projection["intent"] = []
	panel.render_enemy(projection)
	check(not panel.intent_panel.visible, "V33-ABSENT-INTENT-HIDDEN")
	check(panel.intent.text.is_empty() and panel.intent.tooltip_text.is_empty(), "V33-NO-INVENTED-INTENT")
	check(Model.state_hash(screen.snapshot) == state_hash, "V33-NO-INTENT-DOMAIN-UNCHANGED")
	projection["tactical"] = {}
	panel.render_enemy(projection)
	check(not panel.break_section.visible and not panel.break_bar.visible, "V33-ABSENT-BREAK-HIDDEN")
	check(not panel.break_stats.visible and panel.break_stats.text.is_empty(), "V33-NO-FAKE-BREAK")
	check(Model.state_hash(screen.snapshot) == state_hash, "V33-NO-BREAK-DOMAIN-UNCHANGED")
	await process_frame
	check(_layout_safe(panel), "V33-1280-COLLAPSED-BOUNDS")

	# Locked and Exposed are actual tactical flags, not UI-authored state.
	projection["intent"] = _sample_intent()
	projection["tactical"] = {"break_gauge": 0, "break_max": 80,
		"break_locked": true, "exposed": {"Boss": true}}
	panel.render_enemy(projection)
	check(panel.break_stats.text.contains(tr("BATTLE_BREAK_LOCKED")), "V33-LOCKED-TEXT")
	check(panel.break_stats.text.contains(tr("BATTLE_EXPOSED")), "V33-EXPOSED-TEXT")
	check(panel.break_stats.tooltip_text == panel.break_stats.text, "V33-FULL-BREAK-TOOLTIP")
	check(panel.break_stats.get_theme_color("font_color") == Tokens.INTENT, "V33-LOCKED-WARNING-COLOR")
	await process_frame
	check(_layout_safe(panel), "V33-1280-LOCKED-INTENT-BOUNDS")
	check(Model.state_hash(screen.snapshot) == state_hash, "V33-LOCKED-DOMAIN-UNCHANGED")

	# Keep overflow elided, preserve full source text in tooltips.
	var original_name: String = str(projection["actor_name_keys"].get("Boss", "BATTLE_TITLE"))
	projection["actor_name_keys"]["Boss"] = "BATTLE_INTENT_DETAIL"
	panel.render_enemy(projection)
	check(panel.boss_title.tooltip_text == panel.boss_title.text, "V33-IDENTITY-TOOLTIP")
	check(panel.boss_title.text_overrun_behavior == TextServer.OVERRUN_TRIM_ELLIPSIS, "V33-IDENTITY-ELLIPSIS")
	projection["actor_name_keys"]["Boss"] = original_name
	for viewport: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = viewport
		await process_frame
		panel.render_enemy(projection)
		check(_layout_safe(panel), "V33-LOCKED-INTENT-SAFE-%d" % viewport.x)
		check(Model.state_hash(screen.snapshot) == state_hash, "V33-HASH-%d" % viewport.x)
	screen.set_locale("en")
	panel = screen.hud.get_node("EnemyStatus")
	check(panel.intent_panel != null and panel.hp_bar != null, "V33-EN-COMPONENT-REBIND")
	check(panel.boss_stats.text.begins_with("HP"), "V33-EN-HP")
	screen.set_locale("zh_TW")
	panel = screen.hud.get_node("EnemyStatus")
	check(panel.intent_panel != null and panel.break_bar != null, "V33-ZHTW-COMPONENT-REBIND")
	check(panel.boss_stats.text.contains("生命"), "V33-ZHTW-HP")
	check(Model.state_hash(screen.snapshot) == state_hash, "V33-I18N-DOMAIN-UNCHANGED")
	screen.queue_free()
	await process_frame
	print("V33_BOSS_REPORT executed=%d passed=%d failed=%d" % [executed, executed - failed, failed])
	quit(0 if failed == 0 else 1)

