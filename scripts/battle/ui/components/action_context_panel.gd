@tool
extends PanelContainer
## V2.2 action details: preview/settings scroll; Confirm and Cancel stay fixed.
const UI = preload("res://scripts/battle/ui/components/ui_elements.gd")
const Tokens = preload("res://scripts/battle/ui/components/battle_visual_tokens.gd")
signal command_requested(kind: String, fields: Dictionary)
signal confirm_requested()
signal cancel_requested()

@export var details: Label
@export var feedback: Label
@export var mode: OptionButton
@export var combo: CheckButton
@export var confirm_button: Button
@export var reduced_toggle: CheckButton
@export var mute_toggle: CheckButton
@export var detail_scroll: ScrollContainer
@export var action_row: HBoxContainer
@export var summary: HBoxContainer
@export var artwork: TextureRect
@export var action_title: Label
@export var cost_badge: Label
@export var target_label: Label
@export var preferences_disclosure: Button
@export var preferences_content: Control

func _ready() -> void:
	mode.item_selected.connect(func(_i: int) -> void: command_requested.emit("REFRESH_PREVIEW", {}))
	combo.toggled.connect(func(_on: bool) -> void: command_requested.emit("REFRESH_PREVIEW", {}))
	confirm_button.pressed.connect(func() -> void: confirm_requested.emit())
	action_row.get_node("CancelButton").pressed.connect(func() -> void: cancel_requested.emit())
	# Preferences may live in the HUD's separate floating panel.
	if preferences_content != null:
		preferences_content.get_node("Button").pressed.connect(func() -> void: command_requested.emit("SKIP_ANIMATION", {}))
	if reduced_toggle != null:
		reduced_toggle.toggled.connect(func(enabled: bool) -> void: command_requested.emit("REDUCED_MOTION", {"enabled":enabled}))
	if mute_toggle != null:
		mute_toggle.toggled.connect(func(enabled: bool) -> void: command_requested.emit("MUTE_AUDIO", {"enabled":enabled}))

func render_summary(title: String, texture: Texture2D, cost: String, target: String) -> void:
	details.get_parent().show()
	action_title.text = title
	artwork.texture = texture
	cost_badge.text = cost
	cost_badge.visible = not cost.is_empty()
	target_label.text = target

func clear_summary() -> void:
	render_summary(tr("BATTLE_SELECT"), preload("res://assets/ui/v35/cmd_analyze.svg"), "", tr("BATTLE_CONTEXT_EMPTY"))
	details.get_parent().hide()
