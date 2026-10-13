extends Control

const BattleStateClass = preload("res://scripts/domain/battle_state.gd")
const CardDataClass = preload("res://scripts/domain/card_data.gd")
const CardViewScript = preload("res://scripts/ui/card_view.gd")
const ArenaArtScript = preload("res://scripts/ui/arena_art.gd")

var battle: BattleState
var selected_hero := "kleya"
var hand_root: Control
var hud: VBoxContainer
var log_box: RichTextLabel
var battlefield: Control
var dragged_card: Control
var drag_origin := Vector2.ZERO
var card_views: Array[Control] = []
var anim_layer: Control

const HEROES := ["kleya", "nova", "yora"]
const ACCENTS := {"kleya": Color("#72e8ff"), "nova": Color("#ff9a72"), "yora": Color("#c59aff")}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	battle = BattleStateClass.new()
	battle.changed.connect(_refresh)
	battle.event_logged.connect(_add_log)
	_build_ui()
	call_deferred("_refresh")

func _build_ui() -> void:
	var bg := Control.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.set_script(load("res://scripts/ui/backdrop.gd"))
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	add_child(root)
	var top := _panel("#071321", 68)
	root.add_child(top)
	var top_row := HBoxContainer.new()
	top_row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	top_row.add_theme_constant_override("separation", 18)
	top.add_child(top_row)
	var title := _label("A R B I T R I U M   /   N E X U S", 19, Color("#d7f8ff"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(title)
	var phase_label := _label("ENCOUNTER 01     •     ROUND 1", 13, Color("#65cfe2"))
	phase_label.name = "PhaseLabel"
	top_row.add_child(phase_label)
	var battle_area := Control.new()
	battle_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	battle_area.set_script(ArenaArtScript)
	root.add_child(battle_area)
	battlefield = battle_area
	var character_art := TextureRect.new()
	character_art.texture = load("res://assets/nexus_party_splash.png")
	character_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	character_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	character_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	character_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	battle_area.add_child(character_art)
	var overlays := HBoxContainer.new()
	overlays.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlays.add_theme_constant_override("separation", 20)
	battle_area.add_child(overlays)
	var party := VBoxContainer.new()
	party.custom_minimum_size.x = 300
	party.add_theme_constant_override("separation", 10)
	party.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	party.offset_left = 26
	party.offset_top = 26
	party.offset_bottom = -24
	battle_area.add_child(party)
	for hero in HEROES:
		var row := _hero_panel(hero)
		party.add_child(row)
	var boss := _boss_panel()
	boss.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	boss.offset_left = -318
	boss.offset_top = 18
	boss.offset_right = -20
	boss.offset_bottom = 230
	boss.custom_minimum_size = Vector2(298, 205)
	battle_area.add_child(boss)
	var bottom := HBoxContainer.new()
	bottom.custom_minimum_size.y = 232
	bottom.add_theme_constant_override("separation", 12)
	root.add_child(bottom)
	var left_column := VBoxContainer.new()
	left_column.custom_minimum_size.x = 228
	left_column.add_theme_constant_override("separation", 8)
	bottom.add_child(left_column)
	var analysis_label := _label("ANALYSIS  /  0", 13, Color("#63e5cb"))
	analysis_label.name = "AnalysisLabel"
	left_column.add_child(analysis_label)
	var event_panel := _panel("#0b1a2a", 128)
	left_column.add_child(event_panel)
	log_box = RichTextLabel.new()
	log_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	log_box.offset_left = 10
	log_box.offset_top = 8
	log_box.offset_right = -8
	log_box.offset_bottom = -6
	log_box.bbcode_enabled = true
	log_box.scroll_following = true
	log_box.add_theme_font_size_override("normal_font_size", 11)
	event_panel.add_child(log_box)
	log_box.append_text("[color=#6bdeea]›[/color] ROUND 1 // PLAYER PHASE\n[color=#6bdeea]›[/color] Three independent decks online\n[color=#6bdeea]›[/color] Drag a card onto the Nexus to play\n")
	var hand_panel := _panel("#0a1522", 232)
	hand_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(hand_panel)
	var hand_title := _label("TACTICAL HAND     /     DRAG A CARD INTO THE ARENA", 11, Color("#6c9bae"))
	hand_title.position = Vector2(16, 8)
	hand_panel.add_child(hand_title)
	hand_root = Control.new()
	hand_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hand_root.offset_left = 8
	hand_root.offset_top = 30
	hand_root.offset_right = -8
	hand_root.offset_bottom = -5
	hand_panel.add_child(hand_root)
	var action_col := VBoxContainer.new()
	action_col.custom_minimum_size.x = 148
	action_col.add_theme_constant_override("separation", 10)
	bottom.add_child(action_col)
	var turn_btn := Button.new()
	turn_btn.text = "END TURN  ↗"
	turn_btn.custom_minimum_size = Vector2(140, 48)
	turn_btn.pressed.connect(_on_end_turn)
	action_col.add_child(turn_btn)
	var resolve_btn := Button.new()
	resolve_btn.text = "RESOLVE INTENT"
	resolve_btn.custom_minimum_size = Vector2(140, 48)
	resolve_btn.pressed.connect(_on_resolve)
	action_col.add_child(resolve_btn)
	var hint := _label("SPACE  /  END TURN\nReaction cards stay live\nduring enemy phase", 11, Color("#7794a2"))
	action_col.add_child(hint)
	anim_layer = Control.new()
	anim_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	anim_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(anim_layer)

func _hero_panel(hero: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(282, 98)
	p.add_theme_stylebox_override("panel", _style("#102337", ACCENTS[hero]))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 5)
	p.add_child(col)
	var name := _label(hero.to_upper() + "   /   FIELD OPERATIVE", 12, ACCENTS[hero])
	col.add_child(name)
	var bars := _label("HP 100 / 100        MANA 3 / 3", 11, Color("#d2e9ef"))
	bars.name = "Hero_" + hero
	col.add_child(bars)
	var select := Button.new()
	select.text = "SELECT DECK   →"
	select.custom_minimum_size.y = 28
	select.pressed.connect(func(): selected_hero = hero; _refresh())
	col.add_child(select)
	return p

func _boss_panel() -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _style("#1c1626", Color("#e77da8")))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	p.add_child(col)
	col.add_child(_label("THREAT  /  CLASS Ω", 10, Color("#e88cae")))
	col.add_child(_label("ARBITRIUM\nNEXUS", 24, Color("#f4e5ff")))
	var boss_stats := _label("HP 300 / 300\nSTABILITY 50 / 50", 13, Color("#e5cfef"))
	boss_stats.name = "BossStats"
	col.add_child(boss_stats)
	var weak := _label("◈  WEAK NODE  •  EXPOSE AT 0", 10, Color("#ffbd74"))
	col.add_child(weak)
	var intent := _label("INTENT  /  NEXUS LANCE", 12, Color("#ff718e"))
	intent.name = "IntentLabel"
	col.add_child(intent)
	col.add_child(_label("Drag attack cards here to strike", 10, Color("#9c8ba8")))
	return p

func _refresh() -> void:
	if not is_inside_tree() or hand_root == null: return
	var round_label = find_child("PhaseLabel", true, false)
	if round_label: round_label.text = "%s PHASE     •     ROUND %02d     •     PLAYS %d/2" % [battle.phase, battle.round, battle.ordinary_plays]
	var boss_stats = find_child("BossStats", true, false)
	if boss_stats: boss_stats.text = "HP  %d / 300\nSTABILITY  %d / 50" % [battle.boss_hp, battle.boss_stability]
	var intent = find_child("IntentLabel", true, false)
	if intent: intent.text = "INTENT  /  " + battle.boss_intent.replace("_", " ")
	var al = find_child("AnalysisLabel", true, false)
	if al: al.text = "ANALYSIS  /  %d" % battle.analysis
	for hero in HEROES:
		var h = find_child("Hero_" + hero, true, false)
		if h:
			var s: Dictionary = battle.heroes[hero]
			h.text = "HP %d / %d       MANA %d / %d       DECK %d" % [s.hp, s.max_hp, s.mana, s.max_mana, battle.hands[hero].size()]
			var container = h.get_parent().get_parent()
			container.modulate = Color.WHITE if hero == selected_hero else Color(0.66,0.75,0.82)
	for c in card_views: c.queue_free()
	card_views.clear()
	var cards: Array = battle.hands[selected_hero]
	var card_w := 142.0
	var spacing := minf(116.0, (hand_root.size.x - card_w - 8) / maxf(1, cards.size() - 1))
	spacing = maxf(0.0, spacing)
	var total := card_w + spacing * maxf(0, cards.size() - 1)
	for i in cards.size():
		var view: Control = CardViewScript.new()
		view.card_data = cards[i]
		view.accent = ACCENTS[selected_hero]
		view.set_meta("hand_index", i)
		view.drag_started.connect(_on_card_drag_started.bind(view))
		view.drag_released.connect(_on_card_drag_released.bind(view))
		hand_root.add_child(view)
		view.position = Vector2((hand_root.size.x-total)*0.5+i*spacing, 8 + absf(float(i-(cards.size()-1)*0.5))*3)
		view.set_meta("home_position", view.position)
		view.rotation = deg_to_rad((i-(cards.size()-1)*0.5)*2.0)
		card_views.append(view)
	if battlefield: battlefield.queue_redraw()

func _on_card_drag_started(view: Control) -> void:
	dragged_card = view
	drag_origin = view.global_position
	view.z_index = 1000
	view.scale = Vector2(1.08,1.08)

func _on_card_drag_released(view: Control, screen_pos: Vector2) -> void:
	if dragged_card != view: return
	var idx: int = int(view.get_meta("hand_index"))
	var played := false
	if Rect2(Vector2(760, 85), Vector2(500, 390)).has_point(screen_pos):
		played = battle.play_reaction(selected_hero, idx) if battle.phase == "ENEMY" else battle.play_card(selected_hero, idx)
	if played:
		var tween := create_tween()
		tween.tween_property(view, "global_position", Vector2(1000, 280), 0.18)
		tween.parallel().tween_property(view, "scale", Vector2(0.25,0.25), 0.18)
		tween.tween_callback(view.queue_free)
	else:
		var tween := create_tween()
		tween.tween_property(view, "position", view.get_meta("home_position", view.position), 0.18).set_trans(Tween.TRANS_BACK)
		view.scale = Vector2.ONE
	dragged_card = null

func _on_end_turn() -> void:
	if battle.phase == "PLAYER": battle.end_player_phase()

func _on_resolve() -> void:
	if battle.phase == "ENEMY": battle.resolve_enemy_phase()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("end_turn"): _on_end_turn()

func _add_log(message: String) -> void:
	if log_box: log_box.append_text("[color=#6bdeea]›[/color] " + message + "\n")

func _panel(color: String, height: float) -> PanelContainer:
	var p := PanelContainer.new()
	p.custom_minimum_size.y = height
	p.add_theme_stylebox_override("panel",_style(color,Color("#214455")))
	return p

func _style(color: String, border: Color) -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = Color(color)
	st.border_color = border
	st.set_border_width_all(1)
	st.set_corner_radius_all(6)
	st.content_margin_left = 12
	st.content_margin_right = 12
	st.content_margin_top = 9
	st.content_margin_bottom = 8
	return st

func _label(text_value: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text_value
	l.add_theme_font_size_override("font_size",size)
	l.add_theme_color_override("font_color",color)
	return l
