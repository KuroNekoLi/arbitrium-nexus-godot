@tool
extends Control
## Read-only Last Spell cut-in. Activation is an intent, never a resource write.
signal activation_requested(target_id: String)
signal cancel_requested()
signal target_changed(target_id: String)
const UI = preload("res://scripts/battle/ui/components/ui_elements.gd")
const Visual = preload("res://scripts/battle/ui/components/battle_command_visual.gd")
const Tokens = preload("res://scripts/battle/ui/components/battle_visual_tokens.gd")
const AppearanceRegistry = preload("res://scripts/battle/presentation/character_appearance_registry.gd")
const TargetCard = preload("res://scripts/battle/ui/components/last_spell_target_card.gd")
const TargetMarker = preload("res://scripts/battle/ui/components/last_spell_target_marker.gd")
@export var artwork: TextureRect
@export var title: Label
@export var costs: Label
@export var timing: Label
@export var error_label: Label
@export var target_selector: OptionButton
@export var activate_button: Button
@export var cancel_button: Button
var target_ids: Array[String] = []
var inspection: Dictionary = {}
var targeting: Dictionary = {}
var target_cards: Dictionary = {}
var world_markers: Dictionary = {}
@export var information: PanelContainer
@export var scope_label: Label
@export var description: Label
@export var target_heading: Label
@export var target_row: HBoxContainer
@export var world_layer: Control
@export var summary_title: Label
@export var summary_description: Label
@export var summary_target: Label
@export var spell_art: TextureRect
@export var ap_value: Label
@export var mp_value: Label
@export var rune: TextureRect
var accent: Color

func _ready() -> void:
	activate_button.pressed.connect(func() -> void:
		if not activate_button.disabled and target_selector.selected >= 0:
			activation_requested.emit(target_ids[target_selector.selected]))
	cancel_button.pressed.connect(func() -> void: cancel_requested.emit())

func present(spell_name: String, quote: Dictionary, texture: Texture2D, targets: Array, reason: String,
		presentation: Dictionary = {}) -> void:
	inspection = quote.duplicate(true)
	targeting = presentation.get("targeting", {}).duplicate(true)
	accent = Color("#F2CE79") if targeting.get("team", "") == "ALLY" else Color("#BB84FF")
	rune.modulate = Color(accent, 0.6)
	title.text = spell_name
	title.add_theme_color_override("font_color", accent.lightened(0.3))
	# CG is distinct from the target/party portrait crop. Legacy texture stays fallback.
	var actor_id: String = str(presentation.get("actor_id", ""))
	var cg: Texture2D = AppearanceRegistry.cg_for(actor_id)
	artwork.texture = cg if cg != null else texture
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
