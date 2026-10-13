extends Node2D

const BattleStateClass = preload("res://scripts/domain/battle_state.gd")

var battle
var font: Font
var log_lines: Array[String] = []
var selected_hero: String = "kleya"
var pulse: float = 0.0
var flash: float = 0.0

const BG := Color("080d20")
const PANEL := Color("111a35")
const PANEL_2 := Color("182449")
const LINE := Color("344477")
const CYAN := Color("67d8ff")
const GOLD := Color("f5cf68")
const RED := Color("ff6b77")
const TEXT := Color("e7efff")
const MUTED := Color("8fa4cc")

func _ready() -> void:
	battle = BattleStateClass.new()
	battle.changed.connect(_on_changed)
	battle.event_logged.connect(_on_log)
	font = ThemeDB.fallback_font
	queue_redraw()

func _process(delta: float) -> void:
	pulse += delta
	flash = maxf(0.0, flash - delta)
	queue_redraw()

func _on_changed() -> void:
	flash = 0.35
	queue_redraw()

func _on_log(message: String) -> void:
	log_lines.push_front(message)
	if log_lines.size() > 6:
		log_lines.pop_back()
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), BG)
	_draw_header()
	_draw_boss()
	_draw_party()
	_draw_hand()
	_draw_footer()

func _draw_header() -> void:
	draw_rect(Rect2(24, 18, 1232, 58), PANEL)
	draw_line(Vector2(24, 76), Vector2(1256, 76), LINE, 2)
	_text("ARBITRIUM NEXUS", Vector2(48, 53), 25, CYAN)
	_text("COMBAT SIM // v1.0", Vector2(308, 50), 14, MUTED)
	_text("ROUND %02d" % battle.round, Vector2(1070, 47), 16, GOLD)
	_text(battle.phase + " PHASE", Vector2(1070, 66), 12, RED if battle.phase == "ENEMY" else CYAN)

func _draw_boss() -> void:
	var panel := Rect2(430, 100, 826, 270)
	draw_rect(panel, PANEL)
	draw_rect(Rect2(452, 122, 210, 224), Color("1d2b55"))
	var core := Vector2(557, 234)
	var ring := 64.0 + sin(pulse * 2.0) * 4.0
	draw_circle(core, ring, Color(0.25, 0.65, 0.95, 0.08))
	draw_arc(core, ring, 0, TAU, 48, CYAN, 3)
	draw_circle(core, 35, Color("0b122d"))
	draw_circle(core, 22, Color(0.4, 0.84, 1.0, 0.65))
	_text("ARBITRIUM NEXUS", Vector2(690, 135), 22, TEXT)
	_text("VOID REGULATOR // BOSS", Vector2(690, 157), 12, MUTED)
	_text("HP", Vector2(690, 188), 12, MUTED)
	_bar(Rect2(730, 176, 470, 18), float(battle.boss_hp) / BattleStateClass.BOSS_MAX_HP, RED)
	_text("%d / %d" % [battle.boss_hp, BattleStateClass.BOSS_MAX_HP], Vector2(1082, 190), 13, TEXT)
	_text("STABILITY", Vector2(690, 225), 12, MUTED)
	_bar(Rect2(770, 213, 430, 18), float(battle.boss_stability) / BattleStateClass.BOSS_MAX_STABILITY, GOLD)
	_text("%d / %d" % [battle.boss_stability, BattleStateClass.BOSS_MAX_STABILITY], Vector2(1082, 227), 13, TEXT)
	_text("WEAK NODE", Vector2(690, 263), 12, MUTED)
	_text("EXPOSED" if battle.boss_stability == 0 else "LOCKED", Vector2(790, 263), 13, CYAN if battle.boss_stability == 0 else MUTED)
	_text("ENEMY INTENT", Vector2(690, 300), 12, MUTED)
	draw_rect(Rect2(805, 280, 395, 38), Color("32283f") if battle.phase == "ENEMY" else PANEL_2)
	_text("⚡  " + battle.boss_intent.replace("_", " "), Vector2(826, 305), 17, RED if battle.phase == "ENEMY" else GOLD)
	_text("ANALYSIS %d / 3" % battle.analysis, Vector2(690, 338), 12, CYAN)
	_text("INTERRUPT READY" if battle.interrupt_available else "INTERRUPT SPENT", Vector2(950, 338), 12, CYAN if battle.interrupt_available else MUTED)

func _draw_party() -> void:
	_text("SQUAD LINK // INDEPENDENT DECKS", Vector2(32, 105), 14, CYAN)
	var y := 132.0
	for hero_id: String in BattleStateClass.PLAYER_IDS:
		var hero: Dictionary = battle.heroes[hero_id]
		var rect := Rect2(24, y, 378, 70)
		draw_rect(rect, PANEL_2 if hero_id == selected_hero else PANEL)
		draw_rect(Rect2(24, y, 5, 70), _hero_color(hero_id))
		_text(hero_id.to_upper(), Vector2(44, y + 25), 17, TEXT)
		_text("%d / 100 HP" % hero["hp"], Vector2(44, y + 48), 12, MUTED)
		_bar(Rect2(154, y + 17, 105, 10), float(hero["hp"]) / 100.0, _hero_color(hero_id))
		_text("MANA %d / %d" % [hero["mana"], hero["max_mana"]], Vector2(278, y + 27), 13, GOLD)
		_text("HAND %d" % battle.hands[hero_id].size(), Vector2(278, y + 49), 11, MUTED)
		y += 82

func _draw_hand() -> void:
	_text("HAND // " + selected_hero.to_upper(), Vector2(430, 396), 14, CYAN)
	_text("ORDINARY PLAYS %d / %d" % [battle.ordinary_plays, BattleStateClass.MAX_ORDINARY_PLAYS], Vector2(1035, 396), 12, GOLD)
	var cards: Array = battle.hands[selected_hero]
	var card_x := 430.0
	for i: int in range(cards.size()):
		var card = cards[i]
		var rect := Rect2(card_x, 414, 128, 176)
		var enabled: bool = battle.phase == "PLAYER" and battle.ordinary_plays < BattleStateClass.MAX_ORDINARY_PLAYS and card.is_ordinary() and int(battle.heroes[selected_hero]["mana"]) >= card.cost
		var fill := Color("273b6b") if enabled else Color("1a2444")
		if card.reaction and battle.phase == "ENEMY":
			fill = Color("49304f")
		draw_rect(rect, fill)
		draw_rect(Rect2(card_x, 414, 128, 5), GOLD if card.reaction else CYAN)
		_text("%02d" % (i + 1), Vector2(card_x + 10, 435), 11, MUTED)
		_text(card.title, Vector2(card_x + 10, 459), 16, TEXT)
		_text("COST %d" % card.cost, Vector2(card_x + 10, 481), 11, GOLD)
		_text(card.description, Vector2(card_x + 10, 507), 10, MUTED)
		_text("REACTION" if card.reaction else "ORDINARY", Vector2(card_x + 10, 570), 10, CYAN if not card.reaction else GOLD)
		card_x += 138

func _draw_footer() -> void:
	draw_rect(Rect2(24, 616, 1232, 84), PANEL)
	_text("BATTLE LOG", Vector2(44, 641), 12, CYAN)
	var ly := 660.0
	for line: String in log_lines:
		_text("• " + line, Vector2(44, ly), 11, MUTED)
		ly += 14
	draw_rect(Rect2(1084, 630, 148, 48), Color("5c3148") if battle.phase == "ENEMY" else Color("254e65"))
	_text("RESOLVE" if battle.phase == "ENEMY" else "END TURN", Vector2(1111, 660), 15, TEXT)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var point: Vector2 = event.position
		for index: int in range(BattleStateClass.PLAYER_IDS.size()):
			var hero_id: String = BattleStateClass.PLAYER_IDS[index]
			if Rect2(24, 132 + index * 82, 378, 70).has_point(point):
				selected_hero = hero_id
				queue_redraw()
				return
		for index: int in range(battle.hands[selected_hero].size()):
			if Rect2(430 + index * 138, 414, 128, 176).has_point(point):
				var card = battle.hands[selected_hero][index]
				if battle.phase == "ENEMY" and card.reaction:
					battle.play_reaction(selected_hero, index)
				else:
					battle.play_card(selected_hero, index)
				return
		if Rect2(1084, 630, 148, 48).has_point(point):
			if battle.phase == "PLAYER":
				battle.end_player_phase()
			else:
				battle.resolve_enemy_phase()
			return

func _bar(rect: Rect2, ratio: float, color: Color) -> void:
	draw_rect(rect, Color("0a1028"))
	draw_rect(Rect2(rect.position, Vector2(rect.size.x * clampf(ratio, 0.0, 1.0), rect.size.y)), color)

func _text(value: String, position: Vector2, size: int, color: Color) -> void:
	draw_string(font, position, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _hero_color(hero_id: String) -> Color:
	return {"kleya": Color("ff8aa0"), "nova": Color("72ddff"), "yora": Color("c89cff")}.get(hero_id, CYAN)

