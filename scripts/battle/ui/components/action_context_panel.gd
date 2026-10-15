extends PanelContainer
const UI = preload("res://scripts/battle/ui/components/ui_elements.gd")
signal command_requested(kind: String, fields: Dictionary)
signal confirm_requested()
signal cancel_requested()
var details: Label
var feedback: Label
var mode: OptionButton
var combo: CheckButton
var confirm_button: Button
var log_label: Label

func _ready() -> void:
	var context: VBoxContainer = UI.column(self)
	UI.label(context, "BATTLE_DETAILS", 14)
	details = UI.label(context, "BATTLE_SELECT", 16)
	details.custom_minimum_size.y = 84
	mode = OptionButton.new()
	mode.add_item(tr("BATTLE_CHANTLESS"))
	mode.add_item(tr("BATTLE_FULL"))
	mode.visible = false
	context.add_child(mode)
	mode.item_selected.connect(func(_i: int) -> void: command_requested.emit("REFRESH_PREVIEW", {}))
	combo = CheckButton.new()
	combo.text = tr("BATTLE_COMBO")
	combo.visible = false
	context.add_child(combo)
	combo.toggled.connect(func(_on: bool) -> void: command_requested.emit("REFRESH_PREVIEW", {}))
	var confirm_row := HBoxContainer.new()
	context.add_child(confirm_row)
	confirm_button = UI.button(confirm_row, "BATTLE_CONFIRM", func() -> void: confirm_requested.emit())
	UI.button(confirm_row, "BATTLE_CANCEL", func() -> void: cancel_requested.emit())
	feedback = UI.label(context, "", 14)
	feedback.add_theme_color_override("font_color", Color("ffd18d"))
	log_label = UI.label(context, "BATTLE_LOG", 12)
	log_label.max_lines_visible = 3

