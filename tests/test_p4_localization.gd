extends SceneTree
## Source → pure parser → atomic install → Godot locale lookup.
const Catalog = preload("res://scripts/battle/presentation/battle_translations.gd")
const Encounter = preload("res://scripts/domain/m5/lv40/lv40_encounter.gd")
const IDS: Array[String] = ["U01","U02","U03","U04","U05",
	"R01","R02","R03","R05","R06","R07","R08",
	"A01","A02","A03","A04","A05","A06","A07",
	"T01","T03","T04","T05","T06","T09","T10"]
var passed: int = 0
var failed: int = 0

func check(condition: bool, id: String) -> void:
	if condition:
		passed += 1
		print("PASS ",id)
	else:
		failed += 1
		push_error("FAIL "+id)

func write_fixture(name: String, csv: String) -> String:
	var path: String = "user://p4_l10n_"+name+".csv"
	var file: FileAccess = FileAccess.open(path,FileAccess.WRITE)
	if file == null:
		return ""
	file.store_string(csv)
	file.close()
	return path

func _initialize() -> void:
	var previous_locale: String = TranslationServer.get_locale()
	Catalog.uninstall_owned()
	var baseline: Dictionary = Catalog.validate_catalogues()
	check(baseline["ok"],"P4-L10N-01-VALID-TWO-CATALOGUES")
	check(baseline.get("warnings",[]).size() == 2,"P4-L10N-02-DECLARED-LEGACY-DUPLICATES")
	var english: Dictionary = baseline.get("catalogues",{}).get("en",{})
	var chinese: Dictionary = baseline.get("catalogues",{}).get("zh_TW",{})
	var content: Dictionary = Encounter.config()
	for key: String in ["BATTLE_TITLE","BATTLE_CONFIRM","BATTLE_REACTION","BATTLE_VICTORY"]:
		check(english.has(key) and chinese.has(key),"P4-L10N-03-LEGACY-"+key)
	for id: String in IDS:
		check(content["lv40_cards"][id]["name_key"] == "LV40_"+id+"_NAME" and content["lv40_cards"][id]["description_key"] == "LV40_"+id+"_DESC",
			"P4-L10N-21-DOMAIN-KEY-"+id)
		var appearance: Variant = load("res://resources/ui/appearances/"+id+".tres")
		check(appearance != null and str(appearance.get("definition_id")) == id,
			"P4-L10N-04-APPEARANCE-"+id)
		for suffix: String in ["NAME","DESC"]:
			var key: String = "LV40_"+id+"_"+suffix
			check(english.has(key) and chinese.has(key) and
				not str(english.get(key,"")).is_empty() and not str(chinese.get(key,"")).is_empty(),
				"P4-L10N-05-BILINGUAL-"+key)
			if appearance != null:
				check(str(appearance.get("name_key" if suffix == "NAME" else "description_key")) == key,
					"P4-L10N-06-APPEARANCE-KEY-"+key)
	for key: String in ["actor.ren.name","actor.akane.name","actor.tsumugi.name",
			"actor.arcane_sentry.name"]:
		check(english.has(key) and chinese.has(key),"P4-L10N-07-ACTOR-"+key)
	for i: int in range(1,12):
		var key: String = "intent.b%02d.name" % i
		check(english.has(key) and chinese.has(key),"P4-L10N-08-INTENT-"+key)
	for key: String in ["last_spell.ren.name","last_spell.akane.name","last_spell.tsumugi.name"]:
		check(english.has(key) and chinese.has(key),"P4-L10N-09-LAST-"+key)
	var malformed: String = write_fixture("invalid","keys,en,zh_TW\nBAD,missing\n")
	var empty: String = write_fixture("empty","keys,en,zh_TW\nBAD,Hello,\n")
	var duplicate: String = write_fixture("duplicate","keys,en,zh_TW\nBAD,Hello,您好\nBAD,Other,其他\n")
	var quoted: String = write_fixture("quoted","keys,en,zh_TW\nQUOTED,\"Hello, friend\",\"你好,朋友\"\n")
	var missing: String = "user://p4_l10n_missing_uncreated.csv"
	check(not Catalog.validate_catalogues([malformed])["ok"],"P4-L10N-10-BAD-ROW-REJECT")
	check(not Catalog.validate_catalogues([empty])["ok"],"P4-L10N-11-EMPTY-CELL-REJECT")
	check(not Catalog.validate_catalogues([duplicate])["ok"],"P4-L10N-12-DUPLICATE-REJECT")
	check(not Catalog.validate_catalogues([missing])["ok"],"P4-L10N-13-MISSING-REJECT")
	var escaped: Dictionary = Catalog.validate_catalogues([quoted])
	check(escaped["ok"] and escaped["catalogues"]["en"].get("QUOTED","") == "Hello, friend",
		"P4-L10N-14-QUOTED-CSV-PARSER")
	var invalid_install: Dictionary = Catalog.install_checked([malformed])
	check(not invalid_install["ok"] and not Catalog.installed and Catalog.owned_count() == 0,
		"P4-L10N-15-ATOMIC-FAILURE")
	var result: Dictionary = Catalog.install_checked()
	check(result["ok"] and Catalog.installed and Catalog.owned_count() == 2,
		"P4-L10N-16-INSTALL")
	check(TranslationServer.get_locale() == previous_locale,"P4-L10N-17-NO-LOCALE-MUTATION")
	result = Catalog.install_checked()
	check(result["ok"] and result.get("already_installed",false) and Catalog.owned_count() == 2,
		"P4-L10N-18-IDEMPOTENT")
	for locale: String in ["en","zh_TW"]:
		TranslationServer.set_locale(locale)
		for key: String in ["BATTLE_TITLE","LV40_U01_NAME","actor.ren.name","intent.b11.name"]:
			check(TranslationServer.translate(key) == baseline["catalogues"][locale][key],
				"P4-L10N-19-RUNTIME-"+locale+"-"+key)
	TranslationServer.set_locale(previous_locale)
	Catalog.uninstall_owned()
	check(not Catalog.installed and Catalog.owned_count() == 0,"P4-L10N-20-OWNER-CLEANUP")
	for path: String in [malformed,empty,duplicate,quoted]:
		if not path.is_empty():
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("P4_LOCALIZATION_REPORT executed=",passed+failed," passed=",passed," failed=",failed)
	quit(1 if failed > 0 else 0)
