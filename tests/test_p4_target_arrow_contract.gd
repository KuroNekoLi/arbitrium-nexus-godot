extends SceneTree
const Overlay = preload("res://scripts/battle/ui/components/card_targeting_arrow_overlay.gd")
const Battle = preload("res://scenes/battle/battle_screen.tscn")
const Model = preload("res://scripts/domain/m1/combat_model.gd")
var count: int = 0
var failed: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	count += 1
	if not value: failed += 1
	print(("PASS " if value else "FAIL ") + label)

func run() -> void:
	root.size = Vector2i(1280,720)
	var arrow: Control = Overlay.new()
	arrow.size = Vector2(1280,720)
	root.add_child(arrow)
	var enemy := Control.new()
	enemy.position = Vector2(720,130)
	enemy.size = Vector2(190,260)
	root.add_child(enemy)
	var ally := Control.new()
	ally.position = Vector2(420,260)
	ally.size = Vector2(100,150)
	root.add_child(ally)
	await process_frame
	check(arrow.mouse_filter == Control.MOUSE_FILTER_IGNORE,"NONINTERCEPT")
	check(arrow.focus_mode == Control.FOCUS_NONE,"NO-FOCUS")
	check(not arrow.is_aiming,"INITIAL-NOT-AIMING")
	arrow.begin_aim(Vector2(400,600),["Boss"],{"Boss":enemy,"B":ally})
	check(arrow.is_aiming,"BEGINS")
	check(arrow.target_at(Vector2(790,210)) == "Boss","LEGAL-TARGET")
	check(arrow.target_at(Vector2(450,280)).is_empty(),"INVALID-ALLY-NOT-TARGET")
	arrow._update_pointer(Vector2(800,210))
	check(arrow.hovered_target == "Boss","HOVER")
	check(arrow.end_global == enemy.get_global_rect().get_center(),"SNAP")
	var points: PackedVector2Array = arrow._local_geometry()
	check(points.size() == Overlay.SAMPLES+1,"BEZIER-SAMPLES")
	check(points[0].distance_to(arrow.source_global) < 0.001,"SOURCE-ANCHOR")
	check(points[-1].distance_to(arrow.end_global) < 0.001,"END-ANCHOR")
	arrow._update_pointer(Vector2(300,300))
	check(arrow.hovered_target.is_empty(),"HOVER-OFF")
	check(arrow.end_global == Vector2(300,300),"POINTER-FOLLOWS")
	arrow.update_legal_targets(["B"])
	arrow._update_pointer(Vector2(450,280))
	check(arrow.hovered_target == "B","ALLY-TARGET")
	arrow.update_legal_targets([])
	check(not arrow.is_aiming,"EMPTY-LEGAL-CLEARS")
	arrow.end_aim()
	check(not arrow.is_aiming,"END-IS-IDEMPOTENT")
	arrow.queue_free()
	enemy.queue_free()
	ally.queue_free()
	var screen: Control = Battle.instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame
	var hud: Control = screen.hud
	check(hud.targeting_arrow != null,"HUD-OVERLAY")
	check(hud.targeting_arrow.mouse_filter == Control.MOUSE_FILTER_IGNORE,"HUD-NO-INPUT-CAPTURE")
	check(hud.card_views.size() == 4,"SIMPLECARDS-ORIGINAL-HAND")
	var before: String = Model.state_hash(screen.snapshot)
	var eligible: Control = null
	for card: Control in hud.card_views:
		if card.legal:
			eligible = card
			break
	check(eligible != null,"HAS-LEGAL-CARD")
	if eligible != null:
		screen._begin_card_arrow(str(eligible.instance_id))
		check(hud.targeting_arrow.is_aiming,"BATTLE-DRAG-START")
		check(screen.pending_card == eligible.instance_id,"CARD-INSTANCE-ID")
		check(hud.targeting_arrow.legal_ids == screen.legal_targets,"REAL-DOMAIN-TARGETS")
		check(Model.state_hash(screen.snapshot) == before,"NO-DOMAIN-WRITE")
		screen.cancel_action()
		check(not hud.targeting_arrow.is_aiming,"CANCEL-HIDES")
	check(Model.state_hash(screen.snapshot) == before,"CANCEL-READONLY")
	screen.queue_free()
	await process_frame
	print("TARGET_ARROW_REPORT executed=%d passed=%d failed=%d" % [count,count-failed,failed])
	quit(0 if failed == 0 else 1)

