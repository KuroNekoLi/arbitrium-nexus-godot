extends SceneTree
## V3.1: semantic bars and Theme use genuine projection; no Domain transactions.
const Scene = preload("res://scenes/battle/battle_screen.tscn")
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const ThemeResource = preload("res://resources/ui/battle_theme.tres")
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

func run() -> void:
	root.size = Vector2i(1280, 720)
	var screen: Control = Scene.instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame
	var hud: Control = screen.hud
	var panel: Control = hud.get_node("EnemyStatus")
	var hp: ProgressBar = panel.hp_bar
	var breaks: ProgressBar = panel.break_bar
	var resource: Theme = ThemeResource
	check(resource != null and hud.theme == resource, "V31-CANONICAL-THEME")
	check(resource.get_stylebox("panel", "PanelContainer") is StyleBoxFlat, "V31-PANEL-STYLE")
	check(resource.get_stylebox("normal", "Button") is StyleBoxFlat, "V31-BUTTON-NORMAL")
	check(resource.get_stylebox("hover", "Button") is StyleBoxFlat, "V31-BUTTON-HOVER")
	check(resource.get_stylebox("disabled", "Button") is StyleBoxFlat, "V31-BUTTON-DISABLED")
	check(resource.get_stylebox("focus", "Button") is StyleBoxFlat, "V31-BUTTON-FOCUS")
	check(resource.get_stylebox("background", "ProgressBar") is StyleBoxFlat, "V31-TRACK-STYLE")
	check(hp != null and breaks != null and hp != breaks, "V31-SEPARATE-BARS")
	check(hp.name == "BossHPBar" and breaks.name == "BossBreakBar", "V31-BAR-NAMES")
	check(not hp.show_percentage and not breaks.show_percentage, "V31-NO-GUESSED-PERCENT-LABEL")
	check(hp.mouse_filter == Control.MOUSE_FILTER_IGNORE and breaks.mouse_filter == Control.MOUSE_FILTER_IGNORE, "V31-READONLY-BARS")
	check(hp.get_theme_stylebox("fill") is StyleBoxFlat and breaks.get_theme_stylebox("fill") is StyleBoxFlat, "V31-SEMANTIC-FILL")
	var hp_fill: StyleBoxFlat = hp.get_theme_stylebox("fill")
	var break_fill: StyleBoxFlat = breaks.get_theme_stylebox("fill")
	check(hp_fill.bg_color == Tokens.HP, "V31-HP-COLOR")
	check(break_fill.bg_color == Tokens.BREAK, "V31-BREAK-COLOR")
	check(hp_fill.bg_color != break_fill.bg_color, "V31-BAR-COLOR-DISTINCT")
	var before: String = Model.state_hash(screen.snapshot)
	var projection: Dictionary = hud.vm.duplicate(true)
	var boss: Dictionary = projection["actors"]["Boss"]
	var max_hp: int = int(boss["max_hp"])
	boss["hp"] = maxi(0, max_hp / 2)
	projection["tactical"] = {"break_gauge": 20, "break_max": 80, "break_locked": false, "exposed": {}}
	panel.render_enemy(projection)
	check(is_equal_approx(float(hp.max_value), float(maxi(max_hp, 1))), "V31-HP-REAL-MAX")
	check(is_equal_approx(float(hp.value), float(boss["hp"])), "V31-HP-REAL-VALUE")
	check(is_equal_approx(float(breaks.max_value), 80.0) and is_equal_approx(float(breaks.value), 20.0), "V31-BREAK-REAL-VALUE")
	check(breaks.visible and panel.break_stats.visible, "V31-BREAK-VISIBLE")
	check(panel.break_stats.text.contains("20") and panel.break_stats.text.contains("80"), "V31-BREAK-LABEL")
	check(Model.state_hash(screen.snapshot) == before, "V31-DOMAIN-UNCHANGED")
	projection["tactical"] = {}
	panel.render_enemy(projection)
	check(not breaks.visible and not panel.break_stats.visible, "V31-HIDE-ABSENT-BREAK")
	check(Model.state_hash(screen.snapshot) == before, "V31-DOMAIN-UNCHANGED-NO-BREAK")
	projection["tactical"] = {"break_gauge": -12, "break_max": 0, "break_locked": true, "exposed": {}}
	panel.render_enemy(projection)
	check(is_equal_approx(float(breaks.max_value), 1.0) and is_zero_approx(float(breaks.value)), "V31-SAFE-ZERO-BREAK-MAX")
	check(panel.break_stats.text.contains(tr("BATTLE_BREAK_LOCKED")), "V31-LOCKED-REAL-STATUS")
	projection["actors"]["Boss"]["hp"] = maxi(max_hp + 50, 1)
	panel.render_enemy(projection)
	check(hp.value <= hp.max_value, "V31-CLAMP-RENDER-ONLY")
	check(Model.state_hash(screen.snapshot) == before, "V31-CLAMP-DOMAIN-UNCHANGED")
	screen.set_locale("en")
	hud = screen.hud
	panel = hud.get_node("EnemyStatus")
	check(panel.hp_bar != null and panel.break_bar != null, "V31-EN-BARS-REBIND")
	check(panel.boss_stats.text.begins_with("HP"), "V31-EN-HP-LOCALIZED")
	screen.set_locale("zh_TW")
	hud = screen.hud
	panel = hud.get_node("EnemyStatus")
	check(panel.boss_stats.text.contains("生命"), "V31-ZHTW-HP-LOCALIZED")
	check(hud.card_views.size() == 4 and hud.reaction_panel != null, "V31-HUD-CONTRACT-REMAINS")
	screen.queue_free()
	await process_frame
	print("V31_VISUAL_REPORT executed=%d passed=%d failed=%d" % [executed, executed-failed, failed])
	quit(0 if failed == 0 else 1)

