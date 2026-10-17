extends SceneTree
## Four real visual assets per character; Domain and actor identity are read-only.
const Scene = preload("res://scenes/battle/battle_screen.tscn")
const Art = preload("res://scripts/battle/presentation/character_appearance_registry.gd")
const Fixture = preload("res://tests/fixtures/m5_full_battle_fixture.gd")
const Model = preload("res://scripts/domain/m1/combat_model.gd")
var count := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func expect(value: bool, label: String) -> void:
	count += 1
	if not value: failures += 1
	print(("PASS " if value else "FAIL ") + label)

func run() -> void:
	var screen: Control = Scene.instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame
	var initial: Dictionary = Fixture.initial()
	for id: String in ["A","B","C"]:
		var appearance: Resource = Art.appearance_for(id)
		var slug: String = appearance.resource_path.get_file().get_basename() if appearance != null else ""
		var split_y: int = {"ren":536,"akane":512,"tsumugi":504}.get(slug,0)
		var p1: Texture2D = Art.portrait_for_status(id,"ACTIVE")
		var p2: Texture2D = Art.portrait_for_status(id,"INCAPACITATED")
		var f1: Texture2D = Art.field_cg_for_status(id,"ACTIVE")
		var f2: Texture2D = Art.field_cg_for_status(id,"INCAPACITATED")
		expect(p1 != null and p2 != null and f1 != null and f2 != null,"CG-ALL-FOUR-"+id)
		if p1 == null or p2 == null or f1 == null or f2 == null: continue
		expect(split_y > 0 and p1.get_size() == Vector2(512,split_y) and p2.get_size() == Vector2(512,split_y),"CG-HEAD-SIZE-"+id)
		expect(f1.get_size() == Vector2(512,1280-split_y) and f2.get_size() == Vector2(512,1280-split_y),"CG-FIELD-SIZE-"+id)
		expect(Art.field_cg_for_status(id,"EXHAUSTED") == null,"CG-EXHAUSTED-ABSENT-"+id)
		var fresh: Dictionary = initial.duplicate(true)
		var hash: String = Model.state_hash(fresh)
		screen.present(fresh)
		var field: Node2D = screen.get_node("Design/Arena/"+id)
		var roster: Button = screen.hud.roster[id]
		expect(field.visible and field.state_cg != null and field.state_cg.visible,"CG-ACTIVE-ONFIELD-"+id)
		expect(roster.portrait.texture.get_size() == Vector2(512,split_y),"CG-ACTIVE-PORTRAIT-"+id)
		expect(Model.state_hash(screen.snapshot) == hash,"CG-ACTIVE-PURE-"+id)
		var ko: Dictionary = initial.duplicate(true)
		ko["core"]["battle"]["actors"][id]["hp"] = 0
		ko["core"]["battle"]["actors"][id]["status"] = "INCAPACITATED"
		var ko_hash: String = Model.state_hash(ko)
		screen.present(ko)
		expect(field.visible and field.downed and field.state_cg.visible,"CG-KO-STILL-ON-FIELD-"+id)
		expect(roster.hp_bar.value == 0.0 and not roster.retirement_mark.visible,"CG-KO-HP-ZERO-"+id)
		expect(roster.portrait.texture.get_size() == Vector2(512,split_y),"CG-KO-PORTRAIT-"+id)
		expect(Model.state_hash(screen.snapshot) == ko_hash,"CG-KO-PURE-"+id)
		screen.present(initial)
		expect(field.visible and not field.downed and field.state_cg.visible,"CG-RECOVERY-"+id)
	var retired: Dictionary = initial.duplicate(true)
	retired["core"]["battle"]["actors"]["B"]["status"] = "EXHAUSTED"
	retired["core"]["battle"]["retired_from_field_by_actor"] = {"B":true}
	screen.present(retired)
	expect(not screen.get_node("Design/Arena/B").visible,"CG-LAST-SPELL-RETIRED")
	expect(screen.hud.roster["B"].retirement_mark.visible,"CG-LAST-SPELL-CROSS")
	expect(screen.get_node("Design/Arena/A").visible and screen.get_node("Design/Arena/C").visible,"CG-OTHER-TWO-REMAIN")
	screen.queue_free()
	await process_frame
	print("STATE_CG_REPORT executed=%d passed=%d failed=%d" % [count,count-failures,failures])
	quit(0 if failures == 0 else 1)
