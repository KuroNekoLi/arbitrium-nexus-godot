extends "res://addons/simple_cards/card/card.gd"
const Frame = preload("res://scripts/battle/ui/components/battle_card_frame.gd")
signal selection_requested(instance: String)
signal release_requested(instance: String, pointer: Vector2)
signal drag_requested(instance: String)
signal chant_held(instance: String, full: bool)
const FULL_CHANT_HOLD_SECONDS: float = 0.45
var can_full_chant: bool = false
var full_chant_held: bool = false
var _press_seconds: float = 0.0
var chant_hint: Label
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
var combo_eligible: bool = false
## Presentation-only overlay state: "", ELIGIBLE, SELECTED, UNAVAILABLE.
var combo_state: String = ""
var combo_reduced_motion: bool = false
var combo_layer: Control
var combo_frame: TextureRect
var combo_badge: Label
var combo_pulse: Tween
const COMBO_FRAME_TEXTURES: Dictionary = {
	"ELIGIBLE": preload("res://assets/ui/combo/combo_card_eligible.png"),
	"SELECTED": preload("res://assets/ui/combo/combo_card_selected.png"),
	"UNAVAILABLE": preload("res://assets/ui/combo/combo_card_unavailable.png"),
}
## Localized non-colour cue; the glyph shape also differs per state.
const COMBO_BADGE: Dictionary = {
	"ELIGIBLE": ["◇ ", "CP2_ELIGIBLE", "caa0f2"],
	"SELECTED": ["◆ ", "CP2_SELECTED", "ffe2a1"],
	"UNAVAILABLE": ["", "CP2_UNAVAILABLE", "a99bb8"],
}
const COMBO_ALPHA_LOW: float = 0.35
const COMBO_ALPHA_HIGH: float = 0.55
const COMBO_ALPHA_STATIC: float = 0.45
const COMBO_PULSE_PERIOD: float = 1.5
var _release_pointer: Vector2
var _has_release_pointer: bool = false
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
	_build_combo_overlay(style)
	chant_hint = Label.new()
	chant_hint.name = "HoldChantHint"
	chant_hint.text = tr("BATTLE_FULL")
	chant_hint.add_theme_font_size_override("font_size", 13)
	chant_hint.add_theme_color_override("font_color", Color("#E1BEFF"))
	chant_hint.add_theme_color_override("font_outline_color", Color("#091321"))
	chant_hint.add_theme_constant_override("outline_size", 5)
	chant_hint.position = Vector2(10, 35)
	chant_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chant_hint.hide()
	face.add_child(chant_hint)
	tooltip_text = tr(appearance.description_key) + ("\n" + unavailable_reason if not legal else "")
	card_clicked.connect(func(_card: Card) -> void: selection_requested.emit(instance_id))
	drag_started.connect(func(_card: Card) -> void:
		z_index = 90
		# Keep the card Control alive for SimpleCards input/release bookkeeping,
		# but hide its entire face while the targeting arrow is being aimed.
		face.hide()
		drag_requested.emit(instance_id))
	drag_ended.connect(func(_card: Card) -> void:
		release_requested.emit(instance_id,_release_pointer if _has_release_pointer else get_global_mouse_position())
		_restore_home.call_deferred()
		_apply_visual_state())
	card_hovered.connect(_hover.bind(true))
	card_unhovered.connect(_hover.bind(false))
	card_focused.connect(_hover.bind(true))
	card_unfocused.connect(_hover.bind(false))

func _on_button_down() -> void:
	_has_release_pointer = false
	_press_seconds = 0.0
	full_chant_held = false
	super._on_button_down()

func _input(event: InputEvent) -> void:
	# The release event owns the drop coordinate. Polling the OS cursor inside
	# a later signal can observe a subsequent motion (especially on Windows).
	# SimpleCards remains the only owner of press/drag/release state.
	if holding and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_release_pointer = get_canvas_transform().affine_inverse()*event.position
		_has_release_pointer = true

func _process(delta: float) -> void:
	super._process(delta)
	if not _released and can_full_chant and not full_chant_held:
		_press_seconds += delta
		if _press_seconds >= FULL_CHANT_HOLD_SECONDS:
			full_chant_held = true
			chant_hint.show()
			chant_held.emit(instance_id, true)

func _on_button_up() -> void:
	# drag_ended consumers capture FULL before the held gesture is cleared.
	super._on_button_up()
	full_chant_held = false
	_press_seconds = 0.0
	chant_hint.hide()
	chant_held.emit(instance_id, false)

func _restore_home() -> void:
	if not is_inside_tree(): return
	# The addon restores an unowned card to zero rotation after drag_ended.
	# Apply our presentation-only arc pose after its release handler completes.
	face.show()
	tween_position(home,0.18)
	tween_rotation(rad_to_deg(home_rotation),0.18)
	tween_scale(home_scale,0.18)

## UI-only selection/focus: raise the FACE rather than moving the Card hit rect.
## SimpleCards still owns drag, focus and click. Selected state persists across redraw.
func set_selected_visual(active: bool) -> void:
	selected_visual = active
	_apply_visual_state()

## Legacy boolean API retained for existing callers/tests.
func set_combo_eligible(active: bool) -> void:
	set_combo_state("ELIGIBLE" if active else "", combo_reduced_motion)

func _build_combo_overlay(style: StyleBoxFlat) -> void:
	# The face is a PanelContainer: the holder receives its content rect, and
	# the frame is pushed back out by the content margins to the card edge.
	# The candidate PNG is 2x (328x436) with a 12px safe border => 6px here,
	# inside the 9/7px content margin, so name, cost and artwork stay clear.
	combo_layer = Control.new()
	combo_layer.name = "ComboFrameLayer"
	combo_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face.add_child(combo_layer)
	combo_frame = TextureRect.new()
	combo_frame.name = "ComboFrameOverlay"
	combo_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	combo_frame.stretch_mode = TextureRect.STRETCH_SCALE
	combo_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	combo_frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	combo_frame.offset_left = -style.content_margin_left
	combo_frame.offset_top = -style.content_margin_top
	combo_frame.offset_right = style.content_margin_right
	combo_frame.offset_bottom = style.content_margin_bottom
	combo_layer.add_child(combo_frame)
	combo_badge = Label.new()
	combo_badge.name = "ComboStateBadge"
	combo_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	combo_badge.add_theme_font_size_override("font_size", 12)
	combo_badge.add_theme_color_override("font_outline_color", Color("#091321"))
	combo_badge.add_theme_constant_override("outline_size", 4)
	var pill := StyleBoxFlat.new()
	pill.bg_color = Color(0.05, 0.03, 0.11, 0.88)
	pill.set_corner_radius_all(7)
	pill.content_margin_left = 6
	pill.content_margin_right = 6
	pill.content_margin_top = 1
	pill.content_margin_bottom = 1
	combo_badge.add_theme_stylebox_override("normal", pill)
	# Sits above the card's top edge: never over the name, cost or artwork.
	combo_badge.anchor_left = 0.5
	combo_badge.anchor_right = 0.5
	combo_badge.grow_horizontal = Control.GROW_DIRECTION_BOTH
	combo_badge.offset_top = -style.content_margin_top - 22
	combo_badge.offset_bottom = -style.content_margin_top - 4
	combo_layer.add_child(combo_badge)
	_apply_combo_state()

func set_combo_state(state: String, reduced: bool = false) -> void:
	if not COMBO_FRAME_TEXTURES.has(state): state = ""
	var changed: bool = state != combo_state or reduced != combo_reduced_motion
	combo_state = state
	combo_reduced_motion = reduced
	combo_eligible = state in ["ELIGIBLE", "SELECTED"]
	if changed: _apply_combo_state()
	_apply_visual_state()

func _apply_combo_state() -> void:
	if combo_frame == null: return
	if combo_pulse: combo_pulse.kill()
	combo_pulse = null
	var visible_state: bool = not combo_state.is_empty()
	combo_frame.visible = visible_state
	combo_badge.visible = visible_state
	if not visible_state:
		combo_frame.texture = null
		return
	combo_frame.texture = COMBO_FRAME_TEXTURES[combo_state]
	var badge: Array = COMBO_BADGE[combo_state]
	combo_badge.text = str(badge[0]) + tr(str(badge[1]))
	combo_badge.add_theme_color_override("font_color", Color(str(badge[2])))
	# Reduced motion and UNAVAILABLE: fixed alpha, no scale/shake/offset.
	if combo_reduced_motion or combo_state == "UNAVAILABLE":
		combo_frame.modulate.a = COMBO_ALPHA_STATIC
		return
	combo_frame.modulate.a = COMBO_ALPHA_LOW
	combo_pulse = create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	combo_pulse.tween_property(combo_frame, "modulate:a", COMBO_ALPHA_HIGH, COMBO_PULSE_PERIOD * 0.5)
	combo_pulse.tween_property(combo_frame, "modulate:a", COMBO_ALPHA_LOW, COMBO_PULSE_PERIOD * 0.5)

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
	# Combo state is carried by the texture overlay; the native border keeps
	# the hover/focus/selection ring so combo visuals never override it.
	hover_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
	hover_tween.tween_property(face, "position:y", lift, 0.14)
	hover_tween.tween_property(face, "scale", magnify, 0.14)

func _exit_tree() -> void:
	if hover_tween: hover_tween.kill()
	if combo_pulse: combo_pulse.kill()
	super._exit_tree()
