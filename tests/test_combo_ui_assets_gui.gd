extends SceneTree
## Rendered Combo UI candidate-asset verification (2026-10-16).
## Real scene → BattleScreen → Controller → real Domain via the existing QA
## fixture (owned-instance zone exchange only). Presentation never mutates
## Domain; every check reads accepted state or rendered nodes.
const Scene = preload("res://scenes/battle/lv40_playable_battle.tscn")
const Fixture = preload("res://tests/fixtures/combo_preparation_v2_fixture.gd")
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const OUT: String = "res://docs/verification/ui/combo_ui_assets_20261016/evidence/"
var executed: int = 0
var failed: int = 0
var screen: Control
var prefix: String = ""

func _initialize() -> void: call_deferred("run")

func check(ok: bool, id: String) -> void:
	executed += 1
	if not ok: failed += 1
	print(("PASS " if ok else "FAIL ")+prefix+"-"+id)

func capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	var error: Error = root.get_texture().get_image().save_png(OUT+prefix+"-"+label+".png")
	check(error == OK,"PNG-"+label)

func wait(seconds: float) -> void:
	await create_timer(seconds).timeout

func card_for(instance: String) -> Control:
	for card: Control in screen.hud.card_views:
		if card.instance_id == instance: return card
	return null

func set_motion(reduced: bool) -> void:
	screen.director.reduced_motion = reduced
	screen.director.overlay.reduced_motion = reduced
	screen.hud.reduced_toggle.set_pressed_no_signal(reduced)

func reset(rig: Dictionary) -> void:
	screen.director.reset_session()
	screen.cancel_action()
	screen.controller.begin(rig["state"],rig["config"])
	screen.selected_actor = "A"
	screen.present(rig["state"])
	await wait(0.25)

func third_ally(rig: Dictionary) -> String:
	for id: String in ["A","B","C"]:
		if id != "A" and id != rig["partner"]: return id
	return ""

func wait_for_node(parent: Node, node_name: String, timeout: float) -> Node:
	var deadline: int = Time.get_ticks_msec() + int(timeout*1000.0)
	while Time.get_ticks_msec() < deadline:
		var node: Node = parent.get_node_or_null(node_name)
		if node != null: return node
		await process_frame
	return null

func states_flow(rig: Dictionary, reduced: bool, tag: String) -> void:
	await reset(rig)
	var roster: Dictionary = screen.hud.roster
	check(roster["A"].combo_state == "IDLE" and roster["A"].combo_mark.visible and roster["A"].combo_mark.texture != null,"UI-R01-idle-texture-"+tag)
	if not reduced: await capture("01-idle")
	screen.select_card(rig["setup"])
	await wait(0.2)
	check(screen.preparation.state == "SETUP_SELECTED","UI-setup-selected-"+tag)
	check(roster["A"].combo_state == "SELECTED","UI-R02-roster-selected-"+tag)
	check(roster[rig["partner"]].combo_state == "ELIGIBLE" and roster[rig["partner"]].combo_strength == 2,"UI-R03-roster-eligible-"+tag)
	check(roster[third_ally(rig)].combo_state == "UNAVAILABLE","UI-R04-roster-unavailable-"+tag)
	check(roster["A"].combo_mark.get_global_rect().size.x <= 32.0,"UI-R05-indicator-compact-"+tag)
	var setup_card: Control = card_for(rig["setup"])
	check(setup_card != null and setup_card.combo_state == "SELECTED" and setup_card.combo_frame.visible,"UI-C01-card-selected-"+tag)
	await capture("02-setup"+("-reduced" if reduced else ""))
	screen.select_actor(rig["partner"])
	await wait(0.2)
	var finisher: Control = card_for(rig["finisher"])
	check(finisher != null and finisher.combo_state == "ELIGIBLE" and finisher.combo_eligible,"UI-C02-card-eligible-"+tag)
	if finisher != null:
		# Overlay must align with the card edge and never alter card geometry.
		var face_rect: Rect2 = finisher.face.get_global_rect()
		var frame_rect: Rect2 = finisher.combo_frame.get_global_rect()
		check(face_rect.position.distance_to(frame_rect.position) < 1.5 and face_rect.size.distance_to(frame_rect.size) < 1.5,"UI-C03-overlay-aligned-"+tag)
		check(finisher.combo_frame.mouse_filter == Control.MOUSE_FILTER_IGNORE,"UI-C04-overlay-no-input-"+tag)
		var name_label: Control = finisher.face.find_child("*Name*",true,false) as Control
		check(name_label == null or name_label.visible,"UI-C05-name-visible-"+tag)
		var a0: float = finisher.combo_frame.modulate.a
		await wait(0.45)
		var a1: float = finisher.combo_frame.modulate.a
		if reduced:
			check(is_equal_approx(a0,0.45) and is_equal_approx(a1,0.45) and finisher.combo_pulse == null,"UI-C06-reduced-fixed-alpha-"+tag)
		else:
			check(a0 >= 0.34 and a1 <= 0.56 and absf(a1-a0) > 0.02 and finisher.combo_pulse != null,"UI-C06-normal-alpha-pulse-"+tag)
		check(finisher.combo_frame.scale == Vector2.ONE and finisher.combo_frame.rotation == 0.0,"UI-C07-no-scale-rotation-"+tag)
	await capture("03-finisher"+("-reduced" if reduced else ""))
	# Component-only: a non-ACTIVE actor can never be shown as eligible and the
	# incapacitated dimming / status pill stay authoritative.
	var probe: Control = roster[third_ally(rig)]
	var actor: Dictionary = screen.snapshot["core"]["battle"]["actors"][third_ally(rig)].duplicate(true)
	actor["status"] = "INCAPACITATED"
	probe.update_projection(actor,"INCAPACITATED")
	probe.set_combo_state("ELIGIBLE")
	check(probe.combo_state == "UNAVAILABLE" and probe.combo_strength == 0 and probe.portrait.modulate != Color.WHITE,"UI-R06-incapacitated-never-eligible-"+tag)
	actor["status"] = "ACTIVE"
	probe.update_projection(actor,"")
	screen.present(screen.snapshot)

func unavailable_flow(make_offense: bool) -> void:
	var low: Dictionary = Fixture.make(make_offense)
	low["state"]["core"]["battle"]["actors"][low["partner"]]["mp"] = 0
	await reset(low)
	screen.select_card(low["setup"])
	await wait(0.15)
	screen.select_actor(low["partner"])
	await wait(0.2)
	var finisher: Control = card_for(low["finisher"])
	check(finisher != null and finisher.combo_state == "UNAVAILABLE" and not finisher.combo_eligible and finisher.combo_frame.visible,"UI-C08-card-unavailable")
	await capture("04-card-unavailable")

func combo_flow(rig: Dictionary, reduced: bool, tag: String) -> void:
	await reset(rig)
	var overlay: Control = screen.director.overlay
	var before_tape: int = screen.controller.tape().size()
	check(screen.controller.submit(Fixture.command(rig)),"UI-X00-combo-accepted-"+tag)
	var post_hash: String = Model.state_hash(screen.controller.snapshot())
	var cutin: Node = await wait_for_node(overlay,"ComboCutIn",3.0)
	check(cutin != null,"UI-X01-cutin-shown-"+tag)
	if cutin == null: return
	for layer: String in ["Background","Energy","Frame","SetupWell/SetupCG","FinisherWell/FinisherCG","ComboTitle"]:
		check(cutin.get_node_or_null(layer) != null,"UI-X02-layer-"+layer.get_file()+"-"+tag)
	var cut_rect: Rect2 = (cutin as Control).get_global_rect().grow(1.0)
	for well_name: String in ["SetupWell","FinisherWell"]:
		var well: Control = cutin.get_node(well_name)
		var cg: TextureRect = well.get_child(0)
		check(well.clip_contents and cut_rect.encloses(well.get_global_rect()) and cg.texture != null,"UI-X07-existing-cg-clipped-in-well-"+well_name+"-"+tag)
	check((cutin.get_node("Background") as TextureRect).texture.resource_path.ends_with("combo_cutin_background.png")
		and (cutin.get_node("Frame") as TextureRect).texture.resource_path.ends_with("combo_cutin_frame.png")
		and (cutin.get_node("Energy") as TextureRect).texture.resource_path.ends_with("combo_cutin_energy.png"),"UI-X03-three-candidate-layers-"+tag)
	check((cutin.get_node("Frame") as Control).get_index() > (cutin.get_node("SetupWell") as Control).get_index(),"UI-X04-frame-above-cg-"+tag)
	var defense: bool = rig["partner"] != "B"
	var vfx_name: String = "ComboDefenseBarrier" if defense else "ComboOffenseImpact"
	var vfx: AnimatedSprite2D = overlay.get_node_or_null(vfx_name) as AnimatedSprite2D
	check(vfx != null,"UI-V01-vfx-spawned-"+tag)
	if vfx != null:
		var frames: SpriteFrames = vfx.sprite_frames
		var cell: AtlasTexture = frames.get_frame_texture(&"combo",5) as AtlasTexture
		check(frames.get_frame_count(&"combo") == 16 and is_equal_approx(frames.get_animation_speed(&"combo"),12.0)
			and not frames.get_animation_loop(&"combo") and cell.region == Rect2(256,256,256,256),"UI-V02-sheet-4x4-16f-12fps-"+tag)
		var span: float = 256.0*vfx.scale.x
		check(span < 0.5*float(screen.get_viewport_rect().size.x) and span < 360.0,"UI-V03-no-fullscreen-flash-"+tag)
		if defense:
			check(vfx.material == null and vfx.modulate.a < 0.9,"UI-V04-defense-not-additive-silhouette-visible-"+tag)
		check(not vfx.visible and not vfx.is_playing(),"UI-V06-vfx-waits-for-cutin-"+tag)
	await wait(0.25)
	await capture(("05-cutin-defense" if defense else "05-cutin-offense")+("-reduced" if reduced else ""))
	# Timing contract: normal 1.4 + 0.2 fade; reduced 0.8 static + 0.2 fade.
	var hold: float = 0.8 if reduced else 1.4
	await wait(hold-0.25-0.15)
	check(is_instance_valid(cutin) and cutin.is_inside_tree(),"UI-X05-cutin-alive-before-hold-"+tag)
	await wait(0.15+0.2+0.35)
	check(not is_instance_valid(cutin) or not cutin.is_inside_tree(),"UI-X06-cutin-gone-after-fade-"+tag)
	if vfx != null:
		check(is_instance_valid(vfx) and vfx.visible,"UI-V07-vfx-visible-after-cutin-"+tag)
		if is_instance_valid(vfx):
			if reduced:
				check(not vfx.is_playing() and vfx.frame == 7,"UI-V05-reduced-static-frame-"+tag)
			else:
				check(vfx.is_playing() and vfx.frame >= 2 and vfx.frame <= 11,"UI-V05-normal-plays-impact-"+tag)
		await capture(("06-vfx-defense" if defense else "06-vfx-offense")+("-reduced" if reduced else ""))
	check(Model.state_hash(screen.controller.snapshot()) == post_hash,"UI-D01-domain-unchanged-by-presentation-"+tag)
	# replay_receipt() independently re-runs the tape through the Domain.
	check(screen.controller.tape().size() == before_tape+1 and screen.controller.replay_receipt()["matches"],"UI-D02-replay-matches-"+tag)

func skip_flow(rig: Dictionary) -> void:
	await reset(rig)
	var overlay: Control = screen.director.overlay
	check(screen.controller.submit(Fixture.command(rig)),"UI-S00-combo-accepted")
	var hash_after: String = Model.state_hash(screen.controller.snapshot())
	var cutin: Node = await wait_for_node(overlay,"ComboCutIn",3.0)
	check(cutin != null,"UI-S01-cutin-before-skip")
	screen._command_requested("SKIP_ANIMATION",{})
	await process_frame
	check(overlay.get_node_or_null("ComboCutIn") == null and overlay.get_node_or_null("ComboOffenseImpact") == null and overlay.get_node_or_null("ComboDefenseBarrier") == null,"UI-S02-skip-clears-cutin-vfx")
	check(Model.state_hash(screen.controller.snapshot()) == hash_after,"UI-S03-skip-no-domain-change")
	# Cut-in-only skip API.
	overlay.show_combo("A","C","CP2_DEFENSE")
	overlay.skip_combo()
	await process_frame
	check(overlay.get_node_or_null("ComboCutIn") == null,"UI-S04-skip-combo-api")

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Combo UI asset suite requires a rendered window")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for dimensions: Vector2i in [Vector2i(1280,720),Vector2i(1920,1080)]:
		for locale: String in ["zh_TW","en"]:
			root.size = dimensions
			screen = Scene.instantiate()
			root.add_child(screen)
			await wait(0.4)
			screen.set_locale(locale)
			screen.director.overlay.audio_enabled = false
			prefix = "%dx%d-%s" % [dimensions.x,dimensions.y,locale]
			check(screen.get_viewport_rect().size == Vector2(1280,720) or root.size == dimensions,"ENV-root-size")
			set_motion(false)
			await states_flow(Fixture.make(true),false,"normal")
			await unavailable_flow(true)
			await combo_flow(Fixture.make(true),false,"offense-normal")
			await combo_flow(Fixture.make(),false,"defense-normal")
			set_motion(true)
			await states_flow(Fixture.make(true),true,"reduced")
			await combo_flow(Fixture.make(true),true,"offense-reduced")
			await combo_flow(Fixture.make(),true,"defense-reduced")
			set_motion(false)
			await skip_flow(Fixture.make(true))
			screen.queue_free()
			await process_frame
	print("COMBO_UI_ASSETS_REPORT executed=%d passed=%d failed=%d" % [executed,executed-failed,failed])
	quit(0 if failed == 0 else 1)
