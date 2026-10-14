extends RefCounted
## M2.3 seeded Fisher-Yates; RNG state travels WITH the immutable zone
## snapshot. Only Draw and Discard enter the reshuffle pool; never Casting.
const Zones = preload("res://scripts/domain/m2/cards/card_zone_resolver.gd")
const TARGET_HAND: int = 4

static func _shuffle_zone(state: Dictionary, actor_id: String) -> void:
	var cards: Array = state["actors"][actor_id]["zones"]["draw"]
	var rng := RandomNumberGenerator.new()
	rng.state = int(state["rng_state"])
	for i: int in range(cards.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var temporary: Variant = cards[i]
		cards[i] = cards[j]
		cards[j] = temporary
	state["rng_state"] = rng.state
	Zones.emit(state, "DeckShuffled", actor_id, {"draw_count": cards.size()})

static func _recycle_discard(state: Dictionary, actor_id: String) -> bool:
	var zones: Dictionary = state["actors"][actor_id]["zones"]
	if not zones["draw"].is_empty() or zones["discard"].is_empty():
		return false
	var old_discard: Array = zones["discard"].duplicate()
	zones["discard"].clear()
	zones["draw"].append_array(old_discard)
	_shuffle_zone(state, actor_id)
	Zones.emit(state, "DiscardReshuffled", actor_id, {"count": old_discard.size()})
	return true

static func draw_cards(state: Dictionary, actor_id: String, requested: int) -> Dictionary:
	if not Zones.validate_state(state):
		return Zones.rejected(state, "INVALID_ZONE_STATE")
	if not state["actors"].has(actor_id) or requested < 0:
		return Zones.rejected(state, "INVALID_DRAW_REQUEST")
	var next_state: Dictionary = state.duplicate(true)
	var emitted: Array = []
	var capacity: int = Zones.HAND_CAP - next_state["actors"][actor_id]["zones"]["hand"].size()
	for _i: int in range(min(requested, capacity)):
		var zones: Dictionary = next_state["actors"][actor_id]["zones"]
		if zones["draw"].is_empty():
			if zones["discard"].is_empty():
				break
			var previous_event_seq: int = int(next_state["event_seq"])
			if not _recycle_discard(next_state, actor_id):
				break
			for event: Dictionary in next_state["events"]:
				if int(event["event_seq"]) > previous_event_seq:
					emitted.append(event)
		var draw_zone: Array = next_state["actors"][actor_id]["zones"]["draw"]
		if draw_zone.is_empty():
			break
		var card_id: String = str(draw_zone[draw_zone.size() - 1])
		var moved: Dictionary = Zones.move(next_state, actor_id, card_id, "draw", "hand", "CardDrawn")
		if not moved["accepted"]:
			return Zones.rejected(state, str(moved["error"]))
		next_state = moved["state"]
		emitted.append_array(moved["events"])
	if not Zones.validate_state(next_state):
		return Zones.rejected(state, "ZONE_CONSERVATION_VIOLATION")
	return Zones.accepted(next_state, emitted)

static func draw_to_four(state: Dictionary, actor_id: String) -> Dictionary:
	if not Zones.validate_state(state) or not state["actors"].has(actor_id):
		return Zones.rejected(state, "INVALID_ZONE_STATE_OR_ACTOR")
	var missing: int = max(0, TARGET_HAND - state["actors"][actor_id]["zones"]["hand"].size())
	return draw_cards(state, actor_id, missing)

static func start_battle(loadouts: Dictionary, contexts: Dictionary, definitions: Dictionary,
		ownership: Dictionary, seed_value: int, deck_rules: Dictionary = {}) -> Dictionary:
	var created: Dictionary = Zones.create_party(loadouts, contexts, definitions, ownership,
		seed_value, deck_rules)
	if not created["accepted"]:
		return created
	var state: Dictionary = created["state"]
	var log: Array = []
	var ids: Array = state["actors"].keys()
	ids.sort()
	for actor_key: Variant in ids:
		var actor_id: String = str(actor_key)
		_shuffle_zone(state, actor_id)
		log.append(state["events"][-1])
		var drawn: Dictionary = draw_cards(state, actor_id, TARGET_HAND)
		if not drawn["accepted"]:
			return Zones.rejected({}, str(drawn["error"]))
		state = drawn["state"]
		log.append_array(drawn["events"])
	return Zones.accepted(state, log)
