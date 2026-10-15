extends Control
const Encounter = preload("res://tests/fixtures/m5_full_battle_fixture.gd")
const Adapter = preload("res://scripts/battle/presentation/battle_presentation_adapter.gd")
var view_model: Dictionary = {}
@onready var design: Control = $Design

func _ready() -> void:
	view_model = Adapter.project(Encounter.initial())
	resized.connect(_fit_design)
	_fit_design()

func _fit_design() -> void:
	var factor: float = minf(size.x / 1280.0, size.y / 720.0)
	design.scale = Vector2.ONE * factor
	design.position = (size - Vector2(1280, 720) * factor) * 0.5
