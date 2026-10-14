extends SceneTree
## M4.1 CAST-001..003, M21-CAST-001. Headless domain fixture, not damage.
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const Draw = preload("res://scripts/domain/m2/cards/draw_resolver.gd")
const Zones = preload("res://scripts/domain/m2/cards/card_zone_resolver.gd")
const M2 = preload("res://scripts/domain/m2/integration/m2_domain_resolver.gd")
const Phase = preload("res://scripts/domain/m3/phase/phase_engine.gd")
const Casting = preload("res://scripts/domain/m4/integration/m4_domain_resolver.gd")
const Instance = preload("res://scripts/domain/m4/casting/casting_instance_resolver.gd")
const SEED: int = 20261014
var passed: int = 0
var failed: int = 0
var config: Dictionary = {}

func _yes(id: String, value: bool) -> void:
	if value:
		passed += 1
		print("PASS ", id)
	else:
		failed += 1
		printerr("FAIL ", id)

func _config() -> Dictionary:
	var c: Variant = JSON.parse_string(FileAccess.get_file_as_string(
		"res://resources/combat/rulesets/m2_2_provisional_costs.json"))
	var r: Variant = JSON.parse_string(FileAccess.get_file_as_string(
		"res://resources/combat/rulesets/m2_1_provisional_resources.json"))
	if not c is Dictionary or not r is Dictionary:
		return {}
	var resources: Dictionary = c.duplicate(true)
	resources["basic_attack_ap_cost"] = int(r["basic_attack_ap_cost"])
	resources["basic_attack_mp_gain"] = int(r["basic_attack_mp_gain"])
	return {"costs": c, "resources": resources,
		"definitions": {"spell": {"card_id": "spell", "ap_cost": 1, "mp_cost": 2}},
		"casting_profiles": {"spell": {"spell_id": "spell",
			"allowed_modes": ["CHANTLESS", "FULL"], "base_stability": 10}},
		"m4_dual_cast_enabled": true,
		"reaction_definitions": {}, "trigger_rules": []}

func _initial(seed: int = SEED) -> Dictionary:
	var decks: Dictionary = {}
	var contexts: Dictionary = {}
	var owned: Dictionary = {}
	for actor: String in ["A", "B", "C"]:
		var cards: Array = []
		for i: int in range(12):
			cards.append("spell")
		decks[actor] = cards
		contexts[actor] = {"actor_id": actor, "variant_id": "default", "tags": []}
		owned[actor] = {"spell": 12}
	var drawn: Dictionary = Draw.start_battle(decks, contexts,
		{"spell": {"id": "spell", "kind": "SP"}}, owned, seed)
	if not drawn["accepted"]:
		return {}
	var battle: Dictionary = Model.make_state(["A","B","C"],["Boss"],seed)
	for actor: String in ["A","B","C"]:
		battle["actors"][actor]["mp"] = 8
		battle["actors"][actor]["max_mp"] = 10
	return Phase.make_state(M2.make_state(battle, drawn["state"]), [])

func _cmd(s: Dictionary, kind: String, id: String, args: Dictionary = {}) -> Dictionary:
	var c: Dictionary = {"type": kind, "command_id": id,
		"expected_event_seq": int(s["event_seq"])}
	for key: Variant in args:
		c[key] = args[key]
	return c

func _apply(s: Dictionary, kind: String, id: String, args: Dictionary = {},
		cfg: Dictionary = {}) -> Dictionary:
	return Casting.apply(s, _cmd(s,kind,id,args), config if cfg.is_empty() else cfg)

func _card(s: Dictionary, actor: String, slot: int = 0) -> String:
	return str(s["core"]["cards"]["actors"][actor]["zones"]["hand"][slot])

func _spell(s: Dictionary, actor: String, mode: String = "FULL", slot: int = 0) -> Dictionary:
	return {"actor_id": actor, "casting_mode": mode,
		"card_instance_id": _card(s,actor,slot), "target_actor_id": "Boss"}

func _reject(r: Dictionary, s: Dictionary, err: String) -> bool:
	return not r["accepted"] and str(r["error"]) == err and r["events"].is_empty() \
		and Model.state_hash(r["state"]) == Model.state_hash(s)

func _idx(events: Array, kind: String) -> int:
	for i: int in range(events.size()):
		if str(events[i]["kind"]) == kind:
			return i
	return -1

func _init() -> void:
	config = _config()
	var s: Dictionary = _initial()
	if config.is_empty() or s.is_empty():
		printerr("M4_1_FIXTURE_INVALID")
		quit(1)
		return
	var before_hash: String = Model.state_hash(s)
	var pre_rng: String = Model.state_hash(s["core"]["battle"]["rng"])
	var chant: Dictionary = _apply(s,"CAST_SPELL_M4","chant-A",_spell(s,"A","CHANTLESS"))
	var a: Dictionary = chant["state"]
	_yes("CAST-001-CHANTLESS_ACCEPTED", chant["accepted"])
	_yes("CAST-001-CARD_IN_DISCARD", a["core"]["cards"]["actors"]["A"]["zones"]["discard"].size() == 1
		and a["core"]["cards"]["actors"]["A"]["zones"]["casting"].is_empty())
	_yes("CAST-001-IMMEDIATE_EFFECT_CONTRACT", _idx(chant["events"],"SpellEffectDeferredToM5") >= 0
		and chant["events"][_idx(chant["events"],"SpellEffectDeferredToM5")]["details"]["mode"] == "CHANTLESS")
	_yes("CAST-001-NO_CONCENTRATION", a["core"]["battle"]["actors"]["A"]["status"] == "ACTIVE"
		and a["core"]["battle"]["casting_instances"].is_empty())
	_yes("CAST-001-COST_PAID_ONCE", a["core"]["battle"]["party_resources"]["current_ap"] == 5
		and a["core"]["battle"]["actors"]["A"]["mp"] == 6
		and a["core"]["battle"]["paid_cost_command_ids"].size() == 1)
	_yes("M21-CAST-001-IMMEDIATE_NO_HP_DAMAGE", a["core"]["battle"]["actors"]["Boss"]["hp"] == 100)
	var full: Dictionary = _apply(s,"CAST_SPELL_M4","full-A",_spell(s,"A"))
	var f: Dictionary = full["state"]
	_yes("CAST-002-FULL_ACCEPTED", full["accepted"] and Casting.validate_state(f))
	_yes("CAST-002-CARD_IN_CASTING", f["core"]["cards"]["actors"]["A"]["zones"]["casting"].size() == 1
		and f["core"]["cards"]["actors"]["A"]["zones"]["discard"].is_empty())
	_yes("CAST-002-ONE_CASTING_INSTANCE", f["core"]["battle"]["casting_instances"].size() == 1
		and f["core"]["battle"]["casting_instances"].has("cast:full-A"))
	_yes("CAST-002-CONCENTRATING", f["core"]["battle"]["actors"]["A"]["status"] == "CONCENTRATING")
	var cast: Dictionary = f["core"]["battle"]["casting_instances"]["cast:full-A"]
	_yes("CAST-002-SCHEDULED_NEXT_PLAYER", cast["planned_resolve_round"] == 2
		and cast["started_round"] == 1 and cast["can_cancel"] == false)
	_yes("CAST-002-COST_PAID_AT_START", f["core"]["battle"]["party_resources"]["current_ap"] == 5
		and f["core"]["battle"]["actors"]["A"]["mp"] == 6
		and f["core"]["battle"]["paid_cost_command_ids"].size() == 1)
	_yes("M21-CAST-001-EQUAL_BASE_MP", f["core"]["battle"]["actors"]["A"]["mp"] == a["core"]["battle"]["actors"]["A"]["mp"])
	_yes("CAST-002-OWN_INSTANCE_STABILITY_ONLY", cast["current_stability"] == 10
		and cast["stability_authority"] == "BALANCE_PROVISIONAL_M4_2_NOT_IMPLEMENTED"
		and not f["core"]["battle"].has("casting_break_gauge"))
	_yes("CAST-002-ZONE_CONSERVATION", Zones.validate_state(f["core"]["cards"])
		and Instance.valid(f["core"]))
	_yes("CAST-002-RNG_UNCHANGED", Model.state_hash(f["core"]["battle"]["rng"]) == pre_rng)
	_yes("CAST-002-NO_PREMATURE_EFFECT", _idx(full["events"],"SpellEffectDeferredToM5") == -1)
	_yes("CAST-003-BASIC_ATTACK_DENIED", _reject(_apply(f,"BASIC_ATTACK_RESOURCE_ONLY","attack-A",
		{"actor_id":"A"}), f, "ACTOR_UNAVAILABLE_OR_PHASE"))
	_yes("CAST-003-SECOND_FULL_DENIED", _reject(_apply(f,"CAST_SPELL_M4","full-A2",
		_spell(f,"A","FULL")),f,"ACTOR_UNAVAILABLE"))
	_yes("CAST-003-CHANTLESS_WHILE_CONCENTRATING_DENIED", _reject(_apply(f,"CAST_SPELL_M4",
		"chant-again",_spell(f,"A","CHANTLESS")),f,"ACTOR_UNAVAILABLE"))
	_yes("CAST-003-M2_FREE_SWAP_NO_ACTIVE_ACTOR", _reject(_apply(f,"FREE_SWAP","swap-A",
		{"actor_id":"A","card_instance_id":_card(f,"A")}),f,"ACTOR_UNAVAILABLE"))
	_yes("CAST-003-OTHER_ACTOR_CAN_ACT", _apply(f,"BASIC_ATTACK_RESOURCE_ONLY",
		"attack-B",{"actor_id":"B"})["accepted"])
	_yes("CAST-003-STILL_INITIAL_UNCHANGED", Model.state_hash(s) == before_hash)
	_yes("CAST-003-NO_CANCEL_COMMAND", _reject(_apply(f,"CANCEL_CAST","cancel",
		{"actor_id":"A","casting_id":"cast:full-A"}),f,"FEATURE_NOT_IMPLEMENTED_M3_1"))
	_yes("CAST-NEG-DUPLICATE_COMMAND", _reject(Casting.apply(f, _cmd(s,
		"CAST_SPELL_M4","full-A",_spell(s,"A")),config),f,"DUPLICATE_COMMAND"))
	_yes("CAST-NEG-STALE_EVENT_SEQ", _reject(Casting.apply(f, _cmd(s,
		"CAST_SPELL_M4","new-but-stale",_spell(s,"B")),config),f,"STALE_STATE"))
	var bad_mode: Dictionary = _spell(s,"A","INSTANT")
	_yes("CAST-NEG-BAD_CAST_MODE", _reject(_apply(s,"CAST_SPELL_M4","bad-mode",bad_mode),
		s,"CASTING_MODE_NOT_ALLOWED"))
	var mode_cfg: Dictionary = config.duplicate(true)
	mode_cfg["casting_profiles"]["spell"]["allowed_modes"] = ["FULL"]
	_yes("CAST-NEG-MODE_UNAVAILABLE", _reject(_apply(s,"CAST_SPELL_M4","mode-unavail",
		_spell(s,"A","CHANTLESS"),mode_cfg),s,"CASTING_MODE_NOT_ALLOWED"))
	_yes("CAST-NEG-WRONG_CARD_OWNER", _reject(_apply(s,"CAST_SPELL_M4","wrong-owner",
		{"actor_id":"B","card_instance_id":_card(s,"A"),"casting_mode":"FULL","target_actor_id":"Boss"}),
		s,"CARD_NOT_IN_OWN_HAND"))
	_yes("CAST-NEG-MISSING_TARGET", _reject(_apply(s,"CAST_SPELL_M4","missing-target",
		{"actor_id":"A","card_instance_id":_card(s,"A"),"casting_mode":"FULL",
			"target_actor_id":"Missing"}),s,"INVALID_CASTING_TARGET"))
	var no_mp: Dictionary = s.duplicate(true)
	no_mp["core"]["battle"]["actors"]["A"]["mp"] = 1
	_yes("CAST-NEG-INSUFFICIENT_MP_ATOMIC", _reject(_apply(no_mp,"CAST_SPELL_M4",
		"no-mp",_spell(no_mp,"A")),no_mp,"INSUFFICIENT_MP"))
	var no_ap: Dictionary = s.duplicate(true)
	no_ap["core"]["battle"]["party_resources"]["current_ap"] = 0
	var limited: Dictionary = config.duplicate(true)
	limited["costs"]["overload_enabled"] = false
	var no_ap_result: Dictionary = _apply(no_ap,"CAST_SPELL_M4","no-ap",_spell(no_ap,"A"),limited)
	_yes("CAST-NEG-AP_FAILURE_NO_PARTIAL_COMMIT", not no_ap_result["accepted"]
		and Model.state_hash(no_ap_result["state"]) == Model.state_hash(no_ap))
	var no_profile: Dictionary = config.duplicate(true)
	no_profile["casting_profiles"] = {}
	_yes("CAST-NEG-NO_CASTING_PROFILE", _reject(_apply(s,"CAST_SPELL_M4",
		"no-profile",_spell(s,"A"),no_profile),s,"MISSING_CASTING_PROFILE"))
	var no_stability: Dictionary = config.duplicate(true)
	no_stability["casting_profiles"]["spell"].erase("base_stability")
	_yes("CAST-NEG-STABILITY_REQUIRES_PROVISIONAL_FIXTURE", _reject(_apply(s,
		"CAST_SPELL_M4","no-stability",_spell(s,"A"),no_stability),
		s,"MISSING_PROVISIONAL_STABILITY_FIXTURE"))
	_yes("CAST-NEG-NO_CONFIG_DONT_INVENT", _reject(_apply(s,"CAST_SPELL_M4","no-cost",
		_spell(s,"A"),{"casting_profiles":config["casting_profiles"]}),
		s,"MISSING_VERSIONED_COST"))
	# Walk genuine M3 phase transitions and use the real M4 timeline,
	# which must run before M2 renewed AP and draw-to-four.
	var ended: Dictionary = _apply(f,"END_PLAYER_PHASE","round1-end")
	var expired: Dictionary = _apply(ended["state"],"END_ENEMY_PHASE","round1-enemy-end")
	_yes("CAST-002-ENEMY_PHASE_WITH_CONCENTRATION", ended["accepted"] and expired["accepted"]
		and expired["state"]["core"]["battle"]["casting_instances"].size() == 1)
	var opened: Dictionary = _apply(expired["state"],"START_PLAYER_PHASE","round2-start")
	if not opened["accepted"]:
		printerr("M4_1_BOUNDARY_REJECTED ",opened["error"])
		quit(1)
		return
	var r2: Dictionary = opened["state"]
	_yes("CAST-002-RELEASED_ONLY_AT_BOUNDARY", r2["core"]["battle"]["casting_instances"].is_empty()
		and r2["core"]["battle"]["actors"]["A"]["status"] == "ACTIVE")
	_yes("CAST-002-CAST_TO_DISCARD_ON_RELEASE", r2["core"]["cards"]["actors"]["A"]["zones"]["casting"].is_empty()
		and r2["core"]["cards"]["actors"]["A"]["zones"]["discard"].size() == 1)
	_yes("CAST-002-RELEASE_NO_SECOND_PAYMENT", r2["core"]["battle"]["paid_cost_command_ids"].size() == 1
		and r2["core"]["battle"]["actors"]["A"]["mp"] == 6)
	_yes("CAST-002-PHASE2_HAND_REFILLS_FOUR", r2["core"]["cards"]["actors"]["A"]["zones"]["hand"].size() == 4)
	_yes("CAST-002-EVENT_BEFORE_M2_RENEW_AND_DRAW", _idx(opened["events"],"CastingReleased") >= 0
		and _idx(opened["events"],"CastingReleased") < _idx(opened["events"],"PlayerResourcesOpened")
		and _idx(opened["events"],"SpellEffectDeferredToM5") < _idx(opened["events"],"CardDrawn"))
	_yes("CAST-002-EFFECT_IS_NOT_REAL_DAMAGE", r2["core"]["battle"]["actors"]["Boss"]["hp"] == 100)
	_yes("CAST-002-CARD_CONSERVATION_AFTER_ROUND_CHANGE", Zones.validate_state(r2["core"]["cards"]))
	_yes("CAST-002-CAST_CAN_RESTART_LATER", _apply(r2,"CAST_SPELL_M4","round2-full",
		_spell(r2,"A","FULL"))["accepted"])
	_yes("CAST-002-M4_REPLAY_ENTIRE_PHASE", Casting.replay(s, [
		_cmd(s,"CAST_SPELL_M4","full-A",_spell(s,"A")),
		_cmd(f,"END_PLAYER_PHASE","round1-end"),
		_cmd(ended["state"],"END_ENEMY_PHASE","round1-enemy-end"),
		_cmd(expired["state"],"START_PLAYER_PHASE","round2-start")
	], config)["state_hash"] == Model.state_hash(r2))
	_yes("CAST-002-FAILED_INPUT_PRESERVES_RNG", Model.state_hash(no_mp["core"]["battle"]["rng"]) == pre_rng)
	_yes("CAST-002-NO_FORGED_EFFECT_ON_REJECT", _idx(_apply(no_mp,"CAST_SPELL_M4",
		"no-mp-second",_spell(no_mp,"A"))["events"],"SpellEffectDeferredToM5") == -1)
	print("M4_1_REPLAY seed=",SEED, " initial=",before_hash,
		" events=",Casting.replay(s, [
			_cmd(s,"CAST_SPELL_M4","full-A",_spell(s,"A")),
			_cmd(f,"END_PLAYER_PHASE","round1-end"),
			_cmd(ended["state"],"END_ENEMY_PHASE","round1-enemy-end"),
			_cmd(expired["state"],"START_PLAYER_PHASE","round2-start")
		], config)["event_hash"], " final=",Model.state_hash(r2))
	print("M4_1_TEST_REPORT executed=",passed+failed," passed=",passed," failed=",failed)
	if failed == 0:
		print("M4_1_DUAL_CAST_DOMAIN_VERIFIED")
	quit(0 if failed == 0 else 1)
