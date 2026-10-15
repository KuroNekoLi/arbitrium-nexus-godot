extends Control
## V1 composition facade. Keep all public signals/fields for BattleScreen + P4 tests.
const HeaderScene = preload("res://scenes/battle/ui/team_phase_header.tscn")
const PartyScene = preload("res://scenes/battle/ui/party_status_panel.tscn")
const CommandsScene = preload("res://scenes/battle/ui/command_menu.tscn")
const EnemyScene = preload("res://scenes/battle/ui/enemy_status_panel.tscn")
const ContextScene = preload("res://scenes/battle/ui/action_context_panel.tscn")
const LogScene = preload("res://scenes/battle/ui/battle_log_panel.tscn")
const HandScene = preload("res://scenes/battle/ui/hand_view.tscn")
const TargetsScene = preload("res://scenes/battle/ui/target_hit_regions.tscn")
const ReactionScene = preload("res://scenes/battle/ui/reaction_queue.tscn")
const UI = preload("res://scripts/battle/ui/components/ui_elements.gd")

signal actor_requested(actor: String)
signal card_requested(instance: String)
signal card_released(instance: String, pointer: Vector2)
signal command_requested(kind: String, fields: Dictionary)
signal target_requested(actor: String)
signal confirm_requested()
signal cancel_requested()
signal locale_requested(locale: String)

# Compatibility facade: battle_screen.gd and P42/P43 tests directly read these.
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
var result_panel: PanelContainer
var result_label: Label
var reduced_toggle: CheckButton
var mute_toggle: CheckButton
var conditions: Label
var _conditions_panel: PanelContainer

var _top: Control
var _party: Control
var _commands: Control
var _enemy: Control
var _context: Control
var _log: Control
var _targets: Control
var _modal_shield: Control
var _modal_active: bool = false
var _return_focus: WeakRef
var _background_focus: Dictionary = {}
var command_prompt: PanelContainer
var command_prompt_title: Label
var command_prompt_description: Label
var command_prompt_column: VBoxContainer
var preferences_panel: PanelContainer

func _ready() -> void:
	theme = preload("res://resources/ui/battle_theme.tres")
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()

func _place(scene: PackedScene, rect: Rect2) -> Control:
	var component := scene.instantiate() as Control
	component.position = rect.position
	component.size = rect.size
	add_child(component)
	return component

func _build() -> void:
	_top = _place(HeaderScene, Rect2(16, 12, 1248, 64))
	header = _top.header
	resources = _top.resources
	_top.locale_requested.connect(func(locale: String) -> void: locale_requested.emit(locale))
	_top.command_requested.connect(func(kind: String, fields: Dictionary) -> void: command_requested.emit(kind, fields))

	# V1 deliberately preserves the previous 1280×720 rectangles.
	_conditions_panel = PanelContainer.new()
	_conditions_panel.name = "Conditions"
	_conditions_panel.position = Vector2(312, 98)
	_conditions_panel.size = Vector2(640, 36)
	add_child(_conditions_panel)
	conditions = UI.label(UI.column(_conditions_panel), "", 14)
	conditions.autowrap_mode = TextServer.AUTOWRAP_OFF
	conditions.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

	_party = _place(PartyScene, Rect2(16, 98, 260, 318))
	roster = _party.roster
	_party.actor_requested.connect(func(actor: String) -> void: actor_requested.emit(actor))

	_commands = _place(CommandsScene, Rect2(16, 432, 248, 266))
	end_button = _commands.end_button
	_commands.command_requested.connect(func(kind: String, fields: Dictionary) -> void: command_requested.emit(kind, fields))

	_enemy = _place(EnemyScene, Rect2(984, 12, 280, 238))
	boss_stats = _enemy.boss_stats
	intent = _enemy.intent

	_context = _place(ContextScene, Rect2(984, 348, 280, 220))
	details = _context.details
	mode = _context.mode
	combo = _context.combo
	confirm_button = _context.confirm_button
	feedback = _context.feedback
	_log = _place(LogScene, Rect2(984, 580, 280, 118))
	log_label = _log.log_label
	# Shared metallic corners stay separate from live labels, bars and input.
	for panel: Control in [_commands, _enemy, _context, _log]:
		preload("res://scripts/battle/ui/components/battle_hud_chrome.gd").install(panel)
	reduced_toggle = _context.reduced_toggle
	mute_toggle = _context.mute_toggle
	_context.hide()
	_context.action_row.hide()
	# Feedback and preferences are not card details; they must remain available
	# when no card is selected. Keep the public field references unchanged.
	feedback.reparent(self)
	feedback.position = Vector2(320, 420)
	feedback.size = Vector2(620, 42)
	feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preferences_panel = PanelContainer.new()
	preferences_panel.name = "PresentationPreferences"
	preferences_panel.position = Vector2(984, 82)
	preferences_panel.size = Vector2(280, 170)
	preferences_panel.z_index = 80
	add_child(preferences_panel)
	var preferences: Control = _context.detail_scroll.get_child(0).get_node("PreferencesContent")
	preferences.reparent(preferences_panel)
	preferences.show()
	preferences_panel.hide()
	var disclosure: Button = _context.get_child(0).get_node("PreferencesDisclosure")
	# Replace the old local disclosure, not its presentation preference signals.
	for connection: Dictionary in disclosure.pressed.get_connections():
		disclosure.pressed.disconnect(connection["callable"])
	disclosure.reparent(_top.get_node("UtilityPanel").get_child(0))
	disclosure.pressed.connect(func() -> void: preferences_panel.visible = not preferences_panel.visible)
	command_prompt = PanelContainer.new()
	command_prompt.name = "CommandConfirmation"
	command_prompt.position = Vector2(430, 190)
	command_prompt.size = Vector2(420, 230)
	command_prompt.z_index = 110
	add_child(command_prompt)
	command_prompt_column = UI.column(command_prompt)
	command_prompt_title = UI.label(command_prompt_column, "BATTLE_CONFIRM", 22)
	command_prompt_description = UI.label(command_prompt_column, "", 16)
	command_prompt_description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	command_prompt.hide()
	_context.command_requested.connect(func(kind: String, fields: Dictionary) -> void: command_requested.emit(kind, fields))
	_context.confirm_requested.connect(func() -> void: confirm_requested.emit())
	_context.cancel_requested.connect(func() -> void: cancel_requested.emit())

	hand = _place(HandScene, Rect2(290, 470, 686, 240))
	card_views = hand.card_views
	hand.card_requested.connect(func(instance: String) -> void: card_requested.emit(instance))
	hand.card_released.connect(func(instance: String, pointer: Vector2) -> void: card_released.emit(instance, pointer))
	hand.chant_held.connect(func(instance: String, full: bool) -> void:
		command_requested.emit("HOLD_CHANT", {"instance_id": instance, "full": full}))

	_targets = _place(TargetsScene, Rect2(0, 0, 1280, 720))
	target_buttons = _targets.target_buttons
	_targets.target_requested.connect(func(actor: String) -> void: target_requested.emit(actor))

	reaction_panel = _place(ReactionScene, Rect2(300, 154, 665, 305)) as PanelContainer
	reaction_panel.z_index = 100
	var result := PanelContainer.new()
	result.name = "Result"
	result.position = Vector2(390,210)
	result.size = Vector2(500,180)
	result.z_index = 120
	add_child(result)
	result_panel = result
	var result_column: VBoxContainer = UI.column(result)
	result_label = UI.label(result_column,"",30)
	UI.button(result_column,"BATTLE_RESTART",func() -> void: command_requested.emit("RESTART_BATTLE",{}))
	result.hide()
	reaction_column = reaction_panel.reaction_column
	reaction_panel.command_requested.connect(func(kind: String, fields: Dictionary) -> void: command_requested.emit(kind, fields))
	_modal_shield = Control.new()
	_modal_shield.name = "ModalInputShield"
	_modal_shield.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_modal_shield.mouse_filter = Control.MOUSE_FILTER_STOP
	_modal_shield.z_index = 95
	_modal_shield.hide()
	add_child(_modal_shield)
	# GUI picking follows tree order, not draw z_index. Keep the shield before
	# both modal panels so it blocks the background, never their own buttons.
	move_child(_modal_shield,reaction_panel.get_index())
	move_child(command_prompt, result_panel.get_index())

func render(projection: Dictionary, actor: String, cards: Array, reaction_choices: Array) -> void:
	vm = projection
	selected = actor
	result_panel.visible = vm["outcome"] in ["VICTORY","DEFEAT"]
	result_label.text = tr("BATTLE_"+str(vm["outcome"]))
	_top.render_phase(vm)
	conditions.text = _party.render_party(vm, actor)
	conditions.tooltip_text = conditions.text
	_conditions_panel.visible = _selected_has_conditions(vm, actor)
	_commands.render_commands(vm)
	_enemy.render_enemy(vm)
	hand.render_cards(cards)
	card_views = hand.card_views
	reaction_panel.render_window(vm["reaction"], reaction_choices,vm.get("actor_name_keys",{}))
	_sync_modal_focus()

func _focus_buttons(node: Node, output: Array[Control]) -> void:
	for child: Node in node.get_children():
		if child is BaseButton and child.is_visible_in_tree() and not child.disabled:
			output.append(child)
		_focus_buttons(child,output)

func _suspend_focus(node: Node) -> void:
	if node is Control and node.focus_mode != Control.FOCUS_NONE:
		_background_focus[node.get_instance_id()] = {"node":weakref(node),"mode":node.focus_mode}
		node.focus_mode = Control.FOCUS_NONE
	for child: Node in node.get_children(): _suspend_focus(child)

func _restore_background_focus() -> void:
	for saved: Dictionary in _background_focus.values():
		var node: Control = saved["node"].get_ref()
		if is_instance_valid(node) and not node.is_queued_for_deletion():
			node.focus_mode = saved["mode"]
	_background_focus.clear()

## GUI modal isolation is presentation-only; it never confirms or passes a window.
func _sync_modal_focus() -> void:
	var active: bool = result_panel.visible or reaction_panel.visible or command_prompt.visible
	_modal_shield.visible = active
	if active:
		if not _modal_active:
			_return_focus = weakref(get_viewport().gui_get_focus_owner())
		# SimpleCards also refreshes hover from geometry outside native GUI picking.
		# NONE prevents its focus-on-hover from escaping into a covered hand.
		for child: Node in get_children():
			if child not in [reaction_panel,result_panel,command_prompt,_modal_shield]: _suspend_focus(child)
		var panel: Control = result_panel if result_panel.visible else reaction_panel if reaction_panel.visible else command_prompt
		var buttons: Array[Control] = []
		_focus_buttons(panel,buttons)
		for i: int in buttons.size():
			buttons[i].focus_next = buttons[i].get_path_to(buttons[(i+1)%buttons.size()])
			buttons[i].focus_previous = buttons[i].get_path_to(buttons[(i-1+buttons.size())%buttons.size()])
		if not buttons.is_empty(): buttons[0].grab_focus()
	elif _modal_active:
		_restore_background_focus()
		var previous: Control = _return_focus.get_ref() if _return_focus != null else null
		if is_instance_valid(previous) and not previous.is_queued_for_deletion() and previous.is_visible_in_tree():
			previous.grab_focus()
		else:
			end_button.grab_focus()
	_modal_active = active

func show_command_confirmation(title: String, description: String) -> void:
	_context.hide()
	preferences_panel.hide()
	command_prompt_title.text = title
	command_prompt_description.text = description
	_context.action_row.reparent(command_prompt_column)
	_context.action_row.show()
	command_prompt.show()
	_sync_modal_focus()

func clear_command_confirmation() -> void:
	command_prompt.hide()
	if _context.action_row.get_parent() == command_prompt_column:
		_context.action_row.reparent(_context.get_child(0))
	_context.action_row.hide()
	_sync_modal_focus()

func set_selected_card(instance: String) -> void:
	# Display-only selection; legacy BattleScreen stays authoritative for actions.
	hand.set_selected_instance(instance)

func _arrange_hand() -> void:
	# Legacy compatibility adapter; the HandView owns ArcShape.
	hand._arrange_hand()

func _render_reaction(choices: Array) -> void:
	# Legacy compatibility adapter; the ReactionQueue owns draft rows.
	reaction_panel.render_window(vm["reaction"], choices,vm.get("actor_name_keys",{}))

func set_targets(ids: Array) -> void:
	_targets.set_targets(ids)

## Contextual status only: idle phase HUD should not obscure the battlefield.
## The three roster items still expose all actor states and tooltips.
func _selected_has_conditions(projection: Dictionary, actor: String) -> bool:
	if int(projection.get("barriers", {}).get(actor, 0)) > 0:
		return true
	if projection.get("reaction", {}).get("guard_actor_ids", []).has(actor):
		return true
	for cast: Dictionary in projection.get("casts", {}).values():
		if str(cast.get("caster_id", "")) == actor:
			return true
	return false
