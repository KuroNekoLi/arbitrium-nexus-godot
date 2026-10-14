extends SceneTree
## M2.3 independent 12-SP / card-instance conservation / seeded draw / V2.
const Deck = preload("res://scripts/domain/m2/cards/deck_validator.gd")
const Zones = preload("res://scripts/domain/m2/cards/card_zone_resolver.gd")
const Draw = preload("res://scripts/domain/m2/cards/draw_resolver.gd")
const Profile = preload("res://scripts/domain/m2/persistence/deck_profile_v2.gd")
const SEED: int = 20261014
var passed: int = 0
var failed: int = 0

func _expect(case_id: String, ok: bool) -> void:
	if ok:
		passed += 1
		print("PASS ", case_id)
	else:
		failed += 1
		printerr("FAIL ", case_id)

func _contexts() -> Dictionary:
	return {
		"A": {"actor_id": "A", "variant_id": "default", "tags": ["mage"]},
		"B": {"actor_id": "B", "variant_id": "default", "tags": ["fighter"]},
		"C": {"actor_id": "C", "variant_id": "default", "tags": ["mage"]}
	}

func _definitions() -> Dictionary:
	return {
		"burst": {"id": "burst", "kind": "SP"},
		"react": {"id": "react", "kind": "SP", "reaction_trigger": "ATTACK"},
		"owner": {"id": "owner", "kind": "SP", "owner_actor_id": "A"},
		"variant": {"id": "variant", "kind": "SP", "allowed_variant_ids": ["special"]},
		"tag": {"id": "tag", "kind": "SP", "required_actor_tags": ["mage"]},
		"guard": {"id": "guard", "kind": "ACTION"},
		"last": {"id": "last", "kind": "LAST_SPELL"}
	}

func _loadouts() -> Dictionary:
	var decks: Dictionary = {}
	for actor_id: String in ["A", "B", "C"]:
		var cards: Array = []
		for i: int in range(12):
			cards.append("burst")
		decks[actor_id] = cards
	return decks

func _owned() -> Dictionary:
	return {"A": {"burst": 12, "react": 12, "owner": 12, "variant": 12, "tag": 12},
		"B": {"burst": 12, "react": 12, "owner": 12, "variant": 12, "tag": 12},
		"C": {"burst": 12, "react": 12, "owner": 12, "variant": 12, "tag": 12}}

func _start(seed_value: int = SEED) -> Dictionary:
	return Draw.start_battle(_loadouts(), _contexts(), _definitions(), _owned(), seed_value)

func _zone(state: Dictionary, actor_id: String, name: String) -> Array:
	return state["actors"][actor_id]["zones"][name]

func _move(state: Dictionary, actor_id: String, instance_id: String, from_zone: String, to_zone: String) -> Dictionary:
	return Zones.move(state, actor_id, instance_id, from_zone, to_zone)

func _init() -> void:
	var decks: Dictionary = _loadouts()
	var contexts: Dictionary = _contexts()
	var definitions: Dictionary = _definitions()
	var owned: Dictionary = _owned()
	_expect("PRE3-R16-EXACT_12", Deck.validate_party(decks, contexts, definitions, owned)["ok"])
	_expect("DECK-REPEATS_ALLOWED", Deck.validate_loadout(contexts["A"], decks["A"], definitions, owned["A"])["ok"])
	var fewer: Array = decks["A"].duplicate()
	fewer.pop_back()
	_expect("PRE3-R16-NO_AUTO_PADDING", Deck.validate_loadout(contexts["A"], fewer, definitions, owned["A"])["error"] == "LOADOUT_REQUIRES_EXACTLY_12_SP")
	var more: Array = decks["A"].duplicate()
	more.append("burst")
	_expect("DECK-REJECT_13", not Deck.validate_loadout(contexts["A"], more, definitions, owned["A"])["ok"])
	_expect("DECK-OWNERSHIP", Deck.validate_loadout(contexts["A"], decks["A"], definitions, {"burst": 11})["error"] == "INSUFFICIENT_OWNED_COPIES")
	_expect("DECK-CONFIGURED_COPY_LIMIT", Deck.validate_loadout(contexts["A"], decks["A"], definitions, owned["A"], {"max_copies_by_definition": {"burst": 2}})["error"] == "CONFIGURED_COPY_LIMIT")
	var changed: Array = decks["A"].duplicate()
	changed[0] = "owner"
	_expect("DECK-OWNER_ALLOW", Deck.validate_loadout(contexts["A"], changed, definitions, owned["A"])["ok"])
	_expect("DECK-OWNER_DENY", Deck.validate_loadout(contexts["B"], changed, definitions, owned["B"])["error"] == "ACTOR_INELIGIBLE")
	changed[0] = "variant"
	_expect("DECK-VARIANT_DENY", Deck.validate_loadout(contexts["A"], changed, definitions, owned["A"])["error"] == "VARIANT_INELIGIBLE")
	changed[0] = "tag"
	_expect("DECK-TAG_ALLOW", Deck.validate_loadout(contexts["A"], changed, definitions, owned["A"])["ok"])
	_expect("DECK-TAG_DENY", Deck.validate_loadout(contexts["B"], changed, definitions, owned["B"])["error"] == "TAG_INELIGIBLE")
	changed[0] = "guard"
	_expect("DECK-GUARD_NOT_SP", Deck.validate_loadout(contexts["A"], changed, definitions, owned["A"])["error"] == "NOT_A_VALID_SP")
	changed[0] = "last"
	_expect("DECK-LAST_SEPARATE", Deck.validate_loadout(contexts["A"], changed, definitions, owned["A"])["error"] == "NOT_A_VALID_SP")
	changed[0] = "react"
	_expect("DECK-REACTION_IS_SP", Deck.validate_loadout(contexts["A"], changed, definitions, owned["A"])["ok"])

	var created: Dictionary = _start()
	if not created["accepted"]:
		printerr("FAIL M2_3_SETUP ", created["error"])
		quit(1)
		return
	var s: Dictionary = created["state"]
	_expect("DECK-001", Zones.validate_state(s) and _zone(s, "A", "hand").size() == 4
		and _zone(s, "A", "draw").size() == 8 and _zone(s, "A", "discard").is_empty()
		and _zone(s, "B", "hand").size() == 4 and _zone(s, "C", "hand").size() == 4)
	var global_ids: Dictionary = {}
	for actor_id: String in ["A", "B", "C"]:
		for id: Variant in s["actors"][actor_id]["instances"]:
			global_ids[id] = true
	_expect("DECK-004-36_UNIQUE", global_ids.size() == 36)
	_expect("DECK-004-SAME_DEFINITION_DISTINCT",
		s["actors"]["A"]["instances"]["A:sp:00"]["definition_id"] == "burst"
		and s["actors"]["A"]["instances"]["A:sp:11"]["definition_id"] == "burst")
	var replay: Dictionary = _start()
	_expect("DECK-SEEDED_REPLAY", replay["accepted"] and JSON.stringify(replay["state"]) == JSON.stringify(s))
	var alternative_seed: Dictionary = _start(SEED + 1)
	_expect("DECK-SEED_TRACKED", alternative_seed["accepted"] and alternative_seed["state"]["seed"] != s["seed"])

	var first: Dictionary = _move(s, "A", str(_zone(s, "A", "hand")[0]), "hand", "discard")
	var second: Dictionary = _move(first["state"], "A", str(_zone(first["state"], "A", "hand")[0]), "hand", "discard")
	var refilled: Dictionary = Draw.draw_to_four(second["state"], "A")
	_expect("DECK-002", first["accepted"] and second["accepted"] and refilled["accepted"]
		and _zone(refilled["state"], "A", "hand").size() == 4
		and _zone(refilled["state"], "A", "discard").size() == 2
		and _zone(refilled["state"], "A", "draw").size() == 6
		and refilled["events"].size() == 2 and Zones.validate_state(refilled["state"]))
	var no_refill: Dictionary = Draw.draw_to_four(refilled["state"], "A")
	_expect("M25-HAND-001", no_refill["accepted"] and no_refill["events"].is_empty()
		and JSON.stringify(no_refill["state"]) == JSON.stringify(refilled["state"]))
	# Exact spec-13 M25-HAND-001 cases: 3 / 4 / 7 at phase boundary.
	var hand3: Dictionary = _move(s, "A", str(_zone(s, "A", "hand")[0]), "hand", "discard")
	var hand3_refill: Dictionary = Draw.draw_to_four(hand3["state"], "A")
	var hand7: Dictionary = Draw.draw_cards(s, "A", 3)
	var hand7_refill: Dictionary = Draw.draw_to_four(hand7["state"], "A")
	_expect("M25-HAND-001-THREE_FOUR_SEVEN", hand3["accepted"] and hand3_refill["accepted"]
		and hand3_refill["events"].size() == 1
		and _zone(hand3_refill["state"], "A", "hand").size() == 4
		and hand7["accepted"] and hand7_refill["accepted"]
		and hand7_refill["events"].is_empty() and _zone(hand7_refill["state"], "A", "hand").size() == 7)
	# Exact spec-13 PRE3-20: hand 7, request draw 3, take just 1.
	var cap_from7: Dictionary = Draw.draw_cards(hand7["state"], "A", 3)
	_expect("PRE3-20-CAP_SEVEN_REQUEST_THREE", cap_from7["accepted"]
		and cap_from7["events"].size() == 1 and _zone(cap_from7["state"], "A", "hand").size() == 8
		and _zone(cap_from7["state"], "A", "draw").size() == 4
		and Zones.validate_state(cap_from7["state"]))
	var extra: Dictionary = Draw.draw_cards(refilled["state"], "A", 10)
	_expect("M25-HAND-002", extra["accepted"] and _zone(extra["state"], "A", "hand").size() == 8
		and _zone(extra["state"], "A", "draw").size() == 2
		and extra["events"].size() == 4 and Zones.validate_state(extra["state"]))
	var capped: Dictionary = Draw.draw_cards(extra["state"], "A", 3)
	_expect("M25-HAND-002-CAP_NO_DRAW", capped["accepted"] and capped["events"].is_empty()
		and JSON.stringify(capped["state"]) == JSON.stringify(extra["state"]))
	var ninth: Dictionary = _move(extra["state"], "A", str(_zone(extra["state"], "A", "draw")[0]), "draw", "hand")
	_expect("M25-HAND-002-NINTH_REJECT", not ninth["accepted"] and ninth["error"] == "HAND_FULL"
		and JSON.stringify(ninth["state"]) == JSON.stringify(extra["state"]))
	var wrong_owner: Dictionary = _move(s, "B", "A:sp:00", "draw", "hand")
	_expect("DECK-004-OWNER_ATOMIC", not wrong_owner["accepted"] and wrong_owner["error"] == "INSTANCE_NOT_OWNED"
		and JSON.stringify(wrong_owner["state"]) == JSON.stringify(s))
	var wrong_source: Dictionary = _move(s, "A", str(_zone(s, "A", "hand")[0]), "discard", "hand")
	_expect("DECK-004-SOURCE_ATOMIC", not wrong_source["accepted"]
		and JSON.stringify(wrong_source["state"]) == JSON.stringify(s))
	var chanting: Dictionary = _move(s, "A", str(_zone(s, "A", "hand")[0]), "hand", "casting")
	_expect("PRE3-12-CASTING_ZONE", chanting["accepted"]
		and _zone(chanting["state"], "A", "casting").size() == 1 and Zones.validate_state(chanting["state"]))
	var resolved: Dictionary = _move(chanting["state"], "A", str(_zone(chanting["state"], "A", "casting")[0]), "casting", "discard")
	_expect("PRE3-12-RESOLVE_DISCARD", resolved["accepted"] and Zones.validate_state(resolved["state"]))

	# All nonhand cards are held by casting: no phantom redraw.
	var empty: Dictionary = s
	for i: int in range(2):
		var step: Dictionary = _move(empty, "A", str(_zone(empty, "A", "hand")[0]), "hand", "casting")
		empty = step["state"]
	for i: int in range(8):
		var step: Dictionary = _move(empty, "A", str(_zone(empty, "A", "draw")[0]), "draw", "casting")
		empty = step["state"]
	var no_supply: Dictionary = Draw.draw_to_four(empty, "A")
	_expect("DECK-004-EMPTY_POOL_NO_LOOP", no_supply["accepted"]
		and _zone(no_supply["state"], "A", "hand").size() == 2 and no_supply["events"].is_empty()
		and JSON.stringify(no_supply["state"]) == JSON.stringify(empty))
	var to_discard: Dictionary = empty
	for i: int in range(10):
		var step: Dictionary = _move(to_discard, "A", str(_zone(to_discard, "A", "casting")[0]), "casting", "discard")
		to_discard = step["state"]
	var shuffled: Dictionary = Draw.draw_to_four(to_discard, "A")
	var reshuffled: bool = false
	for event: Dictionary in shuffled["events"]:
		if event["kind"] == "DiscardReshuffled":
			reshuffled = true
	_expect("DECK-003-RESHUFFLE", shuffled["accepted"] and reshuffled and Zones.validate_state(shuffled["state"])
		and _zone(shuffled["state"], "A", "hand").size() == 4
		and _zone(shuffled["state"], "A", "draw").size() == 8
		and _zone(shuffled["state"], "A", "discard").is_empty())
	# Exact spec-13 DECK-003: draw 1 + discard 10 + hand 1.
	# Must draw the one remaining card, shuffle discard, then draw two.
	var mixed: Dictionary = s
	for i: int in range(3):
		var step: Dictionary = _move(mixed, "A", str(_zone(mixed, "A", "hand")[0]), "hand", "discard")
		mixed = step["state"]
	for i: int in range(7):
		var step: Dictionary = _move(mixed, "A", str(_zone(mixed, "A", "draw")[0]), "draw", "discard")
		mixed = step["state"]
	var mixed_before: bool = _zone(mixed, "A", "hand").size() == 1
		and _zone(mixed, "A", "draw").size() == 1 and _zone(mixed, "A", "discard").size() == 10
	var mixed_result: Dictionary = Draw.draw_to_four(mixed, "A")
	var drawn_count: int = 0
	var recycled_count: int = 0
	for event: Dictionary in mixed_result["events"]:
		if event["kind"] == "CardDrawn":
			drawn_count += 1
		if event["kind"] == "DiscardReshuffled":
			recycled_count += 1
	_expect("DECK-003-ONE_DRAW_TEN_DISCARD", mixed_before and mixed_result["accepted"]
		and drawn_count == 3 and recycled_count == 1
		and _zone(mixed_result["state"], "A", "hand").size() == 4
		and _zone(mixed_result["state"], "A", "draw").size() == 8
		and _zone(mixed_result["state"], "A", "discard").is_empty()
		and Zones.validate_state(mixed_result["state"]))
	var corrupted: Dictionary = s.duplicate(true)
	corrupted["actors"]["A"]["zones"]["hand"].append(corrupted["actors"]["A"]["zones"]["draw"][0])
	var refused: Dictionary = Draw.draw_cards(corrupted, "A", 1)
	_expect("DECK-004-DUPLICATE_REJECT", not Zones.validate_state(corrupted)
		and not refused["accepted"] and JSON.stringify(refused["state"]) == JSON.stringify(corrupted))
	var missing: Dictionary = s.duplicate(true)
	missing["actors"]["A"]["zones"]["draw"].pop_back()
	_expect("DECK-004-MISSING_REJECT", not Zones.validate_state(missing))
	var isolated: Dictionary = _move(s, "A", str(_zone(s, "A", "hand")[0]), "hand", "isolated")
	_expect("DECK-004-ISOLATED", isolated["accepted"] and Zones.validate_state(isolated["state"]))

	var legacy: Dictionary = {"version": 1, "decks": {
		"A": ["a", "b", "c", "d", "e", "f", "g", "h"],
		"B": ["a", "b", "c", "d", "e", "f", "g", "h"],
		"C": ["a", "b", "c", "d", "e", "f", "g", "h"]}}
	var original_text: String = JSON.stringify(legacy)
	var inspected: Dictionary = Profile.inspect_profile(legacy)
	_expect("M2_3-PERSIST-LEGACY_RECOGNIZED", inspected["status"] == "LEGACY_RECONFIGURATION_REQUIRED"
		and JSON.stringify(inspected["original"]) == original_text)
	_expect("PRE3-R16-LEGACY_NOT_READY", not Profile.validate_for_battle(legacy, contexts, definitions, owned)["ok"])
	var v2: Dictionary = {"version": 2, "loadouts": {}}
	for actor_id: String in ["A", "B", "C"]:
		v2["loadouts"][actor_id] = {"variant_id": "default", "cards": decks[actor_id].duplicate()}
	_expect("M2_3-PERSIST-V2_VALID", Profile.validate_for_battle(v2, contexts, definitions, owned)["ok"])
	var invalid_v2: Dictionary = v2.duplicate(true)
	invalid_v2["loadouts"]["A"]["cards"].pop_back()
	_expect("PRE3-R16-V2_NO_PADDING", not Profile.validate_for_battle(invalid_v2, contexts, definitions, owned)["ok"])
	var wrong_variant: Dictionary = v2.duplicate(true)
	wrong_variant["loadouts"]["A"]["variant_id"] = "special"
	_expect("M2_3-PERSIST-VARIANT_REVALIDATED", Profile.validate_for_battle(wrong_variant, contexts, definitions, owned)["error"] == "VARIANT_CHANGED_REVALIDATE")
	_test_files(v2, legacy, contexts, definitions, owned)
	_expect("M2_3_EVENT_SEQUENCING", int(shuffled["state"]["event_seq"]) == shuffled["state"]["events"].size())
	print("M2_3_TEST_REPORT executed=", passed + failed, " passed=", passed, " failed=", failed, " seed=", SEED)
	if failed == 0:
		print("M2_3_CARD_DOMAIN_VERIFIED")
	quit(0 if failed == 0 else 1)

func _test_files(v2: Dictionary, legacy: Dictionary, contexts: Dictionary,
		definitions: Dictionary, owned: Dictionary) -> void:
	var v2_path: String = "user://m2_3_test_v2.json"
	var v1_path: String = "user://m2_3_test_v1.json"
	var source := FileAccess.open(v1_path, FileAccess.WRITE)
	if source == null:
		_expect("M2_3-PERSIST-DISK_SETUP", false)
		return
	var original: String = JSON.stringify(legacy)
	source.store_string(original)
	source.close()
	var saved: Dictionary = Profile.save_profile(v2, contexts, definitions, owned, v2_path)
	var loaded: Dictionary = Profile.load_profile(v2_path)
	# JSON round-trip sorts Dictionary keys and may parse 2 as 2.0.
	# Check real schema fields/ordered card IDs rather than raw key order.
	var equivalent: bool = loaded["status"] == "V2_CANDIDATE"
	if equivalent:
		var restored: Dictionary = loaded["original"]
		equivalent = int(restored.get("version", -1)) == 2
		if not restored.get("loadouts", null) is Dictionary:
			equivalent = false
		else:
			var saved_loadouts: Dictionary = restored["loadouts"]
			for actor_id: String in ["A", "B", "C"]:
				if not saved_loadouts.has(actor_id) or not saved_loadouts[actor_id] is Dictionary:
					equivalent = false
					break
				var restored_actor: Dictionary = saved_loadouts[actor_id]
				if str(restored_actor.get("variant_id", "")) != "default" or not restored_actor.get("cards", null) is Array:
					equivalent = false
					break
				if restored_actor["cards"] != v2["loadouts"][actor_id]["cards"]:
					equivalent = false
					break
	_expect("M2_3-PERSIST-V2_SAVE_LOAD", saved["saved"] and equivalent)
	_expect("M2_3-PERSIST-LEGACY_BYTES_UNCHANGED", FileAccess.get_file_as_string(v1_path) == original)
	var legacy_save: Dictionary = Profile.save_profile(legacy, contexts, definitions, owned, v2_path)
	_expect("M2_3-PERSIST-LEGACY_SAVE_REJECT", not legacy_save["saved"])
	var invalid: Dictionary = v2.duplicate(true)
	invalid["loadouts"]["B"]["cards"].pop_back()
	var refused: Dictionary = Profile.save_profile(invalid, contexts, definitions, owned, v2_path)
	_expect("M2_3-PERSIST-INVALID_CANNOT_OVERWRITE", not refused["saved"]
		and Profile.load_profile(v2_path)["status"] == "V2_CANDIDATE")
