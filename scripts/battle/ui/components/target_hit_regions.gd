extends Control
signal target_requested(actor: String)
var target_buttons: Dictionary = {}

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

func set_targets(ids: Array) -> void:
	for id: String in target_buttons:
		var target: Button = target_buttons[id]
		target.mouse_filter = Control.MOUSE_FILTER_STOP if ids.has(id) else Control.MOUSE_FILTER_IGNORE
		target.focus_mode = Control.FOCUS_ALL if ids.has(id) else Control.FOCUS_NONE
		target.text = "◇" if ids.has(id) else ""

