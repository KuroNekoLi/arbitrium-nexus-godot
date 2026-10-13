extends SceneTree

const GameScene = preload("res://scenes/main.tscn")

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var game: Control = GameScene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game._open_deck_builder()
	await process_frame
	await process_frame
	var screenshot: Image = root.get_viewport().get_texture().get_image()
	screenshot.save_png(ProjectSettings.globalize_path("res://outputs/deck_builder.png"))
	print("Saved the live deck editor capture")
	quit(0)
