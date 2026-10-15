extends SceneTree
## Fresh-process component contract: do not rely on BattleScreen initialization.
const Roster = preload("res://scenes/ui/hero_roster_item.tscn")
const Translations = preload("res://scripts/battle/presentation/battle_translations.gd")
var executed: int = 0
var failed: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, id: String) -> void:
	executed += 1
	if not ok:
		failed += 1
	print(("PASS " if ok else "FAIL ") + id)

func run() -> void:
	check(not Translations.installed, "V34-LEGACY-FRESH-CATALOGUES")
	var hero: Button = Roster.instantiate()
	root.add_child(hero)
	await process_frame
	check(Translations.owned_count() == 2, "V34-LEGACY-CATALOGUES-INSTALLED")
	for locale: String in ["en", "zh_TW"]:
		TranslationServer.set_locale(locale)
		hero.update_status(73, 100, 6, 10, 8)
		check(hero.hp_label.text == hero.tr("BATTLE_HP") % [73, 100], "V34-LEGACY-HP-" + locale)
		check(hero.mana_label.text == hero.tr("BATTLE_MP") % [6, 10], "V34-LEGACY-MP-" + locale)
		check(not hero.mana_label.text.contains("手牌") and not hero.mana_label.text.contains("Hand"),
			"V34-LEGACY-NO-HAND-COUNTER-" + locale)
		check(hero.hp_bar.value == 73 and hero.hp_bar.max_value == 100, "V34-LEGACY-HP-BAR-" + locale)
		check(hero.mana_bar.value == 6 and hero.mana_bar.max_value == 10, "V34-LEGACY-MP-BAR-" + locale)
		hero.update_status(0, 0, 0, 0, 0)
		check(hero.hp_bar.max_value == 1 and hero.mana_bar.max_value == 1 and
			hero.hp_bar.value == 0 and hero.mana_bar.value == 0, "V34-LEGACY-ZERO-BARS-" + locale)
		check(hero.hp_label.text == hero.tr("BATTLE_HP") % [0, 0], "V34-LEGACY-ZERO-TEXT-" + locale)
	var previous: WeakRef = weakref(hero.hp_bar)
	hero.queue_free()
	await process_frame
	hero = Roster.instantiate()
	root.add_child(hero)
	await process_frame
	check(previous.get_ref() == null and hero.hp_bar != null, "V34-LEGACY-REENTRY-RESOURCE-LIFETIME")
	check(Translations.owned_count() == 2, "V34-LEGACY-IDEMPOTENT-CATALOGUES")
	hero.queue_free()
	await process_frame
	print("V34_LEGACY_ROSTER_REPORT executed=%d passed=%d failed=%d" % [executed, executed - failed, failed])
	quit(0 if failed == 0 else 1)
