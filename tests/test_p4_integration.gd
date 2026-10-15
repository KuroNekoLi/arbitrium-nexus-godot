extends SceneTree
const Scene = preload("res://scenes/battle/battle_screen.tscn")
const F = preload("res://tests/fixtures/m5_full_battle_fixture.gd")
const Factory = preload("res://scripts/battle/battle_command_factory.gd")
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const Controller = preload("res://scripts/battle/battle_controller.gd")
var executed: int = 0
var failed: int = 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, id: String) -> void:
	executed += 1
	if not ok: failed += 1
	print(("PASS " if ok else "FAIL ")+id)

func run() -> void:
	var screen: Control = Scene.instantiate()
	root.add_child(screen)
	await process_frame
	var before: Dictionary = screen.controller.snapshot()
	var id: String = str(screen.hud.card_views[0].instance_id)
	screen.select_card(id)
	screen.select_target("Boss")
	var command: Dictionary = screen.pending_command.duplicate(true)
	check(command.has("command_id") and command["expected_event_seq"] == 0,"P43-SCHEMA")
	screen.confirm_action()
	var after: Dictionary = screen.controller.snapshot()
	check(after["core"]["battle"]["actors"]["Boss"]["hp"] < before["core"]["battle"]["actors"]["Boss"]["hp"],"P43-DOMAIN-HP")
	check(after["core"]["battle"]["party_resources"]["current_ap"] == 5,"P43-REAL-AP-PAYMENT")
	check(after["core"]["battle"]["actors"]["A"]["mp"] == 9,"P43-REAL-MP-PAYMENT")
	check(after["core"]["cards"]["actors"]["A"]["zones"]["discard"].has(id),"P43-HAND-TO-DISCARD")
	check(not after["core"]["cards"]["actors"]["A"]["zones"]["hand"].has(id),"P43-NOT-IN-TWO-ZONES")
	check(screen.hud.card_views.size() == 3,"P43-HUD-REAL-HAND")
	check(Model.state_hash(screen.snapshot) == Model.state_hash(after),"P43-HUD-STATE-SYNC")
	var frozen: String = Model.state_hash(after)
	check(not screen.controller.submit(command),"P43-DUPLICATE-REJECTED")
	check(Model.state_hash(screen.controller.snapshot()) == frozen,"P43-DUPLICATE-ATOMIC")
	var stale: Dictionary = Factory.build(after,"BASIC_ATTACK_RESOURCE_ONLY",{"actor_id":"A","target_actor_id":"Boss"})
	stale["expected_event_seq"] = 0
	check(not screen.controller.submit(stale),"P43-STALE-REJECTED")
	var invalid: Dictionary = Factory.build(after,"BASIC_ATTACK_RESOURCE_ONLY",{"actor_id":"A","target_actor_id":"missing"})
	check(not screen.controller.submit(invalid),"P43-INVALID-TARGET")
	check(Model.state_hash(screen.controller.snapshot()) == frozen,"P43-REJECTION-RNG-EVENTS-ATOMIC")
	var detached: Dictionary = screen.controller.snapshot()
	detached["core"]["battle"]["actors"]["Boss"]["hp"] = 1
	check(Model.state_hash(screen.controller.snapshot()) == frozen,"P43-DETACHED-SNAPSHOT")
	var sequential: bool = true
	for i: int in after["events"].size(): sequential = sequential and after["events"][i]["event_seq"] == i+1
	check(sequential,"P43-EVENT-ORDER")
	var kinds: Array = after["events"].map(func(event: Dictionary) -> String: return str(event["kind"]))
	var payment_index: int = kinds.find("SPCostReservedOnly")
	var card_index: int = kinds.find("CardZoneChanged")
	var damage_index: int = kinds.find("DamageTrace")
	var hp_index: int = kinds.find("HPDamageApplied")
	var settled_index: int = kinds.find("PlayerActionSettled")
	check(payment_index >= 0 and payment_index < card_index and card_index < damage_index and damage_index < hp_index and hp_index < settled_index,"P43-PAYMENT-CARD-DAMAGE-ACTION-ORDER")
	var receipt: Dictionary = screen.controller.replay_receipt()
	check(receipt["accepted"] and receipt["matches"],"P43-SEEDED-REPLAY")
	check(screen.controller.save_tape("user://p43_test.tape") == OK,"P43-SAVE-TAPE")
	var saved: Dictionary = Controller.verify_saved_tape("user://p43_test.tape")
	check(saved["accepted"] and saved["matches"],"P43-PERSISTED-REPLAY")
	await create_timer(0.7).timeout
	check(not screen.director.presented_damage.is_empty(),"P43-ANIMATION-CONSUMED-EVENT")
	check(Model.state_hash(screen.controller.snapshot()) == frozen,"P43-ANIMATION-NO-MUTATION")
	check(screen.get_node("Design/Arena/A").position == Vector2(438,458),"P43-ACTOR-RETURNS-HOME")
	screen._command_requested("END_PLAYER_PHASE",{})
	check(screen.snapshot["reaction_window"].get("status","") == "DRAFTING","P43-END-AUTO-ENEMY-UNTIL-REACTION")
	var pause: String = Model.state_hash(screen.controller.snapshot())
	await create_timer(0.1).timeout
	check(Model.state_hash(screen.controller.snapshot()) == pause,"P43-REACTION-NOT-AUTO-PASSED")
	screen._command_requested("PASS_REACTION",{})
	check(screen.snapshot["phase"] == "PLAYER_PHASE" and screen.snapshot["core"]["battle"]["round"] == 2,"P43-MANUAL-PASS-RESUMES")
	check(screen.controller.replay_receipt()["matches"],"P43-CROSS-PHASE-REPLAY")
	var weak: WeakRef = weakref(screen.controller)
	screen.queue_free()
	await process_frame
	await create_timer(0.8).timeout
	check(weak.get_ref() == null,"P43-SIGNAL-OWNER-CLEANUP")
	var again: Control = Scene.instantiate()
	root.add_child(again)
	await process_frame
	check(again.controller.tape().is_empty() and again.snapshot["event_seq"] == 0,"P43-FRESH-REENTRY")
	var poor: Dictionary = F.initial()
	poor["core"]["battle"]["party_resources"]["current_ap"] = 0
	again.controller.begin(poor,F.config())
	again.present(poor)
	check(not again.hud.card_views[0].legal,"P43-RESOURCE-POOR-CARD-UNAVAILABLE")
	var poor_hash: String = Model.state_hash(poor)
	var denied: Dictionary = Factory.card(poor,"A",str(poor["core"]["cards"]["actors"]["A"]["zones"]["hand"][0]),"Boss")
	check(not again.controller.submit(denied),"P43-RESOURCE-POOR-COMMIT-REJECTED")
	check(Model.state_hash(again.controller.snapshot()) == poor_hash,"P43-RESOURCE-POOR-ATOMIC")
	again.queue_free()
	await process_frame
	print("P4_3_REPORT executed=%d passed=%d failed=%d" % [executed,executed-failed,failed])
	quit(0 if failed == 0 else 1)
