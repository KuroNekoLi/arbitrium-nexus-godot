extends SceneTree
## Presentation fixtures only. Does not execute the deferred Combo Domain/GUI
## groups, synthesize mouse actions or submit gameplay commands.
const Scene = preload("res://scenes/battle/battle_screen.tscn")
const Catalog = preload("res://scripts/battle/presentation/spell_animation_catalog.gd")
var executed: int = 0
var failed: int = 0

func _initialize() -> void: call_deferred("run")

func check(ok: bool, id: String) -> void:
	executed += 1
	if not ok: failed += 1
	print(("PASS " if ok else "FAIL ")+id)

func run() -> void:
	var events: Array = [
		{"kind":"CastingReleased","details":{"casting_id":"cast-b","caster_id":"B"}},
		{"kind":"DamageTrace","details":{"source_actor_id":"B","recipient_id":"Boss"}},
		{"kind":"CastingReleased","details":{"casting_id":"cast-c","caster_id":"C"}},
		{"kind":"DamageTrace","details":{"source_actor_id":"C","recipient_id":"Boss"}}]
	var prior: Dictionary = {"cast-b":{"spell_id":"A01","target_snapshot":{"actor_id":"Boss"}},
		"cast-c":{"spell_id":"T09","target_snapshot":{"actor_id":"Boss"}}}
	var visual: Array = Catalog.annotate_releases(events,prior)
	check(not events[0]["details"].has("spell_id"),"REVIEW-release-events-not-mutated")
	check(visual[0]["details"]["spell_id"] == "A01" and visual[0]["details"]["target_actor_id"] == "Boss","REVIEW-real-release-schema-enriched")
	var groups: Array = Catalog.release_groups(visual)
	check(groups.size() == 2 and groups[0].size() == 2 and groups[1].size() == 2,"REVIEW-two-release-jobs")
	check(Catalog.receipt_style({},groups[0]) == "FIREBALL" and Catalog.receipt_style({},groups[1]) == "LIGHT_BOLT","REVIEW-independent-release-styles")
	check(Catalog.release_groups([]).is_empty(),"REVIEW-empty-receipt")
	var screen: Control = Scene.instantiate()
	root.add_child(screen)
	await process_frame
	var director: Node = screen.director
	director.playing = true # Inspect queued display jobs without playing fake damage.
	var command: Dictionary = {"type":"COMMIT_PREPARED_COMBO_V2","command_id":"visual-fixture",
		"setup_actor_id":"A","setup_target_ids":["B"],"finisher_actor_id":"C","finisher_target_ids":["C"],
		"_visual_setup_card_id":"R08","_visual_finisher_card_id":"T04"}
	var accepted_events: Array = [
		{"kind":"PlayerActionSettled","command_id":"visual-fixture:setup","event_seq":1,"details":{"actor_id":"A"}},
		{"kind":"PlayerActionSettled","command_id":"visual-fixture:finisher","event_seq":2,"details":{"actor_id":"C"}}]
	director.enqueue(accepted_events,command)
	check(director.queue.size() == 2,"REVIEW-composite-display-keeps-two-jobs")
	if director.queue.size() == 2:
		check(director.queue[0]["command"]["target_actor_id"] == "B" and director.queue[1]["command"]["target_actor_id"] == "C","REVIEW-display-preserves-separate-targets")
		check(director.queue[0]["command"]["_visual_card_id"] == "R08" and director.queue[1]["command"]["_visual_card_id"] == "T04","REVIEW-display-preserves-card-styles")
	check(screen.controller.tape().is_empty(),"REVIEW-no-gameplay-command-submitted")
	director.skip_all()
	var actor: Node2D = screen.get_node("Design/Arena/B")
	check(actor.state_cg != null and actor.state_cg.visible,"REVIEW-state-CG-active")
	actor.play_spell_cast()
	check(actor.state_cg.modulate == actor.base_tint.lightened(0.33),"REVIEW-cast-flash-visible-CG")
	actor.reset_motion()
	check(actor.state_cg.modulate == actor.base_tint and actor.body.modulate == actor.base_tint,"REVIEW-skip-clears-tint")
	actor.play_hit()
	check(actor.state_cg.modulate == Color(2,1.3,1.5),"REVIEW-hit-flash-visible-CG")
	actor.reset_motion()
	actor.play_attack(Vector2(800,400))
	check(actor.body.visible and not actor.state_cg.visible,"REVIEW-attack-frames-not-hidden")
	await create_timer(0.12).timeout
	actor.play_attack(Vector2(800,400))
	await create_timer(0.7).timeout
	check(actor.state_cg.visible and not actor.body.visible and actor.position == actor.home,"REVIEW-attack-restores-idle-CG")
	screen.queue_free()
	await process_frame
	print("BRANCH_PRESENTATION_REPORT executed=%d passed=%d failed=%d" % [executed,executed-failed,failed])
	quit(0 if failed == 0 else 1)
