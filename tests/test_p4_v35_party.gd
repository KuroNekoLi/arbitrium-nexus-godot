extends SceneTree
## V3.5.1 Top Left: party identity, status badges and AP/RP header tuning.
## Headless contract. Keyboard selection goes through Viewport.push_input;
## real mouse GUI picking needs a windowed renderer and stays in the existing
## test_p4_v34_gui_input.gd scope (GUI_NOT_VERIFIED unless that suite is run).
## MOCK_ONLY projections are display boundaries and never reach the Domain.
const Scene = preload("res://scenes/battle/battle_screen.tscn")
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const Factory = preload("res://scripts/battle/battle_command_factory.gd")
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

func press_key(code: Key) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventKey.new()
		event.physical_keycode = code
		event.keycode = code
		event.pressed = pressed
		root.push_input(event)
	await process_frame

func card_id(state: Dictionary, actor: String, definition: String) -> String:
	var own: Dictionary = state["core"]["cards"]["actors"][actor]
	for id: String in own["zones"]["hand"]:
		if own["instances"][id]["definition_id"] == definition:
			return id
	return ""

func encloses(outer: Control, inner: Control) -> bool:
	return outer.get_global_rect().grow(1.0).encloses(inner.get_global_rect())

## Empty labels pass; non-empty labels must be at least as wide as their text
## (catches ellipsis-collapsed pills that render as empty capsules).
func text_fits(label: Label) -> bool:
	if label.text.is_empty():
		return true
	var width: float = label.get_theme_font("font").get_string_size(label.text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size")).x
	return label.visible and label.size.x + 0.5 >= width

func run() -> void:
	root.size = Vector2i(1280, 720)
	var screen: Control = Scene.instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame
	screen._command_requested("REDUCED_MOTION", {"enabled": true})
	var before: String = Model.state_hash(screen.snapshot)

	# 1) Structure + geometry in two locales × two resolutions.
	for locale: String in ["zh_TW", "en"]:
		screen.set_locale(locale)
		for dim: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
			root.size = dim
			await process_frame
			await process_frame
			var hud: Control = screen.hud
			var panel: Control = hud.get_node("PartyStatusPanel")
			var tag: String = "%s-%d" % [locale, dim.x]
			var all_ok := true
			for id: String in ["A", "B", "C"]:
				var hero: Button = hud.roster[id]
				all_ok = all_ok and encloses(panel, hero)
				all_ok = all_ok and hero.hp_bar.custom_minimum_size.y >= 8 and hero.mana_bar.custom_minimum_size.y >= 8
				all_ok = all_ok and hero.hp_bar.has_node("BarCrest") and hero.mana_bar.has_node("BarCrest")
				for label: Label in [hero.name_label, hero.hp_label, hero.mana_label]:
					all_ok = all_ok and encloses(hero, label)
				all_ok = all_ok and encloses(hero, hero.get_node("Layout/Stats/Subtitle"))
			check(all_ok, "V35P-ROSTER-GEOMETRY-" + tag)
			var hero_a: Button = hud.roster["A"]
			check(hero_a.status_badges != null and hero_a.get_node("Layout/PortraitFrame").is_ancestor_of(hero_a.status_badges),
				"V35P-BADGE-SLOT-ON-PORTRAIT-" + tag)
			check(hero_a.get_node("Layout/Stats/Subtitle").get_theme_stylebox("normal") is StyleBoxFlat,
				"V35P-STATUS-PILL-" + tag)
			var pills_ok := true
			for id: String in ["A", "B", "C"]:
				pills_ok = pills_ok and text_fits(hud.roster[id].get_node("Layout/Stats/Subtitle"))
			check(pills_ok, "V35P-STATUS-PILL-TEXT-VISIBLE-" + tag)
			var header: Control = hud.get_node("TopBar")
			var resource: Control = header.get_node("ResourcePanel")
			check(resource.size.y <= 64 and encloses(resource, header.rp_value) and encloses(resource, header.ap_value),
				"V35P-HEADER-COMPACT-" + tag)
			check(header.rp_value.text == "RP %d" % int(hud.vm["resources"]["rp"]) and
				header.ap_value.text == "%d AP" % int(hud.vm["resources"]["current_ap"]),
				"V35P-HEADER-TRUE-VALUES-" + tag)
	check(Model.state_hash(screen.snapshot) == before, "V35P-LAYOUT-NO-DOMAIN-CHANGE")

	root.size = Vector2i(1280, 720)
	screen.set_locale("zh_TW")
	await process_frame
	var hud: Control = screen.hud
	var header: Control = hud.get_node("TopBar")
	check(header.rp_value.get_theme_font_size("font_size") >= 13 and
		header.get_node("ResourcePanel").find_child("APCaption", true, false).get_theme_font_size("font_size") >= 13,
		"V35P-HEADER-CAPTION-RP-LEGIBLE")
	check((header.get_node("ResourcePanel").find_child("ResourceFrame", true, false) as NinePatchRect).modulate == header.FRAME_TINT,
		"V35P-HEADER-DARK-GOLD-FRAME")

	# 2) Selection identity: keyboard dispatch, distinct selected/hover/focus.
	check(hud.roster["A"].button_pressed, "V35P-INITIAL-A")
	for pair: Array in [[KEY_2, "B"], [KEY_3, "C"], [KEY_1, "A"]]:
		await press_key(pair[0])
		hud = screen.hud
		var only: bool = true
		for id: String in ["A", "B", "C"]:
			only = only and (hud.roster[id].button_pressed == (id == pair[1]))
		check(screen.selected_actor == pair[1] and only, "V35P-KEY-SELECT-" + pair[1])
		check(Model.state_hash(screen.snapshot) == before, "V35P-KEY-NO-DOMAIN-CHANGE-" + pair[1])
	var selected_style: StyleBoxFlat = hud.roster["A"].get_theme_stylebox("normal")
	var idle_style: StyleBoxFlat = hud.roster["B"].get_theme_stylebox("normal")
	var hover_style: StyleBoxFlat = hud.roster["B"].get_theme_stylebox("hover")
	check(selected_style.border_width_left >= 3 and selected_style.shadow_size >= 6, "V35P-SELECTED-STRONG")
	check(hover_style.border_width_left > idle_style.border_width_left, "V35P-HOVER-DISTINCT")
	var focus: StyleBoxFlat = hud.roster["B"].get_theme_stylebox("focus")
	check(focus.border_color == Tokens.FOCUS_RING and focus.border_width_left >= 2 and not focus.draw_center,
		"V35P-FOCUS-RING")

	# 3) Real idle data → no fabricated badges.
	var no_badges := true
	for id: String in ["A", "B", "C"]:
		no_badges = no_badges and hud.roster[id].badge_ids().is_empty()
	check(no_badges, "V35P-REAL-IDLE-NO-BADGES")

	# 4) MOCK_ONLY display boundary for each badge source.
	var mock: Dictionary = hud.vm.duplicate(true)
	mock["barriers"] = {"B": 12}
	mock["reaction"]["guard_actor_ids"] = ["A"]
	mock["casts"] = {"mock-cast": {"caster_id": "C", "current_stability": 3, "focus_ward": 1}}
	mock["actors"]["A"]["status"] = "EXHAUSTED"
	var party: Control = hud.get_node("PartyStatusPanel")
	party.render_party(mock, "A")
	await process_frame
	check(hud.roster["A"].badge_ids() == ["GUARD", "EXHAUSTED"], "V35P-MOCK-GUARD-EXHAUSTED")
	check(hud.roster["B"].badge_ids() == ["BARRIER"], "V35P-MOCK-BARRIER")
	check(hud.roster["C"].badge_ids() == ["CASTING"], "V35P-MOCK-CASTING")
	check(hud.roster["B"].status_badges.get_child(0).tooltip_text == screen.tr("BATTLE_BARRIER") % "12",
		"V35P-MOCK-BARRIER-TOOLTIP-EXACT")
	check(hud.roster["A"].status_kind == "EXHAUSTED", "V35P-MOCK-STATUS-PILL-KIND")
	var badges_inside := true
	for id: String in ["A", "B", "C"]:
		for badge: Control in hud.roster[id].status_badges.get_children():
			badges_inside = badges_inside and encloses(hud.roster[id], badge)
			badges_inside = badges_inside and badge.mouse_filter == Control.MOUSE_FILTER_IGNORE
	check(badges_inside, "V35P-BADGES-INSIDE-NONBLOCKING")
	check(Model.state_hash(screen.snapshot) == before, "V35P-MOCK-NO-DOMAIN-CHANGE")

	# Incapacitated: dimmed, still enabled and still emits a view request.
	mock["actors"]["C"]["status"] = "INCAPACITATED"
	party.render_party(mock, "A")
	var requested: Array = []
	party.actor_requested.connect(func(id: String) -> void: requested.append(id))
	check(not hud.roster["C"].disabled and hud.roster["C"].badge_ids().has("INCAPACITATED"),
		"V35P-INCAPACITATED-ENABLED")
	check(hud.roster["C"].portrait.modulate != Color.WHITE, "V35P-INCAPACITATED-DIMMED")
	hud.roster["C"].pressed.emit()
	check(requested == ["C"], "V35P-INCAPACITATED-STILL-VIEWABLE")
	screen.select_actor("A")
	hud = screen.hud
	var cleared := true
	for id: String in ["A", "B", "C"]:
		cleared = cleared and hud.roster[id].badge_ids().is_empty()
	check(cleared, "V35P-REAL-RERENDER-CLEARS-MOCK")
	check(Model.state_hash(screen.snapshot) == before, "V35P-INCAP-NO-DOMAIN-CHANGE")

	# 5) Real Domain casting (accepted command; not a mocked dictionary).
	var state: Dictionary = screen.controller.snapshot()
	var spell: String = card_id(state, "C", "regular")
	check(not spell.is_empty(), "V35P-REAL-SPELL-OWNED")
	check(screen.controller.submit(Factory.card(state, "C", spell, "Boss", "FULL")), "V35P-REAL-FULL-CHANT-ACCEPTED")
	await process_frame
	hud = screen.hud
	var real_casts: Array = screen.view_model["casts"].values().filter(
		func(cast: Dictionary) -> bool: return str(cast["caster_id"]) == "C")
	check(not real_casts.is_empty() and hud.roster["C"].badge_ids().has("CASTING"), "V35P-REAL-CASTING-BADGE")
	check(hud.roster["C"].status_kind == str(screen.view_model["actors"]["C"]["status"]), "V35P-REAL-STATUS-PILL")
	check(not hud.roster["A"].badge_ids().has("CASTING") and not hud.roster["B"].badge_ids().has("CASTING"),
		"V35P-REAL-CASTING-ONLY-CASTER")
	var after_cast: String = Model.state_hash(screen.snapshot)
	await press_key(KEY_3)
	check(screen.hud.roster["C"].button_pressed and screen.hud.roster["C"].badge_ids().has("CASTING"),
		"V35P-REAL-CASTER-SELECTABLE")
	check(Model.state_hash(screen.snapshot) == after_cast, "V35P-REAL-SELECT-NO-DOMAIN-CHANGE")
	screen.queue_free()
	await process_frame
	print("V35_PARTY_REPORT executed=%d passed=%d failed=%d" % [executed, executed - failed, failed])
	quit(0 if failed == 0 else 1)
