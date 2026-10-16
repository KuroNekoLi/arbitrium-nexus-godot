extends PanelContainer
## Modal presentation. Data/quotes are supplied by the Domain preview.
signal choice_requested(combo: bool)
signal cancelled()
signal selection_changed()
const UI = preload("res://scripts/battle/ui/components/ui_elements.gd")
var title: Label
var setup_targets: OptionButton
var recipes: OptionButton
var normal_text: Label
var combo_text: Label
var normal_button: Button
var combo_button: Button
var cancel_button: Button
var portraits: Array[TextureRect] = []
var locked: bool = false

func _ready() -> void:
	name = "ComboConfirmation"
	position = Vector2(286,120)
	size = Vector2(688,430)
	z_index = 112
	mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025,0.045,0.10,0.97)
	style.border_color = Color("cda75e")
	style.set_border_width_all(2)
	style.set_content_margin_all(18)
	style.set_corner_radius_all(10)
	add_theme_stylebox_override("panel",style)
	var column: VBoxContainer = UI.column(self)
	title = UI.label(column,"CP2_PREPARATION",24)
	var actors := HBoxContainer.new()
	column.add_child(actors)
	for i: int in 2:
		var portrait := TextureRect.new()
		portrait.custom_minimum_size = Vector2(58,64)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		actors.add_child(portrait)
		portraits.append(portrait)
	setup_targets = OptionButton.new()
	setup_targets.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actors.add_child(setup_targets)
	setup_targets.item_selected.connect(func(_index: int) -> void: selection_changed.emit())
	recipes = OptionButton.new()
	column.add_child(recipes)
	recipes.item_selected.connect(func(_index: int) -> void: selection_changed.emit())
	var comparisons := HBoxContainer.new()
	comparisons.add_theme_constant_override("separation",18)
	column.add_child(comparisons)
	for i: int in 2:
		var text: Label = UI.label(comparisons,"",16)
		text.custom_minimum_size = Vector2(310,200)
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if i == 0: normal_text = text
		else: combo_text = text
	combo_text.add_theme_color_override("font_color",Color("e1beff"))
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation",12)
	column.add_child(buttons)
	# Cancel first in the focus cycle: accidental Enter never consumes cards.
	cancel_button = UI.button(buttons,"BATTLE_CANCEL",func() -> void: cancelled.emit())
	normal_button = UI.button(buttons,"CP2_NORMAL",func() -> void: _choose(false))
	combo_button = UI.button(buttons,"CP2_COMMIT",func() -> void: _choose(true))
	for button: Button in [cancel_button,normal_button,combo_button]: button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hide()

func _choose(combo: bool) -> void:
	if locked: return
	locked = true
	normal_button.disabled = true
	combo_button.disabled = true
	choice_requested.emit(combo)

func render_comparison(data: Dictionary, normal: String, combo: String) -> void:
	locked = false
	normal_text.text = normal.replace("\\n","\n")
	combo_text.text = combo.replace("\\n","\n")
	normal_button.disabled = not bool(data["normal_accepted"])
	combo_button.disabled = not bool(data["combo_accepted"])

func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		cancelled.emit()
		accept_event()
