extends SceneTree
## Review-only real X11 capture of a stationary spell projectile; visual-only
## synthetic DamageTrace is not claimed to be an accepted gameplay action.
const Screen = preload("res://scenes/battle/battle_screen.tscn")
const Writer = preload("res://scripts/qa/screenshot_writer.gd")
const Model = preload("res://scripts/domain/m1/combat_model.gd")
var checks: int = 0
var failed: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, tag: String) -> void:
	checks += 1
	if not ok: failed += 1
	print(("PASS " if ok else "FAIL ") + tag)

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("X11 GL renderer required for VFX screenshot")
		quit(1)
		return
	var writer := Writer.new()
	var namespace: Dictionary = Writer.prefix_from_args(OS.get_cmdline_user_args())
	if not bool(namespace.get("ok",false)):
		quit(1)
		return
	root.size = Vector2i(1280,720)
	var screen: Control = Screen.instantiate()
	root.add_child(screen)
	await create_timer(0.42).timeout
	var state_hash: String = Model.state_hash(screen.controller.snapshot())
	var actor: Node2D = screen.get_node("Design/Arena/B")
	var boss: Node2D = screen.get_node("Design/Arena/Boss")
	var event: Dictionary = {"kind":"DamageTrace","command_id":"screenshot-visual-only",
		"event_seq":10001,"details":{"source_actor_id":"B","recipient_id":"Boss",
		"hp_damage":40,"hit":true,"hit_index":0}}
	screen.director.enqueue([event],{"type":"PLAY_LV40_CARD","actor_id":"B",
		"target_actor_id":"Boss","_visual_card_id":"A01"})
	await create_timer(0.13).timeout
	await RenderingServer.frame_post_draw
	var projectile: Sprite2D = screen.director.overlay.get_node_or_null("SpellProjectile")
	check(projectile != null, "SPELL-CAPTURE-PROJECTILE-EXISTS")
	check(actor.position == actor.home, "SPELL-CAPTURE-CASTER-NOT-MOVED")
	check(boss.position == boss.home, "SPELL-CAPTURE-BOSS-NOT-MOVED")
	if projectile != null:
		check(projectile.position.x > actor.position.x and projectile.position.x < boss.position.x,
			"SPELL-CAPTURE-PROJECTILE-BETWEEN")
	var image: Image = root.get_texture().get_image()
	check(image != null and image.get_size() == Vector2i(1280,720),
		"SPELL-CAPTURE-REAL-1280")
	var output: Dictionary = writer.write_png(image,"akane_fireball_in_flight",str(namespace["prefix"]))
	check(bool(output.get("ok",false)), "SPELL-CAPTURE-PNG-VALID")
	if bool(output.get("ok",false)):
		var thumb: Image = image.duplicate()
		thumb.resize(640,360,Image.INTERPOLATE_LANCZOS)
		check(thumb.save_jpg(str(output["path"]).get_base_dir().path_join("akane_fireball_thumb.jpg"),0.75)==OK,
			"SPELL-CAPTURE-THUMB")
	check(Model.state_hash(screen.controller.snapshot()) == state_hash,"SPELL-CAPTURE-DOMAIN-PRESERVED")
	await create_timer(0.8).timeout
	screen.director.skip_all()
	screen.queue_free()
	await create_timer(0.55).timeout
	print("SPELL_RENDER_REPORT executed=%d passed=%d failed=%d" % [checks,checks-failed,failed])
	quit(0 if failed == 0 else 1)
