@tool
extends EditorPlugin
## Disabled in the shipped project. Captures the real editor, never Domain.
var elapsed: float = 0.0
var stage: int = 0
var output_dir: String

func _enter_tree() -> void:
	set_process(OS.get_cmdline_user_args().has("--qa-editor-capture"))
	output_dir = "res://outputs/p4_input_capture/editor_" + str(OS.get_process_id())

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed < 4.0:
		return
	elapsed = 0.0
	var scene: Node = EditorInterface.get_edited_scene_root()
	if scene == null:
		push_error("EDITOR_CAPTURE_NO_SCENE")
		get_tree().quit(1)
		return
	if stage == 0:
		EditorInterface.set_main_screen_editor("2D")
		EditorInterface.edit_node(scene.get_node("Design/Arena/A"))
	elif stage == 1:
		capture("editor_battle")
		if scene.get("controller") != null or not scene.get("snapshot").is_empty():
			push_error("EDITOR_CAPTURE_DOMAIN_ISOLATION_FAILED")
			get_tree().quit(1)
			return
		print("EDITOR_CAPTURE_DOMAIN_ISOLATION_PASS")
		scene.set("editor_preview_mode", "Last Spell Akane")
		EditorInterface.edit_node(scene)
	elif stage == 2:
		capture("editor_last_akane")
		scene.set("editor_preview_mode", "Battle")
		get_tree().quit()
	stage += 1

func capture(label: String) -> void:
	var error: Error = DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	if error == OK:
		var viewport: Viewport = EditorInterface.get_base_control().get_viewport()
		error = viewport.get_texture().get_image().save_png(output_dir.path_join(label+".png"))
	if error != OK:
		push_error("EDITOR_CAPTURE_FAILED:"+str(error))
	else:
		print("EDITOR_CAPTURE ", output_dir.path_join(label+".png"))
