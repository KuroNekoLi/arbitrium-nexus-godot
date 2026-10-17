extends PanelContainer
## Modal presentation. Data/quotes are supplied by the Domain preview.
signal choice_requested(combo: bool)
signal cancelled()
signal selection_changed()
const UI = preload("res://scripts/battle/ui/components/ui_elements.gd")
@export var title: Label
@export var setup_targets: OptionButton
@export var recipes: OptionButton
@export var normal_text: Label
@export var combo_text: Label
@export var normal_button: Button
@export var combo_button: Button
@export var cancel_button: Button
var portraits: Array[TextureRect] = []
var locked: bool = false

func _ready() -> void:
	portraits = [$VBoxContainer/HBoxContainer/TextureRect, $VBoxContainer/HBoxContainer/TextureRect2]
	setup_targets.item_selected.connect(func(_index: int) -> void: selection_changed.emit())
	recipes.item_selected.connect(func(_index: int) -> void: selection_changed.emit())
	cancel_button.pressed.connect(func() -> void: cancelled.emit())
	normal_button.pressed.connect(func() -> void: _choose(false))
	combo_button.pressed.connect(func() -> void: _choose(true))

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
