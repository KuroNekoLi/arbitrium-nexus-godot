extends RefCounted
## Canonical deterministic M3.5 *test-only* command-tape composer.
## Every step runs the REAL integrated reducer; no supplied snapshots
## of expected state, no mocks of RP or CardInstance transitions.
const Fixture = preload("res://tests/fixtures/m3_5_fixture.gd")
const Domain = preload("res://scripts/domain/m3/integration/m3_domain_resolver.gd")

static func _send(context: Dictionary, kind: String,
		arguments: Dictionary = {}, tag: String = "") -> bool:
	var id: String = "m3.5:" + str(context["commands"].size()) + ":" + kind
	var state: Dictionary = context["state"]
	var cmd: Dictionary = Fixture.command(state, kind, id, arguments)
	context["commands"].append(cmd)
	var result: Dictionary = Domain.apply(state, cmd, Fixture.config())
	if not result["accepted"]:
		context["error"] = "step:" + id + " -> " + str(result["error"])
		context["failed_command"] = cmd
		return false
	context["state"] = result["state"]
	context["last_result"] = result
	if not tag.is_empty():
		context["checkpoints"][tag] = {"state": result["state"].duplicate(true),
			"events": result["events"].duplicate(true),
			"state_hash": result["state_hash"]}
	return true

static func _action(context: Dictionary, label: String) -> bool:
	return _send(context, "DECLARE_NEXT_ENEMY_ACTION", {}, label + "_declared") \
		and _send(context, "OPEN_REACTION_WINDOW", {
			"enemy_action_id": str(context["state"]["active_enemy_action_id"])
		}, label + "_opened")

static func _queue(context: Dictionary, entry: Dictionary, tag: String = "") -> bool:
	return _send(context, "QUEUE_REACTION", {
		"window_id": str(context["state"]["reaction_window"]["window_id"]),
		"entry": entry}, tag)

static func _decide(context: Dictionary, kind: String, tag: String) -> bool:
	return _send(context, kind, {
		"window_id": str(context["state"]["reaction_window"]["window_id"])
	}, tag)

static func _finish(context: Dictionary, label: String) -> bool:
	return _send(context, "COMPLETE_ENEMY_ACTION_FIXTURE", {
		"enemy_action_id": str(context["state"]["active_enemy_action_id"])
	}, label + "_finished")

static func build(seed_value: int = Fixture.SEED) -> Dictionary:
	var initial: Dictionary = Fixture.make(seed_value)
	if initial.is_empty():
		return {"ok": false, "error": "INVALID_FIXTURE"}
	var context: Dictionary = {"ok": false, "error": "",
		"initial": initial.duplicate(true), "state": initial.duplicate(true),
		"commands": [], "checkpoints": {}, "last_result": {}}
	# RP6, no UI auto-advance. Four publicly announced EnemyActions.
	if not _send(context, "END_PLAYER_PHASE", {}, "r1_enemy_phase"):
		return context
	if not _action(context, "countered"):
		return context
	if not _queue(context, Fixture.entry("REACTION_SP_FIXTURE", "A", "A", context["state"])):
		return context
	if not _queue(context, Fixture.entry("BASIC_PROTECT", "B", "A")):
		return context
	if not _queue(context, Fixture.entry("REACTION_SP_FIXTURE", "C", "C", context["state"]),
			"countered_draft"):
		return context
	if not _decide(context, "CONFIRM_REACTIONS", "countered_confirmed"):
		return context
	if not _finish(context, "countered"):
		return context
	# Guard 1 RP covers a three-hit action, then Protect B redirects the
	# entire action 2 RP. A's paid Guard is NOT retroactively refunded.
	if not _action(context, "triple"):
		return context
	if not _queue(context, Fixture.entry("BASIC_GUARD", "A", "A")):
		return context
	if not _queue(context, Fixture.entry("BASIC_PROTECT", "B", "A"), "triple_draft"):
		return context
	if not _decide(context, "CONFIRM_REACTIONS", "triple_confirmed"):
		return context
	if not _finish(context, "triple"):
		return context
	# 1 RP left. AOE cannot Protect, but one Guard can cover its hits.
	if not _action(context, "aoe"):
		return context
	if not _queue(context, Fixture.entry("BASIC_GUARD", "A", "A")):
		return context
	if not _decide(context, "CONFIRM_REACTIONS", "aoe_confirmed"):
		return context
	if not _finish(context, "aoe"):
		return context
	# Exactly zero RP -> immediate *empty* closed window with a logged
	# ReactionWindowEmptySkipped, NOT unauthorized Pass of a legal window.
	if not _action(context, "empty"):
		return context
	if not _finish(context, "empty"):
		return context
	if not _send(context, "END_ENEMY_PHASE", {}, "r1_enemy_end"):
		return context
	if not _send(context, "START_PLAYER_PHASE", {}, "r2_player_phase"):
		return context
	# Approved player free order A→A→B→A, immediate fixture AP/MP
	# settlement via the existing M2 resource ledger.
	for actor: String in ["A", "A", "B", "A"]:
		if not _send(context, "BASIC_ATTACK_RESOURCE_ONLY",
				{"actor_id": actor}, "r2_basic_" + str(context["commands"].size())):
			return context
	if not _send(context, "END_PLAYER_PHASE", {}, "r2_enemy_phase"):
		return context
	# Another complete enemy turn. No pass on time elapsed. Every legal
	# pending window receives an EXPLICIT player Pass.
	for label: String in ["countered", "triple", "aoe", "empty"]:
		if not _action(context, "r2_" + label):
			return context
		if str(context["state"]["reaction_window"]["status"]) == "DRAFTING":
			if not _decide(context, "PASS_REACTION", "r2_" + label + "_passed"):
				return context
		if not _finish(context, "r2_" + label):
			return context
	if not _send(context, "END_ENEMY_PHASE", {}, "r2_enemy_end"):
		return context
	if not _send(context, "START_PLAYER_PHASE", {}, "r3_player_phase"):
		return context
	context["ok"] = true
	return context
