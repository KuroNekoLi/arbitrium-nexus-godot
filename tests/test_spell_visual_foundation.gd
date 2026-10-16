extends SceneTree
## Presentation-only VFX fixture. Fake receipts here are deliberately scoped to
## testing event consumption; gameplay integration is covered by P4 + Lv40 tests.
const Scene = preload("res://scenes/battle/battle_screen.tscn")
const Visuals = preload("res://scripts/battle/presentation/spell_animation_catalog.gd")
const Model = preload("res://scripts/domain/m1/combat_model.gd")
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, id: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print(("PASS " if ok else "FAIL ") + id)

func fixture_damage(actor: String, seq: int) -> Array:
	return [{"kind":"DamageTrace","command_id":"visual-only:%d" % seq,
		"event_seq":seq,"details":{"source_actor_id":actor,"recipient_id":"Boss",
		"hp_damage":28,"hit":true,"hit_index":0}}]

func fixture_command(actor: String, id: String) -> Dictionary:
	return {"type":"PLAY_LV40_CARD","actor_id":actor,"target_actor_id":"Boss",
		"_visual_card_id":id}

func run() -> void:
	check(Visuals.STYLE.size() == 33, "VFX-CATALOG-COUNT")
	for id: String in ["U01","A01","A02","A04","A06","A07","T09","T10"]:
		check(Visuals.is_projectile(Visuals.style_for(id)), "VFX-PROJECTILE-"+id)
	for id: String in ["R01","R02","R03","R06","R07","LS_REN_SWORD_V1"]:
		check(Visuals.style_for(id) == "MELEE", "VFX-KEEP-MELEE-"+id)
	for id: String in ["U02","U03","U04","U05","A03","A05","T01","T03",
		"T04","T05","T06","LS_TSUMUGI_HEAL_V1"]:
		check(Visuals.is_support(Visuals.style_for(id)), "VFX-SUPPORT-"+id)
	check(Visuals.style_for("NO_SUCH_CARD") == "NONE", "VFX-UNKNOWN-DOES-NOT-INVENT")
	var release: Array = [{"kind":"CastingReleased","details":{"spell_id":"A04"}}]
	check(Visuals.receipt_style({"_visual_card_id":"R01"},release) == "FIRE_BEAM",
		"VFX-DELAYED-CAST-WINS-OVER-ACTIVE-CARD")
	var last: Array = [{"kind":"LastSpellReleased","details":{"spell_id":"LS_AKANE_MAGE_V1"}}]
	check(Visuals.receipt_style({"type":"END_PLAYER_PHASE"},last) == "FIRE_LANCE",
		"VFX-LAST-SPELL-RELEASE")
	var screen: Control = Scene.instantiate()
	root.add_child(screen)
	await process_frame
	var director: Node = screen.director
	var caster: Node2D = screen.get_node("Design/Arena/B")
	var sword: Node2D = screen.get_node("Design/Arena/A")
	var boss: Node2D = screen.get_node("Design/Arena/Boss")
	var initial_hash: String = Model.state_hash(screen.controller.snapshot())
	var home: Vector2 = caster.home
	check(caster.position == home, "VFX-CASTER-HOME-INITIAL")
	director.enqueue(fixture_damage("B",900),fixture_command("B","A01"))
	await create_timer(0.08).timeout
	check(caster.position == home, "VFX-FIREBALL-CAST-STATIONARY")
	check(director.overlay.get_node_or_null("SpellProjectile") != null,
		"VFX-FIREBALL-LAUNCHED")
	check(boss.position == boss.home, "VFX-TARGET-STATIONARY")
	await create_timer(0.94).timeout
	check(caster.position == home and not director.playing,"VFX-FIREBALL-COMPLETE")
	check(director.overlay.get_node_or_null("SpellProjectile") == null,
		"VFX-PROJECTILE-CLEANED")
	check(director.presented_damage.size() == 1,"VFX-RECEIPT-DAMAGE-ONCE")
	director.enqueue(fixture_damage("A",901),fixture_command("A","R01"))
	await create_timer(0.12).timeout
	check(sword.position != sword.home, "VFX-SWORD-KEEPS-LUNGE")
	check(director.overlay.get_node_or_null("SpellProjectile") == null,
		"VFX-SWORD-NO-PROJECTILE")
	await create_timer(0.80).timeout
	check(sword.position == sword.home,"VFX-SWORD-RETURNS-HOME")
	director.enqueue(fixture_damage("B",902),fixture_command("B","A07"))
	await create_timer(0.06).timeout
	director.skip_all()
	await process_frame # queue_free() is deferred until end-of-frame in Godot.
	check(not director.playing and director.queue.is_empty(),"VFX-SKIP-CANCELS-QUEUE")
	check(director.overlay.get_node_or_null("SpellProjectile") == null,"VFX-SKIP-REMOVES-FX")
	check(caster.position == home,"VFX-SKIP-RESTORES-POSITION")
	director.reduced_motion = true
	director.overlay.reduced_motion = true
	director.enqueue(fixture_damage("B",903),fixture_command("B","A01"))
	await process_frame
	check(caster.position == home,"VFX-REDUCED-MOTION-STATIONARY")
	check(director.overlay.get_node_or_null("SpellProjectile") == null,
		"VFX-REDUCED-MOTION-NO-FLIGHT")
	check(Model.state_hash(screen.controller.snapshot()) == initial_hash,
		"VFX-NO-DOMAIN-OR-REPLAY-WRITES")
	director.skip_all() # Cancel pending reduced-motion effect tweens before teardown.
	await process_frame
	screen.queue_free()
	await process_frame
	print("SPELL_VISUAL_REPORT executed=%d passed=%d failed=%d" %
		[checks,checks-failures,failures])
	quit(0 if failures == 0 else 1)
