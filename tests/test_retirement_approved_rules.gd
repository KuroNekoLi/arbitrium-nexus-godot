extends SceneTree
## RET-01..05, owner approved 2026-10-16. Prepared boundary is FIXTURE_ONLY;
## activation/payment/release/outcome/replay use the real M5 and Controller.
const Encounter = preload("res://scripts/domain/m5/lv40/lv40_encounter.gd")
const Content = preload("res://scripts/domain/m5/lv40/lv40_content.gd")
const M5 = preload("res://scripts/domain/m5/integration/m5_domain_resolver.gd")
const Factory = preload("res://scripts/battle/battle_command_factory.gd")
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const Boundary = preload("res://scripts/domain/m3/phase/phase_boundary_resolver.gd")
const HP = preload("res://scripts/domain/m5/status/hp_lifecycle_bridge.gd")
const Targets = preload("res://scripts/domain/m5/lv40/last_spell_targeting.gd")
const Controller = preload("res://scripts/battle/battle_controller.gd")
const Damage = preload("res://scripts/domain/m5/damage/damage_pipeline_resolver.gd")
const Protect = preload("res://scripts/domain/m3/reaction/basic_protect_resolver.gd")
var total: int = 0
var failed: int = 0

func _initialize() -> void: call_deferred("run")

func check(ok: bool, id: String) -> void:
	total += 1
	if not ok: failed += 1
	print(("PASS " if ok else "FAIL ") + id)

func prepared(cfg: Dictionary, actors: Array[String]) -> Dictionary:
	var state: Dictionary = Encounter.initial()
	state.core.battle.party_resources.current_ap = 18 # explicitly prepared fixture
	for actor: String in actors:
		var target: String = "A" if actor == "C" else "Boss"
		var command: Dictionary = Factory.build(state, "ACTIVATE_LAST_SPELL_M4",
			{"actor_id":actor,"target_actor_id":target,"confirmed":true,"casting_mode":"FULL"})
		var result: Dictionary = M5.apply(state, command, cfg)
		check(result.accepted, "RET3-ACTIVATION-"+actor)
		if not result.accepted:
			print("RET3_REJECT ", result.error)
			return {}
		state = result.state
	state.phase = "AWAITING_PLAYER_START"
	state.core.battle.phase = "AWAITING_PLAYER_START"
	state.core.battle.round = 2
	state.core.cards.phase = "AWAITING_PLAYER_START"
	state.core.cards.player_phase_index = 2
	return state

func run() -> void:
	var cfg: Dictionary = Encounter.config()
	check(cfg.get("last_spell_retirement_v1", false) and Encounter.VERSION.ends_with("-3"), "RET3-VERSIONED-CONTENT")
	var state: Dictionary = prepared(cfg, ["A","B","C"])
	if state.is_empty(): quit(1); return
	state.core.battle.actors.Boss.hp = 999999 # boundary fixture prevents early victory
	state.core.battle.actors.Boss.max_hp = 999999
	var start: Dictionary = Factory.build(state, "START_PLAYER_PHASE")
	var final: Dictionary = M5.apply(state, start, cfg)
	check(final.get("accepted", false), "RET3-TRUE-M5-RELEASE")
	if not final.get("accepted", false): print("RET3_REJECT ", final.get("error", "MISSING_RECEIPT")); quit(1); return
	check(final.state.core.battle.retired_from_field_by_actor.size() == 3, "RET3-THREE-RETIRED")
	check(final.state.core.battle.outcome == "DEFEAT", "RET3-ALL-RETIRED-DEFEAT")
	check(final.state.core.battle.actors.Boss.hp > 0, "RET3-BOSS-SURVIVES")
	check(final.state.core.battle.allies.size() == 3 and final.state.core.cards.actors.size() == 3, "RET3-IDENTITY-AND-CARDS-RETAINED")
	check(Targets.candidates(final.state.core,"C",cfg).is_empty(), "RET3-NO-ALLY-TARGETS")
	check(not HP.heal(final.state.core,"A",10).ok and not HP.revive(final.state.core,"A",10).ok, "RET3-NO-HEAL-REVIVE")
	var tape: Array[Dictionary] = [start]
	var replay: Dictionary = M5.replay(state,tape,cfg)
	check(replay.accepted and replay.state_hash == final.state_hash, "RET3-RELEASE-REPLAY")
	var controller: Node = Controller.new()
	root.add_child(controller)
	controller.begin(state,cfg)
	check(controller.submit(start) and controller.snapshot().core.battle.outcome == "DEFEAT", "RET3-CONTROLLER-DEFEAT")
	check(controller.replay_receipt().matches, "RET3-CONTROLLER-REPLAY")
	controller.free()
	var won: Dictionary = final.state.core.battle.duplicate(true)
	won.actors.Boss.hp = 0
	check(Boundary.outcome(won) == "VICTORY", "RET3-VICTORY-PRIORITY")
	var mixed: Dictionary = final.state.core.battle.duplicate(true)
	mixed.retired_from_field_by_actor.erase("C")
	mixed.actors.C.hp = 0
	mixed.actors.C.status = "INCAPACITATED"
	check(Boundary.outcome(mixed) == "DEFEAT", "RET3-KO-AND-RETIRED-DEFEAT")
	mixed.actors.C.hp = 1
	mixed.actors.C.status = "CONCENTRATING"
	check(Boundary.outcome(mixed) == "ONGOING", "RET3-LIVE-CASTER-COUNTS")
	var support: Dictionary = prepared(cfg,["C"])
	support.core.battle.actors.C.hp = 1
	var healed: Dictionary = M5.apply(support, Factory.build(support,"START_PLAYER_PHASE"),cfg)
	check(healed.accepted and healed.state.core.battle.actors.C.hp > 1, "RET3-SELF-HEAL-BEFORE-EXIT")
	check(healed.accepted and healed.state.core.battle.retired_from_field_by_actor.get("C",false), "RET3-SUPPORT-RETIRES-AFTER-EFFECT")
	if healed.accepted:
		var healed_index: int = -1
		var retired_index: int = -1
		for i: int in healed.events.size():
			var event: Dictionary = healed.events[i]
			if event.kind == "HPHealed" and event.details.get("actor_id", "") == "C": healed_index = i
			if event.kind == "ActorExhausted" and event.details.get("actor_id", "") == "C": retired_index = i
		check(healed_index >= 0 and retired_index > healed_index, "RET3-HEAL-EVENT-BEFORE-RETIREMENT")
		var before: String = Model.state_hash(healed.state)
		var invalid: Dictionary = Factory.build(healed.state,"ACTIVATE_LAST_SPELL_M4",
			{"actor_id":"A","target_actor_id":"C","confirmed":true,"casting_mode":"FULL"})
		var denied: Dictionary = M5.apply(healed.state,invalid,cfg)
		check(not denied.accepted and Model.state_hash(denied.state) == before, "RET3-ILLEGAL-COMMAND-ATOMIC")
		var damage: Dictionary = Damage.resolve(healed.state.core,"Boss","C",cfg.m5_enemy_profiles.B01,{},cfg,"retired-damage")
		check(not damage.ok and damage.error == "M51_TARGET_RETIRED_FROM_FIELD", "RET3-DAMAGE-REJECTS-RETIRED")
		var protection: Dictionary = Protect.check(healed.state.core,{}, {},"A","C")
		check(not protection.ok and protection.error == "TARGET_RETIRED_FROM_FIELD", "RET3-PROTECT-REJECTS-RETIRED")
	# Same config version, identical state/tape: only explicit new configuration
	# enables retirement. Never reinterpret historical tapes as the new rules.
	var old_cfg: Dictionary = Content.config("lv40-starter-v0.3-boss-v0.2-A-provisional-2")
	var old_state: Dictionary = state.duplicate(true)
	old_state.core.battle.lv40.version = old_cfg.m5_lv40_content_version
	var legacy: Dictionary = M5.apply(old_state,start,old_cfg)
	check(legacy.accepted and not legacy.state.core.battle.has("retired_from_field_by_actor") and legacy.state.core.battle.outcome == "ONGOING", "RET3-LEGACY-CONFIG-SEMANTICS")
	var old_replay: Dictionary = M5.replay(old_state,tape,old_cfg)
	check(old_replay.accepted and old_replay.state_hash == legacy.state_hash, "RET3-LEGACY-REPLAY")
	print("RETIREMENT_APPROVED_REPORT executed=%d passed=%d failed=%d" % [total,total-failed,failed])
	quit(0 if failed == 0 else 1)
