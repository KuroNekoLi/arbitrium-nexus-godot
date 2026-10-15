extends SceneTree
## M4.5 multi-round canonical Replay includes M2/M3/M4.1–M4.4 actual
## atomic commands and deliberate fail-closed variants; no M5 HP engine.
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const Zones = preload("res://scripts/domain/m2/cards/card_zone_resolver.gd")
const M4 = preload("res://scripts/domain/m4/integration/m4_domain_resolver.gd")
const Policy = preload("res://scripts/domain/m3/reaction/reaction_presentation_policy.gd")
const Fixture = preload("res://tests/fixtures/m4_5_scenario.gd")
var passed: int = 0
var failed: int = 0
func check(id: String, success: bool) -> void:
	if success:
		passed += 1
		print("PASS ",id)
	else:
		failed += 1
		printerr("FAIL ",id)
func _seq(state: Dictionary) -> bool:
	if int(state["event_seq"]) != state["events"].size():
		return false
	for i: int in range(state["events"].size()):
		if int(state["events"][i].get("event_seq",-1)) != i+1:
			return false
	return true
func _event_count(events: Array, kind: String) -> int:
	var n: int = 0
	for event: Dictionary in events:
		if str(event.get("kind","")) == kind:
			n += 1
	return n
func _rejected(s: Dictionary, config: Dictionary, req: Dictionary,
		error: String) -> bool:
	var before: String = Model.state_hash(s)
	var r: Dictionary = M4.apply(s,req,config)
	return not r["accepted"] and str(r["error"]) == error and \
		r["events"].is_empty() and Model.state_hash(r["state"]) == before and \
		Model.state_hash(s) == before

func _init() -> void:
	var case: Dictionary = Fixture.build()
	if not case.get("ok",false):
		printerr("M4_5_REPLAY_CASE_REJECTED ",case.get("error","unknown"))
		quit(1)
		return
	var initial: Dictionary = case["initial"]
	var expected: Dictionary = case["state"]
	var tape: Array[Dictionary] = []
	for entry: Dictionary in case["tape"]:
		tape.append(entry.duplicate(true))
	var config: Dictionary = case["config"]
	var original_initial_hash: String = Model.state_hash(initial)
	var tape_hash: String = Model.state_hash(tape)
	var expected_hash: String = Model.state_hash(expected)
	var run1: Dictionary = M4.replay(initial,tape,config)
	var run2: Dictionary = M4.replay(initial,tape,config)
	if not run1.get("accepted",false) or not run2.get("accepted",false):
		printerr("M4_5_REPLAY_FAILED ",run1.get("error","unknown"),
			" / ",run2.get("error","unknown"))
		quit(1)
		return
	check("M45-REP-01-FULL_TAPE_EXECUTED",run1["accepted"] and tape.size() >= 28)
	check("M45-REP-02-FINAL_STATE_EQUAL",run1["state_hash"] == expected_hash)
	check("M45-REP-03-REPEATED_SAME_SEED_STATE",run1["state_hash"] == run2["state_hash"])
	check("M45-REP-04-REPEATED_SAME_SEED_EVENTS",run1["event_hash"] == run2["event_hash"])
	check("M45-REP-05-CANONICAL_LOG_MATCH",run1["events"] == run1["state"]["events"])
	check("M45-REP-06-OUTER_EVENT_SEQUENCE_MONOTONIC",_seq(run1["state"]))
	check("M45-REP-07-CARD_INSTANCES_CONSERVED",Zones.validate_state(run1["state"]["core"]["cards"]))
	check("M45-REP-08-M4_CORE_VALID",M4.validate_state(run1["state"]))
	check("M45-REP-09-INPUT_INITIAL_UNCHANGED",Model.state_hash(initial) == original_initial_hash)
	check("M45-REP-10-INPUT_TAPE_UNCHANGED",Model.state_hash(tape) == tape_hash)
	check("M45-REP-11-TWO_CONCENTRATING_CASTS",_event_count(run1["events"],"CastingStarted") == 2)
	check("M45-REP-12-ONE_LAST_COMMITTED",_event_count(run1["events"],"LastSpellCommitted") == 1)
	check("M45-REP-13-LAST_NOT_RELEASED",_event_count(run1["events"],"LastSpellReleased") == 0)
	check("M45-REP-14-ONE_LAST_INVALIDATION",_event_count(run1["events"],"LastSpellInvalidated") == 1)
	check("M45-REP-15-ORDINARY_SPELLS_RELEASED",_event_count(run1["events"],"CastingReleased") == 2)
	check("M45-REP-16-PROTECT_TWICE",_event_count(run1["events"],"AttackTargetRedirected") == 2)
	check("M45-REP-17-ONE_WARD_GRANTED",_event_count(run1["events"],"FocusWardGranted") == 1)
	check("M45-REP-18-ONE_DESTABILIZATION",_event_count(run1["events"],"LastSpellDestabilizedDelayed") == 1)
	check("M45-REP-19-NO_LAST_MP_REFUND",_event_count(run1["events"],"MPRestored") == 0)
	check("M45-REP-20-REVIVE_NO_RECAST",run1["state"]["core"]["battle"]["last_spell_used_by_actor"]["A"] == 1
		and run1["state"]["core"]["battle"]["actors"]["A"]["hp"] == 35)
	var hashes: Array[String] = []
	var event_hashes: Array[String] = []
	var receipt_count: int = 0
	var receipt_all_sha: bool = true
	var receipts: Array = []
	var sim: Dictionary = initial.duplicate(true)
	for instruction: Dictionary in tape:
		var response: Dictionary = M4.apply(sim,instruction,config)
		if not response["accepted"]:
			receipt_all_sha = false
			break
		sim = response["state"]
		receipt_count += 1
		receipts.append({"command_id":str(instruction["command_id"]),
			"seq":int(sim["event_seq"]),"hash":str(response["state_hash"])})
		if str(response["state_hash"]).length() != 64 or \
				str(response["event_hash"]).length() != 64:
			receipt_all_sha = false
	check("M45-REP-21-EACH_COMMAND_RECEIPT_HASHED",receipt_count == tape.size() and receipt_all_sha)
	check("M45-REP-22-RECEIPT_LAST_HASH_MATCHES",receipts.size() > 0
		and receipts[-1]["hash"] == run1["state_hash"])
	check("M45-REP-23-RECEIPTS_UNIQUE_COMMAND_IDS",receipts.size() == tape.size()
		and _unique_tape(tape))
	check("M45-REP-24-APPENDING_NO_HIDDEN_COMMANDS",int(sim["event_seq"]) == run1["events"].size())
	# M3.4 is a projection, never a clock, payment, or AP/MP source.
	for mode: String in ["SMART","ALWAYS_ASK","QUICK"]:
		var s: Dictionary = initial.duplicate(true)
		var valid: bool = true
		for instruction: Dictionary in tape:
			var policy: Dictionary = Policy.describe(s,mode,{
				"elapsed_seconds":120,"fps":1,"auto_pass":true,
				"significance":"MINOR","input_device":"TOUCH"})
			if not policy.get("ok",false):
				valid = false
				break
			var result: Dictionary = M4.apply(s,instruction,config)
			if not result["accepted"]:
				valid = false
				break
			s = result["state"]
		hashes.append(Model.state_hash(s))
		var independently: Dictionary = M4.replay(initial,tape,config)
		event_hashes.append(str(independently.get("event_hash","")))
		check("M45-REP-25-"+mode+"_NO_DOMAIN_MUTATION",valid
			and Model.state_hash(s) == expected_hash)
	check("M45-REP-26-ALL_UI_MODES_EQUAL_STATE",hashes[0] == hashes[1] and hashes[1] == hashes[2])
	check("M45-REP-27-ALL_UI_MODES_EQUAL_EVENTS",event_hashes[0] == event_hashes[1]
		and event_hashes[1] == event_hashes[2])
	check("M45-REP-28-NO_REALTIME_STATE_FIELD",not run1["state"].has("elapsed_seconds")
		and not run1["state"].has("deadline") and not run1["state"].has("ui_mode"))
	var stale: Array[Dictionary] = tape.duplicate(true)
	stale[7]["expected_event_seq"] = -1
	var refused: Dictionary = M4.replay(initial,stale,config)
	check("M45-REP-29-STALE_TAPE_FAILS_CLOSED",not refused["accepted"]
		and refused["error"] == "STALE_STATE"
		and refused["events"].size() < run1["events"].size())
	check("M45-REP-30-STALE_DOES_NOT_CHANGE_ORIGIN",Model.state_hash(initial) == original_initial_hash)
	var duplicate: Array[Dictionary] = tape.duplicate(true)
	duplicate[8]["command_id"] = str(duplicate[0]["command_id"])
	var dupe: Dictionary = M4.replay(initial,duplicate,config)
	check("M45-REP-31-DUPLICATE_COMMAND_REJECTED",not dupe["accepted"]
		and dupe["error"] == "DUPLICATE_COMMAND")
	var no_hp_engine: Dictionary = config.duplicate(true)
	no_hp_engine["m4_4_trusted_life_fixture"] = false
	var life_not_authorized: Dictionary = M4.replay(initial,tape,no_hp_engine)
	check("M45-REP-32-HIT_AUTHORIZATION_NOT_SKIPPED",not life_not_authorized["accepted"]
		and life_not_authorized["error"] == "M5_HP_ENGINE_NOT_AVAILABLE")
	var changed_content: Dictionary = config.duplicate(true)
	changed_content["reaction_definitions"]["regular"]["focus_ward_amount"] = 1
	var changed: Dictionary = M4.replay(initial,tape,changed_content)
	check("M45-REP-33-VERSIONED_CONTENT_AFFECTS_REPLAY",not changed["accepted"]
		or changed["event_hash"] != run1["event_hash"]
		or changed["state_hash"] != run1["state_hash"])
	var other: Dictionary = Fixture.initial(Fixture.SEED+1)
	check("M45-REP-34-SEED_DISTINGUISHES_INITIAL",not other.is_empty()
		and Model.state_hash(other) != original_initial_hash)
	check("M45-REP-35-NO_REAL_BOSS_HP_DAMAGE",run1["state"]["core"]["battle"]["actors"]["Boss"]["hp"] == 100)
	check("M45-REP-36-BOTH_HP0_ACTORS_ACCOUNTED",run1["state"]["core"]["battle"]["actors"]["B"]["hp"] == 0
		and run1["state"]["core"]["battle"]["actors"]["A"]["hp"] == 35)
	print("M4_5_REPLAY seed=",Fixture.SEED," commands=",tape.size(),
		" initial=",original_initial_hash,
		" events=",run1["event_hash"]," final=",run1["state_hash"])
	print("M4_5_REPLAY_REPORT executed=",passed+failed,
		" passed=",passed," failed=",failed)
	if failed == 0:
		print("M4_5_REPLAY_DOMAIN_ACCEPTED")
	quit(0 if failed == 0 else 1)

func _unique_tape(tape: Array[Dictionary]) -> bool:
	var ids: Dictionary = {}
	for request: Dictionary in tape:
		var id: String = str(request.get("command_id",""))
		if id.is_empty() or ids.has(id):
			return false
		ids[id] = true
	return true
