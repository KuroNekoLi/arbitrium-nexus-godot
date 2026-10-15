extends RefCounted
## Atomic, idempotent installation of both versioned battle catalogues.
## This owner only unregisters translations that it installed.
const DEFAULT_FILES: Array[String] = [
	"res://resources/ui/battle_strings.csv",
	"res://resources/ui/lv40_strings.csv"
]
const LOCALES: Array[String] = ["en", "zh_TW"]
## Existing battle_strings.csv contains two historic duplicate keys.
## Their final legacy entries remain authoritative until that file's owner fixes it.
const LEGACY_LAST_WINS: Array[String] = ["BATTLE_SAVED", "BATTLE_SAVE_FAILED"]
static var installed: bool = false
static var _owned: Array[Translation] = []

static func validate_catalogues(paths: Array[String] = DEFAULT_FILES) -> Dictionary:
	if paths.is_empty():
		return {"ok":false,"error":"NO_CATALOGUES","catalogues":{},"warnings":[]}
	var data: Dictionary = {"en":{}, "zh_TW":{}}
	var owners: Dictionary = {}
	var warnings: Array[String] = []
	for index: int in paths.size():
		var path: String = paths[index]
		var file: FileAccess = FileAccess.open(path,FileAccess.READ)
		if file == null:
			return {"ok":false,"error":"MISSING_CATALOGUE:"+path,"catalogues":{},"warnings":warnings}
		var header: PackedStringArray = file.get_csv_line()
		if header.size() != 3 or header[0] != "keys" or header[1] != "en" or header[2] != "zh_TW":
			return {"ok":false,"error":"INVALID_HEADER:"+path,"catalogues":{},"warnings":warnings}
		var line: int = 1
		while not file.eof_reached():
			var row: PackedStringArray = file.get_csv_line()
			line += 1
			if row.size() == 1 and row[0].strip_edges().is_empty() and file.eof_reached():
				continue
			if row.size() != header.size():
				return {"ok":false,"error":"INVALID_ROW:"+path+":"+str(line),"catalogues":{},"warnings":warnings}
			var key: String = row[0].strip_edges()
			if key.is_empty() or row[1].strip_edges().is_empty() or row[2].strip_edges().is_empty():
				return {"ok":false,"error":"EMPTY_CELL:"+path+":"+str(line),"catalogues":{},"warnings":warnings}
			if owners.has(key):
				var historical: bool = index == 0 and owners[key] == 0 and path == DEFAULT_FILES[0] and LEGACY_LAST_WINS.has(key)
				if not historical:
					return {"ok":false,"error":"DUPLICATE_KEY:"+key,"catalogues":{},"warnings":warnings}
				warnings.append("LEGACY_LAST_WINS:"+key)
			owners[key] = index
			for locale: String in LOCALES:
				data[locale][key] = row[1] if locale == "en" else row[2]
	return {"ok":true,"error":"","catalogues":data,"warnings":warnings,"key_count":owners.size()}

static func install_checked(paths: Array[String] = DEFAULT_FILES) -> Dictionary:
	# Install is a transaction: parse and validate EVERY source before mutation.
	if installed:
		return {"ok":true,"error":"","already_installed":true,"owned_count":_owned.size()}
	var validated: Dictionary = validate_catalogues(paths)
	if not validated["ok"]:
		return validated
	var staged: Array[Translation] = []
	for locale: String in LOCALES:
		var translation: Translation = Translation.new()
		translation.set_locale(locale)
		for key: String in validated["catalogues"][locale]:
			translation.add_message(key,str(validated["catalogues"][locale][key]))
		staged.append(translation)
	for translation: Translation in staged:
		TranslationServer.add_translation(translation)
	_owned = staged
	installed = true
	return {"ok":true,"error":"","already_installed":false,"owned_count":_owned.size(),
		"key_count":validated["key_count"],"warnings":validated["warnings"]}

static func install() -> void:
	var result: Dictionary = install_checked()
	if not result["ok"]:
		push_error("Battle translation catalogue rejected: "+str(result["error"]))

static func uninstall_owned() -> void:
	for translation: Translation in _owned:
		TranslationServer.remove_translation(translation)
	_owned.clear()
	installed = false

static func owned_count() -> int:
	return _owned.size()
