extends "res://tests/test_lv40_domain.gd"
## BKC-04: real Lv40 Domain actions, public Intent branches and seed replay.
## Config overrides below are controlled test fixtures, never client payload.
const View = preload("res://scripts/battle/presentation/battle_presentation_adapter.gd")

func _initialize() -> void:
	var r: Dictionary = rig()
	check(bool(r["config"].get("m5_break_c_enabled",false)), "BKC-01-OPT_IN_CONTENT")
	check(str(r["state"]["published_intents"][0].get("break_response","")) == "CANCEL",
		"BKC-02-PUBLIC_PREVIEW_INITIAL")
	# Break does not require CORE_OPEN or a self-revealing Boss action.
	r["state"]["core"]["battle"]["m53"]["break_gauge"] = 1
	r["config"]["m5_3_sp_effects"]["R01"]["damage_profile"]["hit_mode"] = "GUARANTEED"
	var seed_state: Dictionary = r["state"].duplicate(true)
	check(play(r,"A","R01","Boss") and has_event(r["last"],"BreakTriggered") and
		has_event(r["last"],"ExposedApplied"),"BKC-03-BREAK_AUTO_EXPOSED")
	check(str(r["state"]["core"]["battle"]["m53"]["exposed"].get("source","")) == "BREAK",
		"BKC-04-AUTO_EXPOSED_SOURCE")
	check(has_event(r["last"],"ComboOpportunityOffered") and not has_event(r["last"],"ExposedConsumed"),
		"BKC-05-INDEPENDENT_COMBO_AND_NO_SELF_CONSUME")
	check(position(r["last"],"DamageTrace") < position(r["last"],"BreakTriggered"),
		"BKC-06-WHOLE_SP_FIRST")
	check(step(r,"END_PLAYER_PHASE") and
		str(r["state"]["enemy_actions"][0]["public_intent"].get("break_c_result","")) == "CANCEL" and
		not bool(r["state"]["enemy_actions"][0]["public_intent"]["requires_reaction_window"]),
		"BKC-07-REGULAR_CANCEL_PREANNOUNCED")
	check(step(r,"DECLARE_NEXT_ENEMY_ACTION") and
		step(r,"RESOLVE_ENEMY_ATTACK_M5",{"enemy_action_id":r["state"]["active_enemy_action_id"]}) and
		has_event(r["last"],"BossActionCancelledByBreak") and not has_event(r["last"],"DamageTrace"),
		"BKC-08-CANCEL_NO_DAMAGE_NO_FAKE_REACTION")
	check(int(r["state"]["core"]["battle"]["m53"]["break_gauge"]) == 22 and
		int(r["state"]["core"]["battle"]["m53"]["break_resilience_round"]) == 2,
		"BKC-09-BREAK_RESTORES_AND_GUARDS_NEXT_PHASE")
	check(next_round(r) and int(r["state"]["core"]["battle"]["round"]) == 2,
		"BKC-10-NEXT_PLAYER_PHASE")
	r["state"]["core"]["battle"]["m53"]["break_gauge"] = 1
	check(play(r,"A","R01","Boss") and has_event(r["last"],"BreakDamageIgnoredResilient") and
		not has_event(r["last"],"BreakTriggered") and
		int(r["state"]["core"]["battle"]["m53"]["break_gauge"]) == 1,
		"BKC-11-RECOVERY_PREVENTS_PERMA_STUN")
	# Compare a deterministic tape from its exact initial domain state.
	var replay_r: Dictionary = rig()
	replay_r["state"] = seed_state.duplicate(true)
	replay_r["config"]["m5_3_sp_effects"]["R01"]["damage_profile"]["hit_mode"] = "GUARANTEED"
	check(play(replay_r,"A","R01","Boss") and
		step(replay_r,"END_PLAYER_PHASE") and step(replay_r,"DECLARE_NEXT_ENEMY_ACTION") and
		step(replay_r,"RESOLVE_ENEMY_ATTACK_M5",{"enemy_action_id":replay_r["state"]["active_enemy_action_id"]}),
		"BKC-12-DETERMINISTIC_TAPE_CREATED")
	var reproduced: Dictionary = M5.replay(seed_state,replay_r["tape"],replay_r["config"])
	check(reproduced["accepted"] and reproduced["state_hash"] == Model.state_hash(replay_r["state"]) and
		reproduced["event_hash"] == Model.event_hash(replay_r["events"]),
		"BKC-13-SEEDED_REPLAY_HASH_MATCH")
	# Charge preparation must downgrade to a nonattacking B12 and skip the
	# prevented release B06; there is no ghost scheduled cast.
	r = rig()
	announce(r,"B05")
	r["state"]["core"]["battle"]["m53"]["break_gauge"] = 1
	r["config"]["m5_3_sp_effects"]["R01"]["damage_profile"]["hit_mode"] = "GUARANTEED"
	check(play(r,"A","R01","Boss") and step(r,"END_PLAYER_PHASE") and
		str(r["state"]["enemy_actions"][0]["public_intent"]["skill_id"]) == "B12" and
		str(r["state"]["enemy_actions"][0]["public_intent"]["break_controlled_skill_id"]) == "B05",
		"BKC-14-MAJOR_CHARGE_DOWNGRADE")
	check(step(r,"DECLARE_NEXT_ENEMY_ACTION") and
		step(r,"RESOLVE_ENEMY_ATTACK_M5",{"enemy_action_id":r["state"]["active_enemy_action_id"]}) and
		has_event(r["last"],"BossChargeDowngraded") and
		r["state"]["core"]["battle"]["lv40"]["pending_cast"].is_empty(),
		"BKC-15-NO_GHOST_CAST")
	check(next_round(r) and str(r["state"]["published_intents"][0]["skill_id"]) == "B04",
		"BKC-16-CHARGE_RELEASE_SLOT_SKIPPED")
	# Player counter and Break can both be present. A05 genuinely interrupts
	# the casting instance; cancelled B06 must not be replaced by another hit.
	r = rig()
	announce(r,"B05")
	check(enemy(r) and next_round(r),"BKC-17-REAL_CAST_SETUP")
	r["state"]["core"]["battle"]["m53"]["break_gauge"] = 1
	r["config"]["m5_3_sp_effects"]["R01"]["damage_profile"]["hit_mode"] = "GUARANTEED"
	check(play(r,"A","R01","Boss") and play(r,"B","A05","Boss") and
		has_event(r["last"],"CastingInterrupted"),"BKC-18-BREAK_WITH_DISRUPTION")
	check(step(r,"END_PLAYER_PHASE") and str(r["state"]["enemy_actions"][0]["public_intent"]["skill_id"]) == "B10",
		"BKC-19-INTERRUPTED_CAST_PRIORITY")
	check(step(r,"DECLARE_NEXT_ENEMY_ACTION") and
		step(r,"RESOLVE_ENEMY_ATTACK_M5",{"enemy_action_id":r["state"]["active_enemy_action_id"]}) and
		has_event(r["last"],"BossCooldown"),"BKC-20-COOLDOWN_NOT_NEW_ATTACK")
	check(step(r,"END_ENEMY_PHASE") and not bool(r["state"]["core"]["battle"]["m53"]["break_locked"]) and
		not r["state"]["core"]["battle"]["m53"]["exposed"].is_empty(),
		"BKC-21-UNUSED_BREAK_EXPIRES_EXPOSED_REMAINS")
	# Boss posture is optional and never a prerequisite for ordinary Combo.
	r = rig()
	r["state"]["core"]["battle"]["lv40"]["core_open"] = true
	r["config"]["m5_3_boss"]["exposed_rules"]["on_special_posture"] = false
	r["config"]["m5_3_sp_effects"]["R01"]["damage_profile"]["hit_mode"] = "GUARANTEED"
	check(play(r,"A","R01","Boss") and not has_event(r["last"],"ExposedApplied") and
		has_event(r["last"],"ComboOpportunityOffered"),
		"BKC-22-POSTURE_CAN_BE_DISABLED")
	r = rig()
	r["config"]["m5_3_boss"]["exposed_rules"]["on_boss_action"] = true
	r["config"]["m5_3_boss"]["exposed_rules"]["action_skill_ids"] = ["B01"]
	check(enemy(r) and has_event(r["last"],"ExposedApplied") and
		str(r["state"]["core"]["battle"]["m53"]["exposed"].get("source","")) == "BOSS_ACTION",
		"BKC-23-OPTIONAL_BOSS_ACTION_EXPOSED")
	var v: Dictionary = View.project(r["state"],r["config"])
	check(v["public_intent_labels"].size() > 0 and
		str(v["public_intent_labels"][0].get("break_response","")) == "CANCEL",
		"BKC-24-PUBLIC_INTENT_PROJECTION")
	print("BKC_BREAK_C_REPORT executed=%d passed=%d failed=%d" % [
		passed+failed,passed,failed])
	quit(1 if failed > 0 else 0)
