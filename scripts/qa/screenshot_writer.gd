extends RefCounted
## File-only QA writer. No renderer, input, Domain or automatic retry dependencies.
## Prefix is an optional run namespace, not permission to rerun an exhausted suite.
const OUTPUT_SCOPE: String = "res://outputs/p4_input_capture"

static func valid_token(value: String) -> bool:
	if value.is_empty() or value.length() > 80:
		return false
	for index: int in value.length():
		var code: int = value.unicode_at(index)
		if not ((code >= 65 and code <= 90) or (code >= 97 and code <= 122)
			or (code >= 48 and code <= 57) or code == 45 or code == 95):
			return false
	# Windows device names are invalid even with a .png extension.
	var upper: String = value.to_upper()
	if upper in ["CON", "PRN", "AUX", "NUL", "CONIN$", "CONOUT$"]:
		return false
	for number: int in range(1, 10):
		if upper == "COM%d" % number or upper == "LPT%d" % number:
			return false
	return true

static func prefix_from_args(arguments: PackedStringArray) -> Dictionary:
	var prefix: String = ""
	var seen: bool = false
	for argument: String in arguments:
		if argument == "--capture-prefix" or argument.begins_with("--capture-prefix="):
			if seen or not argument.begins_with("--capture-prefix="):
				return {"ok": false, "prefix": "", "detail": "duplicate or missing --capture-prefix=value"}
			seen = true
			prefix = argument.trim_prefix("--capture-prefix=")
			if not valid_token(prefix):
				return {"ok": false, "prefix": "", "detail": "invalid capture-prefix; use 1..80 ASCII letters/digits/_/-"}
	return {"ok": true, "prefix": prefix, "detail": ""}

## Writes only below OUTPUT_SCOPE. Existing files/directories and held reservations fail.
## A failed write may leave a partial PNG: preserve it for diagnosis; never retry/overwrite.
func write_png(image: Image, capture_name: String, prefix: String = "") -> Dictionary:
	var scope: String = ProjectSettings.globalize_path(OUTPUT_SCOPE).simplify_path()
	if not valid_token(capture_name) or (not prefix.is_empty() and not valid_token(prefix)):
		return _result(false, "validate", scope, ERR_INVALID_PARAMETER, "invalid name or prefix")
	var directory: String = scope.path_join(prefix if not prefix.is_empty() else "default")
	var path: String = directory.path_join(capture_name + ".png")
	if image == null or image.is_empty():
		return _result(false, "image", path, ERR_INVALID_DATA, "null or empty image")
	# Reject existing links in the writable scope (trusted project root is a precondition).
	for candidate: String in [scope.get_base_dir(), scope, directory]:
		var parent: DirAccess = DirAccess.open(candidate.get_base_dir())
		if parent != null and parent.is_link(candidate.get_file()):
			return _result(false, "scope", path, ERR_INVALID_PARAMETER, "linked output directory: " + candidate)
	# Some backends report OK for recursive mkdir when the final path is a file.
	# Treat that obstruction as a directory failure before reserving a child path.
	if FileAccess.file_exists(directory):
		return _result(false, "mkdir", path, ERR_CANT_CREATE, "output namespace is a regular file: " + directory)
	var mkdir_error: int = DirAccess.make_dir_recursive_absolute(directory)
	if mkdir_error != OK:
		return _result(false, "mkdir", path, mkdir_error, "cannot create output directory: " + directory)
	if _occupied(path):
		return _result(false, "collision", path, ERR_ALREADY_EXISTS, "destination already exists; no overwrite")
	# Atomic directory reservation serializes cooperating writers, including across processes.
	var lock_path: String = path + ".lock"
	var lock_error: int = DirAccess.make_dir_absolute(lock_path)
	if lock_error != OK:
		return _result(false, "reserve", path, lock_error, "cannot reserve destination: " + lock_path)
	var result: Dictionary
	if _occupied(path):
		result = _result(false, "collision", path, ERR_ALREADY_EXISTS, "destination appeared after reservation")
	else:
		var save_error: int = _save_png(image, path)
		if save_error != OK:
			result = _result(false, "save_png", path, save_error, "Image.save_png failed")
		else:
			result = _verify_png(path, image.get_size())
	var release_error: int = DirAccess.remove_absolute(lock_path)
	if release_error != OK:
		result["ok"] = false
		result["detail"] += "; reservation cleanup failed: %s (%d) %s" % [error_string(release_error), release_error, lock_path]
		result["cleanup_error"] = release_error
	return result

func _occupied(path: String) -> bool:
	var parent: DirAccess = DirAccess.open(path.get_base_dir())
	return FileAccess.file_exists(path) or DirAccess.dir_exists_absolute(path) or (parent != null and parent.is_link(path.get_file()))

## Override only in file-helper tests to exercise deterministic error paths.
func _save_png(image: Image, path: String) -> int:
	return image.save_png(path)

func _verify_png(path: String, expected_size: Vector2i) -> Dictionary:
	if not FileAccess.file_exists(path):
		return _result(false, "verify_exists", path, ERR_FILE_NOT_FOUND, "save returned OK but PNG is missing")
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _result(false, "verify_open", path, FileAccess.get_open_error(), "cannot reopen PNG")
	var length: int = file.get_length()
	var signature: PackedByteArray = file.get_buffer(8)
	file.close()
	if length <= 8 or signature != PackedByteArray([137, 80, 78, 71, 13, 10, 26, 10]):
		return _result(false, "verify_png", path, ERR_FILE_CORRUPT, "invalid PNG signature/length: %d" % length)
	var decoded: Image = Image.new()
	var load_error: int = decoded.load_png_from_buffer(FileAccess.get_file_as_bytes(path))
	if load_error != OK or decoded.get_size() != expected_size:
		return _result(false, "verify_decode", path, load_error if load_error != OK else ERR_INVALID_DATA, "PNG decode or dimensions mismatch")
	return _result(true, "verified", path, OK, "PNG exists, signature and decoded dimensions verified; bytes=%d" % length)

func _result(ok: bool, stage: String, path: String, code: int, detail: String) -> Dictionary:
	return {"ok": ok, "stage": stage, "path": path, "error": code,
		"error_name": error_string(code), "detail": detail}
