extends SceneTree
## M3.5 integrated 2-round headless domain acceptance: actual M1->M3.4
## reducer, no mock RP/CardInstance transactions or real damage.
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const Zones = preload("res://scripts/domain/m2/cards/card_zone_resolver.gd")
const Domain = preload("res://scripts/domain/m3/integration/m3_domain_resolver.gd")
const Fixture = preload("res://tests/fixtures/m3_5_fixture.gd")
const Scenario = preload("res://tests/fixtures/m3_5_scenario.gd")
const Queue = preload("res://scripts/domain/m3/reaction/reaction_queue_resolver.gd")
var passed: int = 0
var failed: int = 0

func check(id: String, yes: bool) -> void:
	if yes:
		passed += 1
		print("PASS ", id)
	else:
		failed += 1
		printerr("FAIL ", id)

func ck(data: Dictionary, name: String) -> Dictionary:
	return data["checkpoints"][name]["state"]

func ev(data: Dictionary, name: String) -> Array:
	return data["checkpoints"][name]["events"]

func index(events: Array, kind: String) -> int:
	for i: int in range(events.size()):
		if str(events[i]["kind"]) == kind:
			return i
	return -1

func kind_count(events: Array, kind: String) -> int:
	var count: int = 0
	for item: Dictionary in events:
		if str(item.get("kind", "")) == kind:
			count += 1
	return count

func card_hand(s: Dictionary, actor: String) -> int:
	return s["core"]["cards"]["actors"][actor]["zones"]["hand"].size()

func _rejected(phase: Dictionary, kind: String, suffix: String,
		fields: Dictionary, expected: String) -> bool:
	var request: Dictionary = Fixture.command(phase, kind, "negative:" + suffix, fields)
	var original: String = Model.state_hash(phase)
	var result: Dictionary = Domain.apply(phase, request, Fixture.config())
	return not result["accepted"] and str(result["error"]) == expected \
		and result["events"].is_empty() and Model.state_hash(result["state"]) == original

func _init() -> void:
	var scenario: Dictionary = Scenario.build()
	if not bool(scenario.get("ok", false)):
		printerr("M3_5_INTEGRATION_SCENARIO_FAILED ", str(scenario.get("error", "unknown")))
		quit(1)
		return
	var initial: Dictionary = scenario["initial"]
	var last: Dictionary = scenario["state"]
	var origin_hash: String = Model.state_hash(initial)
	check("M35-END2END-COMPLETE", bool(scenario["ok"]) and str(last["phase"]) == "PLAYER_PHASE"
		and int(last["core"]["battle"]["round"]) == 3)
	check("M35-END2END-REAL_M2_CARD_ZONES", Domain.validate_state(last)
		and Zones.validate_state(last["core"]["cards"]))
	check("M35-END2END-ALL_36_INSTANCES", last["core"]["cards"]["actors"].size() == 3
		and last["core"]["cards"]["actors"]["A"]["instances"].size() == 12
		and last["core"]["cards"]["actors"]["B"]["instances"].size() == 12
		and last["core"]["cards"]["actors"]["C"]["instances"].size() == 12)
	check("M35-END2END-SEED_IMMUTABLE", Model.state_hash(initial) == origin_hash)
	check("M35-END2END-PUBLIC_ORDER", ck(scenario, "r1_enemy_phase")["enemy_actions"].map(
		func(a: Dictionary) -> String: return str(a["intent_id"])) == ["countered", "triple", "aoe", "empty"])
	check("M35-END2END-RP_CAP6_FROM_AP", ck(scenario, "r1_enemy_phase")["core"]["battle"]["party_resources"]["rp"] == 6)
	check("M35-END2END-PHASE_AWAITING_CONSENT", ck(scenario, "countered_opened")["reaction_window"]["status"] == "DRAFTING")
	var draft: Dictionary = ck(scenario, "countered_draft")
	check("M35-QUEUE-THREE_DIFFERENT_ACTORS", draft["reaction_window"]["draft"].map(
		func(d: Dictionary) -> String: return str(d["actor_id"])) == ["A", "B", "C"])
	check("M35-QUEUE-NO_EARLY_RP_CHARGE", draft["core"]["battle"]["party_resources"]["rp"] == 6)
	check("M35-QUEUE-NO_EARLY_MP_OR_CARD", draft["core"]["battle"]["actors"]["A"]["mp"] == 8
		and card_hand(draft, "A") == 4 and card_hand(draft, "C") == 4)
	check("M35-QUEUE-AGGREGATE_BUDGET", Queue.preview(draft, Fixture.config()["reaction_definitions"])["estimated_rp"] == 4)
	check("M35-QUEUE-CANNOT_PREMATURELY_FINISH", _rejected(draft, "COMPLETE_ENEMY_ACTION_FIXTURE",
		"premature", {"enemy_action_id": draft["active_enemy_action_id"]}, "REACTION_WINDOW_NOT_RESOLVED"))
	var first: Dictionary = ck(scenario, "countered_confirmed")
	var first_events: Array = ev(scenario, "countered_confirmed")
	check("PH3-M3-QUEUE-001", first["reaction_window"]["executed_actor_ids"] == ["A", "C"]
		and first["reaction_window"]["action_active"] == false)
	check("PRE3-R04-SKIP_WITHOUT_PAYMENT", index(first_events, "ReactionSkipped") >= 0
		and first_events[index(first_events,"ReactionSkipped")]["details"]["actor_id"] == "B"
		and first_events[index(first_events,"ReactionSkipped")]["details"]["reason"] == "TRIGGER_GONE")
	check("M35-QUEUE-ONLY_TWO_REAL_PAYMENTS", kind_count(first_events, "ReactionResourcesCommitted") == 2
		and first["core"]["battle"]["party_resources"]["rp"] == 4)
	check("M35-QUEUE-SKIPPED_B_KEEPS_MP", first["core"]["battle"]["actors"]["B"]["mp"] == 8)
	check("M35-QUEUE-SPENT_A_C_CARDS", card_hand(first,"A") == 3 and card_hand(first,"C") == 3
		and first["core"]["cards"]["actors"]["B"]["zones"]["discard"].is_empty())
	check("M35-QUEUE-CARD_INSTANCE_CONSERVED", Zones.validate_state(first["core"]["cards"]))
	check("M35-QUEUE-COMMIT_BEFORE_SKIP_AND_CLOSE", index(first_events,"ReactionConfirmed") >= 0
		and index(first_events,"ReactionConfirmed") < index(first_events,"ReactionResourcesCommitted")
		and index(first_events,"ReactionResourcesCommitted") < index(first_events,"ReactionSkipped")
		and index(first_events,"ReactionSkipped") < index(first_events,"ReactionWindowClosed"))
	check("M35-QUEUE-INDEPENDENT_SUPPORT_AFTER_CANCEL", first["core"]["battle"]["actors"]["C"]["mp"] == 7
		and first["core"]["battle"]["actors"]["A"]["mp"] == 6)
	check("M35-QUEUE-CONFIRM_IS_IDEMPOTENT_REJECT", _rejected(first,"CONFIRM_REACTIONS",
		"repeat", {"window_id": first["reaction_window"]["window_id"]}, "REACTION_WINDOW_CLOSED"))
	check("M35-QUEUE-SKIPPED_GUARD_NOT_CONSUMED", not first["reaction_window"]["executed_actor_ids"].has("B"))
	var cancellation: Array = ev(scenario, "countered_finished")
	check("M35-ACTION-CANCELLATION_METADATA_ONLY", cancellation[-1]["details"]["defense_snapshot"]["enemy_action_cancelled_fixture"]
		and cancellation[-1]["details"]["damage_status"] == "DEFERRED_TO_M5")
	var triple_open: Dictionary = ck(scenario, "triple_opened")
	check("M35-WINDOW-UNIQUE_ACTION_ID", triple_open["reaction_window"]["window_id"] != draft["reaction_window"]["window_id"])
	check("M35-WINDOW-RP_CONTINUES_AS4", triple_open["core"]["battle"]["party_resources"]["rp"] == 4)
	check("M35-WINDOW-RESETS_EXECUTED_ACTORS", triple_open["reaction_window"]["executed_actor_ids"].is_empty())
	var triple_draft: Dictionary = ck(scenario, "triple_draft")
	check("M35-GUARD_PROTECT-NO_DRAFT_CHARGE", triple_draft["core"]["battle"]["party_resources"]["rp"] == 4
		and Queue.preview(triple_draft, Fixture.config()["reaction_definitions"])["estimated_rp"] == 3)
	var triple: Dictionary = ck(scenario, "triple_confirmed")
	var te: Array = ev(scenario, "triple_confirmed")
	check("PRE3-R02-GUARD_ALL_HITS", triple["reaction_window"]["guard_actor_ids"] == ["A"]
		and te[index(te, "GuardCoverageRegistered")]["details"]["hit_count"] == 3)
	check("PH3-M3-PROTECT-001", triple["reaction_window"]["protected_by_actor_id"] == "B"
		and triple["reaction_window"]["original_target_actor_id"] == "A"
		and triple["reaction_window"]["damage_recipient_actor_id"] == "B")
	check("M35-GUARD_PROTECT-ONLY_3RP", triple["core"]["battle"]["party_resources"]["rp"] == 1
		and triple["reaction_window"]["executed_actor_ids"] == ["A","B"])
	check("M35-GUARD_PROTECT-NO_MP_CARD", triple["core"]["battle"]["actors"]["B"]["mp"] == 8
		and card_hand(triple, "B") == 4)
	check("M35-GUARD_PROTECT-CHRONOLOGY", index(te, "GuardCoverageRegistered") < index(te, "AttackTargetRedirected")
		and index(te, "AttackTargetRedirected") < index(te, "ReactionWindowClosed"))
	var td: Dictionary = ck(scenario, "triple_finished")
	var snapshot: Dictionary = ev(scenario, "triple_finished")[-1]["details"]["defense_snapshot"]
	check("M35-PROTECT-M5_HANDOFF_BEFORE_HIT", snapshot["source_enemy_action_id"] == "round:1:intent:triple"
		and snapshot["damage_recipient_actor_id"] == "B"
		and snapshot["hit_count"] == 3)
	check("M35-PROTECT-ONLY_EXPLICIT_STATUS_TRANSFER", snapshot["follows_damage_recipient"] == "EXPLICIT_TAG_ONLY")
	check("M35-PROTECT-NEVER_FAKES_HP_DAMAGE", td["core"]["battle"]["actors"]["A"]["hp"] == 100
		and td["core"]["battle"]["actors"]["B"]["hp"] == 100)
	var aoe_start: Dictionary = ck(scenario, "aoe_opened")
	check("M35-AOE-NO_PROTECT", _rejected(aoe_start, "QUEUE_REACTION", "aoe-protect",
		{"window_id": aoe_start["reaction_window"]["window_id"],
			"entry": Fixture.entry("BASIC_PROTECT", "C", "A")}, "PROTECT_REQUIRES_SINGLE_TARGET"))
	var aoe_done: Dictionary = ck(scenario, "aoe_confirmed")
	check("M35-AOE-GUARD1RP", aoe_done["core"]["battle"]["party_resources"]["rp"] == 0
		and aoe_done["reaction_window"]["guard_actor_ids"] == ["A"])
	check("M35-AOE-MULTIHIT_COVERAGE", ev(scenario, "aoe_confirmed")[index(ev(scenario,"aoe_confirmed"),
		"GuardCoverageRegistered")]["details"]["hit_count"] == 2)
	var empty: Dictionary = ck(scenario, "empty_opened")
	check("M35-RP_ZERO-EMPTY_WINDOW", empty["reaction_window"]["status"] == "CLOSED"
		and empty["reaction_window"]["closure_reason"] == "NO_LEGAL_REACTION"
		and index(ev(scenario, "empty_opened"), "ReactionWindowEmptySkipped") >= 0)
	check("M35-RP_ZERO-NO_PHANTOM_RP", empty["core"]["battle"]["party_resources"]["rp"] == 0)
	check("M35-RP_ZERO-NO_FORCED_CONFIRM", _rejected(empty, "CONFIRM_REACTIONS", "empty-confirm",
		{"window_id": empty["reaction_window"]["window_id"]}, "REACTION_WINDOW_CLOSED"))
	check("M35-END_ENEMY-RP_EXPIRED", ck(scenario, "r1_enemy_end")["core"]["battle"]["party_resources"]["rp"] == 0)
	var second: Dictionary = ck(scenario, "r2_player_phase")
	check("M35-PHASE_ROUND2_STARTS", second["phase"] == "PLAYER_PHASE"
		and second["core"]["battle"]["round"] == 2 and second["core"]["battle"]["party_resources"]["current_ap"] == 6)
	check("M35-PHASE_REFILL_HAND4", card_hand(second,"A") == 4 and card_hand(second,"C") == 4
		and card_hand(second,"B") == 4)
	check("M35-PHASE_RESETS_REACTION_WINDOW", second["reaction_window"].is_empty())
	check("M35-PHASE_RESETS_SWAP_QUOTA", not second["core"]["cards"]["swap_used_by_actor"]["A"])
	check("M35-PHASE_ORDER_RENEW_BEFORE_DRAW", index(ev(scenario, "r2_player_phase"), "PlayerResourcesOpened") >= 0
		and index(ev(scenario, "r2_player_phase"), "CardDrawn") >
			index(ev(scenario,"r2_player_phase"),"PlayerResourcesOpened"))
	var attacks: Array = []
	var at: Array = []
	for k: Variant in scenario["checkpoints"].keys():
		var name: String = str(k)
		if name.begins_with("r2_basic_"):
			at.append({"id": int(name.trim_prefix("r2_basic_")), "actor": str(
				scenario["checkpoints"][k]["events"][-2]["details"]["actor_id"])})
	at.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return int(a["id"]) < int(b["id"]))
	for a: Dictionary in at:
		attacks.append(a["actor"])
	check("P1-D01-PLAYER_ACTION_ORDER_AABA", attacks == ["A", "A", "B", "A"])
	check("M35-PHASE_AABA_AP_ACTUAL_COST", ck(scenario, "r2_enemy_phase")["core"]["battle"]["party_resources"]["rp"] == 2)
	check("M35-PHASE_AABA_NO_UI_TIMER", ck(scenario, "r2_enemy_phase")["phase"] == "ENEMY_PHASE")
	check("M35-PHASE_SECOND_TURN_ALL_PASSED", kind_count(last["events"], "ReactionPassed") == 4)
	check("M35-PHASE_SECOND_TURN_EXPLICIT_PASS", last["phase"] == "PLAYER_PHASE" and last["core"]["battle"]["round"] == 3)
	check("M35-PHASE_FINAL_HP_UNCHANGED_FIXTURE", last["core"]["battle"]["actors"]["Boss"]["hp"] == 100)
	check("M35-PHASE_NO_CASTING_STATUS_FAKE", last["core"]["battle"]["casting_instances"].is_empty()
		and last["core"]["battle"]["statuses"].is_empty())
	check("M35-PHASE_36_CARDS_ALSO_ROUND3", Zones.validate_state(last["core"]["cards"]))
	# Contract boundaries: no backdoor M4/M5 or player movement.
	check("P2-VIS-02-NO_MOVE_COMMAND", _rejected(last, "MOVE_ACTOR", "movement",
		{"actor_id": "A"}, "FEATURE_NOT_IMPLEMENTED_M3_1"))
	check("M35-REJECT_STALE_COMMAND", _rejected(last, "END_PLAYER_PHASE", "stale",
		{"expected_event_seq": -1}, "STALE_STATE"))
	var dupe: Dictionary = Fixture.command(last, "END_PLAYER_PHASE", str(scenario["commands"][0]["command_id"]))
	var before_hash: String = Model.state_hash(last)
	var outcome: Dictionary = Domain.apply(last, dupe, Fixture.config())
	check("M35-REJECT_DUPLICATE_COMMAND", not outcome["accepted"]
		and outcome["error"] == "DUPLICATE_COMMAND"
		and Model.state_hash(outcome["state"]) == before_hash)
	var corrupt: Dictionary = last.duplicate(true)
	corrupt["core"]["cards"]["actors"]["A"]["zones"]["draw"].append(
		str(corrupt["core"]["cards"]["actors"]["A"]["zones"]["hand"][0]))
	check("M35-REJECT_DUPLICATE_CARD_ZONE", not Domain.validate_state(corrupt))
	check("M35-INVALID_SOURCE_FAIL_CLOSED", Domain.apply(corrupt,
		Fixture.command(corrupt, "END_PLAYER_PHASE", "badstate"), Fixture.config())["error"] == "INVALID_INTEGRATED_STATE")
	check("M35-INTEGRATION_DOES_NOT_MUTATE_BATTLE", Model.state_hash(scenario["initial"]) == origin_hash)

	print("M3_5_INTEGRATION_REPORT executed=", passed+failed,
		" passed=",passed," failed=",failed)
	if failed == 0:
		print("M3_5_INTEGRATION_ACCEPTED")
	quit(0 if failed == 0 else 1)
