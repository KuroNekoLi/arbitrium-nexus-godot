extends PanelContainer
## V2.2 action details: preview/settings scroll; Confirm and Cancel stay fixed.
const UI = preload("res://scripts/battle/ui/components/ui_elements.gd")
const Tokens = preload("res://scripts/battle/ui/components/battle_visual_tokens.gd")
signal command_requested(kind: String, fields: Dictionary)
signal confirm_requested()
signal cancel_requested()

var details: Label
var feedback: Label
var mode: OptionButton
var combo: CheckButton
var confirm_button: Button
var reduced_toggle: CheckButton
var mute_toggle: CheckButton
var detail_scroll: ScrollContainer
var action_row: HBoxContainer

func _ready() -> void:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	add_child(root)

	detail_scroll = ScrollContainer.new()
	detail_scroll.name = "DetailScroll"
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	detail_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	detail_scroll.follow_focus = true
	detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_scroll.custom_minimum_size.y = 88
	root.add_child(detail_scroll)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 4)
	detail_scroll.add_child(content)
	# V3.5.4: gold heading + rule, details in a deep inset (presentation only).
	var heading: Label = UI.label(content, "BATTLE_DETAILS", 14)
	heading.name = "DetailsHeading"
	heading.add_theme_color_override("font_color", Color("#D8C08A"))
	var rule := PanelContainer.new()
	rule.name = "DetailsRule"
	rule.custom_minimum_size.y = 1
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rule.add_theme_stylebox_override("panel", Tokens.heading_rule())
	content.add_child(rule)
	var inset := PanelContainer.new()
	inset.name = "DetailsInset"
	var inset_style: StyleBoxFlat = Tokens.inset_frame(Tokens.METAL.darkened(0.35))
	inset_style.content_margin_left = 8
	inset_style.content_margin_right = 8
	inset_style.content_margin_top = 4
	inset_style.content_margin_bottom = 4
	inset.add_theme_stylebox_override("panel", inset_style)
	inset.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(inset)
	details = UI.label(inset, "BATTLE_SELECT", 16)
	details.custom_minimum_size.y = 76

	mode = OptionButton.new()
	mode.add_item(tr("BATTLE_CHANTLESS"))
	mode.add_item(tr("BATTLE_FULL"))
	mode.visible = false
	content.add_child(mode)
	mode.item_selected.connect(func(_i: int) -> void: command_requested.emit("REFRESH_PREVIEW", {}))

	combo = CheckButton.new()
	combo.text = tr("BATTLE_COMBO")
	combo.visible = false
	content.add_child(combo)
	combo.toggled.connect(func(_on: bool) -> void: command_requested.emit("REFRESH_PREVIEW", {}))

	# V2.5: presentation-only preferences are a collapsed disclosure.
	# Confirm/Cancel stay visible below DetailScroll even with the disclosure open.
	var disclosure := Button.new()
	disclosure.name = "PreferencesDisclosure"
	disclosure.text = "⚙"
	disclosure.tooltip_text = tr("BATTLE_REDUCED") + " · " + tr("BATTLE_MUTE")
	disclosure.alignment = HORIZONTAL_ALIGNMENT_LEFT
	disclosure.custom_minimum_size.y = 28
	root.add_child(disclosure)
	var settings := VBoxContainer.new()
	settings.name = "PreferencesContent"
	settings.visible = false
	content.add_child(settings)
	disclosure.pressed.connect(func() -> void:
		settings.visible = not settings.visible)
	reduced_toggle = CheckButton.new()
	reduced_toggle.text = tr("BATTLE_REDUCED")
	reduced_toggle.add_theme_font_size_override("font_size", 12)
	reduced_toggle.toggled.connect(func(enabled: bool) -> void: command_requested.emit("REDUCED_MOTION", {"enabled":enabled}))
	settings.add_child(reduced_toggle)
	UI.button(settings, "BATTLE_SKIP", func() -> void: command_requested.emit("SKIP_ANIMATION", {})).add_theme_font_size_override("font_size", 12)
	mute_toggle = CheckButton.new()
	mute_toggle.text = tr("BATTLE_MUTE")
	mute_toggle.add_theme_font_size_override("font_size", 12)
	mute_toggle.toggled.connect(func(enabled: bool) -> void: command_requested.emit("MUTE_AUDIO", {"enabled":enabled}))
	settings.add_child(mute_toggle)

	# Deliberately OUTSIDE the ScrollContainer: confirmation never scrolls away.
	action_row = HBoxContainer.new()
	action_row.name = "ActionButtons"
	root.add_child(action_row)
	action_row.add_theme_constant_override("separation", 6)
	confirm_button = UI.button(action_row, "BATTLE_CONFIRM", func() -> void: confirm_requested.emit())
	confirm_button.name = "ConfirmButton"
	confirm_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	confirm_button.add_theme_stylebox_override("normal", Tokens.command_surface(Tokens.COMMAND_END, false))
	confirm_button.add_theme_stylebox_override("hover", Tokens.command_surface(Tokens.COMMAND_END, false, true))
	confirm_button.add_theme_stylebox_override("pressed", Tokens.command_surface(Tokens.COMMAND_END, true))
	confirm_button.add_theme_stylebox_override("focus", Tokens.focus_ring())
	confirm_button.add_theme_color_override("font_color", Tokens.COMMAND_END.lightened(0.5))
	var cancel: Button = UI.button(action_row, "BATTLE_CANCEL", func() -> void: cancel_requested.emit())
	cancel.name = "CancelButton"
	cancel.add_theme_stylebox_override("normal", Tokens.command_surface(Tokens.COMMAND_UTILITY, false))
	cancel.add_theme_stylebox_override("hover", Tokens.command_surface(Tokens.COMMAND_UTILITY, false, true))
	cancel.add_theme_stylebox_override("focus", Tokens.focus_ring())

	feedback = UI.label(root, "", 14)
	feedback.add_theme_color_override("font_color", Color("ffd18d"))
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback.max_lines_visible = 2
	feedback.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	feedback.custom_minimum_size.y = 20
