extends Control
signal actor_requested(actor: String)
signal card_requested(instance: String)
signal card_released(instance: String, pointer: Vector2)
signal command_requested(kind: String, fields: Dictionary)
signal target_requested(actor: String)
signal confirm_requested()
signal cancel_requested()
signal locale_requested(locale: String)
const Roster = preload("res://scenes/ui/hero_roster_item.tscn")
const CardView = preload("res://scripts/battle/ui/battle_card_view.gd")
const Portraits: Texture2D = preload("res://assets/portraits/party_portraits.png")
var card_views: Array[Control] = []
var roster: Dictionary = {}
var hand: Control
var end_button: Button
var details: Label
var feedback: Label
var header: Label
var resources: Label
var boss_stats: Label
var intent: Label
var reaction_panel: PanelContainer
var reaction_column: VBoxContainer
var confirm_button: Button
var mode: OptionButton
var combo: CheckButton
var log_label: Label
var target_buttons: Dictionary = {}
var vm: Dictionary = {}
var selected: String = "A"

func _ready() -> void:
	theme = preload("res://resources/ui/battle_theme.tres")
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()

func box(parent: Node, rect: Rect2, node_name: String) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.name = node_name
	panel.position = rect.position
	panel.size = rect.size
	parent.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",6)
	panel.add_child(column)
	return column

func label(parent: Node, key: String, font_size: int = 16) -> Label:
	var item := Label.new()
	item.text = tr(key)
	item.add_theme_font_size_override("font_size",font_size)
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(item)
	return item

func button(parent: Node, key: String, callback: Callable) -> Button:
	var item := Button.new()
	item.text = tr(key)
	item.pressed.connect(callback)
	parent.add_child(item)
	return item

func _build() -> void:
	var top: VBoxContainer = box(self,Rect2(16,12,1248,64),"TopBar")
	var row := HBoxContainer.new()
	top.add_child(row)
	header = label(row,"BATTLE_TITLE",23)
	header.autowrap_mode = TextServer.AUTOWRAP_OFF
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resources = label(row,"",21)
	resources.autowrap_mode = TextServer.AUTOWRAP_OFF
	button(row,"EN",func() -> void: locale_requested.emit("en"))
	button(row,"繁中",func() -> void: locale_requested.emit("zh_TW"))
	button(row,"BATTLE_SAVE",func() -> void: command_requested.emit("SAVE_REPLAY",{}))
	var party := VBoxContainer.new()
	party.position = Vector2(16,92)
	party.size = Vector2(260,318)
	party.add_theme_constant_override("separation",9)
	add_child(party)
	for i: int in 3:
		var actor: String = ["A","B","C"][i]
		var view: Button = Roster.instantiate()
		view.custom_minimum_size = Vector2(260,100)
		party.add_child(view)
		view.get_node("Layout/Stats").add_theme_constant_override("separation",0)
		var portrait := AtlasTexture.new()
		portrait.atlas = Portraits
		portrait.region = Rect2(i*724,0,724,724)
		view.configure(actor,tr("BATTLE_HERO_"+actor),portrait,[Color("efc675"),Color("75d6ff"),Color("df9cff")][i])
		view.hero_selected.connect(func(id: String) -> void: actor_requested.emit(id))
		roster[actor] = view
	var commands: VBoxContainer = box(self,Rect2(16,425,260,269),"Commands")
	button(commands,"BATTLE_BASIC",func() -> void: command_requested.emit("BASIC_ATTACK_RESOURCE_ONLY",{}))
	var utility := HBoxContainer.new()
	commands.add_child(utility)
	button(utility,"BATTLE_ANALYZE",func() -> void: command_requested.emit("UNIMPLEMENTED",{}))
	button(utility,"BATTLE_ITEM",func() -> void: command_requested.emit("UNIMPLEMENTED",{}))
	button(commands,"BATTLE_SWAP",func() -> void: command_requested.emit("FREE_SWAP",{}))
	button(commands,"BATTLE_LAST",func() -> void: command_requested.emit("ACTIVATE_LAST_SPELL_M4",{}))
	end_button = button(commands,"BATTLE_END",func() -> void: command_requested.emit("END_PLAYER_PHASE",{}))
	label(commands,"BATTLE_PROTOTYPE",12)
	var enemy: VBoxContainer = box(self,Rect2(984,92,280,235),"EnemyStatus")
	label(enemy,"BATTLE_TITLE",20)
	boss_stats = label(enemy,"",17)
	label(enemy,"BATTLE_INTENT",14).add_theme_color_override("font_color",Color("ffb1bf"))
	intent = label(enemy,"",16)
	label(enemy,"BATTLE_PROTECTABLE",13)
	var context: VBoxContainer = box(self,Rect2(984,350,280,348),"Context")
	label(context,"BATTLE_DETAILS",14)
	details = label(context,"BATTLE_SELECT",16)
	details.custom_minimum_size.y = 84
	mode = OptionButton.new()
	mode.add_item(tr("BATTLE_CHANTLESS"))
	mode.add_item(tr("BATTLE_FULL"))
	mode.visible = false
	context.add_child(mode)
	mode.item_selected.connect(func(_i: int) -> void: command_requested.emit("REFRESH_PREVIEW",{}))
	combo = CheckButton.new()
	combo.text = tr("BATTLE_COMBO")
	combo.visible = false
	context.add_child(combo)
	combo.toggled.connect(func(_on: bool) -> void: command_requested.emit("REFRESH_PREVIEW",{}))
	var confirm_row := HBoxContainer.new()
	context.add_child(confirm_row)
	confirm_button = button(confirm_row,"BATTLE_CONFIRM",func() -> void: confirm_requested.emit())
	button(confirm_row,"BATTLE_CANCEL",func() -> void: cancel_requested.emit())
	feedback = label(context,"",14)
	feedback.add_theme_color_override("font_color",Color("ffd18d"))
	log_label = label(context,"BATTLE_LOG",12)
	log_label.max_lines_visible = 3
	hand = Control.new()
	hand.name = "HandView"
	hand.position = Vector2(292,480)
	hand.size = Vector2(680,224)
	hand.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hand)
	for entry: Array in [["Boss",Rect2(722,125,250,335)],["A",Rect2(380,285,105,175)],["B",Rect2(485,249,55,173)],["C",Rect2(540,225,75,164)]]:
		var target := Button.new()
		target.name = "Target"+entry[0]
		target.position = entry[1].position
		target.size = entry[1].size
		target.flat = true
		target.mouse_filter = Control.MOUSE_FILTER_IGNORE
		target.focus_mode = Control.FOCUS_NONE
		target.tooltip_text = tr("BATTLE_TITLE" if entry[0] == "Boss" else "BATTLE_HERO_"+entry[0])
		target.pressed.connect(func() -> void: target_requested.emit(entry[0]))
		add_child(target)
		target_buttons[entry[0]] = target
	reaction_panel = PanelContainer.new()
	reaction_panel.name = "ReactionQueue"
	reaction_panel.position = Vector2(300,154)
	reaction_panel.size = Vector2(665,305)
	reaction_panel.z_index = 100
	add_child(reaction_panel)
	reaction_column = VBoxContainer.new()
	reaction_panel.add_child(reaction_column)
	reaction_panel.hide()

func render(projection: Dictionary, actor: String, cards: Array, reaction_choices: Array) -> void:
	vm = projection
	selected = actor
	header.text = tr("BATTLE_PHASE_"+vm["phase"]) + "   ·   " + tr("BATTLE_ROUND") % vm["round"]
	resources.text = tr("BATTLE_RESOURCES") % [vm["resources"]["current_ap"],vm["resources"]["rp"]]
	for id: String in roster:
		var status_key: String = "BATTLE_"+str(vm["actors"][id]["status"])
		roster[id].configure(id,tr("BATTLE_HERO_"+id),roster[id].portrait.texture,roster[id].accent)
		roster[id].update_projection(vm["actors"][id],tr(status_key))
		roster[id].set_selected(id == actor)
	var boss: Dictionary = vm["actors"]["Boss"]
	boss_stats.text = tr("BATTLE_HP") % [boss["hp"],boss["max_hp"]]
	if not vm["tactical"].is_empty():
		boss_stats.text += "\n"+tr("BATTLE_BREAK") % [vm["tactical"]["break_gauge"],vm["tactical"]["break_max"]]
		if vm["tactical"]["break_locked"]: boss_stats.text += "\n"+tr("BATTLE_BREAK_LOCKED")
		if not vm["tactical"]["exposed"].is_empty(): boss_stats.text += "\n"+tr("BATTLE_EXPOSED")
	if not vm["intent"].is_empty():
		var announced: Dictionary = vm["intent"][0]
		var target: String = str(announced["target_ids"][0])
		intent.text = tr("BATTLE_INTENT_DETAIL") % [tr("BATTLE_"+str(announced["skill_id"]).to_upper()),tr("BATTLE_HERO_"+target),announced["hit_count"]]
	end_button.text = tr("BATTLE_END")
	end_button.disabled = vm["phase"] != "PLAYER_PHASE" or vm["outcome"] != "ONGOING"
	for old: Node in hand.get_children():
		hand.remove_child(old)
		old.queue_free()
	card_views.clear()
	var step: float = minf(174, (hand.size.x-164) / maxf(1,cards.size()-1))
	var total: float = 164 + step * maxi(0,cards.size()-1)
	for i: int in cards.size():
		var data: Dictionary = cards[i]
		var card: Control = CardView.new()
		card.instance_id = data["instance_id"]
		card.appearance = data["appearance"]
		card.cost_text = data["cost"]
		card.legal = data["legal"]
		card.unavailable_reason = data["reason"]
		card.position = Vector2((hand.size.x-total)*0.5 + i*step,0)
		card.home = card.position
		hand.add_child(card)
		card.selection_requested.connect(func(id: String) -> void: card_requested.emit(id))
		card.release_requested.connect(func(id: String, point: Vector2) -> void: card_released.emit(id,point))
		card_views.append(card)
	if cards.is_empty(): label(hand,"BATTLE_EMPTY",18)
	_render_reaction(reaction_choices)

func _render_reaction(choices: Array) -> void:
	for child: Node in reaction_column.get_children():
		reaction_column.remove_child(child)
		child.queue_free()
	var window: Dictionary = vm["reaction"]
	reaction_panel.visible = window.get("status","") == "DRAFTING"
	if not reaction_panel.visible: return
	label(reaction_column,"BATTLE_REACTION",18)
	var options := HBoxContainer.new()
	reaction_column.add_child(options)
	for choice: Dictionary in choices:
		var item: Button = button(options,choice["label"],func() -> void: command_requested.emit("QUEUE_REACTION",{"entry":choice["entry"]}))
		item.text = tr("BATTLE_HERO_"+str(choice["entry"]["actor_id"]))+" · "+tr(choice["label"])
		item.add_theme_font_size_override("font_size",13)
	var draft: Array = window.get("draft",[])
	if draft.is_empty(): label(reaction_column,"BATTLE_QUEUE_EMPTY")
	for i: int in draft.size():
		var entry: Dictionary = draft[i]
		var row := HBoxContainer.new()
		reaction_column.add_child(row)
		label(row,"",14).text = tr("BATTLE_REACTION_ORDER") % [i+1,tr("BATTLE_HERO_"+str(entry["actor_id"])),tr("BATTLE_GUARD" if entry["kind"] == "BASIC_GUARD" else "BATTLE_PROTECT")]
		button(row,"BATTLE_REMOVE",func() -> void: command_requested.emit("REMOVE_REACTION",{"actor_id":entry["actor_id"]}))
		if i > 0:
			var order: Array = draft.map(func(d: Dictionary) -> String: return str(d["actor_id"]))
			var temp: Variant = order[i-1]
			order[i-1] = order[i]
			order[i] = temp
			button(row,"BATTLE_UP",func() -> void: command_requested.emit("REORDER_REACTIONS",{"actor_order":order}))
	var actions := HBoxContainer.new()
	reaction_column.add_child(actions)
	button(actions,"BATTLE_CONFIRM",func() -> void: command_requested.emit("CONFIRM_REACTIONS",{}))
	button(actions,"BATTLE_PASS",func() -> void: command_requested.emit("PASS_REACTION",{}))

func set_targets(ids: Array) -> void:
	for id: String in target_buttons:
		var target: Button = target_buttons[id]
		target.mouse_filter = Control.MOUSE_FILTER_STOP if ids.has(id) else Control.MOUSE_FILTER_IGNORE
		target.focus_mode = Control.FOCUS_ALL if ids.has(id) else Control.FOCUS_NONE
		target.text = "◇" if ids.has(id) else ""
