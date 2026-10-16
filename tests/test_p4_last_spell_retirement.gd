extends SceneTree
## Three-active-ally prototype: HP0 stays on the field, successful Last Spell
## retires the actor without deleting Domain identity, cards, or battle history.
const Scene = preload("res://scenes/battle/battle_screen.tscn")
const Fixture = preload("res://tests/fixtures/m5_full_battle_fixture.gd")
const Last = preload("res://scripts/domain/m4/last_spell/last_spell_resolver.gd")
const HP = preload("res://scripts/domain/m5/status/hp_lifecycle_bridge.gd")
const BossPolicy = preload("res://scripts/domain/m5/boss/boss_ai_policy.gd")
const Lv40Boss = preload("res://scripts/domain/m5/lv40/lv40_boss.gd")
const Model = preload("res://scripts/domain/m1/combat_model.gd")
var total: int = 0
var failed: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, name: String) -> void:
	total += 1
	if not ok: failed += 1
	print(("PASS " if ok else "FAIL ") + name)

func run() -> void:
	var screen: Control = Scene.instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame
	var initial: Dictionary = Fixture.initial()
	var down: Dictionary = initial.duplicate(true)
	down["core"]["battle"]["actors"]["B"]["hp"] = 0
	down["core"]["battle"]["actors"]["B"]["status"] = "INCAPACITATED"
	var saved: String = Model.state_hash(down)
	screen.present(down)
	var actor_b: Node2D = screen.get_node("Design/Arena/B")
	var actor_a: Node2D = screen.get_node("Design/Arena/A")
	var card_b: Button = screen.hud.roster["B"]
	check(actor_b.visible, "RET-KO-REMAINS-ON-FIELD")
	check(actor_b.downed and not actor_b.retired, "RET-KO-POSE")
	check(actor_b.body.rotation < -0.5, "RET-KO-CG-TILTED")
	check(actor_a.visible, "RET-KO-OTHER-ALLIES-REMAIN")
	check(card_b.hp_bar.value == 0.0, "RET-KO-HP-BAR-ZERO")
	check(card_b.combat_status == "INCAPACITATED", "RET-KO-ROSTER-STATE")
	check(not card_b.retirement_mark.visible, "RET-KO-NO-RETIRE-CROSS")
	check(Model.state_hash(screen.snapshot) == saved, "RET-KO-DOMAIN-READONLY")

	# Genuine Last Spell lifecycle transition: do not create a fake EXHAUSTED
	# fixture for the Domain receipt.
	var casting: Dictionary = initial.duplicate(true)
	casting["core"]["battle"]["actors"]["B"]["status"] = "CONCENTRATING"
	var spell: Dictionary = {
		"kind":"LAST_SPELL", "state":"CASTING","casting_id":"last:retirement:test",
		"caster_id":"B", "spell_id":"test_last", "target_snapshot":{"actor_id":"Boss"},
		"outcome_modifier_numerator":1,"outcome_modifier_denominator":1
	}
	casting["core"]["battle"]["casting_instances"][spell["casting_id"]] = spell.duplicate(true)
	var result: Dictionary = Last.settle(casting["core"],spell,3,true)
	check(result["ok"], "RET-LAST-SPELL-SETTLES")
	if result["ok"]:
		var final_core: Dictionary = result["core"]
		check(final_core["battle"]["actors"]["B"]["status"] == "EXHAUSTED", "RET-DOMAIN-EXHAUSTED")
		check(bool(final_core["battle"].get("retired_from_field_by_actor",{}).get("B",false)),
			"RET-DOMAIN-FIELD-MEMBERSHIP")
		check(final_core["battle"]["allies"].has("B"), "RET-DOMAIN-KEEPS-IDENTITY")
		check(final_core["cards"]["actors"].has("B"), "RET-DOMAIN-KEEPS-HAND-ZONES")
		check(not HP.heal(final_core,"B",5)["ok"], "RET-DOMAIN-HEAL-REJECTS-RETIRED")
		check(not HP.revive(final_core,"B",20)["ok"], "RET-DOMAIN-REVIVE-REJECTS-RETIRED")
		check(BossPolicy._target(final_core,"FIRST_ACTIVE") == "A", "RET-BOSS-TARGETS-OTHER-ALLY")
		check(not Lv40Boss._live(final_core).has("B"), "RET-LV40-BOSS-EXCLUDES-RETIRED")
		check(Lv40Boss._live(final_core).size() == 2, "RET-EXACTLY-TWO-LIVE-COMBATANTS")
		check(result["timeline"][-1]["kind"] == "ActorExhausted" and
			not bool(result["timeline"][-1]["still_targetable"]),
			"RET-DOMAIN-EVENT-NO-LONGER-TARGETABLE")
		var retired: Dictionary = initial.duplicate(true)
		retired["core"] = final_core
		var state_hash: String = Model.state_hash(retired)
		screen.select_actor("A")
		screen.present(retired)
		card_b = screen.hud.roster["B"]
		check(not actor_b.visible and actor_b.retired, "RET-CG-EXITED")
		check(actor_a.visible and screen.get_node("Design/Arena/C").visible,
			"RET-OTHER-TWO-REMAIN")
		check(card_b.retirement_mark.visible, "RET-ROSTER-CROSS")
		check(card_b.portrait.modulate.r < 0.6, "RET-ROSTER-GREY")
		check(card_b.combat_status == "EXHAUSTED", "RET-ROSTER-EXHAUSTED")
		screen.select_actor("B")
		check(screen.selected_actor != "B", "RET-CANNOT-SELECT-RETIRED")
		check(Model.state_hash(screen.snapshot) == state_hash, "RET-SCREEN-NO-DOMAIN-WRITE")
		screen.present(down)
		check(actor_b.visible and actor_b.downed, "RET-RETURN-TO-KO-FIXTURE")
		screen.present(initial)
		check(actor_b.visible and not actor_b.downed and not actor_b.retired, "RET-REVIVED-VISUAL")
		check(not screen.hud.roster["B"].retirement_mark.visible, "RET-REVIVED-ROSTER")

	screen.queue_free()
	await process_frame
	print("RETIREMENT_REPORT executed=%d passed=%d failed=%d" % [total,total-failed,failed])
	quit(0 if failed == 0 else 1)
