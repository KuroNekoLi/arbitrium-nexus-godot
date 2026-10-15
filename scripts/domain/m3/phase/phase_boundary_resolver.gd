extends RefCounted
## PRE3-R09 boundary: due fixtures -> outcome priority -> real M2 resource
## renewal -> card hand refill. M4/M5 actual Casting/Status ticks are NOT run.
const Integrated = preload("res://scripts/domain/m2/integration/m2_domain_resolver.gd")
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const Zones = preload("res://scripts/domain/m2/cards/card_zone_resolver.gd")
const CastingTimeline = preload("res://scripts/domain/m4/casting/casting_timeline_resolver.gd")
const CastingInstance = preload("res://scripts/domain/m4/casting/casting_instance_resolver.gd")
const Status = preload("res://scripts/domain/m5/status/status_resolver.gd")

static func outcome(battle: Dictionary) -> String:
	var any_enemy_alive: bool = false
	for enemy_id: Variant in battle.get("enemies", []):
		if int(battle["actors"][enemy_id].get("hp", 0)) > 0:
			any_enemy_alive = true
	if not any_enemy_alive:
		return "VICTORY"
	var any_ally_alive: bool = false
	for ally_id: Variant in battle.get("allies", []):
		if int(battle["actors"][ally_id].get("hp", 0)) > 0:
			any_ally_alive = true
	return "ONGOING" if any_ally_alive else "DEFEAT"

static func _failure(core: Dictionary, code: String) -> Dictionary:
	return {"ok": false, "error": code, "core": core.duplicate(true),
		"timeline": [], "remaining_hooks": []}

static func _due_before(a: Dictionary, b: Dictionary) -> bool:
	if str(a["kind"]) != str(b["kind"]):
		return str(a["kind"]) == "CASTING_FIXTURE"
	if int(a["priority"]) != int(b["priority"]):
		return int(a["priority"]) < int(b["priority"])
	if int(a["created_seq"]) != int(b["created_seq"]):
		return int(a["created_seq"]) < int(b["created_seq"])
	return str(a["hook_id"]) < str(b["hook_id"])

static func validate_hooks(hooks: Array) -> bool:
	var ids: Dictionary = {}
	for h: Variant in hooks:
		if not h is Dictionary:
			return false
		var x: Dictionary = h
		var id: String = str(x.get("hook_id", ""))
		if id.is_empty() or ids.has(id):
			return false
		if not ["CASTING_FIXTURE", "STATUS_FIXTURE"].has(str(x.get("kind", ""))):
			return false
		if x.get("fixture_only", false) != true:
			return false
		for field: String in ["execute_round", "priority", "created_seq"]:
			if not x.get(field, null) is int:
				return false
		if int(x["execute_round"]) < 2 or int(x["created_seq"]) < 0:
			return false
		ids[id] = true
	return true

static func check_action_outcome(core: Dictionary) -> Dictionary:
	if not Integrated.validate_state(core):
		return {"ok": false, "error": "INVALID_CORE", "core": core.duplicate(true), "event": {}}
	var next: Dictionary = core.duplicate(true)
	var result: String = outcome(next["battle"])
	next["battle"]["outcome"] = result
	var event: Dictionary = {"kind": "BattleOutcomeEvaluated", "outcome": result,
		"victory_priority": true, "scope": "M3_1_HP_BOUNDARY_ONLY"}
	return {"ok": true, "error": "", "core": next, "event": event}

static func open_player(core: Dictionary, hooks: Array, config: Dictionary,
		command_id: String) -> Dictionary:
	if not Integrated.validate_state(core):
		return _failure(core, "INVALID_CORE")
	if core["battle"]["phase"] != "AWAITING_PLAYER_START":
		return _failure(core, "INVALID_PHASE")
	if str(core["battle"]["outcome"]) != "ONGOING":
		return _failure(core, "BATTLE_ENDED")
	if not validate_hooks(hooks):
		return _failure(core, "INVALID_BOUNDARY_HOOKS")
	# Fail closed instead of silently dropping unscheduled actual M4/M5 work.
	if not core["battle"]["statuses"].is_empty():
		if config.get("m5_2_status_enabled",false) != true:
			return _failure(core, "UNIMPLEMENTED_REAL_TICKS")
		if not Status.validate(core,config):
			return _failure(core, "M52_INVALID_STATUS_STATE")
	if not core["battle"]["casting_instances"].is_empty() and config.get("m4_dual_cast_enabled", false) != true:
		return _failure(core, "UNIMPLEMENTED_REAL_TICKS")
	var next_round: int = int(core["battle"]["round"]) + 1
	var due: Array[Dictionary] = []
	var remaining: Array = []
	for item: Variant in hooks:
		var h: Dictionary = item
		if int(h["execute_round"]) == next_round:
			due.append(h.duplicate(true))
		else:
			if int(h["execute_round"]) < next_round:
				return _failure(core, "MISSED_BOUNDARY_HOOK")
			remaining.append(h.duplicate(true))
	due.sort_custom(_due_before)
	var state: Dictionary = core.duplicate(true)
	var timeline: Array = []
	# M4.1 actual CastingInstance releases before legacy fixture hooks,
	# Outcome, M2 AP renewal and M2 draw-to-four.
	if config.get("m4_dual_cast_enabled", false) == true:
		var released: Dictionary = CastingTimeline.settle_due(state, next_round, config, command_id)
		if not released["ok"]:
			return _failure(core, str(released["error"]))
		state = released["core"]
		timeline.append_array(released["timeline"])
	for hook: Dictionary in due:
		if str(hook["kind"]) == "CASTING_FIXTURE":
			# Strictly a physical Casting -> Discard fixture; DOES NOT cast
			# magic or refund MP. Reject nonexistent/moved instance.
			var id: String = str(hook.get("card_instance_id", ""))
			var actor: String = str(hook.get("actor_id", ""))
			if Zones.location(state["cards"], actor, id) != "casting":
				return _failure(core, "CASTING_FIXTURE_NOT_IN_ZONE")
			var settle: Dictionary = Integrated.apply(state, {
				"type": "RESOLVE_CAST_ZONE_FIXTURE",
				"command_id": command_id + ":fixture:" + str(hook["hook_id"]),
				"expected_event_seq": int(state["event_seq"]),
				"actor_id": actor, "card_instance_id": id}, config)
			if not settle["accepted"]:
				return _failure(core, str(settle["error"]))
			state = settle["state"]
			for event: Dictionary in settle["events"]:
				timeline.append({"kind": "core_event", "raw": event})
		timeline.append({"kind": "BoundaryHookFixtureResolved",
			"hook_id": str(hook["hook_id"]), "fixture_kind": str(hook["kind"]),
			"effect_resolution": "DEFERRED_TO_M4_M5"})
	# Status tick after due Full/Last Chant but before outcome/AP renewal.
	# Newly granted status in this same boundary cannot tick prematurely.
	if config.get("m5_2_status_enabled",false) == true:
		var status_tick: Dictionary = Status.tick(state,next_round,config,command_id)
		if not status_tick["ok"]:
			return _failure(core,str(status_tick["error"]))
		state = status_tick["core"]
		timeline.append_array(status_tick["timeline"])
	# Remaining cards in Casting are legal ONLY if paired with an active
	# later-due CastingInstance. M3 fixtures still fail closed.
	if not CastingInstance.valid(state):
		return _failure(core, "INVALID_CASTING_INSTANCE_LINK")
	for ally: Variant in state["cards"]["actors"]:
		for card_id: Variant in state["cards"]["actors"][ally]["zones"]["casting"]:
			var accounted: bool = false
			for instance: Variant in state["battle"]["casting_instances"].values():
				if str(instance["caster_id"]) == str(ally) and str(instance["card_instance_id"]) == str(card_id) and int(instance["planned_resolve_round"]) > next_round:
					accounted = true
			if not accounted:
				return _failure(core, "UNRESOLVED_CASTING_ZONE")
	var checked: Dictionary = check_action_outcome(state)
	if not checked["ok"]:
		return _failure(core, str(checked["error"]))
	state = checked["core"]
	timeline.append(checked["event"])
	if str(state["battle"]["outcome"]) != "ONGOING":
		return {"ok": true, "error": "", "core": state, "timeline": timeline,
			"remaining_hooks": remaining, "battle_ended": true}
	var refreshed: Dictionary = Integrated.apply(state, {
		"type": "START_PLAYER_RESOURCES",
		"command_id": command_id + ":resources",
		"expected_event_seq": int(state["event_seq"])}, config)
	if not refreshed["accepted"]:
		return _failure(core, str(refreshed["error"]))
	state = refreshed["state"]
	# Integrated M2 already executes resource renewal, swap quota reset, and
	# draw_to_four in that order. Never implement those calculations twice.
	for event: Dictionary in refreshed["events"]:
		timeline.append({"kind": "core_event", "raw": event})
	return {"ok": true, "error": "", "core": state, "timeline": timeline,
		"remaining_hooks": remaining, "battle_ended": false}
