extends SceneTree

const BattleScene = preload("res://scenes/battle/battle_screen.tscn")
var executed: int = 0
var failed: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, case_id: String) -> void:
	executed += 1
	if not condition:
		failed += 1
	print(("PASS " if condition else "FAIL ") + case_id)

func run() -> void:
	var screen: Control = BattleScene.instantiate()
	root.add_child(screen)
	await process_frame
	var arena: Node2D = screen.get_node("Design/Arena")
	var boss: Node2D = arena.get_node("Boss")
	var animation_player: AnimationPlayer = boss.get_node("AnimationPlayer")
	var circle: Sprite2D = boss.get_node("MagicCircle")
	var aura: Sprite2D = boss.get_node("AuraBack")
	var body: Sprite2D = boss.get_node("Body")
	check(arena.get_child_count() == 4 and str(boss.get("actor_id")) == "Boss", "BA-01-BATTLE-ARENA-INTEGRATION")
	check(circle.texture.resource_path.ends_with("assets/monsters/boss/boss_magic_circle.png"), "BA-02-MAGIC-CIRCLE-ASSET")
	check(aura.texture.resource_path.ends_with("assets/monsters/boss/boss_aura.png"), "BA-03-AURA-ASSET")
	check(body.texture.resource_path.ends_with("assets/monsters/boss/boss_body.png"), "BA-04-BODY-ASSET")
	check(circle.z_index < aura.z_index and aura.z_index < body.z_index, "BA-05-LAYER-ORDER")
	check(circle.scale.y < circle.scale.x and animation_player.current_animation == "idle", "BA-06-FLOOR-AND-IDLE-ANIMATION")
	check(screen.director._actor("Boss") == boss and boss.get_portrait_texture() == body.texture, "BA-07-SHARED-BATTLE-PRESENTER-API")
	boss.set_process(false)
	var angle_before: float = float(circle.material.get_shader_parameter("angle"))
	var floor_transform: Transform2D = circle.transform
	boss._process(1.0)
	var angle_delta: float = rad_to_deg(float(circle.material.get_shader_parameter("angle")) - angle_before)
	check(angle_delta >= 5.0 and angle_delta <= 10.0 and circle.transform == floor_transform,
		"BA-14-SLOW-ROTATION-PRESERVES-GROUND-PROJECTION")
	boss.play_hit()
	check(animation_player.current_animation == "hit", "BA-08-HIT-ANIMATION-AVAILABLE")
	await animation_player.animation_finished
	check(animation_player.current_animation == "idle", "BA-09-HIT-RETURNS-TO-IDLE")
	boss.play_defeated()
	check(animation_player.current_animation == "defeated" and bool(boss.get("_defeated")), "BA-10-DEFEATED-ANIMATION-AVAILABLE")
	await create_timer(0.9).timeout
	check(is_zero_approx(body.modulate.a) and is_zero_approx(aura.modulate.a) and is_zero_approx(circle.modulate.a), "BA-11-DEFEAT-FADE-COMPLETES")
	boss.project_conditions("ACTIVE", false, false)
	check(boss.visible and animation_player.current_animation == "idle", "BA-12-ENCOUNTER-RESET-RESTORES-IDLE")
	check(screen._last_target_portrait("Boss") == body.texture, "BA-13-BOSS-TARGET-PORTRAIT-FALLBACK")
	if DisplayServer.get_name() != "headless":
		var temp_dir: String = OS.get_environment("TEMP")
		var screenshots_ok: bool = not temp_dir.is_empty()
		for degrees: int in [0, 30, 45, 60]:
			circle.material.set_shader_parameter("angle", deg_to_rad(degrees))
			await RenderingServer.frame_post_draw
			var image: Image = root.get_texture().get_image()
			var file_name: String = "arbitrium-boss-astriom-runtime.png" if degrees == 0 else "arbitrium-boss-astriom-%d.png" % degrees
			screenshots_ok = screenshots_ok and image != null and not image.is_empty() and image.save_png(temp_dir.path_join(file_name)) == OK
		check(screenshots_ok, "BA-15-REAL-GODOT-ROTATION-SCREENSHOTS-SAVED")
	screen.queue_free()
	await process_frame
	print("BOSS_ASTRIOM_REPORT executed=%d passed=%d failed=%d" % [executed, executed - failed, failed])
	quit(0 if failed == 0 else 1)
