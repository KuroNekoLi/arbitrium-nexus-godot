extends RefCounted
## M4.5 cross-module REAL accepted command tape. Only M4 fixture-verified
## enemy hit/HP and provisional casting effects; never a live M5 pipeline.
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const Draw = preload("res://scripts/domain/m2/cards/draw_resolver.gd")
const M2 = preload("res://scripts/domain/m2/integration/m2_domain_resolver.gd")
const Phase = preload("res://scripts/domain/m3/phase/phase_engine.gd")
const M4 = preload("res://scripts/domain/m4/integration/m4_domain_resolver.gd")
const SEED: int = 20261014

static func configuration() -> Dictionary:
	var c: Variant = JSON.parse_string(FileAccess.get_file_as_string(
		"res://resources/combat/rulesets/m2_2_provisional_costs.json"))
	var r: Variant = JSON.parse_string(FileAccess.get_file_as_string(
		"res://resources/combat/rulesets/m2_1_provisional_resources.json"))
	if not c is Dictionary or not r is Dictionary:
		return {}
	var economy: Dictionary = c.duplicate(true)
	economy["basic_attack_ap_cost"] = int(r["basic_attack_ap_cost"])
	economy["basic_attack_mp_gain"] = int(r["basic_attack_mp_gain"])
	return {"costs":c,"resources":economy,
		"definitions":{"regular":{"card_id":"regular","ap_cost":1,"mp_cost":2}},
		"casting_profiles":{"regular":{"spell_id":"regular",
			"allowed_modes":["CHANTLESS","FULL"],"base_stability":10}},
		"last_spell_slots":{
			"A":{"spell_id":"nova","unlocked":true,"planned_delay_rounds":2,"base_stability":10}},
		"last_spell_cost_definitions":{
			"nova":{"card_id":"nova","ap_cost":2,"mp_cost":3}},
		"last_spell_instability":{"authority":"BALANCE_PROVISIONAL",
			"stability_reset":10,"weaken_numerator":3,"weaken_denominator":4},
		"reaction_definitions":{"regular":{
			"kind":"REACTION_SP","reaction_trigger":"ENEMY_ACTION",
			"rp_cost":1,"mp_cost":1,"fixture_effect":"FOCUS_WARD_FIXTURE",
			"target_scope":"ANY","requires_active_enemy_action":false,
			"cast_compatible":true,"focus_ward_amount":6}},
		"disruption_effects":{
			"direct1":{"channel":"DIRECT_CASTING_INSTANCE",
				"disruption_power":12,"authority":"BALANCE_PROVISIONAL"},
			"direct2":{"channel":"DIRECT_CASTING_INSTANCE",
				"disruption_power":12,"authority":"BALANCE_PROVISIONAL"},
			"onhit":{"channel":"ON_HIT_CASTING",
				"disruption_power":4,"authority":"BALANCE_PROVISIONAL"}},
		"casting_interrupt_refund":{"authority":"BALANCE_PROVISIONAL",
			"numerator":1,"denominator":2,"rounding":"FLOOR_FIXTURE"},
		"m4_dual_cast_enabled":true,
		"m4_2_fixture_authorized":true,"m4_2_verified_hit_fixture":true,
		"m4_2_internal_refund":true,
		"m4_4_trusted_life_fixture":true,"m4_4_verified_hit_fixture":true,
		"m4_4_life_effects":{
			"hp0_A":{"authority":"M4_4_TRUSTED_FIXTURE_ONLY",
				"operation":"HP_ZERO","target_actor_id":"A","hp_after":0},
			"hp0_B":{"authority":"M4_4_TRUSTED_FIXTURE_ONLY",
				"operation":"HP_ZERO","target_actor_id":"B","hp_after":0},
			"revive_A":{"authority":"M4_4_TRUSTED_FIXTURE_ONLY",
				"operation":"REVIVE","target_actor_id":"A","hp_after":35,
				"revive_tag":true}},
		"trigger_rules":[]}

static func initial(seed: int = SEED) -> Dictionary:
	var decks: Dictionary = {}
	var contexts: Dictionary = {}
	var owned: Dictionary = {}
	for actor: String in ["A","B","C"]:
		var deck: Array = []
		for i: int in range(12):
			deck.append("regular")
		decks[actor] = deck
		contexts[actor] = {"actor_id":actor,"variant_id":"default","tags":[]}
		owned[actor] = {"regular":12}
	var dealt: Dictionary = Draw.start_battle(decks,contexts,
		{"regular":{"id":"regular","kind":"SP"}},owned,seed)
	if not dealt["accepted"]:
		return {}
	var battle: Dictionary = Model.make_state(["A","B","C"],["Boss"],seed)
	for actor: String in ["A","B","C"]:
		battle["actors"][actor]["mp"] = 8
		battle["actors"][actor]["max_mp"] = 10
	var intents: Array = [{"intent_id":"combined_attack","enemy_id":"Boss",
		"action_order":1,"created_seq":0,"publicly_declared":true,
		"target_scope":"SINGLE","target_ids":["A"],"hit_count":2,
		"damage_type":"MAGICAL","requires_reaction_window":true}]
	return Phase.make_state(M2.make_state(battle,dealt["state"]),intents)

static func _step(c: Dictionary, kind: String, fields: Dictionary = {},
		checkpoint: String = "") -> bool:
	if not str(c["error"]).is_empty():
		return false
	var s: Dictionary = c["state"]
	var command: Dictionary = {
		"type":kind,"command_id":"m45:"+str(c["tape"].size())+":"+kind,
		"expected_event_seq":int(s["event_seq"])}
	for k: Variant in fields:
		command[k] = fields[k]
	var result: Dictionary = M4.apply(s,command,c["config"])
	if not result["accepted"]:
		c["error"] = str(command["command_id"])+": "+str(result["error"])
		return false
	c["tape"].append(command)
	c["state"] = result["state"]
	c["last_events"] = result["events"]
	if not checkpoint.is_empty():
		c["checkpoints"][checkpoint] = {
			"state":result["state"].duplicate(true),
			"events":result["events"].duplicate(true)}
	return true

static func _begin_enemy(c: Dictionary, name: String) -> bool:
	if not _step(c,"END_PLAYER_PHASE",{},name+"_enemy"):
		return false
	if not _step(c,"DECLARE_NEXT_ENEMY_ACTION",{},name+"_declare"):
		return false
	return _step(c,"OPEN_REACTION_WINDOW",{
		"enemy_action_id":str(c["state"]["active_enemy_action_id"])
	},name+"_window")

static func _pass(c: Dictionary, name: String) -> bool:
	return _step(c,"PASS_REACTION",{
		"window_id":str(c["state"]["reaction_window"]["window_id"])},name)

static func _complete_enemy(c: Dictionary, name: String) -> bool:
	if not _step(c,"COMPLETE_ENEMY_ACTION_FIXTURE",{
		"enemy_action_id":str(c["state"]["active_enemy_action_id"])},name+"_complete"):
		return false
	return _step(c,"END_ENEMY_PHASE",{},name+"_ended")

static func _full(c: Dictionary, actor: String, mode: String,
		name: String) -> bool:
	var s: Dictionary = c["state"]
	var card: String = str(s["core"]["cards"]["actors"][actor]["zones"]["hand"][0])
	return _step(c,"CAST_SPELL_M4",{
		"actor_id":actor,"card_instance_id":card,
		"target_actor_id":"Boss","casting_mode":mode},name)

static func _disrupt(c: Dictionary, effect: String, name: String) -> bool:
	return _step(c,"APPLY_CASTING_DISRUPTION_M4_FIXTURE",{
		"source_enemy_action_id":str(c["state"]["active_enemy_action_id"]),
		"casting_id":"last:m45:0:ACTIVATE_LAST_SPELL_M4",
		"target_casting_id":"last:m45:0:ACTIVATE_LAST_SPELL_M4",
		"effect_id":effect},name)

static func _life(c: Dictionary, effect: String, name: String) -> bool:
	return _step(c,"APPLY_INCAPACITATION_M4_FIXTURE",{
		"source_enemy_action_id":str(c["state"]["active_enemy_action_id"]),
		"verified_hit_fixture":true,"effect_id":effect},name)

static func build(seed: int = SEED) -> Dictionary:
	var origin: Dictionary = initial(seed)
	var config: Dictionary = configuration()
	if origin.is_empty() or config.is_empty():
		return {"ok":false,"error":"EMPTY_OR_INVALID_M45_FIXTURE"}
	var ctx: Dictionary = {"ok":false,"error":"","initial":origin.duplicate(true),
		"state":origin.duplicate(true),"tape":[],"config":config,
		"checkpoints":{},"last_events":[]}
	# Round1: A Last and B Full leave exactly 3 RP for Ward+Protect.
	# C's Chantless is exercised in round2 before C Full; this is still
	# a real freely ordered multiple-action player phase.
	if not _step(ctx,"ACTIVATE_LAST_SPELL_M4",{
		"actor_id":"A","target_actor_id":"Boss","confirmed":true,
		"casting_mode":"FULL"},"last_committed"):
		return ctx
	if not _full(ctx,"B","FULL","b_full"):
		return ctx
	if not _begin_enemy(ctx,"r1"):
		return ctx
	# B is concentrating, but explicitly CAST_COMPATIBLE SP can grant
	# FocusWard to A. C can basic Protect A (no card, 2RP).
	var held: String = str(ctx["state"]["core"]["cards"]["actors"]["B"]["zones"]["hand"][0])
	var window: String = str(ctx["state"]["reaction_window"]["window_id"])
	if not _step(ctx,"QUEUE_REACTION",{"window_id":window,
		"entry":{"kind":"REACTION_SP_FIXTURE","actor_id":"B",
			"target_actor_id":"A","card_instance_id":held}},"ward_draft"):
		return ctx
	if not _step(ctx,"QUEUE_REACTION",{"window_id":window,
		"entry":{"kind":"BASIC_PROTECT","actor_id":"C",
			"target_actor_id":"A"}},"protect_draft"):
		return ctx
	if not _step(ctx,"CONFIRM_REACTIONS",{"window_id":window},"r1_confirm"):
		return ctx
	# On-hit M5-proven fixture cannot interrupt A once Protect redirected C.
	if not _step(ctx,"APPLY_CASTING_DISRUPTION_M4_FIXTURE",{
		"source_enemy_action_id":str(ctx["state"]["active_enemy_action_id"]),
		"casting_id":"last:m45:0:ACTIVATE_LAST_SPELL_M4",
		"effect_id":"onhit","hit_index":0,"hit_fixture_confirmed":true
	},"protected_onhit"):
		return ctx
	if not _disrupt(ctx,"direct1","direct_first"):
		return ctx
	if not _disrupt(ctx,"direct2","last_destabilized"):
		return ctx
	if not _complete_enemy(ctx,"r1"):
		return ctx
	# Round2 boundary releases B's ordinary Full *before* AP and draw.
	if not _step(ctx,"START_PLAYER_PHASE",{},"r2_open"):
		return ctx
	if not _full(ctx,"C","CHANTLESS","c_chantless"):
		return ctx
	if not _full(ctx,"C","FULL","c_full"):
		return ctx
	if not _begin_enemy(ctx,"r2"):
		return ctx
	# Now B is active and can Protect A; the verified HP0 fixture applies
	# to actual redirected recipient B, leaving A Last Spell alive.
	var window2: String = str(ctx["state"]["reaction_window"]["window_id"])
	if not _step(ctx,"QUEUE_REACTION",{"window_id":window2,
		"entry":{"kind":"BASIC_PROTECT","actor_id":"B",
			"target_actor_id":"A"}},"r2_protect_draft"):
		return ctx
	if not _step(ctx,"CONFIRM_REACTIONS",{"window_id":window2},"r2_protected"):
		return ctx
	if not _life(ctx,"hp0_B","r2_protector_hp0"):
		return ctx
	if not _complete_enemy(ctx,"r2"):
		return ctx
	# Round3: C Full releases, A Last remains (one destabilization delay).
	if not _step(ctx,"START_PLAYER_PHASE",{},"r3_open"):
		return ctx
	if not _begin_enemy(ctx,"r3"):
		return ctx
	if not _pass(ctx,"r3_pass"):
		return ctx
	# HP0 A is now valid and *must* cancel Last Spell immediately.
	if not _life(ctx,"hp0_A","r3_last_invalidated"):
		return ctx
	if not _complete_enemy(ctx,"r3"):
		return ctx
	if not _step(ctx,"START_PLAYER_PHASE",{},"r4_open"):
		return ctx
	# Tagged Revive must not restore Last's lost usage or effect.
	if not _step(ctx,"APPLY_REVIVE_M4_FIXTURE",{"effect_id":"revive_A"},"a_revived"):
		return ctx
	ctx["ok"] = true
	return ctx
