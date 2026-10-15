extends PanelContainer
## V3.3: a composed, read-only Boss status with distinct HP/Break and public Intent.
## Rendered threat styling is ornamental; NEVER deduce danger, targets or legality.
const UI = preload("res://scripts/battle/ui/components/ui_elements.gd")
const Tokens = preload("res://scripts/battle/ui/components/battle_visual_tokens.gd")
var boss_stats: Label
var break_stats: Label
var intent: Label
var boss_title: Label
var hp_bar: ProgressBar
var break_bar: ProgressBar
var _intent_heading: Label

var title_plate: HBoxContainer
var hp_section: VBoxContainer
var break_section: VBoxContainer
var intent_panel: PanelContainer
var _intent_accent: ColorRect

func _make_label(parent: Node, name: String, text: String, size_hint: int) -> Label:
	var item: Label = UI.label(parent, text, size_hint)
	item.name = name
	item.autowrap_mode = TextServer.AUTOWRAP_OFF
	item.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	return item

func _make_section(parent: VBoxContainer, name: String) -> VBoxContainer:
	var section := VBoxContainer.new()
	section.name = name
	section.add_theme_constant_override("separation", 2)
	parent.add_child(section)
	return section

func _ready() -> void:
	var enemy: VBoxContainer = UI.column(self)
	enemy.name = "BossContent"
	enemy.add_theme_constant_override("separation", 5)

	title_plate = HBoxContainer.new()
	title_plate.name = "BossTitlePlate"
	title_plate.add_theme_constant_override("separation", 7)
	enemy.add_child(title_plate)
	var identity_mark := ColorRect.new()
	identity_mark.name = "IdentityAccent"
	identity_mark.color = Tokens.METAL
	identity_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	identity_mark.custom_minimum_size = Vector2(3, 21)
	title_plate.add_child(identity_mark)
	boss_title = _make_label(title_plate, "BossName", "BATTLE_TITLE", 19)
	boss_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	boss_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var rule := PanelContainer.new()
	rule.name = "HeaderRule"
	rule.custom_minimum_size.y = 1
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rule.add_theme_stylebox_override("panel", Tokens.heading_rule())
	enemy.add_child(rule)

	hp_section = _make_section(enemy, "BossHPSection")
	boss_stats = _make_label(hp_section, "BossHPText", "", 14)
	hp_bar = ProgressBar.new()
	hp_bar.name = "BossHPBar"
	Tokens.setup_read_only_bar(hp_bar, Tokens.HP)
	hp_section.add_child(hp_bar)

	break_section = _make_section(enemy, "BossBreakSection")
	break_stats = _make_label(break_section, "BossBreakText", "", 13)
	break_stats.tooltip_text = ""
	break_bar = ProgressBar.new()
	break_bar.name = "BossBreakBar"
	Tokens.setup_read_only_bar(break_bar, Tokens.BREAK)
	break_section.add_child(break_bar)

	intent_panel = PanelContainer.new()
	intent_panel.name = "PublishedIntentPanel"
	intent_panel.add_theme_stylebox_override("panel",
		Tokens.inset_frame(Tokens.INTENT.darkened(0.18)))
	intent_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	enemy.add_child(intent_panel)
	var intent_row := HBoxContainer.new()
	intent_row.name = "IntentRow"
	intent_row.add_theme_constant_override("separation", 7)
	intent_panel.add_child(intent_row)
	_intent_accent = ColorRect.new()
	_intent_accent.name = "IntentAccent"
	_intent_accent.color = Tokens.INTENT
	_intent_accent.custom_minimum_size.x = 3
	_intent_accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intent_row.add_child(_intent_accent)
	var intent_content := VBoxContainer.new()
	intent_content.name = "IntentContent"
	intent_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	intent_content.add_theme_constant_override("separation", 2)
	intent_row.add_child(intent_content)
	_intent_heading = _make_label(intent_content, "IntentHeading", "BATTLE_INTENT", 13)
	_intent_heading.add_theme_color_override("font_color", Tokens.INTENT)
	intent = UI.label(intent_content, "", 13)
	intent.name = "IntentDetail"
	intent.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	intent.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intent.max_lines_visible = 2
	intent.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

func render_enemy(projection: Dictionary) -> void:
	boss_title.text = tr(str(projection.get("actor_name_keys", {}).get("Boss", "BATTLE_TITLE")))
	boss_title.tooltip_text = boss_title.text
	var boss: Dictionary = projection["actors"]["Boss"]
	var hp: float = float(boss.get("hp", 0))
	var hp_max: float = maxf(1.0, float(boss.get("max_hp", 1)))
	boss_stats.text = tr("BATTLE_HP") % [int(hp), int(boss.get("max_hp", 1))]
	hp_bar.max_value = hp_max
	hp_bar.value = clampf(hp, 0.0, hp_max)

	var tactical: Dictionary = projection.get("tactical", {})
	var show_break: bool = tactical.has("break_gauge") and tactical.has("break_max")
	break_section.visible = show_break
	break_stats.visible = show_break
	break_bar.visible = show_break
	if show_break:
		var gauge: float = float(tactical["break_gauge"])
		var gauge_max: float = maxf(1.0, float(tactical["break_max"]))
		break_bar.max_value = gauge_max
		break_bar.value = clampf(gauge, 0.0, gauge_max)
		break_stats.text = tr("BATTLE_BREAK") % [int(gauge), int(tactical["break_max"])]
		var locked: bool = bool(tactical.get("break_locked", false))
		var exposed: bool = not tactical.get("exposed", {}).is_empty()
		if locked:
			break_stats.text += " · " + tr("BATTLE_BREAK_LOCKED")
		if exposed:
			break_stats.text += " · " + tr("BATTLE_EXPOSED")
		break_stats.tooltip_text = break_stats.text
		# Semantic color/line treatment; no status rule changes.
		break_stats.add_theme_color_override("font_color",
			Tokens.INTENT if locked else Tokens.BREAK)
	else:
		break_stats.text = ""
		break_stats.tooltip_text = ""

	# A published event is the ONLY source of threat information.
	intent.text = ""
	var published: Array = projection.get("intent", [])
	intent_panel.visible = not published.is_empty()
	if not published.is_empty():
		var announced: Dictionary = published[0]
		var names: PackedStringArray = []
		for target: String in announced.get("target_ids", []):
			names.append(tr(str(projection.get("actor_name_keys", {}).get(
				target, "BATTLE_HERO_" + target))))
		var skill_key: String = str(announced.get("name_key",
			"BATTLE_" + str(announced.get("skill_id", "")).to_upper()))
		intent.text = tr("BATTLE_INTENT_DETAIL") % [
			tr(skill_key), ", ".join(names), int(announced.get("hit_count", 1))]
	intent.tooltip_text = intent.text

