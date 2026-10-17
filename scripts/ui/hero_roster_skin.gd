@tool
class_name HeroRosterSkin
extends Resource
## Inspector-authored surfaces. Runtime selects states without mutating templates.

@export_group("Panel surfaces")
@export var normal: StyleBox:
	set(value):
		normal = value
		emit_changed()
@export var hover: StyleBox:
	set(value):
		hover = value
		emit_changed()
@export var selected: StyleBox:
	set(value):
		selected = value
		emit_changed()
@export var selected_hover: StyleBox:
	set(value):
		selected_hover = value
		emit_changed()
@export var focus: StyleBox:
	set(value):
		focus = value
		emit_changed()
@export var disabled: StyleBox:
	set(value):
		disabled = value
		emit_changed()
@export var combo: StyleBox:
	set(value):
		combo = value
		emit_changed()

@export_group("Portrait surfaces")
@export var portrait_normal: StyleBox:
	set(value):
		portrait_normal = value
		emit_changed()
@export var portrait_selected: StyleBox:
	set(value):
		portrait_selected = value
		emit_changed()

@export_group("Identity colors")
## Applies only to Flat surfaces; Texture surfaces always retain their artwork.
@export var tint_flat_surfaces_with_actor: bool = true:
	set(value):
		tint_flat_surfaces_with_actor = value
		emit_changed()
@export var use_actor_name_color: bool = true:
	set(value):
		use_actor_name_color = value
		emit_changed()
@export var name_color: Color = Color.WHITE:
	set(value):
		name_color = value
		emit_changed()
@export var selected_border_mix: Color = Color("#B59C6D"):
	set(value):
		selected_border_mix = value
		emit_changed()

@export_group("Status pills")
@export var status_surfaces: Dictionary[String, StyleBox] = {}:
	set(value):
		status_surfaces = value
		emit_changed()
@export var status_colors: Dictionary[String, Color] = {}:
	set(value):
		status_colors = value
		emit_changed()
@export var active_portrait_tint: Color = Color.WHITE:
	set(value):
		active_portrait_tint = value
		emit_changed()
@export var downed_portrait_tint: Color = Color(0.55, 0.5, 0.55):
	set(value):
		downed_portrait_tint = value
		emit_changed()
@export var retired_portrait_tint: Color = Color("646464"):
	set(value):
		retired_portrait_tint = value
		emit_changed()

@export_group("Combo indicators")
@export var combo_icons: Dictionary[String, Texture2D] = {}:
	set(value):
		combo_icons = value
		emit_changed()

func panel_surface(state: String, accent: Color) -> StyleBox:
	var template: StyleBox = get(state) as StyleBox
	if template == null or not tint_flat_surfaces_with_actor or not template is StyleBoxFlat or state in ["normal", "focus", "disabled", "combo"]:
		return template
	var result: StyleBoxFlat = template.duplicate() as StyleBoxFlat
	if state == "hover":
		result.border_color = accent.darkened(0.12)
		result.shadow_color = Color(accent, template.shadow_color.a)
	else:
		result.border_color = accent.lerp(selected_border_mix, 0.25)
		result.shadow_color = Color(accent, template.shadow_color.a)
	return result

func portrait_surface(is_selected: bool, accent: Color) -> StyleBox:
	var template: StyleBox = portrait_selected if is_selected else portrait_normal
	if template == null or not tint_flat_surfaces_with_actor or not template is StyleBoxFlat:
		return template
	var result: StyleBoxFlat = template.duplicate() as StyleBoxFlat
	result.border_color = accent if is_selected else accent.darkened(0.35)
	return result

func nested_resources() -> Array[Resource]:
	var items: Array[Resource] = []
	for value: Resource in [normal, hover, selected, selected_hover, focus, disabled, combo, portrait_normal, portrait_selected]:
		if value != null and not items.has(value):
			items.append(value)
	for value: StyleBox in status_surfaces.values():
		if value != null and not items.has(value):
			items.append(value)
	return items
