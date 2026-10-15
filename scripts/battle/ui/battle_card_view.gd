extends "res://addons/simple_cards/card/card.gd"
const Frame = preload("res://scripts/battle/ui/components/battle_card_frame.gd")
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
var _idle_style: StyleBoxFlat

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
	var style: StyleBoxFlat = Frame.outer_frame(appearance.accent, legal)
	_style = style
	_idle_style = style.duplicate() as StyleBoxFlat
	face.add_theme_stylebox_override("panel", style)
	face.pivot_offset = size * 0.5
	add_child(face)
	# Independent native Controls. Source data is never baked into card artwork.
	Frame.build(face, appearance, cost_text, legal, unavailable_reason)
	tooltip_text = tr(appearance.description_key) + ("\n" + unavailable_reason if not legal else "")
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
	_style.border_color = Color("ffe8a3") if selected_visual else Color("9beafc") if prominent else _idle_style.border_color
	_style.shadow_color = Color(0.56, 0.83, 1.0, 0.56) if selected_visual else Color(0.33, 0.70, 0.92, 0.42) if prominent else _idle_style.shadow_color
	_style.shadow_size = 9 if prominent else _idle_style.shadow_size
	hover_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
	hover_tween.tween_property(face, "position:y", lift, 0.14)
	hover_tween.tween_property(face, "scale", magnify, 0.14)

func _exit_tree() -> void:
	if hover_tween: hover_tween.kill()
	super._exit_tree()
