@tool
extends Control
## Editor-authored composition facade. Keep all public signals/fields for BattleScreen + P4 tests.

signal actor_requested(actor: String)
signal card_requested(instance: String)
signal card_released(instance: String, pointer: Vector2)
signal card_drag_started(instance: String)
signal card_chant_held(instance: String, full: bool)
signal command_requested(kind: String, fields: Dictionary)
signal target_requested(actor: String)
signal confirm_requested()
signal cancel_requested()
signal locale_requested(locale: String)

# Compatibility facade: battle_screen.gd and P42/P43 tests directly read these.
var card_views: Array[Control] = []
var roster: Dictionary = {}
@export var hand: Control
@export var end_button: Button
@export var details: Label
@export var feedback: Label
@export var header: Label
@export var resources: Label
@export var boss_stats: Label
@export var intent: Label
@export var reaction_panel: PanelContainer
@export var reaction_column: VBoxContainer
@export var confirm_button: Button
@export var mode: OptionButton
@export var combo: CheckButton
@export var log_label: Label
var target_buttons: Dictionary = {}
var vm: Dictionary = {}
var selected: String = "A"
@export var result_panel: PanelContainer
@export var result_label: Label
@export var reduced_toggle: CheckButton
@export var mute_toggle: CheckButton
@export var conditions: Label
@export var _conditions_panel: PanelContainer

@export var _top: Control
@export var _party: Control
@export var _commands: Control
@export var _enemy: Control
@export var _context: Control
@export var _log: Control
@export var targeting_arrow: Control
@export var _targets: Control
@export var _modal_shield: Control
var _modal_active: bool = false
var _return_focus: WeakRef
var _background_focus: Dictionary = {}
@export var command_prompt: PanelContainer
@export var command_prompt_title: Label
@export var command_prompt_description: Label
@export var command_prompt_column: VBoxContainer
@export var preferences_panel: PanelContainer
@export var last_preview: Control
@export var combo_preview: PanelContainer
@export var preparation_indicator: Label

## Layout and fixed controls are authored in battle_hud.tscn.
## This facade binds intent signals; it never reapplies panel rectangles.
func _ready() -> void:
	roster = _party.roster
	card_views = hand.card_views
	target_buttons = _targets.target_buttons
	_top.locale_requested.connect(func(locale: String) -> void: locale_requested.emit(locale))
	_top.command_requested.connect(_forward_command)
	_party.actor_requested.connect(func(actor: String) -> void: actor_requested.emit(actor))
	_commands.command_requested.connect(_forward_command)
	_context.command_requested.connect(_forward_command)
	_context.confirm_requested.connect(func() -> void: confirm_requested.emit())
	_context.cancel_requested.connect(func() -> void: cancel_requested.emit())
	_context.preferences_disclosure.pressed.connect(func() -> void: preferences_panel.visible = not preferences_panel.visible)
	hand.card_requested.connect(func(instance: String) -> void: card_requested.emit(instance))
	hand.card_released.connect(func(instance: String, pointer: Vector2) -> void:
		end_targeting_arrow()
		card_released.emit(instance, pointer))
	hand.card_drag_started.connect(func(instance: String) -> void: card_drag_started.emit(instance))
	hand.chant_held.connect(func(instance: String, full: bool) -> void:
		card_chant_held.emit(instance, full)
		command_requested.emit("HOLD_CHANT", {"instance_id":instance, "full":full}))
	_targets.target_requested.connect(func(actor: String) -> void: target_requested.emit(actor))
	targeting_arrow.target_hovered.connect(_targets.set_hovered_target)
	reaction_panel.command_requested.connect(_forward_command)
	$Result/VBoxContainer/Button.pressed.connect(func() -> void: command_requested.emit("RESTART_BATTLE", {}))
	last_preview.activation_requested.connect(func(target: String) -> void:
		command_requested.emit("ACTIVATE_LAST_PREVIEW", {"target_id":target}))
	last_preview.cancel_requested.connect(func() -> void: cancel_requested.emit())
	last_preview.target_changed.connect(func(id: String) -> void: target_requested.emit(id))
	refresh_locale()
	if not Engine.is_editor_hint():
		# Tool previews can be serialized by the editor; runtime feedback starts empty.
		feedback.text = ""
		for popup: Control in [reaction_panel, result_panel, command_prompt, preferences_panel, last_preview, combo_preview, _modal_shield]:
			popup.hide()
		last_preview.cancel_button.disabled = false

func bind_arena(arena: Node2D) -> void:
	_targets.arena = arena

## Static labels retain their catalogue keys across repeated locale switches.
func refresh_locale() -> void:
	_translate_static(self)
	mode.set_item_text(0, tr("BATTLE_CHANTLESS"))
	mode.set_item_text(1, tr("BATTLE_FULL"))
	_context.preferences_disclosure.tooltip_text = tr("BATTLE_REDUCED") + " · " + tr("BATTLE_MUTE")

func _translate_static(node: Node) -> void:
	if node is Label or node is Button:
		if not node.has_meta("translation_key"):
			var key: String = node.text
			if key.begins_with("BATTLE_") or key.begins_with("LAST_") or key.begins_with("CP2_"):
				node.set_meta("translation_key", key)
		if node.has_meta("translation_key"):
			node.text = tr(str(node.get_meta("translation_key")))
	for child: Node in node.get_children():
		_translate_static(child)

func _forward_command(kind: String, fields: Dictionary) -> void:
	command_requested.emit(kind, fields)

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
		if child is BaseButton and child.is_visible_in_tree() and not child.disabled and child.focus_mode != Control.FOCUS_NONE:
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
	var active: bool = result_panel.visible or reaction_panel.visible or command_prompt.visible or last_preview.visible or combo_preview.visible
	_modal_shield.visible = active
	if active:
		if not _modal_active:
			_return_focus = weakref(get_viewport().gui_get_focus_owner())
		# SimpleCards also refreshes hover from geometry outside native GUI picking.
		# NONE prevents its focus-on-hover from escaping into a covered hand.
		for child: Node in get_children():
			if child not in [reaction_panel,result_panel,command_prompt,last_preview,combo_preview,_modal_shield]: _suspend_focus(child)
		var panel: Control = result_panel if result_panel.visible else reaction_panel if reaction_panel.visible else combo_preview if combo_preview.visible else last_preview if last_preview.visible else command_prompt
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

func begin_targeting_arrow(instance: String, targets: Array) -> void:
	var source: Vector2 = Vector2.ZERO
	var found: bool = false
	for card: Control in card_views:
		if str(card.instance_id) == instance:
			# Anchor to the slot in the fan, not the moving dragged card.
			source = hand.get_global_transform() * (card.home + Vector2(card.size.x * 0.5, card.size.y * 0.22))
			found = true
			break
	if found:
		targeting_arrow.begin_aim(source,targets,target_buttons)

func update_targeting_arrow(targets: Array) -> void:
	if targeting_arrow.is_aiming:
		targeting_arrow.update_legal_targets(targets)

func end_targeting_arrow() -> void:
	if targeting_arrow != null:
		targeting_arrow.end_aim()

func set_targets(ids: Array) -> void:
	_targets.set_targets(ids)

func set_basic_target_choices(ids: Array, selected_id: String, labels: Dictionary) -> void:
	_targets.set_basic_target_choices(ids, selected_id, labels)

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
