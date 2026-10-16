extends SceneTree
## Current combat smoke: only the 12-SP M2–M5 and Lv40 content path is allowed.
const Roster = preload("res://scripts/domain/m5/lv40/lv40_party_catalog.gd")
const Encounter = preload("res://scripts/domain/m5/lv40/lv40_encounter.gd")
const Zones = preload("res://scripts/domain/m2/cards/card_zone_resolver.gd")
const Model = preload("res://scripts/domain/m1/combat_model.gd")
var tested: int = 0
var failed: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, reason: String) -> void:
	tested += 1
	if not value:
		failed += 1
		printerr("FAIL ", reason)

func _run() -> void:
	var data: Dictionary = Roster.read()
	check(not data.is_empty(), "ROSTER-DATA-LOADED")
	if data.is_empty():
		quit(1)
		return
	var ids: Array[String] = Roster.party_ids(data)
	check(ids.size() == 3, "ROSTER-THREE-SLOTS")
	check(Zones.HAND_CAP == 8 and Zones.EXPECTED_CARDS == 12 and Roster.DECK_SIZE == 12,
		"ROSTER-12-DECK-8-HAND-CANON")
	var loadouts: Dictionary = Roster.loadouts(data)
	var chars: Dictionary = Roster.characters(data)
	var variants: Dictionary = Roster.variants(data)
	var content: Dictionary = Encounter.config()
	check(content.get("m5_lv40_enabled", false), "ROSTER-ACTIVE-LV40-CONFIG")
	for actor: String in ids:
		check(loadouts[actor].size() == 12, "ROSTER-12-"+actor)
		check(not chars[actor].is_empty() and not variants[actor].is_empty(),
			"ROSTER-IDENTITY-"+actor)
		check(str(content["lv40_actor_definitions"][actor]["character_id"]) == str(chars[actor]),
			"ROSTER-NO-HARDCODED-CHARACTERS-"+actor)
		check(str(content["actor_name_keys"][actor]) == str(data["actors"][actor]["name_key"]),
			"ROSTER-I18N-KEY-"+actor)
	var state: Dictionary = Encounter.initial(20261014)
	check(not state.is_empty(), "ROSTER-INITIAL-BATTLE")
	if not state.is_empty():
		check(Zones.validate_state(state["core"]["cards"]), "ROSTER-VALID-DOMAIN-ZONES")
		for actor: String in ids:
			var own: Dictionary = state["core"]["cards"]["actors"][actor]
			check(own["instances"].size() == 12 and own["zones"]["hand"].size() == 4,
				"ROSTER-OPENING-HAND-4-"+actor)
		check(Model.state_hash(state) == Model.state_hash(Encounter.initial(20261014)),
			"ROSTER-DETERMINISTIC-SEED")
	var swapped: Dictionary = data.duplicate(true)
	var first: String = ids[0]
	swapped["actors"][first]["character_id"] = "future_person"
	swapped["actors"][first]["variant_id"] = "future_variant"
	swapped["actors"][first]["name_key"] = "actor.future.name"
	var path: String = "user://replacement_roster_smoke.json"
	var output: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	check(output != null, "ROSTER-TEMP-WRITABLE")
	if output != null:
		output.store_string(JSON.stringify(swapped))
		output.flush()
		output.close()
		var parsed: Dictionary = Roster.read(path)
		check(not parsed.is_empty() and Roster.characters(parsed)[first] == "future_person" and
			Roster.variants(parsed)[first] == "future_variant" and
			str(parsed["actors"][first]["name_key"]) == "actor.future.name",
			"ROSTER-SWAP-IDENTITY-WITHOUT-CODE")
		check(Roster.loadouts(parsed)[first] == loadouts[first],
			"ROSTER-SWAP-PRESERVES-12-CARD-LOADOUT")
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("CURRENT_ROSTER_REPORT executed=%d passed=%d failed=%d" % [tested, tested-failed, failed])
	quit(0 if failed == 0 else 1)
