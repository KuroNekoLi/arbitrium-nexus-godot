extends SceneTree
## Serialization, lifecycle and locale regression for GUI-authored geometry.
const Scene = preload("res://scenes/battle/lv40_playable_battle.tscn")
const Model = preload("res://scripts/domain/m1/combat_model.gd")
var executed: int = 0
var failed: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, id: String) -> void:
	executed += 1
	if not ok: failed += 1
	print(("PASS " if ok else "FAIL ") + id)

func run() -> void:
	var authored: Control = Scene.instantiate()
	var party: Control = authored.get_node("Design/HUD/PartyStatusPanel")
	party.position += Vector2(14, 8)
	var expected_party: Vector2 = party.position
	var actor: Node2D = authored.get_node("Design/Arena/A")
	actor.position += Vector2(24, 12)
	var expected_home: Vector2 = actor.position
	var body: AnimatedSprite2D = actor.get_node("Visuals/AnimationFit/Body")
	body.position = Vector2(8, -5)
	body.scale = Vector2(0.91, 1.08)
	var expected_body: Transform2D = body.transform
	var packed := PackedScene.new()
	check(packed.pack(authored) == OK, "GUI-01-PACK-AUTHORED-OVERRIDES")
	var save_path: String = "user://editor_authored_layout_test.tscn"
	check(ResourceSaver.save(packed, save_path) == OK, "GUI-02-SAVE-OVERRIDES")
	authored.free()
	var reloaded: PackedScene = ResourceLoader.load(save_path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE)
	var screen: Control = reloaded.instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame
	check(screen.hud._party.position == expected_party, "GUI-03-PANEL-POSITION-SURVIVES-READY")
	actor = screen.get_node("Design/Arena/A")
	body = actor.body
	check(body.transform == expected_body, "GUI-04-BODY-TRANSFORM-SURVIVES-READY")
	check(actor.position == expected_home, "GUI-05-SLOT-POSITION-SURVIVES-READY")
	check(body.owner != null and actor.state_cg.owner != null, "GUI-06-VISUALS-ARE-SAVED-NODES")
	var original_hud: Control = screen.hud
	var original_count: int = screen.hud.get_child_count()
	var state_hash: String = Model.state_hash(screen.snapshot)
	for locale: String in ["en", "zh_TW", "en", "zh_TW"]:
		screen.set_locale(locale)
	check(screen.hud == original_hud, "GUI-07-LOCALE-KEEPS-SAME-HUD")
	check(screen.hud._party.position == expected_party, "GUI-08-LOCALE-KEEPS-LAYOUT")
	check(screen.hud.get_child_count() == original_count, "GUI-09-NO-DUPLICATE-PANELS")
	check(Model.state_hash(screen.snapshot) == state_hash, "GUI-10-LAYOUT-LOCALE-NO-DOMAIN-MUTATION")
	actor.appearance.emit_changed()
	check(body.transform == expected_body, "GUI-11-ART-REFRESH-KEEPS-BODY-TRANSFORM")
	var region: Control = actor.get_node("TargetRegion")
	region.position += Vector2(6, -9)
	await process_frame
	var button: Control = screen.hud.target_buttons["A"]
	check(button.get_global_rect().position.is_equal_approx(region.get_global_rect().position), "GUI-12-TARGET-FOLLOWS-REGION")
	screen.hud._targets.position += Vector2(9, 7)
	screen.hud.last_preview.position += Vector2(-12, 8)
	screen.hud._targets._process(0.0)
	screen._open_last_preview()
	var marker: Control = screen.hud.last_preview.world_markers["Boss"]
	var boss_region: Control = screen.get_node("Design/Arena/Boss/TargetRegion")
	check(marker.get_global_rect().position.is_equal_approx(boss_region.get_global_rect().position), "GUI-15-LAST-SPELL-TARGET-RESPECTS-OVERLAY-OFFSETS")
	screen.cancel_action()
	actor.play_attack(screen.get_node("Design/Arena/Boss").position)
	await create_timer(0.75).timeout
	check(actor.position.is_equal_approx(expected_home), "GUI-13-ATTACK-RETURNS-TO-AUTHORED-HOME")
	check(body.transform == expected_body, "GUI-14-ATTACK-KEEPS-BODY-TRANSFORM")
	screen.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	print("EDITOR_AUTHORED_LAYOUT_REPORT executed=%d passed=%d failed=%d" % [executed, executed-failed, failed])
	quit(0 if failed == 0 else 1)
