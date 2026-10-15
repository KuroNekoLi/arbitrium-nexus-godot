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
var summary: HBoxContainer
var artwork: TextureRect
var action_title: Label
var cost_badge: Label
var target_label: Label

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
	summary = HBoxContainer.new()
	summary.name = "ActionSummary"
	summary.add_theme_constant_override("separation", 7)
	content.add_child(summary)
	artwork = TextureRect.new()
	artwork.name = "ActionArtwork"
	artwork.custom_minimum_size = Vector2(48, 48)
	artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	summary.add_child(artwork)
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_theme_constant_override("separation", 0)
	summary.add_child(identity)
	action_title = UI.label(identity, "BATTLE_SELECT", 15)
	action_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	action_title.add_theme_color_override("font_color", Color("#EFE1BE"))
	cost_badge = UI.label(identity, "", 12)
	cost_badge.add_theme_color_override("font_color", Tokens.HERO_MP)
	target_label = UI.label(identity, "BATTLE_TARGET", 11)
	target_label.add_theme_color_override("font_color", Color("#ADBFD0"))
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
	details = UI.label(inset, "BATTLE_SELECT", 13)
	details.custom_minimum_size.y = 32
	clear_summary()

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
	disclosure.custom_minimum_size.y = 18
	disclosure.add_theme_font_size_override("font_size", 11)
	var preferences_style := StyleBoxEmpty.new()
	preferences_style.content_margin_left = 4
	preferences_style.content_margin_top = 0
	preferences_style.content_margin_bottom = 0
	disclosure.add_theme_stylebox_override("normal", preferences_style)
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

## A passive projection: the caller supplies quoted costs and committed names.
## No resource payment or target prediction is performed in this component.
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
