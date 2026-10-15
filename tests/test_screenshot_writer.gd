extends SceneTree
## File-only suite; creates a 2x2 Image without viewport, scene or GUI input.
const Writer = preload("res://scripts/qa/screenshot_writer.gd")

class ErrorWriter:
	extends "res://scripts/qa/screenshot_writer.gd"
	func _save_png(_image: Image, _path: String) -> int:
		return ERR_FILE_CANT_WRITE

class MissingWriter:
	extends "res://scripts/qa/screenshot_writer.gd"
	func _save_png(_image: Image, _path: String) -> int:
		return OK

class CorruptWriter:
	extends "res://scripts/qa/screenshot_writer.gd"
	func _save_png(_image: Image, path: String) -> int:
		var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
		if file == null:
			return FileAccess.get_open_error()
		file.store_string("not a PNG")
		file.close()
		return OK

class WrongSizeWriter:
	extends "res://scripts/qa/screenshot_writer.gd"
	func _save_png(_image: Image, path: String) -> int:
		return Image.create(1, 1, false, Image.FORMAT_RGBA8).save_png(path)

var executed: int = 0
var failed: int = 0
var owned_files: Array[String] = []
var owned_directories: Array[String] = []

func check(condition: bool, id: String) -> void:
	executed += 1
	if not condition:
		failed += 1
	print(("PASS " if condition else "FAIL ") + id)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var writer = Writer.new()
	var image: Image = Image.create(2, 2, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.2, 0.4, 0.8, 1.0))
	var prefix: String = "writer_test_%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	var directory: String = ProjectSettings.globalize_path(Writer.OUTPUT_SCOPE).path_join(prefix)
	# Reserve the fixture namespace first; never clean up pre-existing artifacts.
	var scope_error: int = DirAccess.make_dir_recursive_absolute(directory.get_base_dir())
	var reserve_error: int = DirAccess.make_dir_absolute(directory) if scope_error == OK else scope_error
	check(reserve_error == OK, "SW-01-FIXTURE-RESERVATION")
	if reserve_error != OK:
		finish()
		return
	owned_directories.append(directory)
	var result: Dictionary = writer.write_png(image, "tiny", prefix)
	var path: String = directory.path_join("tiny.png")
	owned_files.append(path)
	check(result["ok"] and result["stage"] == "verified", "SW-02-WRITE-AND-DECODE")
	check(result["path"] == path and FileAccess.file_exists(path), "SW-03-SCOPED-EXISTENCE")
	var before: PackedByteArray = FileAccess.get_file_as_bytes(path)
	image.fill(Color.RED)
	result = writer.write_png(image, "tiny", prefix)
	check(not result["ok"] and result["stage"] == "collision", "SW-04-COLLISION-REJECTED")
	check(before == FileAccess.get_file_as_bytes(path), "SW-05-COLLISION-BYTES-UNCHANGED")
	for bad: String in ["../escape", "a/b", "a\\b", "C:evil", "res://evil", ".", "", "CON", "lpt1", "bad.", "a b", "a".repeat(81)]:
		result = writer.write_png(image, bad, prefix)
		check(not result["ok"] and result["stage"] == "validate", "SW-06-INVALID-NAME-" + str(bad))
	result = writer.write_png(image, "tiny", "../outside")
	check(not result["ok"] and result["stage"] == "validate", "SW-07-PREFIX-TRAVERSAL")
	check(Writer.valid_token("a".repeat(80)), "SW-08-TOKEN-LENGTH-BOUNDARY")
	check(Writer.prefix_from_args(PackedStringArray())["prefix"] == "", "SW-09-DEFAULT-PREFIX")
	check(Writer.prefix_from_args(PackedStringArray(["--capture-prefix=" + prefix]))["ok"], "SW-10-EXPLICIT-PREFIX")
	for args: PackedStringArray in [PackedStringArray(["--capture-prefix="]),
		PackedStringArray(["--capture-prefix"]), PackedStringArray(["--capture-prefix=a", "--capture-prefix=b"]),
		PackedStringArray(["--capture-prefix=a/b"]), PackedStringArray(["--capture-prefix=a=b"])]:
		check(not Writer.prefix_from_args(args)["ok"], "SW-11-INVALID-ARGUMENTS-" + str(args))
	result = writer.write_png(null, "null_image", prefix)
	check(not result["ok"] and result["stage"] == "image", "SW-12-NULL-IMAGE")
	result = writer.write_png(Image.new(), "empty_image", prefix)
	check(not result["ok"] and result["stage"] == "image", "SW-13-EMPTY-IMAGE")
	var occupied: String = directory.path_join("directory.png")
	var mkdir_error: int = DirAccess.make_dir_absolute(occupied)
	if mkdir_error == OK:
		owned_directories.append(occupied)
	result = writer.write_png(image, "directory", prefix)
	check(mkdir_error == OK and result["stage"] == "collision", "SW-14-DIRECTORY-COLLISION")
	var lock_path: String = directory.path_join("busy.png.lock")
	mkdir_error = DirAccess.make_dir_absolute(lock_path)
	if mkdir_error == OK:
		owned_directories.append(lock_path)
	result = writer.write_png(image, "busy", prefix)
	check(mkdir_error == OK and not result["ok"] and result["stage"] == "reserve"
		and not FileAccess.file_exists(directory.path_join("busy.png")), "SW-15-HELD-RESERVATION")
	# A regular file at the requested namespace makes mkdir fail on every platform.
	var blocker_prefix: String = prefix + "_blocked"
	var blocker_path: String = directory.get_base_dir().path_join(blocker_prefix)
	var blocker: FileAccess = FileAccess.open(blocker_path, FileAccess.WRITE)
	if blocker != null:
		owned_files.append(blocker_path)
		blocker.store_string("directory blocker")
		blocker.close()
	result = writer.write_png(image, "tiny", blocker_prefix)
	check(blocker != null and not result["ok"] and result["stage"] == "mkdir"
		and result["error"] != OK and not result["detail"].is_empty(), "SW-16-MKDIR-ERROR-DETAIL")
	result = ErrorWriter.new().write_png(image, "write_error", prefix)
	check(not result["ok"] and result["stage"] == "save_png" and result["error"] == ERR_FILE_CANT_WRITE
		and result.has("error_name") and result["path"].ends_with("write_error.png"), "SW-17-WRITE-ERROR-DETAIL")
	check(not DirAccess.dir_exists_absolute(directory.path_join("write_error.png.lock")), "SW-18-ERROR-RELEASES-RESERVATION")
	result = MissingWriter.new().write_png(image, "missing", prefix)
	check(not result["ok"] and result["stage"] == "verify_exists", "SW-19-FALSE-OK-MISSING-PNG")
	result = CorruptWriter.new().write_png(image, "corrupt", prefix)
	owned_files.append(directory.path_join("corrupt.png"))
	check(not result["ok"] and result["stage"] == "verify_png", "SW-20-FALSE-OK-CORRUPT-PNG")
	result = WrongSizeWriter.new().write_png(image, "wrong_size", prefix)
	owned_files.append(directory.path_join("wrong_size.png"))
	check(not result["ok"] and result["stage"] == "verify_decode", "SW-22-FALSE-OK-WRONG-DIMENSIONS")
	var second_prefix: String = prefix + "_second"
	var second_directory: String = directory.get_base_dir().path_join(second_prefix)
	mkdir_error = DirAccess.make_dir_absolute(second_directory)
	if mkdir_error == OK:
		owned_directories.append(second_directory)
		result = writer.write_png(image, "tiny", second_prefix)
		owned_files.append(second_directory.path_join("tiny.png"))
	check(mkdir_error == OK and result["ok"] and before == FileAccess.get_file_as_bytes(path), "SW-21-PREFIX-ISOLATION")
	for owned_path: String in owned_files:
		if FileAccess.file_exists(owned_path):
			check(DirAccess.remove_absolute(owned_path) == OK, "SW-CLEANUP-FILE-" + owned_path.get_file())
	owned_directories.reverse()
	for owned_path: String in owned_directories:
		check(DirAccess.remove_absolute(owned_path) == OK, "SW-CLEANUP-DIRECTORY-" + owned_path.get_file())
	finish()

func finish() -> void:
	print("SCREENSHOT_WRITER_REPORT executed=%d passed=%d failed=%d" % [executed, executed - failed, failed])
	quit(0 if failed == 0 else 1)
