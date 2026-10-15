extends "res://tests/test_lv40_domain.gd"
const StatusEngine = preload("res://scripts/domain/m5/status/status_resolver.gd")

func _initialize() -> void:
	# T05 true M2 payment and HP Barrier, no target redirect.
	var r: Dictionary = rig()
	in_hand(r["state"],"C","T05")
	announce(r,"B03")
	check(step(r,"END_PLAYER_PHASE") and step(r,"DECLARE_NEXT_ENEMY_ACTION") and step(r,"OPEN_REACTION_WINDOW",{"enemy_action_id":r["state"]["active_enemy_action_id"]}),"DEMO-05-T05-OPEN")
	check(step(r,"QUEUE_REACTION",{"window_id":r["state"]["reaction_window"]["window_id"],
		"entry":{"kind":"REACTION_SP_FIXTURE","actor_id":"C","card_instance_id":in_hand(r["state"],"C","T05"),"target_actor_id":"B"}}) and step(r,"CONFIRM_REACTIONS",{"window_id":r["state"]["reaction_window"]["window_id"]}),"DEMO-05-T05-CONFIRM")
	check(r["state"]["core"]["battle"]["party_resources"]["rp"] == 5 and r["state"]["core"]["battle"]["actors"]["C"]["mp"] == 10,"DEMO-05-T05-EXACT-COST")
	check(float(r["state"]["core"]["battle"]["hp_barriers"]["B"]) == 130 and r["state"]["reaction_window"]["damage_recipient_actor_id"] == "","DEMO-05-T05-NO-REDIRECT")
	# JIT: earlier R05 changes recipient; pending T05 on old recipient skips.
	r = rig()
	var r05: String = in_hand(r["state"],"A","R05")
	var t05: String = in_hand(r["state"],"C","T05")
	announce(r,"B03")
	check(step(r,"END_PLAYER_PHASE") and step(r,"DECLARE_NEXT_ENEMY_ACTION") and step(r,"OPEN_REACTION_WINDOW",{"enemy_action_id":r["state"]["active_enemy_action_id"]}),"DEMO-05-JIT-OPEN")
	check(step(r,"QUEUE_REACTION",{"window_id":r["state"]["reaction_window"]["window_id"],"entry":{"kind":"REACTION_SP_FIXTURE","actor_id":"A","card_instance_id":r05,"target_actor_id":"B"}}),"DEMO-05-JIT-R05-DRAFT")
	check(step(r,"QUEUE_REACTION",{"window_id":r["state"]["reaction_window"]["window_id"],"entry":{"kind":"REACTION_SP_FIXTURE","actor_id":"C","card_instance_id":t05,"target_actor_id":"B"}}),"DEMO-05-JIT-T05-DRAFT")
	check(step(r,"CONFIRM_REACTIONS",{"window_id":r["state"]["reaction_window"]["window_id"]}) and has_event(r["last"],"ReactionSkipped"),"DEMO-05-JIT-SKIPPED")
	check(r["state"]["core"]["cards"]["actors"]["C"]["zones"]["hand"].has(t05) and r["state"]["core"]["battle"]["actors"]["C"]["mp"] == 12 and r["state"]["core"]["battle"]["party_resources"]["rp"] == 4,"DEMO-05-JIT-NO-SPEND")
	# B02 has exactly two hit traces under one declared scope and one Guard.
	r = rig()
	announce(r,"B02")
	r["config"]["m5_enemy_profiles"]["B02"]["hit_mode"] = "GUARANTEED"
	check(enemy(r,"A"),"DEMO-05-B02-GUARD")
	var hits: int = 0
	var guarded: bool = true
	for event: Dictionary in r["last"]:
		if event["kind"] == "DamageTrace":
			hits += 1
			guarded = guarded and bool(event["details"]["guard_applied"])
	check(hits == 2 and guarded,"DEMO-05-B02-TWO-HITS-ONE-GUARD")
	# T10 is after actual HP reduction, one heal, stable ratio tie break.
	r = rig()
	r["state"]["core"]["battle"]["actors"]["A"]["hp"] = 750
	r["state"]["core"]["battle"]["actors"]["C"]["hp"] = 600
	check(play(r,"C","T10","Boss"),"DEMO-10-T10-PAID")
	check(r["state"]["core"]["battle"]["actors"]["A"]["hp"] == 830 and r["state"]["core"]["battle"]["actors"]["C"]["hp"] == 600,"DEMO-10-T10-STABLE-PARTY-TIE")
	check(position(r["last"],"HPDamageApplied") < position(r["last"],"HPHealed"),"DEMO-10-T10-HEAL-AFTER-DAMAGE")
	r = rig()
	r["state"]["core"]["battle"]["actors"]["A"]["hp"] = 1000
	r["state"]["core"]["battle"]["hp_barriers"] = {"Boss":1000.0}
	check(play(r,"C","T10","Boss") and not has_event(r["last"],"HPHealed") and r["state"]["core"]["battle"]["actors"]["A"]["hp"] == 1000,"DEMO-10-T10-BARRIER-NO-HEAL")
	# Scorch uses real StatusInstances and ticks twice at EnemyPhase end.
	r = rig()
	check(play(r,"B","A07","Boss"),"DEMO-10-A07-STATUS")
	check(r["state"]["core"]["battle"]["statuses"].size() == 1,"DEMO-10-A07-REAL-STATUS-INSTANCE")
	var early: Dictionary = StatusEngine.tick(r["state"]["core"],2,r["config"],"early","NEXT_PLAYER_PHASE")
	check(early.get("ok",false) and early["timeline"].is_empty() and early["core"]["battle"]["statuses"] == r["state"]["core"]["battle"]["statuses"],"DEMO-10-NO-EARLY-PLAYER-TICK")
	check(not StatusEngine.tick(r["state"]["core"],2,r["config"],"invalid","CLIENT_TICK").get("ok",false),"DEMO-10-REJECT-UNKNOWN-TICK-BOUNDARY")
	announce(r,"B05")
	check(enemy(r) and step(r,"END_ENEMY_PHASE") and has_event(r["last"],"StatusTickStarted"),"DEMO-10-A07-ENEMY-END-TICK")
	check(step(r,"START_PLAYER_PHASE") and not has_event(r["last"],"StatusTickStarted"),"DEMO-10-A07-NO-DOUBLE-PLAYER-TICK")
	check(enemy(r) and step(r,"END_ENEMY_PHASE") and has_event(r["last"],"StatusExpired"),"DEMO-10-A07-TWO-TICKS-EXPIRE")
	# Last Spell instability: targeted stability setup then genuine B03 hits.
	r = rig()
	r["config"]["m5_enemy_profiles"]["B03"]["hit_mode"] = "GUARANTEED"
	check(step(r,"ACTIVATE_LAST_SPELL_M4",{"actor_id":"B","target_actor_id":"Boss","confirmed":true,"casting_mode":"FULL"}),"DEMO-12-INSTABILITY-SETUP")
	var cast_id: String = Effects.casting_id(r["state"]["core"],"B")
	r["state"]["core"]["battle"]["casting_instances"][cast_id]["current_stability"] = 5
	# A full three-hit sequence must remain a live Last Spell stability scenario.
	# The old fixture killed Akane before the third hit (HP=0 invalidates Last Spell).
	# A setup-only HP Barrier absorbs damage without blocking on-hit Casting disruption.
	# Do not let Akane Guard while CONCENTRATING; that would violate M4.
	r["state"]["core"]["battle"]["hp_barriers"]["B"] = 4000.0
	announce(r,"B03")
	check(enemy(r) and has_event(r["last"],"LastSpellDestabilizedDelayed") and
		int(r["state"]["core"]["battle"]["actors"]["B"]["hp"]) > 0 and
		next_round(r),"DEMO-12-FIRST-THRESHOLD-DELAY")
	announce(r,"B03")
	check(enemy(r) and next_round(r),"DEMO-12-SECOND-HIT")
	announce(r,"B03")
	check(enemy(r) and has_event(r["last"],"LastSpellDestabilizedWeakened"),"DEMO-12-SECOND-THRESHOLD-WEAKEN")
	check(r["state"]["core"]["battle"]["casting_instances"][cast_id]["planned_resolve_round"] == 4,"DEMO-12-NO-INFINITE-DELAY")
	check(next_round(r) and has_event(r["last"],"LastSpellReleased"),"DEMO-12-WEAKENED-RELEASE")
	# Fizzle is the public branch; no hidden retarget on a locked death.
	r = rig()
	announce(r,"B03")
	r["state"]["core"]["battle"]["actors"]["B"]["hp"] = 0
	r["state"]["core"]["battle"]["actors"]["B"]["status"] = "INCAPACITATED"
	check(enemy(r) and has_event(r["last"],"BossActionFizzled") and not has_event(r["last"],"DamageTrace"),"DEMO-02-LOCKED-DEAD-TARGET-FIZZLE")
	# Boundary simultaneous KO uses the existing Status HP lifecycle and outcome.
	r = rig()
	for actor: String in ["A","B","C","Boss"]:
		r["state"]["core"]["battle"]["actors"][actor]["hp"] = 10
		var granted: Dictionary = StatusEngine.grant(r["state"]["core"],"B",actor,"SCORCH_TEST","mutual-"+actor,r["config"])
		check(granted.get("ok",false),"DEMO-12-MUTUAL-STATUS-"+actor)
		if granted.get("ok",false):
			r["state"]["core"] = granted["core"]
	announce(r,"B05")
	check(enemy(r) and step(r,"END_ENEMY_PHASE") and r["state"]["core"]["battle"]["outcome"] == "VICTORY","DEMO-12-MUTUAL-KO-VICTORY")
	deny(r,"START_PLAYER_PHASE",{},"DEMO-12-TERMINAL-IMMUTABLE")
	# Unknown content element defaults to neutral only under the Lv40 flag.
	r = rig()
	var p: Dictionary = r["config"]["m5_basic_attack_profile"].duplicate(true)
	p["element_id"] = "UNLISTED"
	var unknown: Dictionary = Damage.resolve(r["state"]["core"],"A","Boss",p,{},r["config"],"unknown")
	check(unknown.get("ok",false),"DEMO-07-UNKNOWN-NEUTRAL")
	var legacy: Dictionary = r["config"].duplicate(true)
	legacy["m5_lv40_enabled"] = false
	check(not Damage.resolve(r["state"]["core"],"A","Boss",p,{},legacy,"unknown-legacy").get("ok",false), "DEMO-07-NON-LV40-UNKNOWN-REJECT")
	print("LV40_EDGES_REPORT executed=",passed+failed," passed=",passed," failed=",failed)
	quit(1 if failed else 0)
