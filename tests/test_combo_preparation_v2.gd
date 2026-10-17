extends SceneTree
const Fixture = preload("res://tests/fixtures/combo_preparation_v2_fixture.gd")
const M5 = preload("res://scripts/domain/m5/integration/m5_domain_resolver.gd")
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const Prepared = preload("res://scripts/domain/m5/combo/prepared_combo_resolver.gd")
const Preview = preload("res://scripts/battle/presentation/combo_preview.gd")
const Prep = preload("res://scripts/battle/combo_preparation_controller.gd")
const Factory = preload("res://scripts/battle/battle_command_factory.gd")
var executed: int = 0
var failed: int = 0

func check(ok: bool, id: String) -> void:
	executed += 1
	if not ok: failed += 1
	print(("PASS " if ok else "FAIL ")+id)

func deny(rig: Dictionary, command: Dictionary, id: String) -> void:
	var before: String = Model.state_hash(rig["state"])
	var result: Dictionary = M5.apply(rig["state"],command,rig["config"])
	check(not result["accepted"] and result["events"].is_empty() and Model.state_hash(result["state"]) == before and Model.state_hash(rig["state"]) == before,id)

func _initialize() -> void:
	var r: Dictionary = Fixture.make()
	var s: Dictionary = r["state"]
	var before: String = Model.state_hash(s)
	var prep: RefCounted = Prep.new()
	prep.select_setup(s,"A",r["setup"])
	check(Model.state_hash(s) == before,"CP2-01-02-selection-no-state-or-RNG-change")
	check(prep.partners().has("C"),"CP2-03-partners-from-hand")
	check(prep.select_partner("C") and prep.setup_card_instance_id == r["setup"],"CP2-04-preserve-setup")
	check(prep.select_finisher(r["finisher"]) and Prepared.definition(s,"C",prep.finisher_card_instance_id) == "T04","CP2-05-06-preserve-definition-instance")
	check(not prep.select_finisher("foreign"),"CP2-08-ineligible-finisher")
	prep.clear()
	check(Model.state_hash(s) == before,"CP2-09-cancel-pure")
	var command: Dictionary = Fixture.command(r)
	var result: Dictionary = M5.apply(s,command,r["config"])
	check(result["accepted"],"CP2-12-defense-commit")
	if result["accepted"]:
		var next: Dictionary = result["state"]
		check(next["core"]["cards"]["actors"]["A"]["zones"]["discard"].has(r["setup"]) and next["core"]["cards"]["actors"]["C"]["zones"]["discard"].has(r["finisher"]),"CP2-12-two-real-cards")
		check(next["core"]["battle"]["party_resources"]["current_ap"] == 4 and next["core"]["battle"]["actors"]["A"]["mp"] == s["core"]["battle"]["actors"]["A"]["mp"]-2 and next["core"]["battle"]["actors"]["C"]["mp"] == s["core"]["battle"]["actors"]["C"]["mp"]-2,"CP2-13-14-real-payment-zero-extra")
		check(next["core"]["battle"]["hp_barriers"]["B"] == 90.0 and next["core"]["battle"]["hp_barriers"]["C"] == 265.0,"CP2-26-separate-friendly-targets-and-bonus")
		var order: Array = []
		for event: Dictionary in result["events"]:
			if event["kind"] == "PlayerActionSettled": order.append(event["details"]["actor_id"])
		check(order == ["A","C"],"CP2-19-setup-then-finisher-events")
		var duplicate: Dictionary = r.duplicate(true)
		duplicate["state"] = next
		deny(duplicate,command,"CP2-15-duplicate-command")
		var replay: Dictionary = M5.replay(s,[command],r["config"])
		check(replay["state_hash"] == result["state_hash"] and replay["event_hash"] == result["event_hash"],"CP2-20-event-and-state-replay")
	var comparison: Dictionary = Preview.compare(s,command,r["config"])
	check(comparison["normal_accepted"] and comparison["combo_accepted"] and comparison["combo_ap"] == 2,"CP2-domain-comparison-quotes")
	check(Model.state_hash(s) == before,"CP2-preview-pure-state-events-RNG")
	var normal: Dictionary = M5.apply(s,comparison["normal_command"],r["config"])
	check(normal["accepted"] and normal["state"]["core"]["cards"]["actors"]["A"] == s["core"]["cards"]["actors"]["A"] and normal["state"]["core"]["battle"]["actors"]["A"]["mp"] == s["core"]["battle"]["actors"]["A"]["mp"],"CP2-11-normal-only-B")
	for variant: String in ["invalid_target","stale","same_actor","same_card","missing_card","unknown_recipe","full_payload","effect_injection","empty_targets","many_anchors"]:
		var bad: Dictionary = command.duplicate(true)
		match variant:
			"invalid_target": bad["finisher_target_ids"] = ["Boss"]
			"stale": bad["expected_event_seq"] = -1
			"same_actor": bad["finisher_actor_id"] = "A"
			"same_card": bad["finisher_card_instance_id"] = bad["setup_card_instance_id"]
			"missing_card": bad["finisher_card_instance_id"] = "missing"
			"unknown_recipe": bad["recipe_id"] = "missing"
			"full_payload": bad["casting_mode"] = "FULL"
			"effect_injection": bad["damage"] = 9999
			"empty_targets": bad["setup_target_ids"] = []
			"many_anchors": bad["setup_target_ids"] = ["B","C"]
		deny(r,bad,"CP2-10-17-18-28-atomic-"+variant)
	for variant: String in ["low_ap","low_mp","incapacitated","exhausted","retired","setup_dead"]:
		var bad: Dictionary = r.duplicate(true)
		var battle: Dictionary = bad["state"]["core"]["battle"]
		match variant:
			"low_ap": battle["party_resources"]["current_ap"] = 1
			"low_mp": battle["actors"]["C"]["mp"] = 0
			"incapacitated":
				battle["actors"]["C"]["hp"] = 0
				battle["actors"]["C"]["status"] = "INCAPACITATED"
			"exhausted": battle["actors"]["C"]["status"] = "EXHAUSTED"
			"retired": battle["retired_from_field_by_actor"] = {"C":true}
			"setup_dead":
				battle["actors"]["A"]["hp"] = 0
				battle["actors"]["A"]["status"] = "INCAPACITATED"
		deny(bad,Fixture.command(bad),"CP2-17-18-29-30-"+variant)
		if variant in ["incapacitated","exhausted","retired"]: check(Prepared.potentials(bad["state"],"A",bad["setup"]).is_empty(),"CP2-exclude-unavailable-partner-"+variant)
	var offense: Dictionary = Fixture.make(true)
	var attack: Dictionary = M5.apply(offense["state"],Fixture.command(offense),offense["config"])
	check(attack["accepted"],"CP2-24-offense-shared-enemy-target")
	var closed: Dictionary = offense.duplicate(true)
	closed["state"]["core"]["battle"]["lv40"]["core_open"] = false
	var closed_attack: Dictionary = M5.apply(closed["state"],Fixture.command(closed),closed["config"])
	var closed_combo_executed: bool = false
	var closed_core_opened: bool = false
	for event: Dictionary in closed_attack.get("events",[]):
		closed_combo_executed = closed_combo_executed or event["kind"] == "ComboExecuted"
		closed_core_opened = closed_core_opened or event["kind"] == "ExposedApplied"
	check(closed_attack["accepted"] and closed_combo_executed and not closed_core_opened and
		closed_attack["state"]["core"]["battle"]["m53"]["exposed"].is_empty(),
		"CP2-16-offense-combo-without-core-open-or-Exposed")
	var dead_target: Dictionary = offense.duplicate(true)
	dead_target["state"]["core"]["battle"]["actors"]["Boss"]["hp"] = 1
	deny(dead_target,Fixture.command(dead_target),"CP2-17-setup-kills-target-rollback")
	var mismatch: Dictionary = Fixture.command(offense)
	mismatch["setup_target_ids"] = ["B"]
	deny(offense,mismatch,"CP2-shared-target-enforced")
	var rng_failure: Dictionary = offense.duplicate(true)
	rng_failure["state"]["core"]["battle"]["actors"]["B"]["mp"] = 0
	deny(rng_failure,Fixture.command(rng_failure),"CP2-RNG-after-setup-finisher-MP-rejection")
	prep.select_setup(s,"A",r["setup"])
	var changed: Dictionary = s.duplicate(true)
	changed["event_seq"] = int(changed["event_seq"])+1
	check(not prep.reconcile(changed) and prep.state == "INVALIDATED","CP2-stale-preparation-invalidated")
	# Old explicit Setup→Finisher tape remains decodable and pays once per SP.
	var first: Dictionary = Factory.card(s,"A",r["setup"],"B","CHANTLESS",false,r["config"])
	var old: Dictionary = M5.apply(s,first,r["config"])
	var second: Dictionary = Factory.card(old["state"],"C",r["finisher"],"C","CHANTLESS",true,r["config"])
	var old_replay: Dictionary = M5.replay(s,[first,second],r["config"])
	check(old_replay["accepted"],"CP2-old-combo-replay-compatible")
	for seed: int in range(1,101):
		var seeded: Dictionary = Fixture.make(seed % 2 == 0,seed)
		var c: Dictionary = Fixture.command(seeded)
		var once: Dictionary = M5.apply(seeded["state"],c,seeded["config"])
		var replayed: Dictionary = M5.replay(seeded["state"],[c],seeded["config"])
		# Physical Setup may miss for a seed: the whole prepared combo must then
		# reject deterministically. Replay equality covers success AND rejection.
		var consistent: bool = once["accepted"] == replayed["accepted"] and once["state_hash"] == replayed["state_hash"] and once["event_hash"] == replayed["event_hash"]
		if not once["accepted"]:
			consistent = consistent and once["events"].is_empty() and once["state_hash"] == Model.state_hash(seeded["state"])
		check(consistent,"CP2-20-seed-"+str(seed))
	print("COMBO_V2_REPORT executed=%d passed=%d failed=%d" % [executed,executed-failed,failed])
	quit(0 if failed == 0 else 1)
