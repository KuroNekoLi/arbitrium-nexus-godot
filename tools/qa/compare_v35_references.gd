extends SceneTree
## V3.5.5 deterministic reference comparison (no ImageGen, no network).
## Inputs : reference B (pinned JPEG, read via Image.load_from_file because the
##          reference folder is .gdignore'd) and one real Godot capture PNG.
## Outputs: <scope>/<prefix>/side_by_side.png   B | Actual, four HUD corners outlined
##          <scope>/<prefix>/overlay_50.png     50% blend of B and Actual
##          <scope>/<prefix>/corner_<ID>.png    B crop | Actual crop per corner
##          <scope>/<prefix>/compare_report.json per-corner metrics
## Characters / background (screen centre) are deliberately NOT compared.
## Metrics are descriptive only; the 6-dimension / 4-corner score is a human
## (or reviewing agent) judgement recorded separately and never auto-derived.
## Usage: godot --headless --path . --script res://tools/qa/compare_v35_references.gd -- \
##        --actual=<abs or res:// png> --out-prefix=<unique> [--reference=<path>]
const Writer = preload("res://scripts/qa/screenshot_writer.gd")
const BASE := Vector2i(1280, 720)
const DEFAULT_REFERENCE := "res://docs/ui/references/v35/reference_b_target.jpg"
## Corner regions in 1280x720 space (match V35_BASELINE four-corner mapping).
const CORNERS: Dictionary = {
	"TL": Rect2i(0, 0, 300, 330),      # TopBar/ResourcePanel + PartyStatusPanel
	"BL": Rect2i(0, 410, 300, 310),    # Commands
	"TR": Rect2i(980, 0, 300, 330),    # EnemyStatus + intent
	"BR": Rect2i(980, 330, 300, 390),  # Context + BattleLogPanel
}
const CORNER_COLORS: Dictionary = {
	"TL": Color("#F2C46D"), "BL": Color("#C59BFF"), "TR": Color("#FF7A6B"), "BR": Color("#6FD6FF"),
}

func _initialize() -> void:
	call_deferred("run")

func _args() -> Dictionary:
	var parsed: Dictionary = {}
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--") and arg.contains("="):
			parsed[arg.substr(2, arg.find("=") - 2)] = arg.substr(arg.find("=") + 1)
	return parsed

func _load(path: String) -> Image:
	var absolute: String = ProjectSettings.globalize_path(path) if path.begins_with("res://") else path
	var image := Image.new()
	if image.load(absolute) != OK:
		return null
	image.convert(Image.FORMAT_RGB8)
	if image.get_size() != BASE:
		image.resize(BASE.x, BASE.y, Image.INTERPOLATE_LANCZOS)
	return image

func _outline(image: Image, rect: Rect2i, color: Color, width: int = 3) -> void:
	image.fill_rect(Rect2i(rect.position, Vector2i(rect.size.x, width)), color)
	image.fill_rect(Rect2i(rect.position + Vector2i(0, rect.size.y - width), Vector2i(rect.size.x, width)), color)
	image.fill_rect(Rect2i(rect.position, Vector2i(width, rect.size.y)), color)
	image.fill_rect(Rect2i(rect.position + Vector2i(rect.size.x - width, 0), Vector2i(width, rect.size.y)), color)

func _metrics(reference: Image, actual: Image, rect: Rect2i) -> Dictionary:
	var diff: float = 0.0
	var ref_luma: float = 0.0
	var act_luma: float = 0.0
	var count: int = 0
	for y: int in range(rect.position.y, rect.end.y, 2):
		for x: int in range(rect.position.x, rect.end.x, 2):
			var a: Color = reference.get_pixel(x, y)
			var b: Color = actual.get_pixel(x, y)
			diff += (absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b)) / 3.0
			ref_luma += a.get_luminance()
			act_luma += b.get_luminance()
			count += 1
	return {"mean_abs_diff": snappedf(diff / count, 0.0001),
		"reference_luma": snappedf(ref_luma / count, 0.0001),
		"actual_luma": snappedf(act_luma / count, 0.0001), "samples": count}

func _save(image: Image, directory: String, name: String) -> String:
	var path: String = directory.path_join(name)
	return path if image.save_png(path) == OK else ""

func run() -> void:
	var args: Dictionary = _args()
	var prefix: String = str(args.get("out-prefix", ""))
	if prefix.is_empty() or prefix.contains("/") or prefix.contains("\\") or prefix.contains(".."):
		push_error("compare_v35_references requires a plain unique --out-prefix.")
		quit(1)
		return
	var reference: Image = _load(str(args.get("reference", DEFAULT_REFERENCE)))
	var actual: Image = _load(str(args.get("actual", "")))
	if reference == null or actual == null:
		push_error("compare_v35_references could not load reference or --actual image.")
		quit(1)
		return
	var directory: String = ProjectSettings.globalize_path(Writer.OUTPUT_SCOPE).path_join(prefix)
	if DirAccess.dir_exists_absolute(directory):
		push_error("compare_v35_references refuses to overwrite existing prefix: " + prefix)
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(directory)

	var side := Image.create(BASE.x * 2 + 8, BASE.y, false, Image.FORMAT_RGB8)
	side.fill(Color("#05070A"))
	side.blit_rect(reference, Rect2i(Vector2i.ZERO, BASE), Vector2i.ZERO)
	side.blit_rect(actual, Rect2i(Vector2i.ZERO, BASE), Vector2i(BASE.x + 8, 0))
	var overlay: Image = actual.duplicate()
	for y: int in BASE.y:
		for x: int in BASE.x:
			overlay.set_pixel(x, y, reference.get_pixel(x, y).lerp(actual.get_pixel(x, y), 0.5))
	var report: Dictionary = {"reference": str(args.get("reference", DEFAULT_REFERENCE)),
		"actual": str(args.get("actual", "")), "base": [BASE.x, BASE.y], "corners": {}, "outputs": {}}
	for id: String in CORNERS:
		var rect: Rect2i = CORNERS[id]
		var strip := Image.create(rect.size.x * 2 + 6, rect.size.y, false, Image.FORMAT_RGB8)
		strip.fill(CORNER_COLORS[id])
		strip.blit_rect(reference, rect, Vector2i.ZERO)
		strip.blit_rect(actual, rect, Vector2i(rect.size.x + 6, 0))
		report["outputs"]["corner_" + id] = _save(strip, directory, "corner_%s.png" % id)
		report["corners"][id] = _metrics(reference, actual, rect)
		report["corners"][id]["rect"] = [rect.position.x, rect.position.y, rect.size.x, rect.size.y]
		_outline(side, rect, CORNER_COLORS[id])
		_outline(side, Rect2i(rect.position + Vector2i(BASE.x + 8, 0), rect.size), CORNER_COLORS[id])
		_outline(overlay, rect, CORNER_COLORS[id])
	report["outputs"]["side_by_side"] = _save(side, directory, "side_by_side.png")
	report["outputs"]["overlay_50"] = _save(overlay, directory, "overlay_50.png")
	var ok: bool = true
	for key: String in report["outputs"]:
		ok = ok and not str(report["outputs"][key]).is_empty()
	var file := FileAccess.open(directory.path_join("compare_report.json"), FileAccess.WRITE)
	ok = ok and file != null
	if file != null:
		file.store_string(JSON.stringify(report, "\t"))
		file.close()
	print("V35_COMPARE " + JSON.stringify(report["corners"]))
	print("V35_COMPARE_REPORT outputs=%d ok=%s" % [report["outputs"].size(), str(ok)])
	quit(0 if ok else 1)
