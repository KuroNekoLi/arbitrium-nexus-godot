@tool
extends Control
signal target_requested(actor: String)
var target_buttons: Dictionary = {}
var basic_choices: HBoxContainer

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for entry: Array in [["Boss", Rect2(722,125,250,335)], ["A", Rect2(380,285,105,175)], ["B", Rect2(485,249,55,173)], ["C", Rect2(540,225,75,164)]]:
		var target := Button.new()
		target.name = "Target" + entry[0]
		target.position = entry[1].position
		target.size = entry[1].size
		target.flat = true
		target.mouse_filter = Control.MOUSE_FILTER_IGNORE
		target.focus_mode = Control.FOCUS_NONE
		target.tooltip_text = tr("BATTLE_TITLE" if entry[0] == "Boss" else "BATTLE_HERO_" + entry[0])
		target.pressed.connect(func() -> void: target_requested.emit(entry[0]))
		add_child(target)
		target_buttons[entry[0]] = target
	basic_choices = HBoxContainer.new()
	basic_choices.name = "BasicAttackTargets"
	basic_choices.position = Vector2(660, 393)
	basic_choices.size = Vector2(310, 43)
	basic_choices.mouse_filter = Control.MOUSE_FILTER_IGNORE
	basic_choices.hide()
	add_child(basic_choices)

func set_targets(ids: Array) -> void:
	for id: String in target_buttons:
		var target: Button = target_buttons[id]
		target.mouse_filter = Control.MOUSE_FILTER_STOP if ids.has(id) else Control.MOUSE_FILTER_IGNORE
		target.focus_mode = Control.FOCUS_ALL if ids.has(id) else Control.FOCUS_NONE
		target.text = "◇" if ids.has(id) else ""

func set_basic_target_choices(ids: Array, selected_id: String, labels: Dictionary) -> void:
	for child: Node in basic_choices.get_children():
		basic_choices.remove_child(child)
		child.queue_free()
	basic_choices.visible = ids.size() > 1
	if not basic_choices.visible:
		return
	for id: String in ids:
		var choice := Button.new()
		choice.name = "Choice" + id
		choice.text = ("◆ " if id == selected_id else "◇ ") + str(labels.get(id, id))
		choice.tooltip_text = str(labels.get(id, id))
		choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		choice.focus_mode = Control.FOCUS_ALL
		choice.pressed.connect(func() -> void: target_requested.emit(id))
		basic_choices.add_child(choice)
		if target_buttons.has(id):
			target_buttons[id].text = "◆" if id == selected_id else "◇"
