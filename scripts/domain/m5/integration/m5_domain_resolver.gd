extends RefCounted
## M5.1 thin, headless, deterministic entrypoint.
## M2 pay, M3 Phase and Reaction and M4 Casting remain authoritative.
const M4 = preload("res://scripts/domain/m4/integration/m4_domain_resolver.gd")
const Model = preload("res://scripts/domain/m1/combat_model.gd")
static func _deny(original: Dictionary, error: String) -> Dictionary:
	var copy: Dictionary = original.duplicate(true)
	return {"accepted":false,"error":error,"state":copy,"events":[],
		"state_hash":Model.state_hash(copy),"event_hash":Model.event_hash([])}
static func apply(state: Dictionary, command: Dictionary, config: Dictionary) -> Dictionary:
	if config.get("m5_damage_enabled",false) != true:
		return _deny(state,"M51_DAMAGE_NOT_ENABLED")
	if str(config.get("m5_balance_authority","")) != "BALANCE_PROVISIONAL":
		return _deny(state,"M51_BALANCE_NOT_VERSIONED")
	# A trusted M5 hit is computed from the intent's versioned skill, not
	# a front-end command or the M4.2/M4.4 test-only HP bridges.
	for forbidden: String in ["damage","hp_after","final_damage","verified_hit_fixture",
			"damage_recipient_actor_id","crit_result","hit_result"]:
		if command.has(forbidden):
			return _deny(state,"M51_UNTRUSTED_DAMAGE_PAYLOAD")
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
