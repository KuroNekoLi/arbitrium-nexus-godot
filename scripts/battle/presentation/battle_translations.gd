extends RefCounted
static var installed: bool = false
static func install() -> void:
	if installed: return
	var file := FileAccess.open("res://resources/ui/battle_strings.csv", FileAccess.READ)
	if file == null:
		push_error("Missing battle translation catalogue")
		return
	var header: PackedStringArray = file.get_csv_line()
	var translations: Array[Translation] = []
	for i: int in range(1,header.size()):
		var entry := Translation.new()
		entry.set_locale(header[i])
		translations.append(entry)
	while not file.eof_reached():
		var row: PackedStringArray = file.get_csv_line()
		if row.size() != header.size(): continue
		for i: int in translations.size(): translations[i].add_message(row[0],row[i+1])
	for entry: Translation in translations: TranslationServer.add_translation(entry)
	installed = true
