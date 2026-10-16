@tool
extends PanelContainer
const UI = preload("res://scripts/battle/ui/components/ui_elements.gd")
signal command_requested(kind: String, fields: Dictionary)
var reaction_column: VBoxContainer

func _ready() -> void:
	reaction_column = VBoxContainer.new()
	add_child(reaction_column)
	hide()

func render_window(window: Dictionary, choices: Array, names: Dictionary = {}) -> void:
	for child: Node in reaction_column.get_children():
		reaction_column.remove_child(child)
		child.queue_free()
	visible = window.get("status","") == "DRAFTING"
	if not visible: return
	UI.label(reaction_column,"BATTLE_REACTION",18)
	var scroller := ScrollContainer.new()
	scroller.custom_minimum_size.y = 110
	scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	reaction_column.add_child(scroller)
	var options := GridContainer.new()
	options.columns = 2
	options.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroller.add_child(options)
	for choice: Dictionary in choices:
		var item: Button = UI.button(options,choice["label"],func() -> void: command_requested.emit("QUEUE_REACTION",{"entry":choice["entry"]}))
		var actor_id: String = str(choice["entry"]["actor_id"])
		item.text = tr(str(names.get(actor_id,"BATTLE_HERO_"+actor_id)))+" · "+tr(choice["label"])
		if choice["entry"]["kind"] == "REACTION_SP_FIXTURE":
			var target_id: String = str(choice["entry"]["target_actor_id"])
			item.text += " → "+tr(str(names.get(target_id,"BATTLE_HERO_"+target_id)))
		item.add_theme_font_size_override("font_size",13)
		item.tooltip_text = choice.get("tooltip",item.text)
	var draft: Array = window.get("draft",[])
	if draft.is_empty(): UI.label(reaction_column,"BATTLE_QUEUE_EMPTY")
	for i: int in draft.size():
		var entry: Dictionary = draft[i]
		var row := HBoxContainer.new()
		reaction_column.add_child(row)
		var kind_key: String = "BATTLE_GUARD" if entry["kind"] == "BASIC_GUARD" else "BATTLE_PROTECT" if entry["kind"] == "BASIC_PROTECT" else "BATTLE_SPECIAL_REACTION"
		var summary: Label = UI.label(row,"",14)
		summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var actor_id: String = str(entry["actor_id"])
		summary.text = tr("BATTLE_REACTION_ORDER") % [i+1,tr(str(names.get(actor_id,"BATTLE_HERO_"+actor_id))),tr(kind_key)]
		UI.button(row,"BATTLE_REMOVE",func() -> void: command_requested.emit("REMOVE_REACTION",{"actor_id":entry["actor_id"]}))
		if i > 0:
			var order: Array = draft.map(func(d: Dictionary) -> String: return str(d["actor_id"]))
			var temp: Variant = order[i-1]
			order[i-1] = order[i]
			order[i] = temp
			UI.button(row,"BATTLE_UP",func() -> void: command_requested.emit("REORDER_REACTIONS",{"actor_order":order}))
	var actions := HBoxContainer.new()
	reaction_column.add_child(actions)
	UI.button(actions,"BATTLE_CONFIRM",func() -> void: command_requested.emit("CONFIRM_REACTIONS",{}))
	UI.button(actions,"BATTLE_PASS",func() -> void: command_requested.emit("PASS_REACTION",{}))
