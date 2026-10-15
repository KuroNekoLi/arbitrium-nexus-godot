extends RefCounted
## Called only by the existing M5 entry after the shared untrusted-input guard.
const M4 = preload("res://scripts/domain/m4/integration/m4_domain_resolver.gd")
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const Boundary = preload("res://scripts/domain/m3/phase/phase_boundary_resolver.gd")
const Cards = preload("res://scripts/domain/m5/lv40/lv40_card_resolver.gd")
const Boss = preload("res://scripts/domain/m5/lv40/lv40_boss.gd")
const HP = preload("res://scripts/domain/m5/status/hp_lifecycle_bridge.gd")
const Status = preload("res://scripts/domain/m5/status/status_resolver.gd")

static func deny(state: Dictionary, reason: String) -> Dictionary:
	return {"accepted":false,"error":reason,"state":state.duplicate(true),"events":[],
		"state_hash":Model.state_hash(state),"event_hash":Model.event_hash([])}

static func emit(state: Dictionary, output: Array, record: Dictionary, id: String) -> void:
	state["event_seq"] = int(state["event_seq"])+1
	var details: Dictionary = record.duplicate(true)
	var kind: String = str(details.get("kind",""))
	if kind == "core_event":
		kind = str(details["raw"]["event"]["kind"])
		details = {"core_event":details["raw"]}
	elif details.has("core_event"):
		details = {"core_event":details["core_event"]}
	else:
		details.erase("kind")
	var event: Dictionary = {"kind":kind,"details":details,"event_seq":state["event_seq"],
		"command_id":id,"source":"m5_lv40","phase":state["phase"],"round":state["core"]["battle"]["round"]}
	state["events"].append(event)
	output.append(event)

static func receipt(next: Dictionary, output: Array) -> Dictionary:
	return {"accepted":true,"error":"","state":next,"events":output,
		"state_hash":Model.state_hash(next),"event_hash":Model.event_hash(output)}

static func apply(state: Dictionary, command: Dictionary, config: Dictionary) -> Dictionary:
	if not M4.validate_state(state) or not state["core"]["battle"].has("lv40"):
		return deny(state,"LV40_INVALID_ENCOUNTER_STATE")
	if str(state["core"]["battle"]["lv40"].get("version","")) != str(config.get("m5_lv40_content_version","")):
		return deny(state,"LV40_CONTENT_VERSION_MISMATCH")
	var id: String = str(command.get("command_id",""))
	if id.strip_edges().is_empty() or state["seen_command_ids"].has(id):
		return deny(state,"INVALID_OR_DUPLICATE_COMMAND")
	if not command.get("expected_event_seq",null) is int or int(command["expected_event_seq"]) != int(state["event_seq"]):
		return deny(state,"STALE_STATE")
	var kind: String = str(command.get("type",""))
	var next: Dictionary = state.duplicate(true)
	var output: Array = []
	if kind == "PLAY_LV40_CARD":
		# Only a declared intent is accepted from the client. No effect fields.
		for key: String in command:
			if not ["type","command_id","expected_event_seq","actor_id","card_instance_id","target_actor_id","casting_mode","combo_mode"].has(key):
				return deny(state,"LV40_UNTRUSTED_CARD_PAYLOAD")
		var acted: Dictionary = Cards.play(state,command,config)
		if not acted["ok"]:
			return deny(state,str(acted["error"]))
		next["core"] = acted["core"]
		for record: Dictionary in acted["timeline"]:
			emit(next,output,record,id)
		emit(next,output,{"kind":"PlayerActionSettled","actor_id":str(command["actor_id"]),
			"card_definition_id":acted["card_definition_id"],"action_type":kind,"charged_once":true},id)
		var judged: Dictionary = Boundary.check_action_outcome(next["core"],config)
		if not judged["ok"]:
			return deny(state,str(judged["error"]))
		next["core"] = judged["core"]
		emit(next,output,{"kind":"BattleOutcomeEvaluated","outcome":next["core"]["battle"]["outcome"]},id)
		next["seen_command_ids"].append(id)
	elif kind == "END_PLAYER_PHASE":
		if next["phase"] != "PLAYER_PHASE" or next["published_intents"].size() != 1:
			return deny(state,"LV40_INVALID_PHASE")
		var prepared: Dictionary = Boss.before_end(next["core"],next["published_intents"][0],config)
		next["core"] = prepared["core"]
		next["published_intents"] = [prepared["intent"]]
		var downstream: Dictionary = M4.apply(next,command,config)
		if not downstream["accepted"]:
			return deny(state,str(downstream["error"]))
		next = downstream["state"]
		output = downstream["events"]
		emit(next,output,{"kind":"BossIntentCommitted","public_intent":prepared["intent"],
			"fallback":bool(prepared["intent"].get("break_fallback",false))},id)
		var fsm: Dictionary = next["core"]["battle"]["m53"]
		if not fsm["exposed"].is_empty() and int(fsm["exposed"].get("expires_round",0)) <= int(next["core"]["battle"]["round"]):
			fsm["exposed"] = {}
			emit(next,output,{"kind":"ExposedExpired","target_id":"Boss"},id)
		fsm["combo"] = {}
		for actor: String in next["core"]["battle"]["lv40"]["spell_power"].keys():
			if int(next["core"]["battle"]["lv40"]["spell_power"][actor]["expires_round"]) <= int(next["core"]["battle"]["round"]):
				next["core"]["battle"]["lv40"]["spell_power"].erase(actor)
				emit(next,output,{"kind":"SpellPowerExpired","actor_id":actor},id)
	else:
		if ["PLAY_TACTICAL_SP_M53","USE_EFFECT_SP_M5","COMMIT_SP_CARD_FIXTURE","CAST_SPELL_M4",
			"EXTRA_DRAW_FIXTURE","COMPLETE_ENEMY_ACTION_FIXTURE","APPLY_CASTING_DISRUPTION_M4_FIXTURE",
			"APPLY_INCAPACITATION_M4_FIXTURE","APPLY_REVIVE_M4_FIXTURE"].has(kind):
			return deny(state,"LV40_USE_CONTENT_COMMAND")
		if kind == "ACTIVATE_LAST_SPELL_M4":
			var actor: String = str(command.get("actor_id",""))
			var target: String = str(command.get("target_actor_id",""))
			if (actor == "C" and not next["core"]["battle"]["allies"].has(target)) or (actor != "C" and target != "Boss"):
				return deny(state,"LV40_ILLEGAL_LAST_SPELL_TARGET")
		var delegated: Dictionary = M4.apply(next,command,config)
		if not delegated["accepted"]:
			return delegated
		next = delegated["state"]
		output = delegated["events"]
		if kind == "END_ENEMY_PHASE":
			var boundary: Dictionary = end_enemy(next["core"],config,id)
			if not boundary["ok"]:
				return deny(state,str(boundary["error"]))
			next["core"] = boundary["core"]
			for record: Dictionary in boundary["timeline"]:
				emit(next,output,record,id)
			var judged: Dictionary = Boundary.check_action_outcome(next["core"],config)
			if not judged["ok"]:
				return deny(state,str(judged["error"]))
			next["core"] = judged["core"]
			emit(next,output,{"kind":"BattleOutcomeEvaluated","outcome":next["core"]["battle"]["outcome"]},id)
		if kind == "START_PLAYER_PHASE" and next["core"]["battle"]["outcome"] == "ONGOING":
			var publication: Dictionary = Boss.publish(next["core"],config)
			next["core"] = publication["core"]
			next["published_intents"] = [publication["intent"]]
			for record: Dictionary in publication["timeline"]:
				emit(next,output,record,id)
			emit(next,output,{"kind":"BossIntentCommitted","public_intent":publication["intent"]},id)
	if not M4.validate_state(next):
		return deny(state,"LV40_INVARIANT_FAILED")
	return receipt(next,output)

static func end_enemy(core: Dictionary, config: Dictionary, id: String) -> Dictionary:
	var next: Dictionary = core.duplicate(true)
	var records: Array = []
	# Existing M5 Status engine owns instance stacking, refresh, tick and dispel.
	# The optional boundary selector is added by the pending integration patch.
	var tick: Dictionary = Status.call("tick",next,int(next["battle"]["round"])+1,config,id,"ENEMY_PHASE_END")
	if not tick["ok"]:
		return tick
	next = tick["core"]
	records.append_array(tick["timeline"])
	for target: String in next["battle"]["lv40"]["barrier_expiry"].keys():
		var expires: int = int(next["battle"]["lv40"]["barrier_expiry"][target])
		if expires >= 0 and expires <= int(next["battle"]["round"]):
			next["battle"]["hp_barriers"][target] = 0.0
			next["battle"]["lv40"]["barrier_expiry"].erase(target)
			records.append({"kind":"HPBarrierExpired","actor_id":target})
	return {"ok":true,"core":next,"timeline":records}
