extends RefCounted
## M2.1 basic attack MP eligibility policy.
## APPPROVED P1-D01: first SUCCESSFUL Basic Attack per actor per Player Phase.
## All numbers supplied as BALANCE_PROVISIONAL fixtures; no hidden defaults.
static func _whole_nonnegative(value: Variant) -> bool:
	# Godot JSON.parse_string() can decode JSON integer literals as float.
	# Accept exact nonnegative integral numbers, reject fractional costs and
	# values beyond the precision of a JSON/IEEE-754 integer.
	if value is int:
		return int(value) >= 0
	if value is float:
		return value >= 0.0 and value < 9007199254740992.0 and value == floor(value)
	return false

static func quote(state: Dictionary, actor_id: String, rules: Dictionary, expected_ruleset_version: String) -> Dictionary:
	if rules.get("authority", "") != "BALANCE_PROVISIONAL":
		return {"accepted": false, "error": "MISSING_PROVISIONAL_RULESET"}
	if rules.get("ruleset_version", "") != expected_ruleset_version:
		return {"accepted": false, "error": "RULESET_VERSION_MISMATCH"}
	if not rules.has("basic_attack_ap_cost") or not _whole_nonnegative(rules["basic_attack_ap_cost"]):
		return {"accepted": false, "error": "INVALID_ATTACK_COST_CONFIG"}
	if not rules.has("basic_attack_mp_gain") or not _whole_nonnegative(rules["basic_attack_mp_gain"]):
		return {"accepted": false, "error": "INVALID_MP_GAIN_CONFIG"}
	var cost: int = int(rules["basic_attack_ap_cost"])
	var gain: int = int(rules["basic_attack_mp_gain"])
	if cost < 0 or gain < 0:
		return {"accepted": false, "error": "INVALID_ATTACK_RESOURCE_CONFIG"}
	var actor: Dictionary = state["actors"][actor_id]
	var claimed: bool = bool(state["basic_attack_mp_restore_used_by_actor"].get(actor_id, false))
	var actual_gain: int = 0 if claimed else min(gain, int(actor["max_mp"]) - int(actor["mp"]))
	return {"accepted": true, "ap_cost": cost, "mp_restored": actual_gain,
		"first_success_this_player_phase": not claimed, "error": ""}
