extends SceneTree
## Visual face geometry, not the legacy Card hit rectangle. No GUI input reruns.
const Scene = preload("res://scenes/battle/battle_screen.tscn")
const Fixture = preload("res://tests/fixtures/m5_full_battle_fixture.gd")
var executed: int = 0
var failed: int = 0
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var screen: Control = Scene.instantiate()
	root.add_child(screen)
	await process_frame
	for locale: String in ["zh_TW","en"]:
		screen.set_locale(locale)
		for count: int in [0,1,4,8]:
			var state: Dictionary = Fixture.initial()
			var zones: Dictionary = state["core"]["cards"]["actors"]["A"]["zones"]
			while zones["hand"].size() > count: zones["draw"].append(zones["hand"].pop_back())
			while zones["hand"].size() < count: zones["hand"].append(zones["draw"].pop_back())
			screen.present(state)
			await create_timer(0.35).timeout
			var safe: bool = true
			for card: Control in screen.hud.card_views:
				print("V27_FACE ",locale," ",count," root=",card.size," face=",card.face.size," scale=",card.scale," pos=",card.position)
				for point: Vector2 in [Vector2.ZERO,Vector2(card.face.size.x,0),card.face.size,Vector2(0,card.face.size.y)]:
					var global: Vector2 = card.face.get_global_transform()*point
					safe = safe and Rect2(0,0,1280,712).has_point(global)
			executed += 1
			if not safe: failed += 1
			print(("PASS " if safe else "FAIL ")+"V27-FACE-SAFE-"+locale+"-"+str(count))
	screen.queue_free()
	await process_frame
	print("V27_FACE_REPORT executed=%d passed=%d failed=%d" % [executed,executed-failed,failed])
	quit(1 if failed else 0)
