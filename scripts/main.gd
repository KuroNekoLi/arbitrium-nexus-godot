extends Control

const BattleStateClass = preload("res://scripts/domain/battle_state.gd")
const CardDataClass = preload("res://scripts/domain/card_data.gd")
const CardViewScript = preload("res://scripts/ui/card_view.gd")
const ArenaArtScript = preload("res://scripts/ui/arena_art.gd")
const CardResourceType = preload("res://addons/simple_cards/card/card_resource/card_resource.gd")
const HERO_ATLASES := {
	"kleya": preload("res://assets/kleya_atlas.png"),
	"nova": preload("res://assets/nova_atlas.png"),
	"yora": preload("res://assets/yora_atlas.png")
}
const PARTY_ART: Texture2D = preload("res://assets/nexus_party_splash.png")

var battle: BattleState
var selected_hero := "kleya"
var hand_root: Control
var log_box: RichTextLabel
var battlefield: Control
var dragged_card: Control
var card_views: Array[Control] = []
var actor_layer: Node2D
var hero_actors: Dictionary = {}
var boss_actor: Sprite2D
var animation_busy := false
var deck_builder: Control

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
	var title := _label("仲 裁 核 心   /   戰 術 交 鋒", 19, Color("#d7f8ff"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(title)
	var phase_label := _label("遭遇戰 01     •     第 1 回合", 13, Color("#65cfe2"))
	phase_label.name = "PhaseLabel"
	top_row.add_child(phase_label)
	var deck_button := Button.new()
	deck_button.text = "牌組編輯"
	deck_button.pressed.connect(_open_deck_builder)
	top_row.add_child(deck_button)
	var battle_area := Control.new()
	battle_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	battle_area.set_script(ArenaArtScript)
	root.add_child(battle_area)
	battlefield = battle_area
	actor_layer = Node2D.new()
	actor_layer.name = "AnimatedCombatants"
	battle_area.add_child(actor_layer)
	_create_combatants()
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
	var analysis_label := _label("分析值  /  0", 13, Color("#63e5cb"))
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
	log_box.append_text("[color=#6bdeea]›[/color] 第 1 回合｜我方階段\n[color=#6bdeea]›[/color] 三位角色各自持有獨立牌組\n[color=#6bdeea]›[/color] 將卡牌拖曳至戰場即可施放\n")
	var hand_panel := _panel("#0a1522", 232)
	hand_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(hand_panel)
	var hand_title := _label("戰 術 手牌     /     拖曳卡牌至戰場施放", 11, Color("#6c9bae"))
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
	turn_btn.text = "結束回合  ↗"
	turn_btn.custom_minimum_size = Vector2(140, 48)
	turn_btn.pressed.connect(_on_end_turn)
	action_col.add_child(turn_btn)
	var resolve_btn := Button.new()
	resolve_btn.text = "承受敵方行動"
	resolve_btn.custom_minimum_size = Vector2(140, 48)
	resolve_btn.pressed.connect(_on_resolve)
	action_col.add_child(resolve_btn)
	var hint := _label("空白鍵  /  結束回合\n保留能量與反應牌\n於敵方階段即時反制", 11, Color("#7794a2"))
	action_col.add_child(hint)

func _hero_panel(hero: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(282, 98)
	p.add_theme_stylebox_override("panel", _style("#102337", ACCENTS[hero]))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 5)
	p.add_child(col)
	var hero_names := {"kleya": "克蕾雅", "nova": "諾瓦", "yora": "尤拉"}
	var name := _label(hero_names[hero] + "   /   戰術成員", 12, ACCENTS[hero])
	col.add_child(name)
	var bars := _label("生命 100 / 100        能量 3 / 3", 11, Color("#d2e9ef"))
	bars.name = "Hero_" + hero
	col.add_child(bars)
	var select := Button.new()
	select.text = "切換牌組   →"
	select.custom_minimum_size.y = 28
	select.pressed.connect(_select_hero.bind(hero))
	col.add_child(select)
	return p

func _boss_panel() -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _style("#1c1626", Color("#e77da8")))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	p.add_child(col)
	col.add_child(_label("威脅等級  /  Ω 級", 10, Color("#e88cae")))
	col.add_child(_label("仲裁核心", 24, Color("#f4e5ff")))
	var boss_stats := _label("生命 300 / 300\n穩定度 50 / 50", 13, Color("#e5cfef"))
	boss_stats.name = "BossStats"
	col.add_child(boss_stats)
	var weak := _label("◈  弱點節點  •  穩定度歸零時暴露", 10, Color("#ffbd74"))
	col.add_child(weak)
	var intent := _label("敵方意圖  /  核心長槍", 12, Color("#ff718e"))
	intent.name = "IntentLabel"
	col.add_child(intent)
	col.add_child(_label("將攻擊牌拖至此處出擊", 10, Color("#9c8ba8")))
	return p

func _refresh() -> void:
	if not is_inside_tree() or hand_root == null: return
	var round_label = find_child("PhaseLabel", true, false)
	if round_label:
		var phase_name := "我方階段" if battle.phase == "PLAYER" else "敵方階段"
		round_label.text = "%s     •     第 %02d 回合     •     普通出牌 %d/2" % [phase_name, battle.round, battle.ordinary_plays]
	var boss_stats = find_child("BossStats", true, false)
	if boss_stats: boss_stats.text = "生命  %d / 300\n穩定度  %d / 50" % [battle.boss_hp, battle.boss_stability]
	var intent = find_child("IntentLabel", true, false)
	if intent: intent.text = "敵方意圖  /  " + ("核心長槍" if battle.boss_intent == "NEXUS_LANCE" else "穩定度脈衝")
	var al = find_child("AnalysisLabel", true, false)
	if al: al.text = "分析值  /  %d" % battle.analysis
	for hero in HEROES:
		var h = find_child("Hero_" + hero, true, false)
		if h:
			var s: Dictionary = battle.heroes[hero]
			h.text = "生命 %d/%d   能量 %d/%d   手牌 %d" % [s.hp, s.max_hp, s.mana, s.max_mana, battle.hands[hero].size()]
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
		var view: Control = CardViewScript.new(cards[i] as CardResourceType)
		view.combat_data = cards[i] as CardDataClass
		view.accent = ACCENTS[selected_hero]
		view.set_meta("hand_index", i)
		view.drag_started.connect(_on_card_drag_started.bind(view))
		view.drag_ended.connect(_on_card_drag_released.bind(view))
		hand_root.add_child(view)
		view.position = Vector2((hand_root.size.x-total)*0.5+i*spacing, 8 + absf(float(i-(cards.size()-1)*0.5))*3)
		view.set_meta("home_position", view.position)
		view.rotation = deg_to_rad((i-(cards.size()-1)*0.5)*2.0)
		view.set_meta("home_rotation", view.rotation)
		card_views.append(view)
	if battlefield: battlefield.queue_redraw()

func _on_card_drag_started(_card: Card, view: Control) -> void:
	if animation_busy:
		view.undraggable = true
		return
	view.undraggable = false
	dragged_card = view
	view.z_index = 1000
	view.scale = Vector2(1.08,1.08)

func _on_card_drag_released(_card: Card, view: Control) -> void:
	_handle_card_release(view, get_global_mouse_position())

func _handle_card_release(view: Control, drop_pos: Vector2) -> void:
	if dragged_card != view: return
	var idx: int = int(view.get_meta("hand_index"))
	if Rect2(Vector2(750, 76), Vector2(520, 408)).has_point(drop_pos) and _can_play_card(idx):
		animation_busy = true
		for card_view in card_views:
			card_view.disabled = true
		view.call_deferred("kill_all_tweens")
		call_deferred("_animate_card_play", view, idx, selected_hero)
	else:
		call_deferred("_animate_card_return", view)
	dragged_card = null

func _can_play_card(index: int) -> bool:
	var hand: Array = battle.hands[selected_hero]
	if index < 0 or index >= hand.size(): return false
	var card: CardData = hand[index]
	var mana: int = battle.heroes[selected_hero]["mana"]
	if battle.phase == "ENEMY":
		return card.reaction and battle.interrupt_available and mana >= card.cost
	return card.is_ordinary() and battle.ordinary_plays < BattleStateClass.MAX_ORDINARY_PLAYS and mana >= card.cost

func _animate_card_return(view: Control) -> void:
	if not is_instance_valid(view): return
	view.kill_all_tweens()
	var home: Vector2 = view.get_meta("home_position", view.position)
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(view, "position", home, 0.24)
	tween.parallel().tween_property(view, "scale", Vector2.ONE, 0.18)
	tween.parallel().tween_property(view, "rotation", view.get_meta("home_rotation", 0.0), 0.18)

func _animate_card_play(view: Control, hand_index: int, hero_id: String) -> void:
	if not is_instance_valid(view):
		animation_busy = false
		return
	view.kill_all_tweens()
	view.set_process(false)
	view.z_index = 2000
	var data: CardData = view.combat_data
	var boss_target := Vector2(850, 255)
	var target_global := battlefield.global_position + boss_target
	var hero: AnimatedSprite2D = hero_actors[hero_id]
	var origin := hero.position
	var is_attack := data.kind == CardDataClass.CardKind.ATTACK
	var is_defense := data.kind == CardDataClass.CardKind.DEFENSE
	var is_support := data.kind == CardDataClass.CardKind.SUPPORT
	var is_reaction := data.kind == CardDataClass.CardKind.REACTION or data.reaction
	var strike_target := boss_target - Vector2(95, 0)
	var dash_duration := 0.25 if is_attack else 0.18
	var card_tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	card_tween.tween_property(view, "global_position", target_global - view.size * 0.5, 0.3)
	card_tween.parallel().tween_property(view, "scale", Vector2(0.42, 0.42), 0.3)
	card_tween.parallel().tween_property(view, "rotation", 0.0, 0.3)
	var move := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	var move_target := strike_target if is_attack else (origin + Vector2(0, -16) if is_defense else origin + Vector2(42, -10))
	hero.play("run" if is_attack else "idle")
	move.tween_property(hero, "position", move_target, dash_duration)
	if is_attack:
		move.tween_callback(_play_hero_strike.bind(hero))
		move.tween_callback(_show_slash.bind(boss_target, _card_color(data.kind)))
		move.tween_property(hero, "position", origin, 0.24)
	elif is_defense:
		move.tween_callback(_show_guard.bind(origin))
		move.tween_property(hero, "position", origin, 0.2)
	elif is_support:
		move.tween_callback(_show_support.bind(origin + Vector2(48, -10)))
		move.tween_property(hero, "position", origin, 0.2)
	elif is_reaction:
		move.tween_callback(_show_interrupt.bind(boss_target))
		move.tween_property(hero, "position", origin, 0.2)
	else:
		move.tween_property(hero, "position", origin, 0.2)
	await move.finished
	hero.play("idle")
	animation_busy = false
	var boss_hp_before: int = battle.boss_hp
	var played := battle.play_reaction(hero_id, hand_index) if battle.phase == "ENEMY" else battle.play_card(hero_id, hand_index)
	if played:
		if data.kind == CardDataClass.CardKind.ATTACK:
			_animate_boss_hit(_card_color(data.kind), boss_hp_before - battle.boss_hp)
		elif data.kind == CardDataClass.CardKind.DEFENSE:
			_animate_hero_heal(hero, data.power)
		elif data.reaction:
			_animate_boss_hit(_card_color(data.kind), 0)
		else:
			_show_status_text(hero.position + Vector2(0, -85), "分析值 +%d" % data.power, _card_color(data.kind))
		if is_instance_valid(view): view.queue_free()
	else:
		view.disabled = false
		_animate_card_return(view)

func _create_combatants() -> void:
	var positions := {"kleya": Vector2(410, 325), "nova": Vector2(540, 335), "yora": Vector2(675, 325)}
	for hero in HEROES:
		var actor := AnimatedSprite2D.new()
		actor.name = hero.capitalize() + "Sprite"
		actor.sprite_frames = _make_hero_frames(HERO_ATLASES[hero])
		actor.position = positions[hero]
		actor.scale = Vector2(0.27, 0.27)
		actor.z_index = 4
		actor_layer.add_child(actor)
		hero_actors[hero] = actor
		actor.play("idle")
	boss_actor = Sprite2D.new()
	boss_actor.name = "NexusSprite"
	boss_actor.texture = PARTY_ART
	boss_actor.region_enabled = true
	boss_actor.region_rect = Rect2(1000, 0, 696, 956)
	boss_actor.position = Vector2(855, 270)
	boss_actor.scale = Vector2(0.23, 0.23)
	boss_actor.z_index = 2
	actor_layer.add_child(boss_actor)
	var boss_idle := create_tween().set_loops()
	boss_idle.tween_property(boss_actor, "position:y", 267.0, 1.3).set_trans(Tween.TRANS_SINE)
	boss_idle.tween_property(boss_actor, "position:y", 273.0, 1.3).set_trans(Tween.TRANS_SINE)

func _make_hero_frames(atlas: Texture2D) -> SpriteFrames:
	var frames := SpriteFrames.new()
	for animation_name in ["idle", "run", "strike"]:
		frames.add_animation(animation_name)
		frames.set_animation_loop(animation_name, animation_name != "strike")
		frames.set_animation_speed(animation_name, 8.0 if animation_name == "idle" else 12.0)
	var cell_size := Vector2(atlas.get_width() / 3.0, atlas.get_height() / 3.0)
	for row in 3:
		var animation_name: String = ["idle", "run", "strike"][row]
		for column in 3:
			var frame := AtlasTexture.new()
			frame.atlas = atlas
			frame.region = Rect2(Vector2(column, row) * cell_size, cell_size)
			frames.add_frame(animation_name, frame)
	return frames

func _play_hero_strike(actor: AnimatedSprite2D) -> void:
	actor.play("strike")

func _card_color(kind: int) -> Color:
	match kind:
		CardDataClass.CardKind.ATTACK: return Color("#ff765f")
		CardDataClass.CardKind.DEFENSE: return Color("#53d8c2")
		CardDataClass.CardKind.SUPPORT: return Color("#c29aff")
		CardDataClass.CardKind.REACTION: return Color("#ff5cba")
	return Color.WHITE

func _show_guard(center: Vector2) -> void:
	var ring := _effect_ring(center, Color("#53d8c2"), 20.0, 66.0)
	_show_status_text(center + Vector2(-18, -48), "防禦", Color("#7dffe4"))

func _show_support(center: Vector2) -> void:
	var ring := _effect_ring(center, Color("#c29aff"), 12.0, 54.0)
	_show_status_text(center + Vector2(-22, -50), "解析", Color("#dfc7ff"))

func _show_interrupt(center: Vector2) -> void:
	var ring := _effect_ring(center, Color("#ff5cba"), 90.0, 22.0)
	_show_status_text(center + Vector2(-45, -58), "中斷！", Color("#ff8ad1"))

func _effect_ring(center: Vector2, color: Color, from_radius: float, to_radius: float) -> Node2D:
	var ring := Node2D.new()
	ring.set_script(load("res://scripts/ui/ring_effect.gd"))
	ring.position = center
	ring.z_index = 29
	ring.set_meta("ring_color", color)
	ring.set_meta("radius", from_radius)
	actor_layer.add_child(ring)
	var pulse := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	pulse.tween_method(func(radius: float) -> void: ring.set_meta("radius", radius); ring.queue_redraw(), from_radius, to_radius, 0.32)
	pulse.parallel().tween_property(ring, "modulate:a", 0.0, 0.32)
	pulse.tween_callback(ring.queue_free)
	return ring

func _animate_hero_heal(actor: Node2D, amount: int) -> void:
	actor.modulate = Color("#83ffd8")
	var tint := create_tween()
	tint.tween_property(actor, "modulate", Color.WHITE, 0.28)
	_show_status_text(actor.position + Vector2(0, -90), "+%d HP" % amount, Color("#83ffd8"))

func _show_status_text(at: Vector2, text: String, color: Color) -> void:
	var heal := Label.new()
	heal.text = text
	heal.add_theme_font_size_override("font_size", 17)
	heal.add_theme_color_override("font_color", color)
	heal.position = at
	heal.z_index = 32
	actor_layer.add_child(heal)
	var rise := create_tween()
	rise.tween_property(heal, "position:y", heal.position.y - 42, 0.45)
	rise.parallel().tween_property(heal, "modulate:a", 0.0, 0.45)
	rise.tween_callback(heal.queue_free)

func _show_slash(center: Vector2, color: Color) -> void:
	var slash := Line2D.new()
	slash.width = 8.0
	slash.default_color = color
	slash.begin_cap_mode = Line2D.LINE_CAP_ROUND
	slash.end_cap_mode = Line2D.LINE_CAP_ROUND
	slash.points = PackedVector2Array([center + Vector2(-40, 30), center, center + Vector2(45, -32)])
	slash.z_index = 30
	actor_layer.add_child(slash)
	var tween := create_tween()
	tween.tween_property(slash, "modulate:a", 0.0, 0.24)
	tween.tween_callback(slash.queue_free)

func _animate_boss_hit(color: Color, damage: int) -> void:
	var original := boss_actor.position
	var hit := create_tween()
	hit.tween_property(boss_actor, "position", original + Vector2(12, -2), 0.045)
	hit.tween_property(boss_actor, "position", original + Vector2(-8, 1), 0.045)
	hit.tween_property(boss_actor, "position", original, 0.08)
	boss_actor.modulate = color.lightened(0.5)
	var flash := create_tween()
	flash.tween_property(boss_actor, "modulate", Color.WHITE, 0.2)
	var number := Label.new()
	number.text = "-%d" % damage if damage > 0 else "已中斷"
	number.add_theme_font_size_override("font_size", 25)
	number.add_theme_color_override("font_color", color)
	number.position = Vector2(805, 155)
	number.z_index = 32
	actor_layer.add_child(number)
	var rise := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	rise.tween_property(number, "position:y", 120.0, 0.5)
	rise.parallel().tween_property(number, "modulate:a", 0.0, 0.5)
	rise.tween_callback(number.queue_free)

func _on_end_turn() -> void:
	if battle.phase == "PLAYER" and not animation_busy: battle.end_player_phase()

func _select_hero(hero_id: String) -> void:
	if animation_busy: return
	selected_hero = hero_id
	_refresh()

func _on_resolve() -> void:
	if battle.phase == "ENEMY": battle.resolve_enemy_phase()

func _open_deck_builder() -> void:
	if deck_builder != null and is_instance_valid(deck_builder):
		return
	deck_builder = Control.new()
	deck_builder.set_script(load("res://scripts/ui/deck_builder.gd"))
	deck_builder.z_index = 100
	deck_builder.z_as_relative = false
	deck_builder.connect("close_requested", _close_deck_builder)
	deck_builder.connect("apply_requested", _apply_deck_builder)
	add_child(deck_builder)

func _close_deck_builder() -> void:
	if is_instance_valid(deck_builder):
		deck_builder.queue_free()
	deck_builder = null

func _apply_deck_builder() -> void:
	_close_deck_builder()
	battle = BattleStateClass.new()
	battle.changed.connect(_refresh)
	battle.event_logged.connect(_add_log)
	log_box.clear()
	log_box.append_text("[color=#6bdeea]›[/color] 新戰鬥開始｜已套用儲存的角色牌組\n[color=#6bdeea]›[/color] 將卡牌拖曳至戰場即可施放\n")
	_refresh()

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
