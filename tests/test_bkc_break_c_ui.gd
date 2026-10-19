extends SceneTree
## BKC-04: read-only Boss HUD / localization contract, 2 locales x 2 sizes.
## Synthetic branch variants are MOCK_ONLY; actual battlefield state is immutable.
const Scene = preload("res://scenes/battle/lv40_playable_battle.tscn")
const Model = preload("res://scripts/domain/m1/combat_model.gd")
var executed: int = 0
var failed: int = 0

func check(value: bool, name: String) -> void:
	executed += 1
	if value:
		print("PASS ", name)
	else:
		failed += 1
		printerr("FAIL ", name)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1280,720)
	var screen: Control = Scene.instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame
	screen._command_requested("REDUCED_MOTION",{"enabled":true})
	var initial_hash: String = Model.state_hash(screen.snapshot)
	var panel: Control = screen.hud.get_node("EnemyStatus")
	for locale: String in ["zh_TW","en"]:
		screen.set_locale(locale)
		for dim: Vector2i in [Vector2i(1280,720),Vector2i(1920,1080)]:
			root.size = dim
			await process_frame
			var tag: String = locale + "-" + str(dim.x)
			var v: Dictionary = screen.view_model.duplicate(true)
			panel.render_enemy(v)
			check(panel.intent_panel.visible and
				panel.intent.text.contains(screen.tr("BKC_INTENT_CANCEL_PREVIEW")),
				"BKC-UI-01-PREVIEW-" + tag)
			check(not panel.intent.text.contains(screen.tr("BKC_CAST_STABILITY").split("%")[0]),
				"BKC-UI-02-NO_HIDDEN_CAST-" + tag)
			var locked: Dictionary = v.duplicate(true)
			locked["tactical"]["break_locked"] = true
			locked["tactical"]["exposed"] = {"target_id":"Boss","expires_round":2}
			panel.render_enemy(locked)
			check(panel.break_stats.text.contains(screen.tr("BATTLE_BREAK_LOCKED")) and
				panel.break_stats.text.contains(screen.tr("BATTLE_EXPOSED")),
				"BKC-UI-03-LOCK_AND_EXPOSED-" + tag)
			var resilient: Dictionary = v.duplicate(true)
			resilient["tactical"]["break_locked"] = false
			resilient["tactical"]["break_resilience_round"] = int(resilient["round"])
			panel.render_enemy(resilient)
			check(panel.break_stats.text.contains(screen.tr("BKC_BREAK_RESILIENT")),
				"BKC-UI-04-RESILIENCE-" + tag)
			var downgrade: Dictionary = v.duplicate(true)
			downgrade["intent"] = [{
				"enemy_id":"Boss","name_key":"intent.b06.name","skill_id":"B06",
				"target_scope":"SINGLE","target_ids":["A"],"hit_count":1,
				"break_response":"DOWNGRADE","break_fallback_skill_id":"B13"}]
			downgrade["boss_cast_public"] = {
				"current_stability":7,"base_stability":12,"focus_ward":3}
			panel.render_enemy(downgrade)
			var preview: String = screen.tr("BKC_INTENT_DOWNGRADE_PREVIEW") % screen.tr("intent.b13.name")
			check(panel.intent.text.contains(preview),
				"BKC-UI-05-DOWNGRADE_PUBLIC-" + tag)
			check(panel.intent.text.contains(screen.tr("BKC_CAST_STABILITY") % [7,12]) and
				panel.intent.text.contains(screen.tr("BKC_CAST_FOCUS_WARD") % 3),
				"BKC-UI-06-PUBLIC_CAST_WARD-" + tag)
			var cancelled: Dictionary = downgrade.duplicate(true)
			cancelled["intent"][0]["break_c_result"] = "CANCEL"
			panel.render_enemy(cancelled)
			check(panel.intent.text.contains(screen.tr("BKC_INTENT_CANCELLED")),
				"BKC-UI-07-CANCEL_RESULT-" + tag)
			var weakened: Dictionary = downgrade.duplicate(true)
			weakened["intent"][0]["break_c_result"] = "DOWNGRADE"
			panel.render_enemy(weakened)
			check(panel.intent.text.contains(screen.tr("BKC_INTENT_DOWNGRADED")),
				"BKC-UI-08-DOWNGRADE_RESULT-" + tag)
	check(Model.state_hash(screen.snapshot) == initial_hash,
		"BKC-UI-09-NO_DOMAIN_MUTATION")
	screen.queue_free()
	await process_frame
	print("BKC_BREAK_C_UI_REPORT executed=%d passed=%d failed=%d" % [
		executed,executed-failed,failed])
	quit(1 if failed else 0)
