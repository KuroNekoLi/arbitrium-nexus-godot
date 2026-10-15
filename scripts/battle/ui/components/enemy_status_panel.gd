extends PanelContainer
const UI = preload("res://scripts/battle/ui/components/ui_elements.gd")
var boss_stats: Label
var intent: Label

func _ready() -> void:
	var enemy: VBoxContainer = UI.column(self)
	UI.label(enemy, "BATTLE_TITLE", 20)
	boss_stats = UI.label(enemy, "", 17)
	UI.label(enemy, "BATTLE_INTENT", 14).add_theme_color_override("font_color", Color("ffb1bf"))
	intent = UI.label(enemy, "", 16)
	UI.label(enemy, "BATTLE_PROTECTABLE", 13)

func render_enemy(projection: Dictionary) -> void:
	var boss: Dictionary = projection["actors"]["Boss"]
	boss_stats.text = tr("BATTLE_HP") % [boss["hp"], boss["max_hp"]]
	if not projection["tactical"].is_empty():
		boss_stats.text += "\n" + tr("BATTLE_BREAK") % [projection["tactical"]["break_gauge"], projection["tactical"]["break_max"]]
		if projection["tactical"]["break_locked"]:
			boss_stats.text += "\n" + tr("BATTLE_BREAK_LOCKED")
		if not projection["tactical"]["exposed"].is_empty():
			boss_stats.text += "\n" + tr("BATTLE_EXPOSED")
	intent.text = ""
	if not projection["intent"].is_empty():
		var announced: Dictionary = projection["intent"][0]
		var target: String = str(announced["target_ids"][0])
		intent.text = tr("BATTLE_INTENT_DETAIL") % [tr("BATTLE_" + str(announced["skill_id"]).to_upper()), tr("BATTLE_HERO_" + target), announced["hit_count"]]

