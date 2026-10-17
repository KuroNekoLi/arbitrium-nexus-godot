@tool
class_name HeroRosterItem
extends Button

const RosterSkin = preload("res://scripts/ui/hero_roster_skin.gd")
const BattleTranslations = preload("res://scripts/battle/presentation/battle_translations.gd")
var _skin_resources: Array[Resource] = []
var _portrait_base_modulate: Color = Color.WHITE
var _subtitle_base_color: Color = Color.WHITE
@export var skin: RosterSkin = preload("res://resources/ui/hero_roster_skin.tres"):
	set(value):
		_disconnect_skin()
		skin = value
		if is_inside_tree():
			_watch_skin()
		if is_node_ready():
			_refresh_skin()

signal hero_selected(hero_id: String)

@onready var portrait: TextureRect = %Portrait
@onready var name_label: Label = %HeroName
@onready var hp_label: Label = %HeroHP
@onready var mana_label: Label = %HeroMana

var hero_id: String = ""
var accent: Color = Color.WHITE
@export var hp_bar: ProgressBar
@export var mana_bar: ProgressBar
## V3.5.1 presentation-only status surface. Populated exclusively by callers
## that read authoritative projection fields; this component never infers state.
@export var status_badges: HBoxContainer
var status_kind: String = ""
var combat_status: String = "ACTIVE"
var retired: bool = false
@export var retirement_mark: Label
var combo_strength: int = 0
## Presentation-only combo partner state: "", IDLE, ELIGIBLE, SELECTED, UNAVAILABLE.
## Callers derive it from the preparation controller; never from Domain mutation.
var combo_state: String = ""
@export var combo_mark: TextureRect
const COMBO_TOOLTIP_KEYS: Dictionary = {
	"IDLE": "CP2_POTENTIAL", "ELIGIBLE": "CP2_PARTNER",
	"SELECTED": "CP2_SELECTED", "UNAVAILABLE": "CP2_UNAVAILABLE",
}

func _ready() -> void:
	if not Engine.is_editor_hint():
		BattleTranslations.install()
	pressed.connect(_on_pressed)
	_portrait_base_modulate = portrait.modulate
	_subtitle_base_color = get_node("Layout/Stats/Subtitle").get_theme_color("font_color")
	_watch_skin()
	_refresh_skin()

func _enter_tree() -> void:
	if is_node_ready():
		_watch_skin()

func _exit_tree() -> void:
	_disconnect_skin()

func _disconnect_skin() -> void:
	for resource: Resource in _skin_resources:
		if resource.changed.is_connected(_on_skin_changed):
			resource.changed.disconnect(_on_skin_changed)
	_skin_resources.clear()

func _watch_skin() -> void:
	_disconnect_skin()
	if skin == null:
		return
	_skin_resources.append(skin)
	_skin_resources.append_array(skin.nested_resources())
	for resource: Resource in _skin_resources:
		resource.changed.connect(_on_skin_changed)

func _on_skin_changed() -> void:
	_watch_skin()
	if is_node_ready():
		_refresh_skin()

func _refresh_skin() -> void:
	if skin == null:
		return
	name_label.add_theme_color_override("font_color", accent if skin.use_actor_name_color else skin.name_color)
	set_status_kind(status_kind)
	set_combo_state(combo_state)

func set_combo_indicator(strength: int) -> void:
	set_combo_state("ELIGIBLE" if strength > 1 else "IDLE" if strength == 1 else "")

func set_combo_state(state: String) -> void:
	# Retired actors keep the retirement mark as the single visible authority.
	if retired or skin == null or not COMBO_TOOLTIP_KEYS.has(state) or not skin.combo_icons.has(state):
		state = ""
	elif combat_status != "ACTIVE" and state != "":
		# Incapacitated/Exhausted can never finish; never claim eligibility.
		state = "UNAVAILABLE" if skin.combo_icons.has("UNAVAILABLE") else ""
	combo_state = state
	combo_strength = 2 if state in ["ELIGIBLE", "SELECTED"] else 1 if state == "IDLE" else 0
	combo_mark.visible = not state.is_empty()
	if state.is_empty():
		combo_mark.texture = null
		combo_mark.tooltip_text = ""
	else:
		combo_mark.texture = skin.combo_icons[state]
		combo_mark.tooltip_text = tr(COMBO_TOOLTIP_KEYS[state])
	_apply_style()

func configure(id: String, display_name: String, portrait_texture: Texture2D, accent_color: Color) -> void:
	hero_id = id
	accent = accent_color
	name_label.text = display_name
	name_label.tooltip_text = display_name
	portrait.texture = portrait_texture
	_refresh_skin()

## Legacy interface retained; no persistent hand counter is rendered.
func update_status(hp: int, max_hp: int, mana: int, max_mana: int, _hand_count: int) -> void:
	_update_resources(hp, max_hp, mana, max_mana)

func update_projection(actor: Dictionary, state_text: String) -> void:
	combat_status = str(actor.get("status", "ACTIVE"))
	retired = bool(actor.get("retired_from_field", false))
	_update_resources(int(actor["hp"]), int(actor["max_hp"]), int(actor["mp"]), int(actor["max_mp"]))
	var subtitle: Label = get_node("Layout/Stats/Subtitle")
	subtitle.text = state_text
	subtitle.tooltip_text = state_text
	set_status_kind(str(actor.get("status", "")))

func _update_resources(hp: int, max_hp: int, mana: int, max_mana: int) -> void:
	hp_label.text = tr("BATTLE_HP") % [hp, max_hp]
	mana_label.text = tr("BATTLE_MP") % [mana, max_mana]
	hp_bar.max_value = maxf(1.0, float(max_hp))
	hp_bar.value = clampf(float(hp), 0.0, hp_bar.max_value)
	mana_bar.max_value = maxf(1.0, float(max_mana))
	mana_bar.value = clampf(float(mana), 0.0, mana_bar.max_value)
	hp_bar.tooltip_text = hp_label.text
	mana_bar.tooltip_text = mana_label.text

## Presentation-only status pill. Incapacitated is dimmed but the button stays
## enabled: viewing an ally never depends on that ally being able to act.
func set_status_kind(status: String) -> void:
	status_kind = status
	var subtitle: Label = get_node("Layout/Stats/Subtitle")
	if skin == null:
		_apply_retirement()
		return
	var style: StyleBox = skin.status_surfaces.get(status)
	if style == null:
		subtitle.remove_theme_stylebox_override("normal")
	else:
		subtitle.add_theme_stylebox_override("normal", style)
	subtitle.add_theme_color_override("font_color", skin.status_colors.get(status, _subtitle_base_color))
	portrait.modulate = _portrait_base_modulate * (skin.downed_portrait_tint if status == "INCAPACITATED" else skin.active_portrait_tint)
	_apply_retirement()

func _apply_retirement() -> void:
	if retirement_mark == null: return
	retirement_mark.visible = retired
	disabled = retired
	if retired:
		portrait.modulate = _portrait_base_modulate * (skin.retired_portrait_tint if skin != null else Color("646464"))

## badges: Array of {"id": String, "icon": Texture2D, "tooltip": String}.
## Callers must source each entry from a real projection field.
func set_status_badges(badges: Array) -> void:
	for old: Node in status_badges.get_children():
		status_badges.remove_child(old)
		old.queue_free()
	for badge: Dictionary in badges:
		var icon := TextureRect.new()
		icon.name = "Badge_" + str(badge.get("id", ""))
		icon.texture = badge.get("icon", null)
		icon.custom_minimum_size = Vector2(17, 17)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.tooltip_text = str(badge.get("tooltip", ""))
		# Tooltip lives on the Button; icons never intercept selection input.
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		status_badges.add_child(icon)

func badge_ids() -> Array:
	var ids: Array = []
	for child: Node in status_badges.get_children():
		if not child.is_queued_for_deletion():
			ids.append(str(child.name).trim_prefix("Badge_"))
	return ids

func set_selected(selected: bool) -> void:
	button_pressed = selected
	_apply_style()

func _on_pressed() -> void:
	if retired: return
	hero_selected.emit(hero_id)

func _apply_style() -> void:
	if not is_node_ready() or skin == null:
		return
	var portrait_frame := portrait.get_parent() as PanelContainer
	_set_surface(portrait_frame, "panel", skin.portrait_surface(button_pressed, accent))
	var combo_active: bool = combo_strength > 1 and combat_status == "ACTIVE" and not retired
	_set_surface(self, "normal", skin.panel_surface("combo" if combo_active and skin.combo != null else "selected" if button_pressed else "normal", accent))
	_set_surface(self, "hover", skin.panel_surface("selected_hover" if button_pressed else "hover", accent))
	_set_surface(self, "pressed", skin.panel_surface("combo" if combo_active and skin.combo != null else "selected", accent))
	_set_surface(self, "hover_pressed", skin.panel_surface("selected_hover", accent))
	_set_surface(self, "focus", skin.focus)
	_set_surface(self, "disabled", skin.disabled)

func _set_surface(control: Control, slot: String, style: StyleBox) -> void:
	if style == null:
		control.remove_theme_stylebox_override(slot)
	else:
		control.add_theme_stylebox_override(slot, style)
