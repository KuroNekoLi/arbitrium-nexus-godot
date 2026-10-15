extends Control
const UI = preload("res://scripts/battle/ui/components/ui_elements.gd")
const CardView = preload("res://scripts/battle/ui/battle_card_view.gd")
const HandArc = preload("res://addons/simple_cards/shape/premade_shapes/arc_shape.gd")
signal card_requested(instance: String)
signal card_released(instance: String, pointer: Vector2)
var card_views: Array[Control] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func render_cards(cards: Array) -> void:
	var prior_positions: Dictionary = {}
	for old: Control in card_views:
		prior_positions[old.instance_id] = old.position
	for old: Node in get_children():
		remove_child(old)
		old.queue_free()
	card_views.clear()
	var step: float = minf(174, (size.x - 164) / maxf(1, cards.size() - 1))
	var total: float = 164 + step * maxi(0, cards.size() - 1)
	for i: int in cards.size():
		var data: Dictionary = cards[i]
		var card: Control = CardView.new()
		card.instance_id = data["instance_id"]
		card.appearance = data["appearance"]
		card.cost_text = data["cost"]
		card.legal = data["legal"]
		card.unavailable_reason = data["reason"]
		card.position = Vector2((size.x - total) * 0.5 + i * step, 0)
		card.home = card.position
		add_child(card)
		card.selection_requested.connect(func(id: String) -> void: card_requested.emit(id))
		card.release_requested.connect(func(id: String, point: Vector2) -> void: card_released.emit(id, point))
		card_views.append(card)
	_arrange_hand()
	for card: Control in card_views:
		if prior_positions.has(card.instance_id):
			card.position = prior_positions[card.instance_id]
			card.tween_position(card.home, 0.18)
	if cards.is_empty():
		UI.label(self, "BATTLE_EMPTY", 18)

func _arrange_hand() -> void:
	if card_views.is_empty():
		return
	var visual_cards: Array[Card] = []
	for card: Control in card_views:
		visual_cards.append(card)
	var shape: ContainerShape = HandArc.new(4000.0, 8.0, 270.0, minf(174.0, 500.0 / maxf(1, card_views.size() - 1)))
	var layout: ContainerShape.LayoutResult = shape.compute_layout(visual_cards)
	var bounds: Rect2 = shape.get_layout_bounds(visual_cards, layout)
	var fit: float = minf(1.0, minf((size.x - 8) / bounds.size.x, (size.y - 8) / bounds.size.y))
	var offset: Vector2 = (size - bounds.size * fit) * 0.5 - bounds.position * fit
	for i: int in card_views.size():
		var card: Control = card_views[i]
		card.position = offset + layout.positions[i] * fit - card.pivot_offset
		card.home = card.position
		card.rotation = layout.rotations[i]
		card.home_rotation = card.rotation
		card.scale = Vector2.ONE * fit
		card.home_scale = card.scale

