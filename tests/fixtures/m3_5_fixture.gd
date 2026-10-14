extends RefCounted
## M3.5 TEST FIXTURE ONLY. Provisional MP/AP and synthetic Reaction
## cancellation are not content-approval or real M4/M5 combat.
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const Draw = preload("res://scripts/domain/m2/cards/draw_resolver.gd")
const M2 = preload("res://scripts/domain/m2/integration/m2_domain_resolver.gd")
const Domain = preload("res://scripts/domain/m3/integration/m3_domain_resolver.gd")
const SEED: int = 20261014

static func config() -> Dictionary:
	return {"resources": {"authority": "BALANCE_PROVISIONAL",
		"ruleset_version": Model.RULESET_VERSION,
		"basic_attack_ap_cost": 1, "basic_attack_mp_gain": 2},
		"reaction_definitions": {
			"counter": {"kind": "REACTION_SP", "reaction_trigger": "ENEMY_ACTION",
				"rp_cost": 1, "mp_cost": 2, "fixture_effect": "CANCEL_ACTION_FIXTURE",
				"target_scope": "ANY", "requires_active_enemy_action": true},
			"support": {"kind": "REACTION_SP", "reaction_trigger": "ENEMY_ACTION",
				"rp_cost": 1, "mp_cost": 1, "fixture_effect": "INDEPENDENT_SUPPORT_FIXTURE",
				"target_scope": "ANY", "requires_active_enemy_action": false}
		}, "trigger_rules": []}

static func intents() -> Array:
	return [
		{"intent_id": "countered", "enemy_id": "Boss",
			"action_order": 1, "created_seq": 10, "publicly_declared": true,
			"target_scope": "SINGLE", "target_ids": ["A"], "hit_count": 1,
			"damage_type": "MAGICAL", "requires_reaction_window": true},
		{"intent_id": "triple", "enemy_id": "Boss",
			"action_order": 2, "created_seq": 11, "publicly_declared": true,
			"target_scope": "SINGLE", "target_ids": ["A"], "hit_count": 3,
			"damage_type": "PHYSICAL", "requires_reaction_window": true},
		{"intent_id": "aoe", "enemy_id": "Boss",
			"action_order": 3, "created_seq": 12, "publicly_declared": true,
			"target_scope": "AOE", "target_ids": ["A", "B", "C"], "hit_count": 2,
			"damage_type": "MAGICAL", "requires_reaction_window": true},
		{"intent_id": "empty", "enemy_id": "Boss",
			"action_order": 4, "created_seq": 13, "publicly_declared": true,
			"target_scope": "SINGLE", "target_ids": ["A"], "hit_count": 1,
			"damage_type": "PHYSICAL", "requires_reaction_window": true}
	]

static func make(seed_value: int = SEED) -> Dictionary:
	var loadouts: Dictionary = {}
	var contexts: Dictionary = {}
	var owned: Dictionary = {}
	var defs: Dictionary = {"counter": {"id": "counter", "kind": "SP"},
		"support": {"id": "support", "kind": "SP"},
		"ordinary": {"id": "ordinary", "kind": "SP"}}
	for actor: String in ["A", "B", "C"]:
		var definition: String = "counter" if actor == "A" else ("support" if actor == "C" else "ordinary")
		var cards: Array = []
		for i: int in range(12):
			cards.append(definition)
		loadouts[actor] = cards
		contexts[actor] = {"actor_id": actor, "variant_id": "default", "tags": []}
		owned[actor] = {definition: 12}
	var deal: Dictionary = Draw.start_battle(loadouts, contexts, defs, owned, seed_value)
	if not deal["accepted"]:
		return {}
	var battle: Dictionary = Model.make_state(["A", "B", "C"], ["Boss"], seed_value)
	for actor: String in ["A", "B", "C"]:
		battle["actors"][actor]["mp"] = 8
		battle["actors"][actor]["max_mp"] = 10
	return Domain.make_state(M2.make_state(battle, deal["state"]), intents())

static func command(state: Dictionary, kind: String, identifier: String,
		fields: Dictionary = {}) -> Dictionary:
	var request: Dictionary = {"type": kind, "command_id": identifier,
		"expected_event_seq": int(state["event_seq"])}
	for key: Variant in fields:
		request[key] = fields[key]
	return request

static func entry(kind: String, actor: String, target: String,
		state: Dictionary = {}) -> Dictionary:
	var item: Dictionary = {"kind": kind, "actor_id": actor,
		"target_actor_id": target}
	if kind == "REACTION_SP_FIXTURE" and not state.is_empty():
		item["card_instance_id"] = str(state["core"]["cards"]["actors"][actor]["zones"]["hand"][0])
	return item
