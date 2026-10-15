extends SceneTree
## M5.4 executable CORE-01/02 oracles. Never exposes HP setters as commands.
const F = preload("res://tests/fixtures/m5_4_fixture.gd")
const M5 = preload("res://scripts/domain/m5/integration/m5_domain_resolver.gd")
const Boundary = preload("res://scripts/domain/m3/phase/phase_boundary_resolver.gd")
const Status = preload("res://scripts/domain/m5/status/status_resolver.gd")
const Zones = preload("res://scripts/domain/m2/cards/card_zone_resolver.gd")
const Model = preload("res://scripts/domain/m1/combat_model.gd")
var cfg: Dictionary = {}
var n: int = 0
var passed: int = 0
var failed: int = 0
var tape: Array[Dictionary] = []

func check(id: String, valid: bool) -> void:
	if valid:
		passed += 1
		print("PASS ",id)
	else:
		failed += 1
		printerr("FAIL ",id)

func ix(events: Array, kind: String) -> int:
	for i: int in range(events.size()):
		if str(events[i].get("kind","")) == kind:
			return i
	return -1

func count(events: Array, kind: String) -> int:
	var total: int = 0
	for e: Dictionary in events:
		if str(e.get("kind","")) == kind:
			total += 1
	return total

func cmd(state: Dictionary, kind: String, fields: Dictionary = {},
		record: bool = false) -> Dictionary:
	n += 1
	var c: Dictionary = {"type":kind,"command_id":"m54:"+str(n)+":"+kind,
		"expected_event_seq":int(state["event_seq"])}
	for key: Variant in fields:
		c[key] = fields[key]
	var result: Dictionary = M5.apply(state,c,cfg)
	if record and result["accepted"]:
		tape.append(c.duplicate(true))
	return result

func deny(state: Dictionary, kind: String, fields: Dictionary, reason: String) -> bool:
	var before: String = Model.state_hash(state)
	var rng: String = Model.canonical(state["core"]["battle"]["rng"])
	var receipt: Dictionary = cmd(state,kind,fields)
	return not receipt["accepted"] and receipt["error"] == reason and \
		receipt["events"].is_empty() and receipt["state_hash"] == before and \
		Model.state_hash(state) == before and Model.state_hash(receipt["state"]) == before and \
		Model.canonical(receipt["state"]["core"]["battle"]["rng"]) == rng

func hand(state: Dictionary, actor: String) -> String:
	return str(state["core"]["cards"]["actors"][actor]["zones"]["hand"][0])

func tactical(state: Dictionary, actor: String, record: bool = false) -> Dictionary:
	return cmd(state,"PLAY_TACTICAL_SP_M53",{"actor_id":actor,
		"target_actor_id":"Boss","card_instance_id":hand(state,actor),
		"combo_mode":"NORMAL"},record)

func cycle(state: Dictionary, record: bool = false) -> Dictionary:
	var current: Dictionary = cmd(state,"END_PLAYER_PHASE",{},record)
	if not current["accepted"]: return current
	current = cmd(current["state"],"DECLARE_NEXT_ENEMY_ACTION",{},record)
	if not current["accepted"]: return current
	var eid: String = str(current["state"]["active_enemy_action_id"])
	current = cmd(current["state"],"OPEN_REACTION_WINDOW",{
		"enemy_action_id":eid},record)
	if not current["accepted"]: return current
	current = cmd(current["state"],"PASS_REACTION",{
		"window_id":str(current["state"]["reaction_window"]["window_id"])},record)
	if not current["accepted"]: return current
	current = cmd(current["state"],"RESOLVE_ENEMY_ATTACK_M5",{
		"enemy_action_id":eid},record)
	if not current["accepted"]: return current
	current = cmd(current["state"],"END_ENEMY_PHASE",{},record)
	if not current["accepted"]: return current
	return cmd(current["state"],"START_PLAYER_PHASE",{},record)

func _init() -> void:
	cfg = F.config()
	var original: Dictionary = F.paired_ko()
	if original.is_empty():
		printerr("M54_EMPTY_FIXTURE")
		quit(1)
		return
	var initial_hash: String = Model.state_hash(original)
	check("M54-01-BEFORE_COMMITTED_ACTION_ONGOING",
		str(original["core"]["battle"]["outcome"]) == "ONGOING")
	check("M54-02-NO_PUBLIC_RECOIL_DAMAGE",deny(original,"PLAY_TACTICAL_SP_M53",{
		"actor_id":"C","target_actor_id":"Boss","card_instance_id":hand(original,"C"),
		"recoil_hp":900},"M51_UNTRUSTED_DAMAGE_PAYLOAD"))
	check("M54-03-NO_FORGED_BATTLE_OUTCOME",deny(original,"PLAY_TACTICAL_SP_M53",{
		"actor_id":"C","target_actor_id":"Boss","card_instance_id":hand(original,"C"),
		"outcome":"VICTORY"},"M51_UNTRUSTED_DAMAGE_PAYLOAD"))
	var paid: Dictionary = tactical(original,"C",true)
	if not paid["accepted"]:
		printerr("M54_PAID_ACTION_FAILED: ",paid["error"])
		quit(1)
		return
	var state: Dictionary = paid["state"]
	var battle: Dictionary = state["core"]["battle"]
	check("M54-04-PAID_SP_LEGAL_HP_ZERO_BOSS",int(battle["actors"]["Boss"]["hp"]) == 0)
	check("M54-05-PAID_SP_RECOIL_HP_ZERO_C",int(battle["actors"]["C"]["hp"]) == 0)
	check("M54-06-CORE01_SIMULTANEOUS_KO_VICTORY",str(battle["outcome"]) == "VICTORY")
	check("M54-07-NO_DRAW",str(battle["outcome"]) != "DRAW")
	check("M54-08-M51_HP_DAMAGE_BEFORE_RECOIL",ix(paid["events"],"HPDamageApplied") >= 0
		and ix(paid["events"],"HPDamageApplied") <
		ix(paid["events"],"RegisteredRecoilHPDamageApplied"))
	check("M54-09-OUTCOME_AFTER_RECOIL",
		ix(paid["events"],"RegisteredRecoilHPDamageApplied") <
		ix(paid["events"],"BattleOutcomeEvaluated"))
	check("M54-10-CORE02_HP0_IMMEDIATE_INCAPACITATION",
		ix(paid["events"],"ActorIncapacitated") <
		ix(paid["events"],"BattleOutcomeEvaluated"))
	check("M54-11-ONE_PAYMENT_FOR_MULTI_EFFECT",
		int(battle["party_resources"]["current_ap"]) == 5
		and int(battle["actors"]["C"]["mp"]) == 9
		and battle["paid_cost_command_ids"].size() == 1)
	check("M54-12_CARD_CONSERVATION",Zones.validate_state(state["core"]["cards"]))
	check("M54-13-INITIAL_STATE_UNCHANGED",Model.state_hash(original) == initial_hash)
	check("M54-14-TERMINAL_PHASE_REJECTED",deny(state,"END_PLAYER_PHASE",{},"BATTLE_ENDED"))
	check("M54-15-TERMINAL_SP_REJECTED",deny(state,"PLAY_TACTICAL_SP_M53",{
		"actor_id":"C","target_actor_id":"Boss","card_instance_id":hand(state,"C")
		},"BATTLE_ENDED"))
	check("M54-16-TERMINAL_REACTION_REJECTED",deny(state,"QUEUE_REACTION",{},"BATTLE_ENDED"))
	check("M54-17-TERMINAL_CAST_REJECTED",deny(state,"CAST_SPELL_M4",{},"BATTLE_ENDED"))
	check("M54-18-TERMINAL_RANDOM_BASIC_REJECTED",deny(state,"BASIC_ATTACK_RESOURCE_ONLY",{},"BATTLE_ENDED"))
	check("M54-19-TERMINAL_UNTRUSTED_HP_DENIED",deny(state,"APPLY_INCAPACITATION_M4_FIXTURE",{},"BATTLE_ENDED"))
	var replay: Dictionary = M5.replay(original,tape,cfg)
	check("M54-20-SEED_AND_TAPE_REPLAY_ACCEPTED",replay["accepted"] and tape.size() == 1)
	check("M54-21-EVENT_HASH_IDENTICAL",replay["accepted"] and
		replay["event_hash"] == Model.event_hash(state["events"]))
	check("M54-22-STATE_HASH_IDENTICAL",replay["accepted"] and
		replay["state_hash"] == Model.state_hash(state))
	var forged_tape: Array[Dictionary] = tape.duplicate(true)
	forged_tape.append({"type":"END_PLAYER_PHASE","command_id":"m54:forged",
		"expected_event_seq":int(state["event_seq"])})
	var stopped: Dictionary = M5.replay(original,forged_tape,cfg)
	check("M54-23-TAPE_STOPS_AT_TERMINAL",not stopped["accepted"]
		and stopped["error"] == "BATTLE_ENDED")
	check("M54-24-REJECTED_TAPE_PRESERVES_TERMINAL_STATE",
		Model.state_hash(stopped["state"]) == Model.state_hash(state))
	# WIN does not require all allies to die: boss clear is always first.
	var living: Dictionary = F.paired_ko()
	living["core"]["battle"]["actors"]["C"]["hp"] = 100
	var ordinary: Dictionary = tactical(living,"C")
	check("M54-25-BOSS_DEAD_ALLY_LIVING_VICTORY",ordinary["accepted"] and
		ordinary["state"]["core"]["battle"]["outcome"] == "VICTORY" and
		int(ordinary["state"]["core"]["battle"]["actors"]["C"]["hp"]) > 0)
	# Enemy attack goes through the *published* M3 action and M5.1 hits.
	cfg = F.config()
	cfg["m5_actor_stats"]["Boss"]["patk"] = 12
	var threatened: Dictionary = F.enemy_defeat()
	var started: Dictionary = cmd(threatened,"END_PLAYER_PHASE")
	if started["accepted"]:
		started = cmd(started["state"],"DECLARE_NEXT_ENEMY_ACTION")
	if started["accepted"]:
		started = cmd(started["state"],"OPEN_REACTION_WINDOW",{
			"enemy_action_id":str(started["state"]["active_enemy_action_id"])})
	if started["accepted"]:
		started = cmd(started["state"],"PASS_REACTION",{
			"window_id":str(started["state"]["reaction_window"]["window_id"])})
	if started["accepted"]:
		started = cmd(started["state"],"RESOLVE_ENEMY_ATTACK_M5",{
			"enemy_action_id":str(started["state"]["active_enemy_action_id"])})
	check("M54-26-REAL_ENEMY_ACTION_ACCEPTED",started["accepted"])
	if started["accepted"]:
		check("M54-27-BOSS_SURVIVES_TEAM_INCAP_DEFEAT",
			int(started["state"]["core"]["battle"]["actors"]["Boss"]["hp"]) > 0
			and started["state"]["core"]["battle"]["outcome"] == "DEFEAT")
		check("M54-28-ENEMY_ACTION_SETTLED_BEFORE_DEFEAT",
			ix(started["events"],"EnemyActionResolved") <
			ix(started["events"],"BattleOutcomeEvaluated"))
		check("M54-29-DEFEAT_LOCKS_ALL_COMMANDS",
			deny(started["state"],"END_ENEMY_PHASE",{},"BATTLE_ENDED"))
	# Due status events are both committed before authoritative outcome.
	cfg = F.config()
	var ticked: Dictionary = F.tick_double_ko()
	cfg["m5_actor_stats"]["Boss"]["patk"] = 0
	var reached: Dictionary = cycle(ticked)
	check("M54-30-DOT_DOUBLE_KO_BOUNDARY_ACCEPTED",reached["accepted"])
	if reached["accepted"]:
		check("M54-31-DOT_SAME_BOUNDARY_VICTORY",reached["state"]["core"]["battle"]["outcome"] == "VICTORY")
		check("M54-32-DOT_BOTH_TARGETS_ZERO",int(reached["state"]["core"]["battle"]["actors"]["Boss"]["hp"]) == 0
			and int(reached["state"]["core"]["battle"]["actors"]["C"]["hp"]) == 0)
		check("M54-33-DOT_TICKS_BEFORE_OUTCOME",count(reached["events"],"StatusHPDamageApplied") >= 2
			and ix(reached["events"],"StatusHPDamageApplied") <
			ix(reached["events"],"BattleOutcomeEvaluated"))
		check("M54-34-NO_RESOURCE_REFRESH_ON_TERMINAL",
			count(reached["events"],"PlayerResourcesOpened") == 0)
	# A released Last Spell is irrevocable even if its legal recoil takes
	# caster HP to zero later in the SAME player-phase boundary.
	cfg = F.config()
	var last_origin: Dictionary = F.last_release()
	var last: Dictionary = cmd(last_origin,"ACTIVATE_LAST_SPELL_M4",{
		"actor_id":"A","target_actor_id":"Boss","confirmed":true,
		"casting_mode":"FULL"})
	check("M54-35-LAST_SPELL_REAL_PAYMENT_COMMITTED",last["accepted"])
	if last["accepted"]:
		var round_two: Dictionary = cycle(last["state"])
		check("M54-36-LAST_NOT_PREMATURELY_RELEASED",round_two["accepted"]
			and count(round_two["events"],"LastSpellReleased") == 0)
		if round_two["accepted"]:
			var round_three: Dictionary = cycle(round_two["state"])
			check("M54-37-LAST_RELEASE_ROUND_THREE",round_three["accepted"]
				and count(round_three["events"],"LastSpellReleased") == 1)
			if round_three["accepted"]:
				check("M54-38-RELEASED_LAST_KILLS_BOSS_AND_CASTER",round_three["state"]["core"]["battle"]["outcome"] == "VICTORY"
					and int(round_three["state"]["core"]["battle"]["actors"]["A"]["hp"]) == 0
					and int(round_three["state"]["core"]["battle"]["actors"]["Boss"]["hp"]) == 0)
				check("M54-39-RELEASE_BEFORE_RECOIL_BEFORE_OUTCOME",
					ix(round_three["events"],"LastSpellReleased") <
					ix(round_three["events"],"RegisteredRecoilHPDamageApplied")
					and ix(round_three["events"],"RegisteredRecoilHPDamageApplied") <
					ix(round_three["events"],"BattleOutcomeEvaluated"))
				check("M54-40-RELEASED_LAST_NEVER_INVALIDATED",count(round_three["events"],"LastSpellInvalidated") == 0
					and count(round_three["events"],"ScheduledEffectCancelled") == 0)
				check("M54-41-LAST_USED_NOT_RESTORED",
					int(round_three["state"]["core"]["battle"]["last_spell_used_by_actor"]["A"]) == 1
					and bool(round_three["state"]["core"]["battle"]["exhausted_lifetime_by_actor"]["A"]))
	# Poison ticks on the PRE-release boundary must invalidate Last Spell
	# immediately, while other party members keep the encounter alive.
	cfg = F.config()
	var pre: Dictionary = F.initial(F.SEED,{"A":"blank","B":"blank","C":"blank"})
	var spell: Dictionary = cmd(pre,"ACTIVATE_LAST_SPELL_M4",{
		"actor_id":"A","target_actor_id":"Boss","confirmed":true,"casting_mode":"FULL"})
	if spell["accepted"]:
		var poisoned: Dictionary = Status.grant(spell["state"]["core"],"Boss","A",
			"poison","m54-poison-after-last",cfg)
		if poisoned["ok"]:
			spell["state"]["core"] = poisoned["core"]
			var invalidated: Dictionary = cycle(spell["state"])
			check("M54-42-PRE_RELEASE_DOT_INCAPACITATES",invalidated["accepted"]
				and int(invalidated["state"]["core"]["battle"]["actors"]["A"]["hp"]) == 0)
			if invalidated["accepted"]:
				check("M54-43-CORE02_STRICT_CANCEL_CHAIN",
					ix(invalidated["events"],"ActorIncapacitated") <
					ix(invalidated["events"],"LastSpellInvalidated") and
					ix(invalidated["events"],"LastSpellInvalidated") <
					ix(invalidated["events"],"ScheduledEffectCancelled"))
				check("M54-44-NO_PRE_RELEASE_REFUND_OR_QUOTA_RESET",
					int(invalidated["state"]["core"]["battle"]["last_spell_used_by_actor"]["A"]) == 1
					and count(invalidated["events"],"MPRecovered") == 0)
				var next_phase: Dictionary = cycle(invalidated["state"])
				check("M54-45-NO_POSTHUMOUS_LAST_DAMAGE",next_phase["accepted"] and
					count(next_phase["events"],"LastSpellReleased") == 0 and
					count(next_phase["events"],"LastSpellInvalidated") == 0)
	# CORE_RULE_EDGE_PENDING: positive HP but all EXHAUSTED is not DEFEAT.
	cfg = F.config()
	var exhausted: Dictionary = F.initial()
	for actor: String in ["A","B","C"]:
		exhausted["core"]["battle"]["actors"][actor]["status"] = "EXHAUSTED"
	var edge: Dictionary = Boundary.check_action_outcome(exhausted["core"],cfg)
	check("M54-46-EXHAUSTED_POSITIVE_HP_NOT_DEFEAT",edge["ok"]
		and edge["core"]["battle"]["outcome"] == "ONGOING")
	check("M54-47-EXHAUSTED_EDGE_EXPLICIT_PENDING",edge["ok"] and
		edge["event"].get("core_rule_edge","") == "ALL_EXHAUSTED_HP_POSITIVE_PENDING_DECISION"
		and edge["event"].get("auto_defeat",true) == false)
	cfg = F.config()
	var alternate: Dictionary = cfg.duplicate(true)
	alternate["m5_3_sp_effects"]["setup"]["recoil_hp"] = 5
	cfg = alternate
	check("M54-48-VERSIONED_RECOIL_CHANGES_REPLAY_EVENT",
		M5.replay(original,tape,cfg)["event_hash"] != replay["event_hash"])
	cfg = F.config()
	print("M5_4_TEST_REPORT executed=",passed+failed," passed=",passed," failed=",failed)
	if passed == 48 and failed == 0:
		print("M5_4_OUTCOME_DOMAIN_VERIFIED")
		print("M5_4_REPLAY seed=",F.SEED," commands=",tape.size(),
			" initial=",initial_hash," events=",Model.event_hash(state["events"]),
			" final=",Model.state_hash(state))
	quit(0 if passed == 48 and failed == 0 else 1)
