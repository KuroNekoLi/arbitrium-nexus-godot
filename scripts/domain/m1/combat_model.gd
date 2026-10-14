extends RefCounted
## PH3-M1-STATE: pure snapshot/domain shape; no Nodes/Resources/Scenes/clock.
## This is only an M1 scaffold; HP=100 and max_mp=0 are FIXTURE_ONLY, not game balance.
const Rng = preload("res://scripts/domain/m1/combat_rng.gd")
const RULESET_VERSION: String = "arbitrium-phase3-m1-v1"
const CONTENT_VERSION: String = "m1-placeholder-content-v1"

static func make_state(ally_ids: Array[String], enemy_ids: Array[String], seed_value: int) -> Dictionary:
	if ally_ids.is_empty() or enemy_ids.is_empty():
		return {}
	if ally_ids.size() != 3:
		return {}
	var used: Array[String] = []
	for candidate_id: String in ally_ids + enemy_ids:
		if candidate_id.strip_edges().is_empty() or used.has(candidate_id):
			return {}
		used.append(candidate_id)
	var actors: Dictionary = {}
	for ally_id: String in ally_ids:
		actors[ally_id] = _actor_fixture(ally_id, "ALLY")
	for enemy_id: String in enemy_ids:
		actors[enemy_id] = _actor_fixture(enemy_id, "ENEMY")
	return {
		"ruleset_version": RULESET_VERSION,
		"content_version": CONTENT_VERSION,
		"rng": Rng.initial_state(seed_value),
		"seed": seed_value,
		"round": 1,
		"phase": "PLAYER_PHASE",
		"outcome": "ONGOING",
		"selected_actor_id": "",
		"action_seq": 0,
		"event_seq": 0,
		"seen_command_ids": [],
		"party_resources": {"base_ap": 6, "current_ap": 6, "rp": 0, "rp_cap": 6, "ap_debt": 0},
		"allies": ally_ids.duplicate(),
		"enemies": enemy_ids.duplicate(),
		"actors": actors,
		"events": [],
		"casting_instances": {},
		"pending_enemy_actions": [],
		"reaction_queue": [],
		"combo_opportunities": [],
		"statuses": []
	}

static func _actor_fixture(actor_id: String, team: String) -> Dictionary:
	return {"id": actor_id, "team": team, "hp": 100, "max_hp": 100,
		"mp": 0, "max_mp": 0, "status": "ACTIVE",
		"statuses": [], "card_zones": {"draw": [], "hand": [], "discard": [], "casting": []}}

static func snapshot(state: Dictionary) -> Dictionary:
	return state.duplicate(true)

static func canonical(value: Variant) -> String:
	if value is Dictionary:
		var dictionary: Dictionary = value
		var keys: Array = dictionary.keys()
		keys.sort()
		var entries: Array[String] = []
		for key: Variant in keys:
			entries.append(JSON.stringify(str(key)) + ":" + canonical(dictionary[key]))
		return "{" + ",".join(entries) + "}"
	if value is Array:
		var elements: Array[String] = []
		for element: Variant in value:
			elements.append(canonical(element))
		return "[" + ",".join(elements) + "]"
	return JSON.stringify(value)

static func state_hash(state: Dictionary) -> String:
	return canonical(state).sha256_text()

static func event_hash(events: Array) -> String:
	return canonical(events).sha256_text()

static func validate_shell(state: Dictionary) -> bool:
	if state.get("ruleset_version", "") != RULESET_VERSION:
		return false
	if state.get("content_version", "") != CONTENT_VERSION:
		return false
	if not state.has("actors") or not state["actors"] is Dictionary:
		return false
	if not state.has("allies") or not state["allies"] is Array:
		return false
	if not state.has("seen_command_ids") or not state["seen_command_ids"] is Array:
		return false
	if not state.has("rng") or not state["rng"] is Dictionary:
		return false
	if state["rng"].get("algorithm", "") != Rng.ALGORITHM:
		return false
	if int(state["rng"].get("draw_index", -1)) < 0:
		return false
	if int(state.get("event_seq", -1)) < 0 or int(state.get("action_seq", -1)) < 0:
		return false
	if not state.has("party_resources") or not state["party_resources"] is Dictionary:
		return false
	var resources: Dictionary = state["party_resources"]
	for key: String in ["base_ap", "current_ap", "rp", "rp_cap", "ap_debt"]:
		if int(resources.get(key, -1)) < 0:
			return false
	return true
