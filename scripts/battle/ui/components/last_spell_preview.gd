extends Control
## Read-only Last Spell cut-in. Activation is an intent, never a resource write.
signal activation_requested(target_id: String)
signal cancel_requested()
const UI = preload("res://scripts/battle/ui/components/ui_elements.gd")
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

func _ready() -> void:
	name = "LastSpellPreview"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	artwork = TextureRect.new()
	artwork.name = "CharacterCutIn"
	artwork.position = Vector2(260, 80)
	artwork.size = Vector2(370, 630)
	artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(artwork)
	var panel := PanelContainer.new()
	panel.name = "LastSpellInformation"
	panel.position = Vector2(560, 130)
	panel.size = Vector2(405, 560)
	add_child(panel)
	var column: VBoxContainer = UI.column(panel)
	column.add_theme_constant_override("separation", 14)
	UI.label(column, "BATTLE_LAST", 16).add_theme_color_override("font_color", Color("#CAA4F7"))
	title = UI.label(column, "", 25)
	UI.label(column, "BATTLE_FULL", 14)
	costs = UI.label(column, "", 22)
	costs.add_theme_color_override("font_color", Color("#87DEFF"))
	timing = UI.label(column, "", 14)
	var warning: Label = UI.label(column, "BATTLE_LAST_WARNING", 17)
	warning.size_flags_vertical = Control.SIZE_EXPAND_FILL
	warning.add_theme_color_override("font_color", Color("#FFB7BE"))
	target_selector = OptionButton.new()
	target_selector.name = "LastSpellTarget"
	column.add_child(target_selector)
	error_label = UI.label(column, "", 13)
	error_label.add_theme_color_override("font_color", Color("#FFD190"))
	var actions := HBoxContainer.new()
	column.add_child(actions)
	activate_button = UI.button(actions, "BATTLE_LAST_ACTIVATE", func() -> void:
		if not activate_button.disabled and target_selector.selected >= 0:
			activation_requested.emit(target_ids[target_selector.selected]))
	activate_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	activate_button.custom_minimum_size.y = 52
	activate_button.add_theme_stylebox_override("normal", preload("res://scripts/battle/ui/components/battle_command_visual.gd").emphasis_surface(Color("#B77AE9"), "normal"))
	cancel_button = UI.button(actions, "BATTLE_LAST_CANCEL", func() -> void: cancel_requested.emit())
	preload("res://scripts/battle/ui/components/battle_hud_chrome.gd").install(panel)
	hide()

func present(spell_name: String, quote: Dictionary, texture: Texture2D, targets: Array, reason: String) -> void:
	inspection = quote.duplicate(true)
	title.text = spell_name
	artwork.texture = texture
	target_ids.clear()
	target_selector.clear()
	for target: Dictionary in targets:
		target_ids.append(str(target["id"]))
		target_selector.add_item(str(target["name"]))
	if target_ids.has("Boss"):
		target_selector.select(target_ids.find("Boss"))
	costs.text = ""
	timing.text = ""
	if quote.get("ok", false):
		costs.text = tr("BATTLE_COST") % [quote["quote"]["ap_cost"], quote["quote"]["mp_cost"]]
		timing.text = tr("BATTLE_LAST_DELAY") % int(quote["slot"]["planned_delay_rounds"])
	activate_button.disabled = not quote.get("ok", false) or target_ids.is_empty()
	error_label.text = reason if activate_button.disabled else ""
	show()
