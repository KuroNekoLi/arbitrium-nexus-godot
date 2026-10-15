extends Control
## V1 composition facade. Keep all public signals/fields for BattleScreen + P4 tests.
const HeaderScene = preload("res://scenes/battle/ui/team_phase_header.tscn")
const PartyScene = preload("res://scenes/battle/ui/party_status_panel.tscn")
const CommandsScene = preload("res://scenes/battle/ui/command_menu.tscn")
const EnemyScene = preload("res://scenes/battle/ui/enemy_status_panel.tscn")
const ContextScene = preload("res://scenes/battle/ui/action_context_panel.tscn")
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

var _top: Control
var _party: Control
var _commands: Control
var _enemy: Control
var _context: Control
var _targets: Control

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
	var conditions_panel := PanelContainer.new()
	conditions_panel.name = "Conditions"
	conditions_panel.position = Vector2(292, 88)
	conditions_panel.size = Vector2(680, 42)
	add_child(conditions_panel)
	conditions = UI.label(UI.column(conditions_panel), "", 14)

	_party = _place(PartyScene, Rect2(16, 92, 260, 318))
	roster = _party.roster
	_party.actor_requested.connect(func(actor: String) -> void: actor_requested.emit(actor))

	_commands = _place(CommandsScene, Rect2(16, 425, 260, 269))
	end_button = _commands.end_button
	_commands.command_requested.connect(func(kind: String, fields: Dictionary) -> void: command_requested.emit(kind, fields))

	_enemy = _place(EnemyScene, Rect2(984, 92, 280, 235))
	boss_stats = _enemy.boss_stats
	intent = _enemy.intent

	_context = _place(ContextScene, Rect2(984, 350, 280, 348))
	details = _context.details
	mode = _context.mode
	combo = _context.combo
	confirm_button = _context.confirm_button
	feedback = _context.feedback
	log_label = _context.log_label
	reduced_toggle = _context.reduced_toggle
	mute_toggle = _context.mute_toggle
	_context.command_requested.connect(func(kind: String, fields: Dictionary) -> void: command_requested.emit(kind, fields))
	_context.confirm_requested.connect(func() -> void: confirm_requested.emit())
	_context.cancel_requested.connect(func() -> void: cancel_requested.emit())

	hand = _place(HandScene, Rect2(292, 458, 680, 246))
	card_views = hand.card_views
	hand.card_requested.connect(func(instance: String) -> void: card_requested.emit(instance))
	hand.card_released.connect(func(instance: String, pointer: Vector2) -> void: card_released.emit(instance, pointer))

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

func render(projection: Dictionary, actor: String, cards: Array, reaction_choices: Array) -> void:
	vm = projection
	selected = actor
	result_panel.visible = vm["outcome"] in ["VICTORY","DEFEAT"]
	result_label.text = tr("BATTLE_"+str(vm["outcome"]))
	_top.render_phase(vm)
	conditions.text = _party.render_party(vm, actor)
	_commands.render_commands(vm)
	_enemy.render_enemy(vm)
	hand.render_cards(cards)
	card_views = hand.card_views
	reaction_panel.render_window(vm["reaction"], reaction_choices)

func _arrange_hand() -> void:
	# Legacy compatibility adapter; the HandView owns ArcShape.
	hand._arrange_hand()

func _render_reaction(choices: Array) -> void:
	# Legacy compatibility adapter; the ReactionQueue owns draft rows.
	reaction_panel.render_window(vm["reaction"], choices)

func set_targets(ids: Array) -> void:
	_targets.set_targets(ids)
