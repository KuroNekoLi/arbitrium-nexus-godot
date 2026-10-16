extends SceneTree
## True-render X11 mouse drag, 1280 and 1920. Never fires a battle action.
const Scene = preload("res://scenes/battle/battle_screen.tscn")
const Fixture = preload("res://tests/fixtures/m5_full_battle_fixture.gd")
const Writer = preload("res://scripts/qa/screenshot_writer.gd")
const Model = preload("res://scripts/domain/m1/combat_model.gd")
var count: int = 0
var failed: int = 0
var prefix: String = ""
var writer = Writer.new()

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	count += 1
	if not value: failed += 1
	print(("PASS " if value else "FAIL ") + label)

func _physical(point: Vector2) -> Vector2:
	var view_size: Vector2 = root.get_visible_rect().size
	return Vector2(point.x*float(root.size.x)/view_size.x,point.y*float(root.size.y)/view_size.y)

func move_mouse(point: Vector2) -> void:
	var p: Vector2 = _physical(point)
	root.warp_mouse(p)
	var event := InputEventMouseMotion.new()
	event.position = p
	event.global_position = p
	root.push_input(event)
	await create_timer(0.04).timeout

func press_mouse(point: Vector2, down: bool) -> void:
	var p: Vector2 = _physical(point)
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = down
	event.position = p
	event.global_position = p
	root.push_input(event)
	await create_timer(0.04).timeout

func _one_card() -> Dictionary:
	var s: Dictionary = Fixture.initial()
	var zones: Dictionary = s["core"]["cards"]["actors"]["A"]["zones"]
	while zones["hand"].size() > 1:
		zones["draw"].append(zones["hand"].pop_back())
	return s

func try_drag(screen: Control, label: String) -> void:
	var arrow: Control = screen.hud.targeting_arrow
	var card: Control = screen.hud.card_views[0]
	var start: Vector2 = card.get_global_transform()*Vector2(card.size.x*0.5,card.size.y*0.5)
	var target: Vector2 = screen.hud.target_buttons["Boss"].get_global_rect().get_center()
	check(card.legal,"CARD-LEGAL-"+label)
	await move_mouse(start)
	await press_mouse(start,true)
	for i: int in 20:
		await move_mouse(start.lerp(target,float(i+1)/20.0))
	await create_timer(0.1).timeout
	print("TARGET_ARROW_DIAG scenario=%s viewport=%s window=%s screen=%s designScale=%s start=%s target=%s hitRect=%s actualMouse=%s arrowTip=%s hovered=%s manualHit=%s" % [
		label, root.get_visible_rect().size, root.size, screen.size, screen.design.scale,
		start, target, screen.hud.target_buttons["Boss"].get_global_rect(),
		arrow.get_global_mouse_position(), arrow.end_global, arrow.hovered_target,
		arrow.target_at(arrow.get_global_mouse_position())])
	check(arrow.is_aiming,"DRAG-STARTED-"+label)
	check(arrow.hovered_target == "Boss","SNAPPED-TO-BOSS-"+label)
	check(arrow.end_global.distance_to(target) < 3.0,"ARROW-TIP-"+label)
	check(arrow.mouse_filter == Control.MOUSE_FILTER_IGNORE,"MOUSE-TRANSPARENT-"+label)
	if arrow.is_aiming:
		await RenderingServer.frame_post_draw
		var image: Image = root.get_texture().get_image()
		check(image != null and not image.is_empty(),"RENDER-"+label)
		if image != null and not image.is_empty():
			var result: Dictionary = writer.write_png(image,"arrow_"+label,prefix)
			check(bool(result.get("ok",false)),"PNG-"+label)
	await move_mouse(Vector2(320,440))
	await press_mouse(Vector2(320,440),false)
	await process_frame
	check(not arrow.is_aiming,"END-CLEARS-"+label)

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Requires true graphical mouse and canvas.")
		quit(1)
		return
	var opts: Dictionary = Writer.prefix_from_args(OS.get_cmdline_user_args())
	prefix = str(opts.get("prefix",""))
	if not opts.get("ok",false) or prefix.is_empty():
		quit(1)
		return
	root.size = Vector2i(1280,720)
	var screen: Control = Scene.instantiate()
	root.add_child(screen)
	await create_timer(0.4).timeout
	screen.present(_one_card())
	await create_timer(0.2).timeout
	var hash: String = Model.state_hash(screen.snapshot)
	check(screen.hud.card_views.size() == 1,"ONE-CARD")
	await try_drag(screen,"1280")
	check(Model.state_hash(screen.snapshot) == hash,"1280-DOMAIN-UNCHANGED")
	screen.cancel_action()
	root.size = Vector2i(1920,1080)
	# Root viewport size does not guarantee the X11 window itself was resized.
	# In the 1280x720 default test window, physical mouse x=1270 was clipped
	# before it could reach a Boss hit rect in a 1920x1080 screen.
	DisplayServer.window_set_size(Vector2i(1920,1080))
	await create_timer(0.3).timeout
	print("TARGET_ARROW_WINDOW_DIAG reported=%s root=%s visible=%s" % [
		DisplayServer.window_get_size(),root.size,root.get_visible_rect().size])
	await try_drag(screen,"1920")
	check(Model.state_hash(screen.snapshot) == hash,"1920-DOMAIN-UNCHANGED")
	screen.queue_free()
	await process_frame
	print("TARGET_ARROW_GUI_REPORT executed=%d passed=%d failed=%d" % [count,count-failed,failed])
	quit(0 if failed == 0 else 1)

