extends SceneTree
## V3.4 Hero/Command UI visual identity. Strictly read-only projection.
const Scene = preload("res://scenes/battle/battle_screen.tscn")
const CommandScene = preload("res://scenes/battle/ui/command_menu.tscn")
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const Tokens = preload("res://scripts/battle/ui/components/battle_visual_tokens.gd")
var executed: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, id: String) -> void:
	executed += 1
	if not value:
		failures += 1
	print(("PASS " if value else "FAIL ") + id)

func run() -> void:
	root.size = Vector2i(1280, 720)
	var screen: Control = Scene.instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame
	var hud: Control = screen.hud
	var before: String = Model.state_hash(screen.snapshot)
	check(hud.roster.size() == 3, "V34-THREE-HEROES")
	for id: String in ["A", "B", "C"]:
		var hero: Button = hud.roster[id]
		var actor: Dictionary = hud.vm["actors"][id]
		var hp: ProgressBar = hero.hp_bar
		var mp: ProgressBar = hero.mana_bar
		check(hero.hero_id == id, "V34-ID-" + id)
		check(hero.has_node("Layout/PortraitFrame/Portrait"), "V34-PORTRAIT-" + id)
		check(hero.portrait.texture != null, "V34-REAL-PORTRAIT-" + id)
		check(hp.name == "HeroHPBar" and mp.name == "HeroMPBar", "V34-BAR-NAMES-" + id)
		check(hp.get_parent() == hero.get_node("Layout/Stats"), "V34-HP-SIBLING-" + id)
		check(mp.get_parent() == hero.get_node("Layout/Stats"), "V34-MP-SIBLING-" + id)
		check(not hp.show_percentage and not mp.show_percentage, "V34-NO-PERCENT-" + id)
		check(hp.mouse_filter == Control.MOUSE_FILTER_IGNORE and mp.mouse_filter == Control.MOUSE_FILTER_IGNORE, "V34-NONINTERACTIVE-BARS-" + id)
		check(is_equal_approx(float(hp.value), float(actor["hp"])), "V34-TRUE-HP-" + id)
		check(is_equal_approx(float(hp.max_value), maxf(1.0,float(actor["max_hp"]))), "V34-TRUE-HP-MAX-" + id)
		check(is_equal_approx(float(mp.value), float(actor["mp"])), "V34-TRUE-MP-" + id)
		check(is_equal_approx(float(mp.max_value), maxf(1.0,float(actor["max_mp"]))), "V34-TRUE-MP-MAX-" + id)
		var hp_fill: StyleBoxFlat = hp.get_theme_stylebox("fill")
		var mp_fill: StyleBoxFlat = mp.get_theme_stylebox("fill")
		check(hp_fill.bg_color == Tokens.HERO_HP and mp_fill.bg_color == Tokens.HERO_MP, "V34-RESOURCE-SEMANTICS-" + id)
		check(hero.get_theme_stylebox("focus") is StyleBoxFlat, "V34-KEYBOARD-FOCUS-" + id)
		check(hero.get_node("FantasyBorder") is NinePatchRect, "V34-EXISTING-FRAME-" + id)
		check(hero.get_theme_stylebox("normal") is StyleBoxFlat, "V34-HERO-SKIN-" + id)
	check(hud.roster["A"].button_pressed, "V34-INITIAL-A-SELECTED")
	screen.select_actor("B")
	check(hud.roster["B"].button_pressed and not hud.roster["A"].button_pressed, "V34-ACTOR-B-VISUAL")
	check((hud.roster["A"].get_theme_stylebox("normal") as StyleBoxFlat).border_color !=
		(hud.roster["B"].get_theme_stylebox("normal") as StyleBoxFlat).border_color, "V34-SELECTED-BORDER-DISTINCT")
	check(Model.state_hash(screen.snapshot) == before, "V34-ACTOR-SWITCH-NO-DOMAIN-CHANGE")
	screen.select_actor("A")
	check(Model.state_hash(screen.snapshot) == before, "V34-RETURN-A-NO-DOMAIN-CHANGE")

	var commands: Control = hud.get_node("Commands")
	check(commands.command_buttons.size() == 6, "V34-ALL-SIX-COMMAND-BUTTONS")
	check(commands.end_button == hud.end_button, "V34-END-BUTTON-FACADE")
	for key: String in ["BATTLE_BASIC", "BATTLE_ANALYZE", "BATTLE_ITEM",
		"BATTLE_SWAP", "BATTLE_LAST", "BATTLE_END"]:
		var button: Button = commands.command_buttons[key]
		check(button.get_theme_stylebox("normal") is StyleBoxFlat, "V34-COMMAND-NORMAL-" + key)
		check(button.get_theme_stylebox("hover") is StyleBoxFlat, "V34-COMMAND-HOVER-" + key)
		check(button.get_theme_stylebox("focus") is StyleBoxFlat, "V34-COMMAND-FOCUS-" + key)
		check(button.get_node("AccentRail") is ColorRect, "V34-COMMAND-RAIL-" + key)
		check(button.get_node("AccentRail").mouse_filter == Control.MOUSE_FILTER_IGNORE,
			"V34-RAIL-DOES-NOT-STEAL-INPUT-" + key)
	check(commands.command_buttons["BATTLE_LAST"].get_node("AccentRail").color == Tokens.COMMAND_LAST,
		"V34-LAST-SPELL-ACCENT")
	check(commands.command_buttons["BATTLE_END"].get_node("AccentRail").color == Tokens.COMMAND_END,
		"V34-END-PHASE-ACCENT")
	check(commands.command_buttons["BATTLE_ANALYZE"].get_node("AccentRail").color == Tokens.COMMAND_UTILITY,
		"V34-UNIMPLEMENTED-UTILITY-IDENTITY")

	# Verify event names on an isolated command component rather than triggering Domain.
	var separate: Control = CommandScene.instantiate()
	root.add_child(separate)
	await process_frame
	var observed: Array[String] = []
	separate.command_requested.connect(func(kind: String, _fields: Dictionary) -> void:
		observed.append(kind))
	for key: String in ["BATTLE_BASIC", "BATTLE_SWAP", "BATTLE_LAST", "BATTLE_END",
		"BATTLE_ANALYZE", "BATTLE_ITEM"]:
		separate.command_buttons[key].pressed.emit()
	check(observed == ["BASIC_ATTACK_RESOURCE_ONLY", "FREE_SWAP", "ACTIVATE_LAST_SPELL_M4",
		"END_PLAYER_PHASE", "UNIMPLEMENTED", "UNIMPLEMENTED"],
		"V34-COMMAND-EVENTS-UNCHANGED")
	separate.queue_free()

	var phase_projection: Dictionary = hud.vm.duplicate(true)
	phase_projection["phase"] = "ENEMY_PHASE"
	commands.render_commands(phase_projection)
	check(hud.end_button.disabled, "V34-END-PHASE-DISABLED")
	phase_projection["phase"] = "PLAYER_PHASE"
	commands.render_commands(phase_projection)
	check(not hud.end_button.disabled, "V34-END-PHASE-ENABLED")
	check(Model.state_hash(screen.snapshot) == before, "V34-COMMAND-UI-NO-DOMAIN-CHANGE")

	for dim: Vector2i in [Vector2i(1280,720), Vector2i(1920,1080)]:
		root.size = dim
		await process_frame
		var all_safe := true
		var bounds: Rect2 = hud.get_node("PartyStatusPanel").get_global_rect()
		for hero: Button in hud.roster.values():
			all_safe = all_safe and bounds.encloses(hero.get_global_rect())
		check(all_safe, "V34-ROSTER-BOUNDS-%d" % dim.x)
		check(hud.get_node("Commands").get_global_rect().encloses(hud.end_button.get_global_rect()),
			"V34-COMMAND-BOUNDS-%d" % dim.x)
	screen.set_locale("en")
	hud = screen.hud
	check(hud.roster.size() == 3 and hud.end_button.text == "End phase", "V34-EN-REBIND")
	check(hud.roster["A"].hp_bar != null and hud.roster["A"].mana_bar != null,
		"V34-EN-BARS-REBIND")
	screen.set_locale("zh_TW")
	hud = screen.hud
	check(hud.end_button.text == "結束階段", "V34-ZH-REBIND")
	check(hud.roster["A"].hp_bar != null and hud.roster["A"].mana_bar != null,
		"V34-ZH-BARS-REBIND")
	check(Model.state_hash(screen.snapshot) == before, "V34-LOCALE-NO-DOMAIN-CHANGE")
	screen.queue_free()
	await process_frame
	print("V34_ROSTER_COMMAND_REPORT executed=%d passed=%d failed=%d" %
		[executed, executed-failures, failures])
	quit(0 if failures == 0 else 1)

