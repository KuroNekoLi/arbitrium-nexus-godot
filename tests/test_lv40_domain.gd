extends SceneTree
## Targeted state setups preserve real card instances. All actions under test
## use the public M5 entry, never a fixture command or client damage value.
const Encounter = preload("res://scripts/domain/m5/lv40/lv40_encounter.gd")
const M5 = preload("res://scripts/domain/m5/integration/m5_domain_resolver.gd")
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const M4 = preload("res://scripts/domain/m4/integration/m4_domain_resolver.gd")
const Boss = preload("res://scripts/domain/m5/lv40/lv40_boss.gd")
const Effects = preload("res://scripts/domain/m5/lv40/lv40_effects.gd")
const Damage = preload("res://scripts/domain/m5/damage/damage_pipeline_resolver.gd")
var passed: int = 0
var failed: int = 0
var counter: int = 0

func check(value: bool, id: String) -> void:
	if value:
		passed += 1
		print("PASS ",id)
	else:
		failed += 1
		push_error("FAIL "+id)

func rig() -> Dictionary:
	return {"state":Encounter.initial(),"config":Encounter.config(),"tape":[],"events":[],"last":[]}

func in_hand(s: Dictionary, actor: String, definition: String) -> String:
	var cards: Dictionary = s["core"]["cards"]["actors"][actor]
	for key: String in cards["instances"]:
		if str(cards["instances"][key]["definition_id"]) != definition:
			continue
		if cards["zones"]["hand"].has(key):
			return key
		for zone: String in ["draw","discard"]:
			if cards["zones"][zone].has(key):
				var replaced: String = str(cards["zones"]["hand"][0])
				cards["zones"][zone].erase(key)
				cards["zones"][zone].append(replaced)
				cards["zones"]["hand"][0] = key
				return key
	return ""

func cmd(s: Dictionary, kind: String, fields: Dictionary = {}) -> Dictionary:
	counter += 1
	var c: Dictionary = {"type":kind,"command_id":"lv40-test-"+str(counter),"expected_event_seq":int(s["event_seq"])}
	c.merge(fields,true)
	return c

func step(r: Dictionary, kind: String, fields: Dictionary = {}) -> bool:
	var c: Dictionary = cmd(r["state"],kind,fields)
	var result: Dictionary = M5.apply(r["state"],c,r["config"])
	if not result["accepted"]:
		push_error("Rejected "+kind+": "+str(result["error"]))
		return false
	r["state"] = result["state"]
	r["last"] = result["events"]
	r["tape"].append(c)
	r["events"].append_array(result["events"])
	return true

func play(r: Dictionary, actor: String, definition: String, target: String,
		mode: String = "CHANTLESS", combo: String = "NORMAL") -> bool:
	return step(r,"PLAY_LV40_CARD",{"actor_id":actor,
		"card_instance_id":in_hand(r["state"],actor,definition),"target_actor_id":target,
		"casting_mode":mode,"combo_mode":combo})

func deny(r: Dictionary, kind: String, fields: Dictionary, id: String) -> void:
	var before: String = Model.state_hash(r["state"])
	var result: Dictionary = M5.apply(r["state"],cmd(r["state"],kind,fields),r["config"])
	check(not result["accepted"] and result["events"].is_empty() and before == Model.state_hash(result["state"]),id)

func has_event(events: Array, kind: String) -> bool:
	for e: Dictionary in events:
		if e["kind"] == kind:
			return true
	return false

func position(events: Array, kind: String) -> int:
	for i: int in range(events.size()):
		if events[i]["kind"] == kind:
			return i
	return -1

func enemy(r: Dictionary, guard_actor: String = "") -> bool:
	if not step(r,"END_PLAYER_PHASE") or not step(r,"DECLARE_NEXT_ENEMY_ACTION"):
		return false
	var action: Dictionary = r["state"]["enemy_actions"][0]
	if bool(action["public_intent"]["requires_reaction_window"]):
		if not step(r,"OPEN_REACTION_WINDOW",{"enemy_action_id":r["state"]["active_enemy_action_id"]}):
			return false
		if str(r["state"]["reaction_window"]["status"]) == "DRAFTING":
			if not guard_actor.is_empty():
				if not step(r,"QUEUE_REACTION",{"window_id":r["state"]["reaction_window"]["window_id"],
					"entry":{"kind":"BASIC_GUARD","actor_id":guard_actor}}):
					return false
			if not step(r,"CONFIRM_REACTIONS" if not guard_actor.is_empty() else "PASS_REACTION",{"window_id":r["state"]["reaction_window"]["window_id"]}):
				return false
	return step(r,"RESOLVE_ENEMY_ATTACK_M5",{"enemy_action_id":r["state"]["active_enemy_action_id"]})

func next_round(r: Dictionary) -> bool:
	return step(r,"END_ENEMY_PHASE") and step(r,"START_PLAYER_PHASE")

func announce(r: Dictionary, skill: String) -> void:
	r["state"]["published_intents"] = [Boss.intent(r["state"]["core"],skill,r["config"])]

func _initialize() -> void:
	var r: Dictionary = rig()
	check(M4.validate_state(r["state"]),"DEMO-01-M5-ENVELOPE")
	# A real paid physical SP leaves its owner hand; reusing the instance fails atomically.
	var paid_card: String = in_hand(r["state"],"A","R01")
	check(step(r,"PLAY_LV40_CARD",{"actor_id":"A","card_instance_id":paid_card,
		"target_actor_id":"Boss","casting_mode":"CHANTLESS"}), "DEMO-13-LIVE-SP-ACCEPTED")
	check(r["state"]["core"]["cards"]["actors"]["A"]["zones"]["discard"].has(paid_card), "DEMO-13-LIVE-SP-DISCARDED")
	deny(r,"PLAY_LV40_CARD",{"actor_id":"A","card_instance_id":paid_card,
		"target_actor_id":"Boss","casting_mode":"CHANTLESS"}, "DEMO-13-USED-SP-ATOMIC")
	r = rig()
	# Canonical unchanged intent across HP thresholds, then next publication.
	r["state"]["core"]["battle"]["actors"]["Boss"]["hp"] = 1700
	check(enemy(r),"DEMO-02-LOCKED-INTENT-EXECUTES")
	check(r["state"]["enemy_actions"][0]["public_intent"]["skill_id"] == "B01","DEMO-02-NO-RETROACTIVE-PHASE")
	check(next_round(r) and r["state"]["published_intents"][0]["skill_id"] == "B07","DEMO-02-P2-BARRIER-INTENT")
	check(enemy(r) and float(r["state"]["core"]["battle"]["hp_barriers"]["Boss"]) == 180,"DEMO-02-B07-ONLY-BARRIER")
	check(next_round(r) and r["state"]["published_intents"][0]["skill_id"] == "B02","DEMO-02-P2-CYCLE")
	r["state"]["core"]["battle"]["actors"]["Boss"]["hp"] = 700
	check(enemy(r) and next_round(r) and r["state"]["published_intents"][0]["skill_id"] == "B08","DEMO-02-P3-THRESHOLD")
	# True initial tape: B01 -> B05 -> player counter window -> B06.
	r = rig()
	var initial: Dictionary = r["state"].duplicate(true)
	check(enemy(r) and next_round(r),"DEMO-03-ROUND1")
	var before: Dictionary = r["state"]["core"]["battle"]["actors"].duplicate(true)
	check(enemy(r),"DEMO-03-B05-CHARGE")
	check(before == r["state"]["core"]["battle"]["actors"],"DEMO-03-ZERO-HP-CHARGE")
	check(next_round(r) and r["state"]["published_intents"][0]["skill_id"] == "B06","DEMO-03-PLAYER-COUNTER-WINDOW")
	check(enemy(r) and has_event(r["last"],"BossCastingReleased"),"DEMO-03-REAL-RELEASE")
	var tape: Array[Dictionary] = []
	for c: Dictionary in r["tape"]:
		tape.append(c)
	var replayed: Dictionary = M5.replay(initial,tape,r["config"])
	check(replayed["accepted"] and replayed["state_hash"] == Model.state_hash(r["state"]) and replayed["event_hash"] == Model.event_hash(r["events"]),"DEMO-13-FULL-TAPE-REPLAY")
	var same_replay: Dictionary = M5.replay(initial,tape,r["config"])
	check(same_replay["accepted"] and same_replay["state_hash"] == replayed["state_hash"] and same_replay["event_hash"] == replayed["event_hash"], "DEMO-13-IDENTICAL-SEEDED-REPLAY")
	print("LV40_REPLAY seed=20261014 tape=",JSON.stringify(tape)," event_hash=",Model.event_hash(r["events"])," final_hash=",Model.state_hash(r["state"]))
	# Interrupt paid A05, no second free attack in the cooldown slot.
	r = rig()
	announce(r,"B05")
	check(enemy(r) and next_round(r),"DEMO-04-CHARGE-SETUP")
	check(play(r,"B","A05","Boss"),"DEMO-04-PAID-A05")
	check(has_event(r["last"],"CastingInterrupted") and r["state"]["core"]["battle"]["lv40"]["pending_cast"]["current_stability"] == 0,"DEMO-04-STABILITY-ZERO")
	before = r["state"]["core"]["battle"]["actors"].duplicate(true)
	check(enemy(r) and has_event(r["last"],"BossCooldown") and before == r["state"]["core"]["battle"]["actors"],"DEMO-04-COOLDOWN-ZERO-DAMAGE")
	check(next_round(r),"DEMO-04-COOLDOWN-END")
	var card: String = in_hand(r["state"],"B","A05")
	deny(r,"PLAY_LV40_CARD",{"actor_id":"B","card_instance_id":card,"target_actor_id":"Boss","casting_mode":"CHANTLESS"},"DEMO-04-NO-CAST-ATOMIC")
	# AOE one action, three actual recipients, no basic Protect.
	r = rig()
	announce(r,"B04")
	check(step(r,"END_PLAYER_PHASE") and step(r,"DECLARE_NEXT_ENEMY_ACTION") and step(r,"OPEN_REACTION_WINDOW",{"enemy_action_id":r["state"]["active_enemy_action_id"]}),"DEMO-05-AOE-WINDOW")
	deny(r,"QUEUE_REACTION",{"window_id":r["state"]["reaction_window"]["window_id"],"entry":{"kind":"BASIC_PROTECT","actor_id":"A","target_actor_id":"B"}},"DEMO-05-AOE-PROTECT-REJECT")
	for actor: String in ["A","B","C"]:
		check(step(r,"QUEUE_REACTION",{"window_id":r["state"]["reaction_window"]["window_id"],"entry":{"kind":"BASIC_GUARD","actor_id":actor}}),"DEMO-05-AOE-GUARD-"+actor)
	check(step(r,"CONFIRM_REACTIONS",{"window_id":r["state"]["reaction_window"]["window_id"]}),"DEMO-05-AOE-CONFIRM")
	check(step(r,"RESOLVE_ENEMY_ATTACK_M5",{"enemy_action_id":r["state"]["active_enemy_action_id"]}),"DEMO-05-AOE-RESOLVE")
	var recipients: Array = []
	for e: Dictionary in r["last"]:
		if e["kind"] == "DamageTrace":
			recipients.append(e["details"]["recipient_id"])
	check(recipients == ["A","B","C"],"DEMO-05-AOE-THREE-RECIPIENTS")
	# Protect follows actual hit recipient; original casting remains stable.
	r = rig()
	check(play(r,"B","U01","Boss","FULL"),"DEMO-06-CAST-SETUP")
	announce(r,"B03")
	check(step(r,"END_PLAYER_PHASE") and step(r,"DECLARE_NEXT_ENEMY_ACTION") and step(r,"OPEN_REACTION_WINDOW",{"enemy_action_id":r["state"]["active_enemy_action_id"]}),"DEMO-06-WINDOW")
	var cast_id: String = Effects.casting_id(r["state"]["core"],"B")
	var stability: int = int(r["state"]["core"]["battle"]["casting_instances"][cast_id]["current_stability"])
	check(step(r,"QUEUE_REACTION",{"window_id":r["state"]["reaction_window"]["window_id"],"entry":{"kind":"BASIC_PROTECT","actor_id":"A","target_actor_id":"B"}}) and step(r,"CONFIRM_REACTIONS",{"window_id":r["state"]["reaction_window"]["window_id"]}) and step(r,"RESOLVE_ENEMY_ATTACK_M5",{"enemy_action_id":r["state"]["active_enemy_action_id"]}),"DEMO-06-PROTECT-RESOLVE")
	check(int(r["state"]["core"]["battle"]["casting_instances"][cast_id]["current_stability"]) == stability,"DEMO-06-ORIGINAL-CAST-UNTOUCHED")
	# Element and Exposed rules use true M5 damage and a distinct second SP.
	r = rig()
	r["config"]["m5_balance"]["variance_bp"] = 0
	r["config"]["m5_3_sp_effects"]["R01"]["damage_profile"]["hit_mode"] = "GUARANTEED"
	r["state"]["core"]["battle"]["lv40"]["core_open"] = true
	check(play(r,"A","R01","Boss"),"DEMO-08-R01-EXPOSED")
	check(has_event(r["last"],"ExposedApplied") and not has_event(r["last"],"ExposedConsumed"),"DEMO-08-NO-SELF-CONSUME")
	check(has_event(r["last"],"PassiveTriggered") and r["state"]["core"]["battle"]["m53"]["break_gauge"] == 14,"DEMO-09-REN-PASSIVE")
	check(play(r,"B","A06","Boss","CHANTLESS","COMBO") and has_event(r["last"],"ComboExecuted") and has_event(r["last"],"ExposedConsumed"),"DEMO-08-PAID-SECOND-COMBO")
	var fire: bool = false
	for e: Dictionary in r["last"]:
		if e["kind"] == "DamageTrace":
			fire = e["details"]["element_multiplier_bp"] == 11500
	check(fire,"DEMO-07-FIRE115")
	check(play(r,"C","U01","Boss"),"DEMO-07-ARCANE-ACTION")
	var arcane: bool = false
	for e: Dictionary in r["last"]:
		if e["kind"] == "DamageTrace":
			arcane = e["details"]["element_multiplier_bp"] == 9000
	check(arcane,"DEMO-07-ARCANE90")
	# Deferred Break cannot cancel an already-started charge.
	r = rig()
	announce(r,"B05")
	check(enemy(r) and next_round(r),"DEMO-09-PENDING-SETUP")
	r["state"]["core"]["battle"]["m53"]["break_gauge"] = 1
	r["config"]["m5_3_sp_effects"]["R01"]["damage_profile"]["hit_mode"] = "GUARANTEED"
	check(play(r,"A","R01","Boss") and has_event(r["last"],"BreakTriggered"),"DEMO-09-BREAK-WHOLE-SP")
	check(position(r["last"],"DamageTrace") < position(r["last"],"BreakTriggered"),"DEMO-09-EVENT-ORDER")
	check(enemy(r) and has_event(r["last"],"BossCastingReleased") and next_round(r),"DEMO-09-PENDING-CAST-PRESERVED")
	check(enemy(r) and r["state"]["enemy_actions"][0]["public_intent"]["skill_id"] == "B11","DEMO-09-NEXT-ELIGIBLE-FALLBACK")
	check(r["state"]["core"]["battle"]["m53"]["break_gauge"] == 22,"DEMO-09-FALLBACK-RESET22")
	# Universal heal eligibility and negative atomicity.
	for actor: String in ["A","B","C"]:
		r = rig()
		r["state"]["core"]["battle"]["actors"]["A"]["hp"] = 1000
		check(play(r,actor,"U05","A"),"DEMO-10-U05-"+actor)
		check(int(r["state"]["core"]["battle"]["actors"]["A"]["hp"]) == (1210 if actor == "C" else 1150),"DEMO-10-U05-AMOUNT-"+actor)
	r = rig()
	card = in_hand(r["state"],"A","U05")
	var fields: Dictionary = {"actor_id":"A","card_instance_id":card,"target_actor_id":"A","casting_mode":"CHANTLESS"}
	deny(r,"PLAY_LV40_CARD",fields,"DEMO-10-FULL-HP-ATOMIC")
	r["state"]["core"]["battle"]["actors"]["A"]["hp"] = 1000
	r["state"]["core"]["battle"]["actors"]["A"]["mp"] = 0
	deny(r,"PLAY_LV40_CARD",fields,"DEMO-10-ZERO-MP-ATOMIC")
	r = rig()
	card = in_hand(r["state"],"A","U05")
	fields["card_instance_id"] = card
	fields["target_actor_id"] = "B"
	r["state"]["core"]["battle"]["actors"]["B"]["hp"] = 0
	r["state"]["core"]["battle"]["actors"]["B"]["status"] = "INCAPACITATED"
	deny(r,"PLAY_LV40_CARD",fields,"DEMO-10-NO-REVIVE-ATOMIC")
	r = rig()
	card = in_hand(r["state"],"A","R01")
	deny(r,"PLAY_LV40_CARD",{"actor_id":"B","card_instance_id":card,"target_actor_id":"Boss","casting_mode":"CHANTLESS"},"DEMO-10-WRONG-OWNER-ATOMIC")
	deny(r,"PLAY_LV40_CARD",{"actor_id":"A","card_instance_id":card,"target_actor_id":"Boss","casting_mode":"CHANTLESS","damage":99999},"DEMO-10-CLIENT-DAMAGE-ATOMIC")
	deny(r,"PLAY_LV40_CARD",{"actor_id":"A","card_instance_id":card,"target_actor_id":"Boss","casting_mode":"CHANTLESS","expected_event_seq":-1},"DEMO-13-STALE-ATOMIC")
	# Separate Focus Ward and HP Barrier; exact doc27 central calculation.
	r = rig()
	check(play(r,"B","U01","Boss","FULL") and play(r,"C","U03","B"),"DEMO-11-FOCUS-WARD")
	cast_id = Effects.casting_id(r["state"]["core"],"B")
	check(r["state"]["core"]["battle"]["casting_instances"][cast_id]["focus_ward"] == 8 and float(r["state"]["core"]["battle"].get("hp_barriers",{}).get("B",0.0)) == 0.0,"DEMO-11-WARD-NOT-HP")
	check(play(r,"A","U02","B"),"DEMO-11-HP-BARRIER")
	check(r["state"]["core"]["battle"]["casting_instances"][cast_id]["focus_ward"] == 8,"DEMO-11-HP-NOT-WARD")
	var center: Dictionary = Encounter.config()
	center["m5_actor_stats"]["Boss"]["matk"] = 255
	center["m5_balance"]["variance_bp"] = 0
	var core: Dictionary = Encounter.initial()["core"]
	core = Effects.barrier(core,"B",140,1)["core"]
	var hit: Dictionary = Damage.resolve(core,"Boss","B",center["m5_enemy_profiles"]["B06"],{"guard_actor_ids":["B"]},center,"central")
	check(hit["ok"] and core["battle"]["actors"]["B"]["hp"]-hit["core"]["battle"]["actors"]["B"]["hp"] == 112,"DEMO-11-GUARD-THEN-BARRIER112")
	# Full SP release differs from Chantless and applies Akane passive only there.
	r = rig()
	check(play(r,"B","A01","Boss","FULL"),"DEMO-12-FULL-COMMIT")
	check(not has_event(r["last"],"DamageTrace") and enemy(r) and next_round(r),"DEMO-12-FULL-DELAYED")
	check(has_event(r["last"],"CastingReleased") and has_event(r["last"],"PassiveTriggered"),"DEMO-12-AKANE-PASSIVE-RELEASE")
	r = rig()
	check(step(r,"ACTIVATE_LAST_SPELL_M4",{"actor_id":"C","target_actor_id":"A","confirmed":true,"casting_mode":"FULL"}),"DEMO-12-LAST-SUPPORT-COMMIT")
	check(enemy(r) and next_round(r) and enemy(r) and next_round(r),"DEMO-12-LAST-TWO-ROUNDS")
	check(r["state"]["core"]["battle"]["actors"]["C"]["status"] == "EXHAUSTED" and has_event(r["last"],"LastSpellReleased") and has_event(r["last"],"HPHealed"),"DEMO-12-LAST-HEAL-EXHAUSTED")
	# HP0 invalidation uses real M5 damage and M4 lifecycle in the same action.
	r = rig()
	r["state"]["core"]["battle"]["actors"]["B"]["hp"] = 1
	check(step(r,"ACTIVATE_LAST_SPELL_M4",{"actor_id":"B","target_actor_id":"Boss","confirmed":true,"casting_mode":"FULL"}),"DEMO-12-HP0-CAST-SETUP")
	announce(r,"B03")
	r["config"]["m5_enemy_profiles"]["B03"]["hit_mode"] = "GUARANTEED"
	check(enemy(r) and has_event(r["last"],"LastSpellInvalidated"),"DEMO-12-HP0-INSTANT-INVALIDATION")
	check(r["state"]["core"]["battle"]["actors"]["B"]["mp"] == 5 and Effects.casting_id(r["state"]["core"],"B").is_empty(),"DEMO-12-NO-REFUND-NO-PENDING")
	# Real card payment in the existing M3 queue; R05 counter after HP hits.
	r = rig()
	in_hand(r["state"],"A","R05")
	announce(r,"B03")
	check(step(r,"END_PLAYER_PHASE") and step(r,"DECLARE_NEXT_ENEMY_ACTION") and step(r,"OPEN_REACTION_WINDOW",{"enemy_action_id":r["state"]["active_enemy_action_id"]}),"DEMO-05-R05-WINDOW")
	check(step(r,"QUEUE_REACTION",{"window_id":r["state"]["reaction_window"]["window_id"],"entry":{"kind":"REACTION_SP_FIXTURE","actor_id":"A","target_actor_id":"B","card_instance_id":in_hand(r["state"],"A","R05")}}) and step(r,"CONFIRM_REACTIONS",{"window_id":r["state"]["reaction_window"]["window_id"]}),"DEMO-05-R05-PAID")
	check(r["state"]["core"]["battle"]["party_resources"]["rp"] == 4 and r["state"]["core"]["battle"]["actors"]["A"]["mp"] == 7,"DEMO-05-R05-RP-MP")
	check(step(r,"RESOLVE_ENEMY_ATTACK_M5",{"enemy_action_id":r["state"]["active_enemy_action_id"]}) and has_event(r["last"],"ReactionCounterExecuted"),"DEMO-05-R05-COUNTER")
	check(position(r["last"],"DamageTrace") < position(r["last"],"ReactionCounterExecuted"),"DEMO-05-R05-ORDER")
	check(next_round(r) and r["state"]["core"]["battle"]["party_resources"]["rp"] == 0,"DEMO-11-RP-EXPIRES")
	for actor: String in ["A","B","C"]:
		var zones: Dictionary = r["state"]["core"]["cards"]["actors"][actor]["zones"]
		var count: int = 0
		for zone: Array in zones.values():
			count += zone.size()
		check(count == 12,"DEMO-13-CONSERVATION-"+actor)
	print("LV40_DOMAIN_REPORT executed=",passed+failed," passed=",passed," failed=",failed)
	quit(1 if failed else 0)
