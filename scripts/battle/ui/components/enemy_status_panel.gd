extends PanelContainer
## V3.1: Boss HP and Break are separate, read-only visual projections.
## Real values exclusively come from the existing BattlePresentationAdapter.
const UI = preload("res://scripts/battle/ui/components/ui_elements.gd")
const Tokens = preload("res://scripts/battle/ui/components/battle_visual_tokens.gd")
var boss_stats: Label
var break_stats: Label
var intent: Label
var boss_title: Label
var hp_bar: ProgressBar
var break_bar: ProgressBar
var _intent_heading: Label

func _ready() -> void:
	var enemy: VBoxContainer = UI.column(self)
	enemy.add_theme_constant_override("separation", 4)
	boss_title = UI.label(enemy, "BATTLE_TITLE", 19)
	boss_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	boss_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

	boss_stats = UI.label(enemy, "", 14)
	boss_stats.name = "BossHPText"
	boss_stats.autowrap_mode = TextServer.AUTOWRAP_OFF
	hp_bar = ProgressBar.new()
	hp_bar.name = "BossHPBar"
	Tokens.setup_read_only_bar(hp_bar, Tokens.HP)
	enemy.add_child(hp_bar)

	break_stats = UI.label(enemy, "", 13)
	break_stats.name = "BossBreakText"
	break_stats.autowrap_mode = TextServer.AUTOWRAP_OFF
	break_stats.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	break_bar = ProgressBar.new()
	break_bar.name = "BossBreakBar"
	Tokens.setup_read_only_bar(break_bar, Tokens.BREAK)
	enemy.add_child(break_bar)

	_intent_heading = UI.label(enemy, "BATTLE_INTENT", 13)
	_intent_heading.add_theme_color_override("font_color", Tokens.INTENT)
	intent = UI.label(enemy, "", 14)
	intent.max_lines_visible = 2
	intent.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

func render_enemy(projection: Dictionary) -> void:
	boss_title.text = tr(str(projection.get("actor_name_keys", {}).get("Boss", "BATTLE_TITLE")))
	var boss: Dictionary = projection["actors"]["Boss"]
	var hp: float = float(boss.get("hp", 0))
	var hp_max: float = maxf(1.0, float(boss.get("max_hp", 1)))
	boss_stats.text = tr("BATTLE_HP") % [int(hp), int(boss.get("max_hp", 1))]
	hp_bar.max_value = hp_max
	hp_bar.value = clampf(hp, 0.0, hp_max)

	var tactical: Dictionary = projection.get("tactical", {})
	var show_break: bool = tactical.has("break_gauge") and tactical.has("break_max")
	break_stats.visible = show_break
	break_bar.visible = show_break
	if show_break:
		var gauge: float = float(tactical["break_gauge"])
		var gauge_max: float = maxf(1.0, float(tactical["break_max"]))
		break_bar.max_value = gauge_max
		break_bar.value = clampf(gauge, 0.0, gauge_max)
		break_stats.text = tr("BATTLE_BREAK") % [int(gauge), int(tactical["break_max"])]
		if bool(tactical.get("break_locked", false)):
			break_stats.text += " · " + tr("BATTLE_BREAK_LOCKED")
		if not tactical.get("exposed", {}).is_empty():
			break_stats.text += " · " + tr("BATTLE_EXPOSED")
	else:
		break_stats.text = ""

	# Public Intent only. Never synthesize hidden targets or protection rights.
	intent.text = ""
	var published: Array = projection.get("intent", [])
	if not published.is_empty():
		var announced: Dictionary = published[0]
		var names: PackedStringArray = []
		for target: String in announced.get("target_ids", []):
			names.append(tr(str(projection.get("actor_name_keys", {}).get(target, "BATTLE_HERO_" + target))))
		var skill_key: String = str(announced.get("name_key", "BATTLE_" + str(announced.get("skill_id", "")).to_upper()))
		intent.text = tr("BATTLE_INTENT_DETAIL") % [
			tr(skill_key), ", ".join(names), int(announced.get("hit_count", 1))]

