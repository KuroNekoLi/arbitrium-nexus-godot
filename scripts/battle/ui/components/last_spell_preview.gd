extends Control
## Read-only Last Spell cut-in. Activation is an intent, never a resource write.
signal activation_requested(target_id: String)
signal cancel_requested()
signal target_changed(target_id: String)
const UI = preload("res://scripts/battle/ui/components/ui_elements.gd")
const Visual = preload("res://scripts/battle/ui/components/battle_command_visual.gd")
const Tokens = preload("res://scripts/battle/ui/components/battle_visual_tokens.gd")
const TargetCard = preload("res://scripts/battle/ui/components/last_spell_target_card.gd")
const TargetMarker = preload("res://scripts/battle/ui/components/last_spell_target_marker.gd")
var artwork: TextureRect
var title: Label
var costs: Label
var timing: Label
var error_label: Label
var target_selector: OptionButton
var activate_button: Button
var cancel_button: Button
var target_ids: Array[String] = []
var inspection: Dictionary = {}
var targeting: Dictionary = {}
var target_cards: Dictionary = {}
var world_markers: Dictionary = {}
var information: PanelContainer
var scope_label: Label
var description: Label
var target_heading: Label
var target_row: HBoxContainer
var world_layer: Control
var summary_title: Label
var summary_description: Label
var summary_target: Label
var spell_art: TextureRect
var ap_value: Label
var mp_value: Label
var rune: TextureRect
var accent: Color

func _ready() -> void:
	name = "LastSpellPreview"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	world_layer = Control.new()
	world_layer.name = "TargetMarkers"
	world_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(world_layer)
	rune = TextureRect.new()
	rune.texture = preload("res://assets/ui/v35/ap_core.svg")
	rune.position = Vector2(270, 375)
	rune.size = Vector2(270, 270)
	rune.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rune.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rune)
	artwork = TextureRect.new()
	artwork.name = "CharacterCutIn"
	artwork.position = Vector2(278, 393)
	artwork.size = Vector2(245, 317)
	artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(artwork)
	information = PanelContainer.new()
	information.name = "LastSpellInformation"
	information.position = Vector2(455, 292)
	information.size = Vector2(520, 414)
	information.add_theme_stylebox_override("panel", Tokens.inset_frame(Color("#BBA16C"), Color("#040916F2")))
	add_child(information)
	var column: VBoxContainer = UI.column(information)
	column.add_theme_constant_override("separation", 5)
	var heading := HBoxContainer.new()
	column.add_child(heading)
	var emblem := TextureRect.new()
	emblem.texture = preload("res://assets/ui/v35/cmd_last.svg")
	emblem.custom_minimum_size = Vector2(46, 60)
	emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heading.add_child(emblem)
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_theme_constant_override("separation", 0)
	heading.add_child(identity)
	UI.label(identity, "BATTLE_LAST", 12)
	title = UI.label(identity, "", 24)
	scope_label = UI.label(identity, "", 11)
	spell_art = TextureRect.new()
	spell_art.custom_minimum_size = Vector2(88, 70)
	spell_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	spell_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	spell_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heading.add_child(spell_art)
	description = UI.label(column, "", 13)
	description.custom_minimum_size.y = 35
	var prices := HBoxContainer.new()
	prices.add_theme_constant_override("separation", 12)
	column.add_child(prices)
	ap_value = _resource_cell(prices, "LAST_AP", Color("#6EDAFF"))
	mp_value = _resource_cell(prices, "LAST_MP", Color("#D19AFF"))
	timing = _resource_cell(prices, "LAST_TIMING", Color("#E4D5B6"))
	costs = UI.label(column, "", 1)
	costs.hide() # Compatibility field; the visible costs have separate resource cells.
	var warning: Label = UI.label(column, "LAST_IRREVERSIBLE", 13)
	warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning.add_theme_stylebox_override("normal", Tokens.inset_frame(Color("#CC4D6A"), Color("#2C0A1B")))
	warning.add_theme_color_override("font_color", Color("#FFB7BE"))
	target_heading = UI.label(column, "", 13)
	target_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	target_row = HBoxContainer.new()
	target_row.name = "TargetCards"
	target_row.alignment = BoxContainer.ALIGNMENT_CENTER
	target_row.add_theme_constant_override("separation", 8)
	var target_scroll := ScrollContainer.new()
	target_scroll.name = "TargetScroll"
	target_scroll.custom_minimum_size.y = 100
	target_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	target_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(target_scroll)
	target_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	target_scroll.add_child(target_row)
	target_selector = OptionButton.new()
	target_selector.name = "LastSpellTarget"
	column.add_child(target_selector)
	target_selector.hide() # Retained for existing API clients; cards own player selection.
	error_label = UI.label(column, "", 13)
	error_label.add_theme_color_override("font_color", Color("#FFD190"))
	var actions := HBoxContainer.new()
	actions.name = "ActivationFooter"
	actions.add_theme_constant_override("separation", 10)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)
	column.add_child(actions)
	activate_button = UI.button(actions, "BATTLE_LAST_ACTIVATE", func() -> void:
		if not activate_button.disabled and target_selector.selected >= 0:
			activation_requested.emit(target_ids[target_selector.selected]))
	activate_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	activate_button.custom_minimum_size.y = 52
	activate_button.add_theme_font_size_override("font_size", 21)
	activate_button.icon = preload("res://assets/ui/v35/cmd_last.svg")
	activate_button.add_theme_constant_override("icon_max_width", 30)
	cancel_button = UI.button(actions, "BATTLE_LAST_CANCEL", func() -> void: cancel_requested.emit())
	cancel_button.custom_minimum_size.x = 106
	preload("res://scripts/battle/ui/components/battle_hud_chrome.gd").install(activate_button)
	preload("res://scripts/battle/ui/components/battle_hud_chrome.gd").install(information)
	var summary := PanelContainer.new()
	summary.name = "LastSpellSummary"
	summary.position = Vector2(984, 348)
	summary.size = Vector2(280, 220)
	add_child(summary)
	var summary_column: VBoxContainer = UI.column(summary)
	UI.label(summary_column, "BATTLE_LAST", 13)
	summary_title = UI.label(summary_column, "", 19)
	var summary_scroll := ScrollContainer.new()
	summary_scroll.custom_minimum_size.y = 80
	summary_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	summary_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	summary_column.add_child(summary_scroll)
	var summary_body := VBoxContainer.new()
	summary_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary_scroll.add_child(summary_body)
	summary_description = UI.label(summary_body, "", 13)
	UI.label(summary_body, "BATTLE_LAST_WARNING", 11).add_theme_color_override("font_color", Color("#E2ADAC"))
	summary_target = UI.label(summary_column, "", 13)
	preload("res://scripts/battle/ui/components/battle_hud_chrome.gd").install(summary)
	hide()

func _resource_cell(parent: Node, key: String, color: Color) -> Label:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(column)
	UI.label(column, key, 11)
	var value: Label = UI.label(column, "", 18)
	value.add_theme_color_override("font_color", color)
	return value

func present(spell_name: String, quote: Dictionary, texture: Texture2D, targets: Array, reason: String,
		presentation: Dictionary = {}) -> void:
	inspection = quote.duplicate(true)
	targeting = presentation.get("targeting", {}).duplicate(true)
	accent = Color("#F2CE79") if targeting.get("team", "") == "ALLY" else Color("#BB84FF")
	rune.modulate = Color(accent, 0.6)
	title.text = spell_name
	title.add_theme_color_override("font_color", accent.lightened(0.3))
	artwork.texture = texture
	var appearance: Resource = presentation.get("appearance")
	spell_art.texture = presentation.get("spell_art", appearance.artwork if appearance != null else preload("res://assets/ui/v35/cmd_last.svg"))
	description.text = tr(str(targeting.get("description_key", "BATTLE_LAST_WARNING")))
	scope_label.text = tr("LAST_SCOPE_" + str(targeting.get("team", "UNKNOWN")) + "_" + str(targeting.get("scope", "SINGLE"))) + "   ·   " + tr("BATTLE_FULL") + "   ·   " + tr("LAST_ONCE")
	summary_title.text = spell_name
	summary_description.text = description.text
	target_ids.clear()
	target_selector.clear()
	for child: Node in target_row.get_children():
		target_row.remove_child(child)
		child.queue_free()
	for child: Node in world_layer.get_children():
		world_layer.remove_child(child)
		child.queue_free()
	target_cards.clear()
	world_markers.clear()
	var all_targets: bool = targeting.get("scope", "") == "ALL"
	for target: Dictionary in targets:
		var id: String = str(target["id"])
		if target.get("legal", true):
			target_ids.append(id)
			target_selector.add_item(str(target["name"]))
		var target_card: Button = TargetCard.new()
		target_row.add_child(target_card)
		target_card.configure(target, Color("#F2CE79") if targeting.get("team", "") == "ALLY" else Color("#FF647F"), not all_targets)
		target_card.pressed.connect(select_target.bind(id))
		target_cards[id] = target_card
		if target.has("rect") and target.get("legal", true):
			var marker: Button = TargetMarker.new()
			marker.position = target["rect"].position
			marker.size = target["rect"].size
			marker.accent = Color("#F2CE79") if targeting.get("team", "") == "ALLY" else Color("#FF647F")
			marker.mouse_filter = Control.MOUSE_FILTER_IGNORE if all_targets else Control.MOUSE_FILTER_STOP
			marker.focus_mode = Control.FOCUS_NONE
			marker.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
			marker.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
			marker.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
			world_layer.add_child(marker)
			marker.pressed.connect(select_target.bind(id))
			world_markers[id] = marker
	costs.text = ""
	timing.text = ""
	ap_value.text = "—"
	mp_value.text = "—"
	if quote.get("ok", false):
		costs.text = tr("BATTLE_COST") % [quote["quote"]["ap_cost"], quote["quote"]["mp_cost"]]
		ap_value.text = "%d AP" % int(quote["quote"]["ap_cost"])
		mp_value.text = "%d MP" % int(quote["quote"]["mp_cost"])
	var slot: Dictionary = quote.get("slot", presentation.get("slot", {}))
	if slot.has("planned_delay_rounds"):
		timing.text = tr("LAST_RELEASE_VALUE") % int(slot["planned_delay_rounds"])
	activate_button.disabled = not quote.get("ok", false) or target_ids.is_empty()
	error_label.text = reason if activate_button.disabled else ""
	error_label.visible = not error_label.text.is_empty()
	for state: String in ["normal", "hover", "pressed", "disabled"]:
		var style: StyleBoxFlat = Visual.emphasis_surface(accent, state)
		style.bg_color = Color("#13082B") if targeting.get("team", "") != "ALLY" else Color("#231B0C")
		activate_button.add_theme_stylebox_override(state, style)
	var focus_style: StyleBoxFlat = Tokens.inset_frame(accent.lightened(0.4), Color.TRANSPARENT)
	focus_style.set_border_width_all(2)
	activate_button.add_theme_stylebox_override("focus", focus_style)
	select_target(str(presentation.get("selected_id", target_ids[0] if not target_ids.is_empty() else "")), false)
	show()

func select_target(id: String, notify: bool = true) -> void:
	if not target_ids.has(id): return
	target_selector.select(target_ids.find(id))
	var all_targets: bool = targeting.get("scope", "") == "ALL"
	for target: String in target_cards:
		target_cards[target].set_selected(target_ids.has(target) if all_targets else target == id, all_targets)
	for target: String in world_markers:
		world_markers[target].selected = all_targets or target == id
		world_markers[target].queue_redraw()
	target_heading.text = tr("LAST_ALL_SELECTED") % target_ids.size() if all_targets else tr("LAST_CHOOSE_TARGET")
	var names: PackedStringArray = []
	for index: int in target_ids.size():
		if all_targets or target_ids[index] == id:
			names.append(target_selector.get_item_text(index))
	summary_target.text = tr("LAST_TARGET") % " · ".join(names)
	if notify: target_changed.emit(id)
