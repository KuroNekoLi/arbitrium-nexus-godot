extends Control
## Display-only hand fan; owns hover/selection appearance but never Domain state.
const CardView = preload("res://scripts/battle/ui/battle_card_view.gd")
const HandArc = preload("res://addons/simple_cards/shape/premade_shapes/arc_shape.gd")
signal card_requested(instance: String)
signal card_released(instance: String, pointer: Vector2)
signal chant_held(instance: String, full: bool)

var card_views: Array[Control] = []
var selected_instance: String = ""
var empty_state: Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	empty_state = Label.new()
	empty_state.name = "EmptyState"
	empty_state.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	empty_state.mouse_filter = Control.MOUSE_FILTER_IGNORE
	empty_state.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_state.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	empty_state.autowrap_mode = TextServer.AUTOWRAP_OFF
	empty_state.add_theme_font_size_override("font_size", 18)
	empty_state.text = tr("BATTLE_EMPTY")
	empty_state.visible = false
	add_child(empty_state)

func render_cards(cards: Array) -> void:
	var prior_positions: Dictionary = {}
	for old: Control in card_views:
		prior_positions[old.instance_id] = old.position
		remove_child(old)
		old.queue_free()
	card_views.clear() # In-place: the BattleHUD facade holds this exact Array.
	empty_state.text = tr("BATTLE_EMPTY")
	empty_state.visible = cards.is_empty()
	for data: Dictionary in cards:
		var card: Control = CardView.new()
		card.instance_id = str(data["instance_id"])
		card.appearance = data["appearance"]
		card.cost_text = str(data["cost"])
		card.legal = bool(data["legal"])
		card.can_full_chant = bool(data.get("can_full_chant", false))
		card.unavailable_reason = str(data["reason"])
		add_child(card)
		card.selection_requested.connect(func(id: String) -> void: card_requested.emit(id))
		card.release_requested.connect(func(id: String, point: Vector2) -> void: card_released.emit(id, point))
		card.chant_held.connect(func(id: String, full: bool) -> void: chant_held.emit(id, full))
		card_views.append(card)
	_arrange_hand()
	# Keep the real selection ID, even though legacy HUD still rebuilds its cards.
	set_selected_instance(selected_instance)
	for card: Control in card_views:
		if prior_positions.has(card.instance_id):
			card.position = prior_positions[card.instance_id]
			card.tween_position(card.home, 0.18)

func set_selected_instance(instance: String) -> void:
	selected_instance = instance
	var found := instance.is_empty()
	for card: Control in card_views:
		var is_selected: bool = not instance.is_empty() and card.instance_id == instance
		card.set_selected_visual(is_selected)
		found = found or is_selected
	if not found:
		selected_instance = "" # Never highlight a card not owned by this hand.

func _arrange_hand() -> void:
	if card_views.is_empty():
		return
	var visual_cards: Array[Card] = []
	for card: Control in card_views:
		visual_cards.append(card)
	# More pronounced fan than the former radius=4000, arc=8 (nearly flat).
	# For 8 cards, slots stay exposed; hover/focus raises the full card above siblings.
	var spacing: float = minf(174.0, (size.x - 164.0 - 22.0) / maxf(1.0, float(card_views.size() - 1)))
	var shape: ContainerShape = HandArc.new(1050.0, 32.0, 270.0, spacing)
	var layout: ContainerShape.LayoutResult = shape.compute_layout(visual_cards)
	var bounds: Rect2 = shape.get_layout_bounds(visual_cards, layout)
	var fit: float = minf(1.0, minf((size.x - 24.0) / bounds.size.x, (size.y - 16.0) / bounds.size.y))
	var offset: Vector2 = (size - bounds.size * fit) * 0.5 - bounds.position * fit
	for i: int in card_views.size():
		var card: Control = card_views[i]
		var home_pos: Vector2 = offset + layout.positions[i] * fit - card.pivot_offset
		# Some old suites check the unrotated Control rect, too.
		home_pos.x = clampf(home_pos.x, 0.0, size.x - card.size.x)
		home_pos.y = clampf(home_pos.y, 0.0, size.y - card.size.y)
		card.position = home_pos
		card.home = home_pos
		card.rotation = layout.rotations[i]
		card.home_rotation = card.rotation
		card.scale = Vector2.ONE * fit
		card.home_scale = card.scale
