extends SceneTree
## M4.5 genuine cross-slice M3 Reaction → M4 Ward / Direct Disruption,
## M2 cost / Casting zones → Phase boundary → M4.4 HP0 cancellation.
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const Zones = preload("res://scripts/domain/m2/cards/card_zone_resolver.gd")
const M4 = preload("res://scripts/domain/m4/integration/m4_domain_resolver.gd")
const Fixture = preload("res://tests/fixtures/m4_5_scenario.gd")
var passed: int = 0
var failed: int = 0
func check(id: String, condition: bool) -> void:
	if condition:
		passed += 1
		print("PASS ", id)
	else:
		failed += 1
		printerr("FAIL ", id)
func at(data: Dictionary, id: String) -> Dictionary:
	return data["checkpoints"][id]["state"]
func events(data: Dictionary, id: String) -> Array:
	return data["checkpoints"][id]["events"]
func ix(e: Array, kind: String) -> int:
	for i: int in range(e.size()):
		if str(e[i].get("kind","")) == kind:
			return i
	return -1
func count(e: Array, kind: String) -> int:
	var n: int = 0
	for item: Dictionary in e:
		if str(item["kind"]) == kind:
			n += 1
	return n
func no_mutation(s: Dictionary, config: Dictionary, cmd: Dictionary,
		error: String) -> bool:
	var before: String = Model.state_hash(s)
	var response: Dictionary = M4.apply(s,cmd,config)
	return not response["accepted"] and str(response["error"]) == error and \
		response["events"].is_empty() and Model.state_hash(s) == before and \
		Model.state_hash(response["state"]) == before

func _init() -> void:
	var scenario: Dictionary = Fixture.build()
	if not scenario.get("ok",false):
		printerr("M4_5_SCENARIO_REJECTED ",scenario.get("error","missing"))
		quit(1)
		return
	var origin: Dictionary = scenario["initial"]
	var config: Dictionary = scenario["config"]
	var final_state: Dictionary = scenario["state"]
	var all_events: Array = final_state["events"]
	var last_id: String = "last:m45:0:ACTIVATE_LAST_SPELL_M4"
	var initial_hash: String = Model.state_hash(origin)
	check("M45-INT-01-EXECUTED_ALL_REAL_COMMANDS",scenario["tape"].size() >= 28)
	check("M45-INT-02-VALID_M4_DOMAIN",M4.validate_state(final_state))
	check("M45-INT-03-ALL_36_CARDS_CONSERVED",Zones.validate_state(final_state["core"]["cards"])
		and final_state["core"]["cards"]["actors"]["A"]["instances"].size() == 12
		and final_state["core"]["cards"]["actors"]["B"]["instances"].size() == 12
		and final_state["core"]["cards"]["actors"]["C"]["instances"].size() == 12)
	check("M45-INT-04-ORIGIN_IMMUTABLE",Model.state_hash(origin) == initial_hash)
	var started: Dictionary = at(scenario,"b_full")
	check("M45-INT-05-THREE_ACTORS_MIXED_FREE_ORDER",started["core"]["battle"]["casting_instances"].size() == 2
		and started["core"]["battle"]["actors"]["A"]["status"] == "CONCENTRATING"
		and started["core"]["battle"]["actors"]["B"]["status"] == "CONCENTRATING"
		and started["core"]["battle"]["actors"]["C"]["status"] == "ACTIVE")
	check("M45-INT-06-LAST_USES_NO_CARD_ZONE",at(scenario,"last_committed")["core"]["cards"] == origin["core"]["cards"]
		and at(scenario,"last_committed")["core"]["battle"]["last_spell_used_by_actor"]["A"] == 1)
	check("M45-INT-07-MIXED_COST_ACTUAL_M2",started["core"]["battle"]["party_resources"]["current_ap"] == 3
		and started["core"]["battle"]["actors"]["A"]["mp"] == 5
		and started["core"]["battle"]["actors"]["B"]["mp"] == 6
		and started["core"]["battle"]["actors"]["C"]["mp"] == 8)
	check("M45-INT-08-CHASE_CARD_SINGLE_CAST_ZONE",started["core"]["cards"]["actors"]["B"]["zones"]["casting"].size() == 1
		and started["core"]["cards"]["actors"]["C"]["zones"]["discard"].is_empty())
	var draft: Dictionary = at(scenario,"protect_draft")
	check("M45-INT-09-DRAFT_THREE_RP_NO_PAYMENT",draft["core"]["battle"]["party_resources"]["rp"] == 3
		and draft["core"]["battle"]["actors"]["B"]["mp"] == 6)
	check("M45-INT-10-TWO_ACTOR_REACTION_QUEUE",draft["reaction_window"]["draft"].size() == 2
		and draft["reaction_window"]["draft"][0]["actor_id"] == "B"
		and draft["reaction_window"]["draft"][1]["actor_id"] == "C")
	var confirmed: Dictionary = at(scenario,"r1_confirm")
	check("M45-INT-11-CONCENTRATING_CAST_COMPATIBLE_PAID",confirmed["reaction_window"]["executed_actor_ids"] == ["B","C"]
		and confirmed["core"]["battle"]["actors"]["B"]["status"] == "CONCENTRATING"
		and confirmed["core"]["battle"]["actors"]["B"]["mp"] == 5)
	check("M45-INT-12-WARD_ON_LAST_INSTANCE",confirmed["core"]["battle"]["casting_instances"][last_id]["focus_ward"] == 6
		and ix(events(scenario,"r1_confirm"),"FocusWardGranted") >= 0)
	check("M45-INT-13-PROTECT_TARGET_IS_C",confirmed["reaction_window"]["original_target_actor_id"] == "A"
		and confirmed["reaction_window"]["damage_recipient_actor_id"] == "C")
	check("M45-INT-14-RP_LEGAL_ON_CONFIRM",confirmed["core"]["battle"]["party_resources"]["rp"] == 0)
	var redirected: Dictionary = at(scenario,"protected_onhit")
	check("M45-INT-15-ON_HIT_SUPPRESSED_AFTER_PROTECT",
		ix(events(scenario,"protected_onhit"),"CastingDisruptionSuppressedByProtect") >= 0
		and redirected["core"]["battle"]["casting_instances"][last_id]["current_stability"] == 10
		and redirected["core"]["battle"]["casting_instances"][last_id]["focus_ward"] == 6)
	var first: Dictionary = at(scenario,"direct_first")
	check("M45-INT-16-DIRECT_BYPASSES_PROTECT",ix(events(scenario,"direct_first"),"CastingDisruptionEvaluated") >= 0
		and first["core"]["battle"]["casting_instances"][last_id]["focus_ward"] == 0
		and first["core"]["battle"]["casting_instances"][last_id]["current_stability"] == 4)
	var delayed: Dictionary = at(scenario,"last_destabilized")
	check("M45-INT-17-FIRST_INSTABILITY_DELAY_ONCE",
		ix(events(scenario,"last_destabilized"),"LastSpellDestabilizedDelayed") >= 0
		and delayed["core"]["battle"]["casting_instances"][last_id]["planned_resolve_round"] == 4
		and delayed["core"]["battle"]["casting_instances"][last_id]["delay_used"])
	check("M45-INT-18-NO_INTERRUPTION_REFUND_ON_LAST",
		ix(events(scenario,"last_destabilized"),"MPRestored") == -1
		and delayed["core"]["battle"]["actors"]["A"]["mp"] == 5)
	var round2: Dictionary = at(scenario,"r2_open")
	var due2: Array = events(scenario,"r2_open")
	check("M45-INT-19-B_FULL_RELEASED",ix(due2,"CastingReleased") >= 0
		and round2["core"]["battle"]["actors"]["B"]["status"] == "ACTIVE"
		and not round2["core"]["battle"]["casting_instances"].has("cast:m45:1:CAST_SPELL_M4"))
	check("M45-INT-20-RELEASE_BEFORE_AP_AND_DRAW",ix(due2,"CastingReleased") < ix(due2,"PlayerResourcesOpened")
		and ix(due2,"SpellEffectDeferredToM5") < ix(due2,"CardDrawn"))
	check("M45-INT-21-B_CARD_EXACT_CAST_TO_DISCARD",round2["core"]["cards"]["actors"]["B"]["zones"]["casting"].is_empty()
		and round2["core"]["cards"]["actors"]["B"]["zones"]["discard"].size() >= 2)
	check("M45-INT-22-RENEW_PRESERVES_LAST_CAST",round2["core"]["battle"]["casting_instances"].has(last_id)
		and round2["core"]["battle"]["actors"]["A"]["status"] == "CONCENTRATING")
	var r2: Dictionary = at(scenario,"r2_protected")
	check("M45-INT-23-R2_PROTECT_FRESH_WINDOW",r2["reaction_window"]["damage_recipient_actor_id"] == "B"
		and r2["reaction_window"]["original_target_actor_id"] == "A")
	var protector_hp0: Dictionary = at(scenario,"r2_protector_hp0")
	check("M45-INT-24-PROTECT_GUARDIAN_INCAPACITATED",protector_hp0["core"]["battle"]["actors"]["B"]["hp"] == 0
		and protector_hp0["core"]["battle"]["actors"]["A"]["hp"] == 100)
	check("M45-INT-25-CASTER_NOT_INVALIDATED_BY_PROTECTED_HIT",protector_hp0["core"]["battle"]["casting_instances"].has(last_id)
		and ix(events(scenario,"r2_protector_hp0"),"LastSpellInvalidated") == -1)
	var round3: Dictionary = at(scenario,"r3_open")
	check("M45-INT-26-C_NORMAL_FULL_RELEASED",round3["core"]["cards"]["actors"]["C"]["zones"]["casting"].is_empty()
		and round3["core"]["battle"]["actors"]["C"]["status"] == "ACTIVE"
		and ix(events(scenario,"r3_open"),"CastingReleased") >= 0)
	check("M45-INT-27-LAST_DOES_NOT_EARLY_RELEASE",round3["core"]["battle"]["casting_instances"].has(last_id)
		and ix(events(scenario,"r3_open"),"LastSpellReleased") == -1)
	var killed: Dictionary = at(scenario,"r3_last_invalidated")
	var lethal: Array = events(scenario,"r3_last_invalidated")
	check("M45-INT-28-CORE02_INSTANT_ACTOR_ZERO",killed["core"]["battle"]["actors"]["A"]["hp"] == 0
		and killed["core"]["battle"]["actors"]["A"]["status"] == "INCAPACITATED")
	check("M45-INT-29-CORE02_STRICT_CHAIN",ix(lethal,"ActorIncapacitated") >= 0
		and ix(lethal,"ActorIncapacitated") < ix(lethal,"LastSpellInvalidated")
		and ix(lethal,"LastSpellInvalidated") < ix(lethal,"ScheduledEffectCancelled")
		and ix(lethal,"ScheduledEffectCancelled") < ix(lethal,"BattleOutcomeEvaluated"))
	check("M45-INT-30-SCHEDULE_ERASED_AT_DAMAGE_BOUNDARY",not killed["core"]["battle"]["casting_instances"].has(last_id)
		and ix(lethal,"LastSpellEffectDeferredToM5") == -1)
	check("M45-INT-31-NEVER_REFUND_AP_MP_OR_USAGE",killed["core"]["battle"]["last_spell_used_by_actor"]["A"] == 1
		and killed["core"]["battle"]["actors"]["A"]["mp"] == 5
		and ix(lethal,"MPRestored") == -1)
	var round4: Dictionary = at(scenario,"r4_open")
	check("M45-INT-32-T4_NO_RESURRECTED_LAST_EFFECT",ix(events(scenario,"r4_open"),"LastSpellReleased") == -1
		and ix(events(scenario,"r4_open"),"LastSpellEffectDeferredToM5") == -1)
	check("M45-INT-33-T4_INCAPACITATED_HAND_FROZEN",round4["core"]["battle"]["actors"]["A"]["status"] == "INCAPACITATED")
	check("M45-INT-34-REVIVE_NOT_RESTORE_LAST",final_state["core"]["battle"]["actors"]["A"]["hp"] == 35
		and final_state["core"]["battle"]["last_spell_used_by_actor"]["A"] == 1
		and not final_state["core"]["battle"]["casting_instances"].has(last_id))
	check("M45-INT-35-REVIVED_CANNOT_RECAST",no_mutation(final_state,config,{
		"type":"ACTIVATE_LAST_SPELL_M4","command_id":"m45:illegal-recast",
		"expected_event_seq":int(final_state["event_seq"]),
		"actor_id":"A","target_actor_id":"Boss","confirmed":true,
		"casting_mode":"FULL"},"LAST_SPELL_ALREADY_USED"))
	check("M45-INT-36-M5_HP_DAMAGE_NOT_INVENTED",final_state["core"]["battle"]["actors"]["Boss"]["hp"] == 100
		and count(all_events,"LastSpellEffectDeferredToM5") == 0)
	check("M45-INT-37-REAL_CARD_ZONES_PRESERVED",Zones.validate_state(final_state["core"]["cards"]))
	check("M45-INT-38-M4_STATUS_LIFETIME_VALID",M4.validate_state(final_state))
	check("M45-INT-39-COMMANDS_UNIQUE",scenario["tape"].map(
		func(c: Dictionary) -> String: return str(c["command_id"])).size() ==
		scenario["tape"].size())
	check("M45-INT-40-UNTRUSTED_HP_COMMAND_REJECTED",no_mutation(round3,config,{
		"type":"APPLY_INCAPACITATION_M4_FIXTURE","command_id":"m45:spoof",
		"expected_event_seq":int(round3["event_seq"]),
		"source_enemy_action_id":"fake","effect_id":"hp0_A",
		"verified_hit_fixture":true,"hp_after":0},"UNTRUSTED_LIFE_PAYLOAD"))
	var no_trust: Dictionary = config.duplicate(true)
	no_trust["m4_4_trusted_life_fixture"] = false
	check("M45-INT-41-NO_PUBLIC_KILL_COMMAND",no_mutation(round3,no_trust,{
		"type":"APPLY_INCAPACITATION_M4_FIXTURE","command_id":"m45:fake",
		"expected_event_seq":int(round3["event_seq"]),
		"source_enemy_action_id":"fake","effect_id":"hp0_A",
		"verified_hit_fixture":true},"M5_HP_ENGINE_NOT_AVAILABLE"))
	print("M4_5_INTEGRATION seed=",Fixture.SEED,
		" commands=",scenario["tape"].size(),
		" initial=",initial_hash," events=",Model.event_hash(all_events),
		" final=",Model.state_hash(final_state))
	print("M4_5_INTEGRATION_REPORT executed=",passed+failed,
		" passed=",passed," failed=",failed)
	if failed == 0:
		print("M4_5_INTEGRATION_DOMAIN_ACCEPTED")
	quit(0 if failed == 0 else 1)
