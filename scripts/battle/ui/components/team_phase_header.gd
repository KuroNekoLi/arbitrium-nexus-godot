extends Control
## V2: three independent islands keep the world visible between AP, phase and tools.
## The root remains TopBar (height 64) to preserve P42 and facade contracts.
const UI = preload("res://scripts/battle/ui/components/ui_elements.gd")
signal locale_requested(locale: String)
signal command_requested(kind: String, fields: Dictionary)
var header: Label
var resources: Label

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

	var phase_row: HBoxContainer = _add_island("PhasePanel", Rect2(400, 0, 402, 64))
	header = UI.label(phase_row, "BATTLE_TITLE", 23)
	header.autowrap_mode = TextServer.AUTOWRAP_OFF
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var utility_row: HBoxContainer = _add_island("UtilityPanel", Rect2(930, 0, 318, 64))
	UI.button(utility_row, "EN", func() -> void: locale_requested.emit("en"))
	UI.button(utility_row, "繁中", func() -> void: locale_requested.emit("zh_TW"))
	UI.button(utility_row, "BATTLE_SAVE", func() -> void: command_requested.emit("SAVE_REPLAY", {}))

func render_phase(projection: Dictionary) -> void:
	header.text = tr("BATTLE_PHASE_" + projection["phase"]) + "   ·   " + tr("BATTLE_ROUND") % projection["round"]
	resources.text = tr("BATTLE_RESOURCES") % [projection["resources"]["current_ap"], projection["resources"]["rp"]]
