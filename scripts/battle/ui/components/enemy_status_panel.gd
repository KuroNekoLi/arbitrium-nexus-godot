@tool
extends PanelContainer
## V3.3: a composed, read-only Boss status with distinct HP/Break and public Intent.
## Rendered threat styling is ornamental; NEVER deduce danger, targets or legality.
const UI = preload("res://scripts/battle/ui/components/ui_elements.gd")
const Tokens = preload("res://scripts/battle/ui/components/battle_visual_tokens.gd")
@export var boss_stats: Label
@export var break_stats: Label
@export var intent: Label
@export var boss_title: Label
@export var hp_bar: ProgressBar
@export var break_bar: ProgressBar
@export var _intent_heading: Label

@export var title_plate: HBoxContainer
@export var hp_section: VBoxContainer
@export var break_section: VBoxContainer
@export var intent_panel: PanelContainer
@export var _intent_accent: ColorRect
const INTENT_ICON: Texture2D = preload("res://assets/ui/v35/intent_skill.svg")
## Hero accents mirror PartyStatusPanel so a target chip reads as "that hero".
const TARGET_ACCENTS: Dictionary = {"A": Color("efc675"), "B": Color("75d6ff"), "C": Color("df9cff")}
@export var intent_icon: TextureRect
@export var hit_chip: Label
@export var target_badges: HBoxContainer
@export var target_portrait: TextureRect
const AppearanceRegistry = preload("res://scripts/battle/presentation/character_appearance_registry.gd")

func _make_chip(parent: Node, name: String, accent: Color) -> Label:
	var chip := Label.new()
	chip.name = name
	chip.add_theme_font_size_override("font_size", 11)
	chip.add_theme_color_override("font_color", accent.lightened(0.45))
	var style := StyleBoxFlat.new()
	style.bg_color = accent.darkened(0.7)
	style.border_color = accent
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 0
	style.content_margin_bottom = 1
	chip.add_theme_stylebox_override("normal", style)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.autowrap_mode = TextServer.AUTOWRAP_OFF
	# Short chips must report their text width as minimum size; ellipsis
	# trimming lets a shrink-sized Label collapse to an empty pill (V3.5.5 VIS09).
	chip.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	chip.clip_text = false
	parent.add_child(chip)
	return chip

## Read-only accessor for tests/QA: published target ids currently shown.
func target_badge_ids() -> Array:
	var ids: Array = []
	for child: Node in target_badges.get_children():
		ids.append(str(child.name).trim_prefix("Target_"))
	return ids

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
			break_stats.text += "\n" + tr("BATTLE_BREAK_LOCKED")
		elif int(tactical.get("break_resilience_round",-1)) == int(projection.get("round",-2)):
			break_stats.text += "\n" + tr("BKC_BREAK_RESILIENT")
		if exposed:
			break_stats.text += "\n" + tr("BATTLE_EXPOSED")
		break_stats.tooltip_text = break_stats.text
		# Semantic color/line treatment; no status rule changes.
		break_stats.add_theme_color_override("font_color",
			Tokens.INTENT if locked else Tokens.BREAK)
	else:
		break_stats.text = ""
		break_stats.tooltip_text = ""

	# A published event is the ONLY source of threat information.
	intent.text = ""
	hit_chip.text = ""
	hit_chip.visible = false
	for old: Node in target_badges.get_children():
		target_badges.remove_child(old)
		old.queue_free()
	var published: Array = projection.get("intent", [])
	intent_panel.visible = not published.is_empty()
	target_badges.visible = false
	target_portrait.hide()
	if not published.is_empty():
		var announced: Dictionary = published[0]
		var targets: Array = announced.get("target_ids", [])
		# The portrait identifies a published target, not a predicted next victim.
		if targets.size() == 1 and targets[0] in ["A", "B", "C"]:
			target_portrait.texture = AppearanceRegistry.portrait_for(str(targets[0]))
			target_portrait.show()
		var names: PackedStringArray = []
		for target: String in announced.get("target_ids", []):
			var target_name: String = tr(str(projection.get("actor_name_keys", {}).get(
				target, "BATTLE_HERO_" + target)))
			names.append(target_name)
			var chip: Label = _make_chip(target_badges, "Target_" + target,
				TARGET_ACCENTS.get(target, Tokens.INTENT))
			chip.clip_text = false
			chip.text = target_name
			chip.tooltip_text = tr("BATTLE_INTENT_TARGET") % target_name
		target_badges.visible = target_badges.get_child_count() > 0
		if announced.has("hit_count"):
			hit_chip.text = "×%d" % int(announced["hit_count"])
			hit_chip.visible = true
		var skill_key: String = str(announced.get("name_key",
			"BATTLE_" + str(announced.get("skill_id", "")).to_upper()))
		intent.text = tr("BATTLE_INTENT_DETAIL") % [
			tr(skill_key), ", ".join(names), int(announced.get("hit_count", 1))]
		var response: String = str(announced.get("break_response","NOT_ELIGIBLE"))
		var control: String = str(announced.get("break_c_result",""))
		if control == "CANCEL":
			intent.text += "\n" + tr("BKC_INTENT_CANCELLED")
		elif control == "DOWNGRADE":
			intent.text += "\n" + tr("BKC_INTENT_DOWNGRADED")
		elif response == "CANCEL":
			intent.text += "\n" + tr("BKC_INTENT_CANCEL_PREVIEW")
		elif response == "DOWNGRADE":
			var fallback: String = str(announced.get("break_fallback_skill_id",""))
			intent.text += "\n" + (tr("BKC_INTENT_DOWNGRADE_PREVIEW") % tr("intent."+fallback.to_lower()+".name"))
		var boss_cast: Dictionary = projection.get("boss_cast_public",{})
		if boss_cast.has("current_stability"):
			intent.text += "\n" + (tr("BKC_CAST_STABILITY") % [
				int(boss_cast["current_stability"]),int(boss_cast.get("base_stability",1))])
			if int(boss_cast.get("focus_ward",0)) > 0:
				intent.text += "\n" + (tr("BKC_CAST_FOCUS_WARD") % int(boss_cast["focus_ward"]))
	intent.tooltip_text = intent.text

