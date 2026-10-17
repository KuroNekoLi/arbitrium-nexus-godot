@tool
extends Control
## V2: three independent islands keep the world visible between AP, phase and tools.
## The root remains TopBar (height 64) to preserve P42 and facade contracts.
signal locale_requested(locale: String)
signal command_requested(kind: String, fields: Dictionary)
@export var header: Label
@export var resources: Label
@export var ap_value: Label
@export var rp_value: Label
@export var crystal_row: HBoxContainer
const CRYSTAL = preload("res://assets/ui/v35/ap_crystal.svg")

func _ready() -> void:
	$UtilityPanel/HBoxContainer/Button.pressed.connect(func() -> void: locale_requested.emit("en"))
	$UtilityPanel/HBoxContainer/Button2.pressed.connect(func() -> void: locale_requested.emit("zh_TW"))
	$UtilityPanel/HBoxContainer/Button3.pressed.connect(func() -> void: command_requested.emit("SAVE_REPLAY", {}))

func render_phase(projection: Dictionary) -> void:
	header.text = tr("BATTLE_PHASE_" + projection["phase"]) + "   ·   " + tr("BATTLE_ROUND") % projection["round"]
	resources.text = tr("BATTLE_RESOURCES") % [projection["resources"]["current_ap"], projection["resources"]["rp"]]
	render_resource_values(projection["resources"])

func render_resource_values(values: Dictionary) -> void:
	var value: int = int(values["current_ap"])
	ap_value.text = "%d AP" % value
	rp_value.text = "RP %d" % int(values["rp"])
	for old: Node in crystal_row.get_children():
		crystal_row.remove_child(old)
		old.queue_free()
	var slots: int = mini(12, maxi(value, int(values.get("base_ap", value))))
	for index: int in slots:
		var gem := TextureRect.new()
		gem.texture = CRYSTAL
		gem.custom_minimum_size = Vector2(minf(18.0, 132.0 / maxf(1.0, slots)), 20)
		gem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		gem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		gem.modulate = Color.WHITE if index < value else Color(0.22, 0.30, 0.38, 0.55)
		gem.mouse_filter = Control.MOUSE_FILTER_IGNORE
		crystal_row.add_child(gem)
	crystal_row.tooltip_text = resources.text # Numeric value stays exact beyond 12 visible gems.
