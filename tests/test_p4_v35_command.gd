extends SceneTree
## V3.5.2 Bottom Left: command icons, subtitles and Last Spell / End emphasis.
## Presentation contract only. Analyze / Item remain UNIMPLEMENTED: an icon is
## asserted to NOT change their event, and their subtitle must say so.
const Scene = preload("res://scenes/battle/battle_screen.tscn")
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const CommandScene = preload("res://scenes/battle/ui/command_menu.tscn")
const Visual = preload("res://scripts/battle/ui/components/battle_command_visual.gd")
const KEYS: Array[String] = ["BATTLE_BASIC", "BATTLE_ANALYZE", "BATTLE_ITEM",
	"BATTLE_SWAP", "BATTLE_LAST", "BATTLE_END"]
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

func run() -> void:
	root.size = Vector2i(1280, 720)
	var screen: Control = Scene.instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame
	screen._command_requested("REDUCED_MOTION", {"enabled": true})
	var before: String = Model.state_hash(screen.snapshot)

	for locale: String in ["zh_TW", "en"]:
		screen.set_locale(locale)
		for dim: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
			root.size = dim
			await process_frame
			await process_frame
			var tag: String = "%s-%d" % [locale, dim.x]
			var commands: Control = screen.hud.get_node("Commands")
			var icons_ok := true
			var subs_ok := true
			var inside_ok := true
			for key: String in KEYS:
				var button: Button = commands.command_buttons[key]
				var sub: Label = button.get_node("Subtitle")
				icons_ok = icons_ok and button.icon != null and button.icon == Visual.icon_for(key)
				subs_ok = subs_ok and not sub.text.is_empty() and sub.text == screen.tr(Visual.subtitle_key(key))
				subs_ok = subs_ok and sub.text != Visual.subtitle_key(key)
				inside_ok = inside_ok and encloses(button, sub) and encloses(commands, button)
				inside_ok = inside_ok and sub.mouse_filter == Control.MOUSE_FILTER_IGNORE
			check(icons_ok, "V35C-ICONS-" + tag)
			check(subs_ok, "V35C-SUBTITLES-TRANSLATED-" + tag)
			check(inside_ok, "V35C-SUBTITLE-INSIDE-NONBLOCKING-" + tag)
			# Titles shrink-to-fit (>= 11pt) instead of collapsing to "Last Sp…".
			var titles_ok := true
			for key: String in KEYS:
				var button: Button = commands.command_buttons[key]
				var style: StyleBox = button.get_theme_stylebox("normal")
				var room: float = button.size.x - style.get_margin(SIDE_LEFT) - style.get_margin(SIDE_RIGHT) \
					- float(button.get_theme_constant("icon_max_width") + button.get_theme_constant("h_separation"))
				var size: int = button.get_theme_font_size("font_size")
				titles_ok = titles_ok and size >= 11 and button.get_theme_font("font").get_string_size(
					button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x <= room + 0.5
			check(titles_ok, "V35C-TITLES-FIT-" + tag)
	check(Model.state_hash(screen.snapshot) == before, "V35C-LAYOUT-NO-DOMAIN-CHANGE")

	root.size = Vector2i(1280, 720)
	screen.set_locale("zh_TW")
	await process_frame
	var commands: Control = screen.hud.get_node("Commands")
	var basic: Button = commands.command_buttons["BATTLE_BASIC"]
	for key: String in ["BATTLE_LAST", "BATTLE_END"]:
		var strong: Button = commands.command_buttons[key]
		var style: StyleBoxFlat = strong.get_theme_stylebox("normal")
		var plain: StyleBoxFlat = basic.get_theme_stylebox("normal")
		check(style.border_width_left >= 2 and style.border_width_left > plain.border_width_left
			and style.shadow_size > 0, "V35C-EMPHASIS-BORDER-GLOW-" + key)
		check(strong.custom_minimum_size.y > basic.custom_minimum_size.y, "V35C-EMPHASIS-TALLER-" + key)
		check(strong.get_theme_font_size("font_size") > basic.get_theme_font_size("font_size"),
			"V35C-EMPHASIS-FONT-" + key)
	check(not Visual.is_emphasis("BATTLE_ANALYZE") and not Visual.is_emphasis("BATTLE_ITEM"),
		"V35C-UNIMPLEMENTED-NOT-EMPHASIZED")
	check(Visual.subtitle_key("BATTLE_ANALYZE") == "BATTLE_UNIMPLEMENTED_SUB" and
		Visual.subtitle_key("BATTLE_ITEM") == "BATTLE_UNIMPLEMENTED_SUB", "V35C-UNIMPLEMENTED-HONEST-SUBTITLE")

	# Events are unchanged by the visual pass (isolated component, no Domain).
	var separate: Control = CommandScene.instantiate()
	root.add_child(separate)
	await process_frame
	var observed: Array = []
	separate.command_requested.connect(func(kind: String, _fields: Dictionary) -> void: observed.append(kind))
	for key: String in KEYS:
		separate.command_buttons[key].pressed.emit()
	check(observed == ["BASIC_ATTACK_RESOURCE_ONLY", "UNIMPLEMENTED", "UNIMPLEMENTED",
		"FREE_SWAP", "ACTIVATE_LAST_SPELL_M4", "END_PLAYER_PHASE"], "V35C-EVENTS-UNCHANGED")
	separate.queue_free()

	# Disabled End keeps a distinct, readable disabled surface.
	var projection: Dictionary = screen.hud.vm.duplicate(true)
	projection["phase"] = "ENEMY_PHASE"
	commands.render_commands(projection)
	var end: Button = commands.command_buttons["BATTLE_END"]
	check(end.disabled and end.get_theme_stylebox("disabled") != end.get_theme_stylebox("normal"),
		"V35C-END-DISABLED-SURFACE")
	projection["phase"] = "PLAYER_PHASE"
	commands.render_commands(projection)
	check(not end.disabled, "V35C-END-REENABLED")

	# Runtime locale switch re-translates subtitles and tooltips.
	screen.set_locale("en")
	await process_frame
	commands = screen.hud.get_node("Commands")
	var swap: Button = commands.command_buttons["BATTLE_SWAP"]
	check(swap.get_node("Subtitle").text == screen.tr("BATTLE_SWAP_SUB") and
		swap.tooltip_text.ends_with(screen.tr("BATTLE_SWAP_SUB")), "V35C-LOCALE-RETRANSLATE")
	check(Model.state_hash(screen.snapshot) == before, "V35C-FINAL-NO-DOMAIN-CHANGE")
	screen.queue_free()
	await process_frame
	print("V35_COMMAND_REPORT executed=%d passed=%d failed=%d" % [executed, executed - failed, failed])
	quit(0 if failed == 0 else 1)
