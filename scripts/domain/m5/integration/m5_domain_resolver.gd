extends RefCounted
## M5.1 thin, headless, deterministic entrypoint.
## M2 pay, M3 Phase and Reaction and M4 Casting remain authoritative.
const M4 = preload("res://scripts/domain/m4/integration/m4_domain_resolver.gd")
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const M2 = preload("res://scripts/domain/m2/integration/m2_domain_resolver.gd")
const Boundary = preload("res://scripts/domain/m3/phase/phase_boundary_resolver.gd")
const Status = preload("res://scripts/domain/m5/status/status_resolver.gd")
const HP = preload("res://scripts/domain/m5/status/hp_lifecycle_bridge.gd")
const Zones = preload("res://scripts/domain/m2/cards/card_zone_resolver.gd")
static func _deny(original: Dictionary, error: String) -> Dictionary:
	var copy: Dictionary = original.duplicate(true)
	return {"accepted":false,"error":error,"state":copy,"events":[],
		"state_hash":Model.state_hash(copy),"event_hash":Model.event_hash([])}

static func _event(next: Dictionary, output: Array, kind: String,
		command_id: String, detail: Dictionary) -> void:
	next["event_seq"] = int(next["event_seq"])+1
	var event: Dictionary = {"event_seq":int(next["event_seq"]),"kind":kind,
		"command_id":command_id,"source":"m5_status","details":detail.duplicate(true),
		"phase":str(next["phase"]),"round":int(next["core"]["battle"]["round"])}
	next["events"].append(event)
	output.append(event)

## Each status/heal/dispel/revive is backed by a real hand-owned SP and
## one M2 payment. No caller may specify amount, tags, final HP or tick.
static func _status_sp(original: Dictionary, command: Dictionary,
		config: Dictionary) -> Dictionary:
	if config.get("m5_2_status_enabled",false) != true:
		return _deny(original,"M52_STATUS_NOT_ENABLED")
	if not M4.validate_state(original):
		return _deny(original,"M52_INVALID_BATTLE_STATE")
	var id: String = str(command.get("command_id",""))
	if id.is_empty() or original["seen_command_ids"].has(id):
		return _deny(original,"INVALID_OR_DUPLICATE_COMMAND")
	if not command.get("expected_event_seq",null) is int or \
			int(command["expected_event_seq"]) != int(original["event_seq"]):
		return _deny(original,"STALE_STATE")
	var battle: Dictionary = original["core"]["battle"]
	if original["phase"] != "PLAYER_PHASE" or battle["outcome"] != "ONGOING":
		return _deny(original,"M52_INVALID_STATUS_PHASE")
	var actor: String = str(command.get("actor_id",""))
	var target: String = str(command.get("target_actor_id",""))
	var card: String = str(command.get("card_instance_id",""))
	if not battle["allies"].has(actor) or not battle["actors"].has(target) or \
			int(battle["actors"][actor]["hp"]) <= 0 or \
			str(battle["actors"][actor]["status"]) != "ACTIVE":
		return _deny(original,"M52_INVALID_STATUS_ACTOR")
	if Zones.location(original["core"]["cards"],actor,card) != "hand":
		return _deny(original,"M52_CARD_NOT_IN_HAND")
	var definition: String = str(original["core"]["cards"]["actors"][actor]["instances"][card]["definition_id"])
	var effects: Variant = config.get("m5_status_sp_effects",null)
	if not effects is Dictionary or not effects.has(definition) or \
			not effects[definition] is Dictionary:
		return _deny(original,"M52_UNREGISTERED_STATUS_SP")
	var effect: Dictionary = effects[definition]
	var kind: String = str(effect.get("kind",""))
	var team: String = str(effect.get("target_team",""))
	if not ["STATUS","HEAL","REVIVE","DISPEL"].has(kind) or \
			not ["ALLY","ENEMY","ANY"].has(team):
		return _deny(original,"M52_INVALID_STATUS_SP_DEFINITION")
	if team == "ALLY" and not battle["allies"].has(target):
		return _deny(original,"M52_WRONG_TEAM")
	if team == "ENEMY" and not battle["enemies"].has(target):
		return _deny(original,"M52_WRONG_TEAM")
	var hp_before: int = int(battle["actors"][target]["hp"])
	if kind == "REVIVE":
		if hp_before != 0 or effect.get("revive_tag",false) != true:
			return _deny(original,"M52_REVIVE_TARGET_REQUIRED")
	elif hp_before <= 0:
		return _deny(original,"M52_TARGET_INCAPACITATED")
	var next: Dictionary = original.duplicate(true)
	var paid: Dictionary = M2.apply(next["core"],{
		"type":"COMMIT_SP_CARD_FIXTURE","command_id":id,
		"expected_event_seq":int(next["core"]["event_seq"]),
		"actor_id":actor,"card_instance_id":card,"casting_mode":"CHANTLESS"
	},config)
	if not paid["accepted"]:
		return _deny(original,str(paid["error"]))
	next["core"] = paid["state"]
	var output: Array = []
	for wrapped: Dictionary in paid["events"]:
		_event(next,output,str(wrapped["event"]["kind"]),id,
			{"core_event":wrapped,"proven_payment":true})
	var result: Dictionary = {}
	if kind == "STATUS":
		result = Status.grant(next["core"],actor,target,str(effect.get("status_id","")),
			id,config)
	elif kind == "HEAL":
		if not effect.get("amount",null) is int:
			return _deny(original,"M52_HEAL_CONTENT_INVALID")
		result = HP.heal(next["core"],target,int(effect["amount"]))
	elif kind == "REVIVE":
		if not effect.get("restored_hp",null) is int:
			return _deny(original,"M52_REVIVE_CONTENT_INVALID")
		result = HP.revive(next["core"],target,int(effect["restored_hp"]))
	elif kind == "DISPEL":
		result = Status.dispel(next["core"],target,str(effect.get("dispel_tag","")),
			config)
	if not result.get("ok",false):
		return _deny(original,str(result.get("error","M52_EFFECT_FAILED")))
	next["core"] = result["core"]
	for e: Dictionary in result["timeline"]:
		if str(e["kind"]) == "core_event":
			_event(next,output,str(e["raw"]["event"]["kind"]),id,{"core_event":e["raw"]})
		else:
			_event(next,output,str(e["kind"]),id,e)
	_event(next,output,"PlayerActionSettled",id,{
		"actor_id":actor,"target_actor_id":target,"card_definition_id":definition,
		"action_type":"USE_EFFECT_SP_M5","charged_once":true})
	var outcome: Dictionary = Boundary.check_action_outcome(next["core"])
	if not outcome["ok"]:
		return _deny(original,str(outcome["error"]))
	next["core"] = outcome["core"]
	_event(next,output,"BattleOutcomeEvaluated",id,outcome["event"])
	if not M4.validate_state(next) or not Status.validate(next["core"],config):
		return _deny(original,"M52_STATUS_STATE_INVALID")
	next["seen_command_ids"].append(id)
	return {"accepted":true,"error":"","state":next,"events":output,
		"state_hash":Model.state_hash(next),"event_hash":Model.event_hash(output)}

static func apply(state: Dictionary, command: Dictionary, config: Dictionary) -> Dictionary:
	if config.get("m5_damage_enabled",false) != true:
		return _deny(state,"M51_DAMAGE_NOT_ENABLED")
	if str(config.get("m5_balance_authority","")) != "BALANCE_PROVISIONAL":
		return _deny(state,"M51_BALANCE_NOT_VERSIONED")
	# A trusted M5 hit is computed from the intent's versioned skill, not
	# a front-end command or the M4.2/M4.4 test-only HP bridges.
	for forbidden: String in ["damage","hp_after","final_damage","verified_hit_fixture",
			"damage_recipient_actor_id","crit_result","hit_result",
			"status_id","stacks","tick_amount","duration_ticks","restored_hp","revive_tag","heal_amount"]:
		if command.has(forbidden):
			return _deny(state,"M51_UNTRUSTED_DAMAGE_PAYLOAD")
	if str(command.get("type","")) == "USE_EFFECT_SP_M5":
		return _status_sp(state,command,config)
	if ["APPLY_INCAPACITATION_M4_FIXTURE","APPLY_REVIVE_M4_FIXTURE",
			"APPLY_CASTING_DISRUPTION_M4_FIXTURE","COMPLETE_ENEMY_ACTION_FIXTURE"].has(
				str(command.get("type",""))):
		return _deny(state,"M51_INTERNAL_FIXTURE_NOT_PUBLIC")
	return M4.apply(state,command,config)

static func replay(initial: Dictionary, tape: Array[Dictionary],
		config: Dictionary) -> Dictionary:
	var s: Dictionary = initial.duplicate(true)
	var records: Array = []
	for command: Dictionary in tape:
		var result: Dictionary = apply(s,command,config)
		if not result["accepted"]:
			return {"accepted":false,"error":result["error"],"state":s,"events":records,
				"state_hash":Model.state_hash(s),"event_hash":Model.event_hash(records)}
		s = result["state"]
		records.append_array(result["events"])
	return {"accepted":true,"error":"","state":s,"events":records,
		"state_hash":Model.state_hash(s),"event_hash":Model.event_hash(records)}
