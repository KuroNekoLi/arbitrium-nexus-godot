extends "res://addons/simple_cards/card/card.gd"
signal selection_requested(instance: String)
signal release_requested(instance: String, pointer: Vector2)
var instance_id: String = ""
var appearance: Resource
var cost_text: String = ""
var legal: bool = true
var unavailable_reason: String = ""
var face: PanelContainer
var home: Vector2
var home_rotation: float = 0.0
var home_scale: Vector2 = Vector2.ONE
var hover_tween: Tween
var selected_visual: bool = false
var _hover_visual: bool = false
var _style: StyleBoxFlat

func _card_ready() -> void:
	if _layout:
		_layout.hide()
	size = Vector2(164,218)
	custom_minimum_size = size
	center_pos = size * 0.5
	pivot_offset = center_pos
	self_modulate = Color.WHITE
	drag_threshold = 12
	face = PanelContainer.new()
	face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
	face.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_DISABLED
	var style := StyleBoxFlat.new()
	_style = style
	style.bg_color = Color("0b192b")
	style.border_color = appearance.accent if legal else Color("647180")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 9
	style.content_margin_right = 9
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	face.add_theme_stylebox_override("panel",style)
	face.pivot_offset = size * 0.5
	add_child(face)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",4)
	face.add_child(column)
	var cost := Label.new()
	cost.text = cost_text
	cost.add_theme_font_size_override("font_size",16)
	cost.add_theme_color_override("font_color",appearance.accent)
	column.add_child(cost)
	var art := TextureRect.new()
	art.texture = appearance.artwork
	art.custom_minimum_size = Vector2(0,70)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	column.add_child(art)
	var title := Label.new()
	title.text = tr(appearance.name_key)
	title.add_theme_font_size_override("font_size",17)
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	column.add_child(title)
	var desc := Label.new()
	desc.text = tr(appearance.description_key)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# Give wrapping a stable width before the first Container layout. Without
	# it, a one-pixel initial width can inflate the panel's minimum height.
	desc.custom_minimum_size.x = 144
	desc.max_lines_visible = 3 if legal else 2
	desc.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	desc.add_theme_font_size_override("font_size",13)
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(desc)
	if not legal:
		var reason := Label.new()
		reason.text = tr("BATTLE_UNAVAILABLE")
		reason.add_theme_font_size_override("font_size",13)
		column.add_child(reason)
	tooltip_text = tr(appearance.description_key) + ("\n"+unavailable_reason if not legal else "")
	card_clicked.connect(func(_card: Card) -> void: selection_requested.emit(instance_id))
	drag_started.connect(func(_card: Card) -> void: z_index = 90)
	drag_ended.connect(func(_card: Card) -> void:
		release_requested.emit(instance_id,get_global_mouse_position())
		_restore_home.call_deferred()
		_apply_visual_state())
	card_hovered.connect(_hover.bind(true))
	card_unhovered.connect(_hover.bind(false))
	card_focused.connect(_hover.bind(true))
	card_unfocused.connect(_hover.bind(false))

func _restore_home() -> void:
	if not is_inside_tree(): return
	# The addon restores an unowned card to zero rotation after drag_ended.
	# Apply our presentation-only arc pose after its release handler completes.
	tween_position(home,0.18)
	tween_rotation(rad_to_deg(home_rotation),0.18)
	tween_scale(home_scale,0.18)

## UI-only selection/focus: raise the FACE rather than moving the Card hit rect.
## SimpleCards still owns drag, focus and click. Selected state persists across redraw.
func set_selected_visual(active: bool) -> void:
	selected_visual = active
	_apply_visual_state()

func _hover(active: bool) -> void:
	_hover_visual = active
	if holding or not is_instance_valid(face):
		return
	_apply_visual_state()

func _apply_visual_state() -> void:
	if not is_instance_valid(face):
		return
	if hover_tween:
		hover_tween.kill()
	var prominent: bool = selected_visual or _hover_visual or focused or hovered
	if holding:
		z_index = 90
	else:
		z_index = 65 if selected_visual else 55 if prominent else 0
	var lift: float = -38.0 if selected_visual else -31.0 if prominent else 0.0
	var magnify: Vector2 = Vector2.ONE * (1.055 if selected_visual else 1.035 if prominent else 1.0)
	_style.set_border_width_all(3 if prominent else 2)
	_style.border_color = Color("ffe8a3") if selected_visual else Color("9beafc") if prominent else appearance.accent if legal else Color("647180")
	_style.shadow_color = Color(0.56, 0.83, 1.0, 0.56) if selected_visual else Color(0.33, 0.70, 0.92, 0.42) if prominent else Color.TRANSPARENT
	_style.shadow_size = 9 if prominent else 0
	hover_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
	hover_tween.tween_property(face, "position:y", lift, 0.14)
	hover_tween.tween_property(face, "scale", magnify, 0.14)

func _exit_tree() -> void:
	if hover_tween: hover_tween.kill()
	super._exit_tree()
