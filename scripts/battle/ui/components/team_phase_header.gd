extends PanelContainer
const UI = preload("res://scripts/battle/ui/components/ui_elements.gd")
signal locale_requested(locale: String)
signal command_requested(kind: String, fields: Dictionary)
var header: Label
var resources: Label

func _ready() -> void:
	var content: VBoxContainer = UI.column(self)
	var row := HBoxContainer.new()
	content.add_child(row)
	header = UI.label(row, "BATTLE_TITLE", 23)
	header.autowrap_mode = TextServer.AUTOWRAP_OFF
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resources = UI.label(row, "", 21)
	resources.autowrap_mode = TextServer.AUTOWRAP_OFF
	UI.button(row, "EN", func() -> void: locale_requested.emit("en"))
	UI.button(row, "繁中", func() -> void: locale_requested.emit("zh_TW"))
	UI.button(row, "BATTLE_SAVE", func() -> void: command_requested.emit("SAVE_REPLAY", {}))

func render_phase(projection: Dictionary) -> void:
	header.text = tr("BATTLE_PHASE_" + projection["phase"]) + "   ·   " + tr("BATTLE_ROUND") % projection["round"]
	resources.text = tr("BATTLE_RESOURCES") % [projection["resources"]["current_ap"], projection["resources"]["rp"]]
