extends SceneTree
## Contract-blocked staging assertions only, NOT playable Lv40/UI verification.
const Main = preload("res://scenes/battle/battle_screen.tscn")
const Lv40 = preload("res://scenes/battle/lv40_battle.tscn")
var passed: int = 0
var failed: int = 0

func check(id: String, condition: bool) -> void:
	if condition:
		passed += 1
		print("PASS ",id)
	else:
		failed += 1
		push_error("FAIL "+id)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var lv: Control = Lv40.instantiate()
	root.add_child(lv)
	await process_frame
	check("P4-LV40-UI-01-INHERITED-PROFILE",lv.encounter_profile == "lv40")
	check("P4-LV40-UI-02-NO-FIXTURE-SNAPSHOT",lv.snapshot.is_empty())
	check("P4-LV40-UI-03-NO-FIXTURE-CONTROLLER",lv.controller == null)
	check("P4-LV40-UI-04-BLOCKED-FEEDBACK",lv.hud.feedback.text == lv.tr("BATTLE_NOT_IMPLEMENTED"))
	check("P4-LV40-UI-05-DISABLED-END",lv.hud.end_button.disabled)
	check("P4-LV40-UI-09-BLOCKED-INPUT",not lv.is_processing_input() and not lv.is_processing_unhandled_input())
	var blocked_key := InputEventKey.new()
	blocked_key.keycode = KEY_1
	blocked_key.pressed = true
	lv._input(blocked_key)
	check("P4-LV40-UI-10-KEY-NO-STATE",lv.snapshot.is_empty() and lv.controller == null)
	lv.queue_free()
	await process_frame
	var main: Control = Main.instantiate()
	root.add_child(main)
	await process_frame
	check("P4-LV40-UI-06-LEGACY-DEFAULT",main.encounter_profile == "fixture")
	check("P4-LV40-UI-07-LEGACY-SNAPSHOT",not main.snapshot.is_empty())
	check("P4-LV40-UI-08-LEGACY-CONTROLLER",main.controller != null)
	main.queue_free()
	await process_frame
	print("P4_LV40_UI_STAGING_REPORT executed=",passed+failed," passed=",passed," failed=",failed)
	quit(1 if failed else 0)
