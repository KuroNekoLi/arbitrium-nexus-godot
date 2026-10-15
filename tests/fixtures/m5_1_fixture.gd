extends RefCounted
## Versioned, completely TEST-ONLY M5.1 numeric fixture, not balancing canon.
const Prior = preload("res://tests/fixtures/m4_5_scenario.gd")
const Phase = preload("res://scripts/domain/m3/phase/phase_engine.gd")
static const SEED: int = 20261014
static func profile(kind: String = "PHYSICAL", mode: String = "GUARANTEED",
		hits: int = 1, crit: bool = false, element: String = "NEUTRAL") -> Dictionary:
	return {"damage_kind":kind,"hit_mode":mode,"hit_count":hits,
		"crit_eligible":crit,"skill_multiplier_bp":10000,"flat_bonus":0,
		"element_id":element}

static func config() -> Dictionary:
	var c: Dictionary = Prior.configuration()
	c["m5_damage_enabled"] = true
	c["m5_balance_authority"] = "BALANCE_PROVISIONAL"
	c["m5_balance"] = {
		"defense_k":100,"variance_bp":0,"guard_reduction_bp":4000,
		"base_hit_bp":8500,"accuracy_step_bp":100}
	c["m5_actor_stats"] = {
		"A":{"accuracy":10,"evasion":10,"patk":18,"pdef":15,
			"matk":18,"mdef":15,"crit_rate_bp":0,"crit_bonus_bp":5000},
		"B":{"accuracy":10,"evasion":10,"patk":18,"pdef":20,
			"matk":18,"mdef":20,"crit_rate_bp":0,"crit_bonus_bp":5000},
		"C":{"accuracy":10,"evasion":10,"patk":18,"pdef":50,
			"matk":18,"mdef":50,"crit_rate_bp":0,"crit_bonus_bp":5000},
		"Boss":{"accuracy":10,"evasion":10,"patk":12,"pdef":12,
			"matk":12,"mdef":12,"crit_rate_bp":0,"crit_bonus_bp":5000}}
	c["m5_element_resistance"] = {
		"A":{"NEUTRAL":10000,"FIRE":10000},
		"B":{"NEUTRAL":10000,"FIRE":10000},
		"C":{"NEUTRAL":10000,"FIRE":10000},
		"Boss":{"NEUTRAL":10000,"FIRE":12500}}
	c["m5_basic_attack_profile"] = profile()
	c["m5_spell_profiles"] = {
		"regular":profile("MAGICAL"),"nova":profile("MAGICAL")}
	c["m5_enemy_profiles"] = {"boss_strike":profile("PHYSICAL","GUARANTEED",2)}
	return c

static func initial(seed: int = SEED) -> Dictionary:
	var s: Dictionary = Prior.initial(seed)
	if s.is_empty():
		return {}
	# M3's public announcement is authoritative. M5 cannot change it
	# after the Reaction Queue is confirmed.
	s["published_intents"][0]["skill_id"] = "boss_strike"
	return s
