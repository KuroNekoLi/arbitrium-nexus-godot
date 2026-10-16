@tool
extends Control
## V2: three independent islands keep the world visible between AP, phase and tools.
## The root remains TopBar (height 64) to preserve P42 and facade contracts.
const UI = preload("res://scripts/battle/ui/components/ui_elements.gd")
signal locale_requested(locale: String)
signal command_requested(kind: String, fields: Dictionary)
var header: Label
var resources: Label
var ap_value: Label
var rp_value: Label
var crystal_row: HBoxContainer
const CORE = preload("res://assets/ui/v35/ap_core.svg")
const CRYSTAL = preload("res://assets/ui/v35/ap_crystal.svg")
const FRAME = preload("res://addons/kenney_fantasy_ui_borders/panel-border-000.png")
const FRAME_TINT: Color = Color("#B59C6D")
const CAPTION_COLOR: Color = Color("#D9C294")
const AP_COLOR: Color = Color("#F4E7C2")
const RP_COLOR: Color = Color("#7FE3FF")

func _add_island(node_name: String, area: Rect2) -> HBoxContainer:
	var panel := PanelContainer.new()
	panel.name = node_name
	panel.position = area.position
	panel.size = area.size
	add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	panel.add_child(row)
	return row

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var resource_row: HBoxContainer = _add_island("ResourcePanel", Rect2(0, 0, 310, 64))
	resources = UI.label(resource_row, "", 21)
	resources.autowrap_mode = TextServer.AUTOWRAP_OFF
	resources.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resources.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	resources.hide() # Compatibility facade; all visible values read the same projection.
	var panel: PanelContainer = resource_row.get_parent()
	var inset: StyleBoxFlat = panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	# 4px insets keep the larger V3.5.1 caption inside the 64px TopBar contract.
	inset.content_margin_top = 4
	inset.content_margin_bottom = 4
	panel.add_theme_stylebox_override("panel", inset)
	var ornament := NinePatchRect.new()
	ornament.name = "ResourceFrame"
	ornament.texture = FRAME
	ornament.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ornament.patch_margin_left = 12
	ornament.patch_margin_right = 12
	ornament.patch_margin_top = 12
	ornament.patch_margin_bottom = 12
	ornament.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# V3.5.1: converge the white Kenney frame toward the target's dark gold.
	ornament.modulate = FRAME_TINT
	# PanelContainer measures direct children. An unmeasured overlay prevents
	# NinePatch's source texture minimum size from enlarging this HUD island.
	var overlay := Control.new()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(overlay)
	overlay.add_child(ornament)
	var core := TextureRect.new()
	core.name = "APCoreIcon"
	core.texture = CORE
	core.custom_minimum_size = Vector2(44, 44)
	core.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	core.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	core.mouse_filter = Control.MOUSE_FILTER_IGNORE
	resource_row.add_child(core)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 0)
	resource_row.add_child(column)
	var caption := HBoxContainer.new()
	column.add_child(caption)
	var caption_label: Label = UI.label(caption, "BATTLE_TEAM_AP", 13)
	caption_label.name = "APCaption"
	caption_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	caption_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caption_label.add_theme_color_override("font_color", CAPTION_COLOR)
	rp_value = UI.label(caption, "", 13)
	rp_value.name = "RPValue"
	rp_value.autowrap_mode = TextServer.AUTOWRAP_OFF
	rp_value.add_theme_color_override("font_color", RP_COLOR)
	var values := HBoxContainer.new()
	values.add_theme_constant_override("separation", 6)
	column.add_child(values)
	ap_value = UI.label(values, "", 24)
	ap_value.name = "APValue"
	ap_value.autowrap_mode = TextServer.AUTOWRAP_OFF
	ap_value.add_theme_color_override("font_color", AP_COLOR)
	ap_value.add_theme_color_override("font_outline_color", Color("#07111D"))
	ap_value.add_theme_constant_override("outline_size", 4)
	crystal_row = HBoxContainer.new()
	crystal_row.name = "APCrystalRow"
	crystal_row.add_theme_constant_override("separation", 2)
	values.add_child(crystal_row)

	var phase_row: HBoxContainer = _add_island("PhasePanel", Rect2(400, 0, 402, 64))
	preload("res://scripts/battle/ui/components/battle_hud_chrome.gd").install(phase_row.get_parent())
	header = UI.label(phase_row, "BATTLE_TITLE", 23)
	header.autowrap_mode = TextServer.AUTOWRAP_OFF
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var utility_row: HBoxContainer = _add_island("UtilityPanel", Rect2(930, 0, 318, 64))
	preload("res://scripts/battle/ui/components/battle_hud_chrome.gd").install(utility_row.get_parent())
	UI.button(utility_row, "EN", func() -> void: locale_requested.emit("en"))
	UI.button(utility_row, "繁中", func() -> void: locale_requested.emit("zh_TW"))
	UI.button(utility_row, "BATTLE_SAVE", func() -> void: command_requested.emit("SAVE_REPLAY", {}))
	# USER_APPROVED: utility controls are not part of the battle HUD.
	# Retain the node/API for callers; localization and tape services still work.
	utility_row.get_parent().hide()

func render_phase(projection: Dictionary) -> void:
	header.text = tr("BATTLE_PHASE_" + projection["phase"]) + "   ·   " + tr("BATTLE_ROUND") % projection["round"]
	resources.text = tr("BATTLE_RESOURCES") % [projection["resources"]["current_ap"], projection["resources"]["rp"]]
	render_resource_values(projection["resources"])

func render_resource_values(values: Dictionary) -> void:
	var value: int = int(values["current_ap"])
	ap_value.text = "%d AP" % value
	rp_value.text = "RP %d" % int(values["rp"])
	for old: Node in crystal_row.get_children():
		crystal_row.remove_child(old)
		old.queue_free()
	var slots: int = mini(12, maxi(value, int(values.get("base_ap", value))))
	for index: int in slots:
		var gem := TextureRect.new()
		gem.texture = CRYSTAL
		gem.custom_minimum_size = Vector2(minf(18.0, 132.0 / maxf(1.0, slots)), 20)
		gem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		gem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		gem.modulate = Color.WHITE if index < value else Color(0.22, 0.30, 0.38, 0.55)
		gem.mouse_filter = Control.MOUSE_FILTER_IGNORE
		crystal_row.add_child(gem)
	crystal_row.tooltip_text = resources.text # Numeric value stays exact beyond 12 visible gems.
