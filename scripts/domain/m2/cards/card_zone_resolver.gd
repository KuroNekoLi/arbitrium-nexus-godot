extends RefCounted
## Card-instance conservation boundary for the independent M2.3 domain.
## Draw/Hand/Discard/Casting/Isolated are the ONLY registered zones.
## Isolated is reserved for M2.4 swap and never draws or reshuffles.
const CardInstance = preload("res://scripts/domain/m2/cards/card_instance.gd")
const DeckValidator = preload("res://scripts/domain/m2/cards/deck_validator.gd")
const ZONES: Array[String] = ["draw", "hand", "discard", "casting", "isolated"]
const HAND_CAP: int = 8
const EXPECTED_CARDS: int = 12
const SCHEMA: String = "m2.3-zones-v1"

static func rejected(state: Dictionary, reason: String) -> Dictionary:
	return {"accepted": false, "error": reason, "state": state.duplicate(true), "events": []}

static func accepted(state: Dictionary, events: Array = []) -> Dictionary:
	return {"accepted": true, "error": "", "state": state, "events": events}

static func emit(state: Dictionary, kind: String, actor_id: String, details: Dictionary = {}) -> Dictionary:
	state["event_seq"] = int(state["event_seq"]) + 1
	var event: Dictionary = {"event_seq": int(state["event_seq"]), "kind": kind,
		"actor_id": actor_id, "details": details}
	state["events"].append(event)
	return event

static func create_party(loadouts: Dictionary, contexts: Dictionary, definitions: Dictionary,
		ownership: Dictionary, seed_value: int, deck_rules: Dictionary = {}) -> Dictionary:
	var validation: Dictionary = DeckValidator.validate_party(loadouts, contexts, definitions, ownership, deck_rules)
	if not validation["ok"]:
		return rejected({}, str(validation["error"]))
	var actors: Dictionary = {}
	var ids: Array = loadouts.keys()
	ids.sort()
	for key: Variant in ids:
		var actor_id: String = str(key)
		var instances: Dictionary = CardInstance.create_loadout(actor_id, loadouts[actor_id])
		if instances.size() != EXPECTED_CARDS:
			return rejected({}, "FAILED_TO_CREATE_INSTANCES")
		var ordered_ids: Array = []
		for i: int in range(EXPECTED_CARDS):
			ordered_ids.append(actor_id + ":sp:" + str(i).pad_zeros(2))
		actors[actor_id] = {"instances": instances,
			"zones": {"draw": ordered_ids, "hand": [], "discard": [], "casting": [], "isolated": []}}
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var state: Dictionary = {"schema_version": SCHEMA, "seed": seed_value,
		"rng_state": rng.state, "actors": actors, "event_seq": 0, "events": []}
	if not validate_state(state):
		return rejected({}, "INVALID_INITIAL_ZONES")
	return accepted(state)

static func validate_state(state: Dictionary) -> bool:
	if str(state.get("schema_version", "")) != SCHEMA:
		return false
	if not state.has("actors") or not state["actors"] is Dictionary or state["actors"].size() != 3:
		return false
	if not state.get("events", null) is Array or not state.get("event_seq", null) is int:
		return false
	if not state.get("rng_state", null) is int or not state.get("seed", null) is int:
		return false
	var global_ids: Dictionary = {}
	for actor_key: Variant in state["actors"]:
		var actor_id: String = str(actor_key)
		var actor: Variant = state["actors"][actor_key]
		if actor_id.strip_edges().is_empty() or not actor is Dictionary:
			return false
		if not actor.get("instances", null) is Dictionary or not actor.get("zones", null) is Dictionary:
			return false
		var instances: Dictionary = actor["instances"]
		var zones: Dictionary = actor["zones"]
		if instances.size() != EXPECTED_CARDS or zones.size() != ZONES.size():
			return false
		if not zones.has("hand") or not zones["hand"] is Array or zones["hand"].size() > HAND_CAP:
			return false
		var seen: Dictionary = {}
		for zone: String in ZONES:
			if not zones.has(zone) or not zones[zone] is Array:
				return false
			for card_id: Variant in zones[zone]:
				if not card_id is String or seen.has(card_id) or not instances.has(card_id):
					return false
				seen[card_id] = zone
		if seen.size() != EXPECTED_CARDS:
			return false
		for card_key: Variant in instances:
			if not card_key is String or global_ids.has(card_key):
				return false
			global_ids[card_key] = true
			var instance: Variant = instances[card_key]
			if not instance is Dictionary or str(instance.get("instance_id", "")) != str(card_key):
				return false
			if str(instance.get("owner_actor_id", "")) != actor_id:
				return false
			if not seen.has(card_key) or str(instance.get("definition_id", "")).is_empty():
				return false
	return global_ids.size() == EXPECTED_CARDS * 3

static func location(state: Dictionary, actor_id: String, instance_id: String) -> String:
	if not state.get("actors", {}).has(actor_id):
		return ""
	var actor: Dictionary = state["actors"][actor_id]
	for zone: String in ZONES:
		if actor["zones"][zone].has(instance_id):
			return zone
	return ""

static func move(state: Dictionary, actor_id: String, instance_id: String, from_zone: String,
		to_zone: String, event_kind: String = "CardZoneChanged") -> Dictionary:
	if not validate_state(state):
		return rejected(state, "INVALID_ZONE_STATE")
	if not state["actors"].has(actor_id) or not ZONES.has(from_zone) or not ZONES.has(to_zone):
		return rejected(state, "INVALID_ZONE_OPERATION")
	if from_zone == to_zone:
		return rejected(state, "SAME_ZONE")
	var actor: Dictionary = state["actors"][actor_id]
	if not actor["instances"].has(instance_id):
		return rejected(state, "INSTANCE_NOT_OWNED")
	if not actor["zones"][from_zone].has(instance_id):
		return rejected(state, "INSTANCE_NOT_IN_SOURCE")
	if to_zone == "hand" and actor["zones"]["hand"].size() >= HAND_CAP:
		return rejected(state, "HAND_FULL")
	var next_state: Dictionary = state.duplicate(true)
	next_state["actors"][actor_id]["zones"][from_zone].erase(instance_id)
	next_state["actors"][actor_id]["zones"][to_zone].append(instance_id)
	if not validate_state(next_state):
		return rejected(state, "ZONE_CONSERVATION_VIOLATION")
	var event: Dictionary = emit(next_state, event_kind, actor_id, {"instance_id": instance_id,
		"from_zone": from_zone, "to_zone": to_zone})
	return accepted(next_state, [event])
