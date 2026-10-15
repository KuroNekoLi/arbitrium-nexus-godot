extends SceneTree
const Scene = preload("res://scenes/battle/battle_screen.tscn")
const Model = preload("res://scripts/domain/m1/combat_model.gd")
var executed: int = 0
var failed: int = 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool) -> void:
	executed += 1
	if not ok: failed += 1
	print(("PASS" if ok else "FAIL") + " V35-AP-" + str(executed))
func run() -> void:
	var screen: Control = Scene.instantiate()
	root.add_child(screen)
	await process_frame
	for locale: String in ["zh_TW", "en"]:
		screen.set_locale(locale)
		var header: Control = screen.hud.get_node("TopBar")
		var panel: Control = header.get_node("ResourcePanel")
		var before: String = Model.state_hash(screen.snapshot)
		for ap: int in [0, 6, 9, 16]:
			var vm: Dictionary = screen.hud.vm.duplicate(true)
			vm["resources"]["current_ap"] = ap # MOCK_ONLY display boundary; never changes Domain.
			header.render_phase(vm)
			await process_frame
			await process_frame
			check(header.ap_value.text == "%d AP" % ap)
			check(header.crystal_row.get_child_count() == mini(12, maxi(6, ap)))
			check(panel.size.y <= 64 and panel.get_global_rect().encloses(header.ap_value.get_global_rect()))
			check(Model.state_hash(screen.snapshot) == before)
	screen.queue_free()
	await process_frame
	print("V35_RESOURCES_REPORT executed=%d passed=%d failed=%d" % [executed,executed-failed,failed])
	quit(0 if failed == 0 else 1)
