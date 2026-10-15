extends SceneTree
## P4.4 sidecar: real M5 receipts; never edits live HP or supplies damage values.
const Scene = preload("res://scenes/battle/battle_screen.tscn")
const F = preload("res://tests/fixtures/m5_full_battle_fixture.gd")
const Driver = preload("res://tests/fixtures/m5_full_battle_driver.gd")
const Factory = preload("res://scripts/battle/battle_command_factory.gd")
const Model = preload("res://scripts/domain/m1/combat_model.gd")
var executed: int = 0
var failed: int = 0
var failures: Array[String] = []
var idle_count: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, id: String, detail: String = "") -> void:
	executed += 1
	if not ok:
		failed += 1
		failures.append(id)
	print(("PASS " if ok else "FAIL ")+id+(" "+detail if not detail.is_empty() else ""))

func fresh() -> Control:
	var screen: Control = Scene.instantiate()
	root.add_child(screen)
	screen._command_requested("MUTE_AUDIO", {"enabled":true})
	return screen

func dispose(screen: Control) -> void:
	screen.director.skip_all()
	screen.queue_free()
	await process_frame
	await create_timer(0.7).timeout

func attack(screen: Control, actor: String = "A", target: String = "Boss") -> Dictionary:
	return Factory.build(screen.controller.snapshot(), "BASIC_ATTACK_RESOURCE_ONLY",
		{"actor_id":actor,"target_actor_id":target})

func count_idle() -> void:
	idle_count += 1

func traces(events: Array) -> Array:
	var result: Array = []
	for event: Dictionary in events:
		if event["kind"] == "DamageTrace": result.append(event["details"].duplicate(true))
	return result

func kinds(screen: Control) -> Array:
	return screen.director.presented_cues.map(func(cue: Dictionary) -> String: return str(cue["kind"]))

func settings(node: Node, key: String) -> CheckButton:
	for child: Node in node.get_children():
		if child is CheckButton and child.text == tr(key): return child
		var found: CheckButton = settings(child,key)
		if found != null: return found
	return null

func test_skip_restart() -> void:
	var screen: Control = fresh()
	var director: Node = screen.director
	idle_count = 0
	director.idle.connect(count_idle)
	check(screen.controller.submit(attack(screen)),"P44E-SKIP-ACCEPTED")
	check(director.playing and director.presented_damage.is_empty(),"P44E-SKIP-PENDING-AWAIT")
	var before: String = Model.state_hash(screen.controller.snapshot())
	var generation: int = director.generation
	director.skip_all()
	var cues: int = director.presented_cues.size()
	await create_timer(0.8).timeout
	check(director.generation > generation and not director.playing and director.queue.is_empty(),"P44E-SKIP-CANCEL-GENERATION")
	check(director.presented_damage.is_empty() and director.presented_cues.size() == cues and idle_count == 1,"P44E-SKIP-NO-LATE-DAMAGE-OR-IDLE")
	check(Model.state_hash(screen.controller.snapshot()) == before,"P44E-SKIP-DOMAIN-HASH")
	for actor: Node2D in director.arena.get_children():
		check(actor.position == actor.home and actor.body.modulate == actor.base_tint,"P44E-SKIP-ACTOR-HOME-"+actor.actor_id)
	check(director.overlay.get_child_count() == director.overlay.voices.size(),"P44E-SKIP-EFFECTS-CLEARED")
	# Restart while a second receipt is suspended; new session deliberately reuses IDs.
	check(screen.controller.submit(attack(screen,"B")),"P44E-RESTART-OLD-ACCEPTED")
	screen._command_requested("RESTART_BATTLE",{})
	check(director.seen.is_empty() and director.presented_cues.is_empty() and director.presented_damage.is_empty(),"P44E-RESTART-HISTORY-CLEARED")
	check(Model.state_hash(screen.controller.snapshot()) == Model.state_hash(F.initial()),"P44E-RESTART-INITIAL-HASH")
	check(screen.controller.submit(attack(screen)),"P44E-RESTART-REUSED-ID-ACCEPTED")
	var expected: Array = traces(screen.controller.snapshot()["events"])
	await create_timer(0.85).timeout
	check(director.presented_damage == expected and not expected.is_empty(),"P44E-RESTART-NO-OLD-RECEIPT", "expected=%d actual=%d" % [expected.size(),director.presented_damage.size()])
	check(screen.controller.replay_receipt()["matches"],"P44E-RESTART-REPLAY")
	await dispose(screen)

func test_dedupe_rejection() -> void:
	var screen: Control = fresh()
	var command: Dictionary = attack(screen)
	check(screen.controller.submit(command),"P44E-DEDUPE-ACCEPTED")
	var events: Array = screen.controller.snapshot()["events"].duplicate(true)
	var expected: Array = traces(events)
	var count: int = screen.director.presented_cues.size()
	screen.director.enqueue(events,command)
	check(screen.director.queue.is_empty() and screen.director.presented_cues.size() == count,"P44E-DEDUPE-WHILE-PENDING")
	await create_timer(0.8).timeout
	screen.director.enqueue(events,command)
	check(screen.director.presented_damage == expected and screen.director.presented_cues.size() == count,"P44E-DEDUPE-AFTER-IDLE")
	var state_hash: String = Model.state_hash(screen.controller.snapshot())
	var tape_count: int = screen.controller.tape().size()
	var invalids: Array[Dictionary] = [command,attack(screen,"A","missing"),
		Factory.build(screen.controller.snapshot(),"NOT_A_DOMAIN_COMMAND")]
	for i: int in invalids.size():
		check(not screen.controller.submit(invalids[i]),"P44E-INVALID-REJECTED-%d" % i)
		check(Model.state_hash(screen.controller.snapshot()) == state_hash and screen.controller.tape().size() == tape_count,"P44E-INVALID-ATOMIC-%d" % i)
		check(screen.director.presented_cues.size() == count and screen.director.presented_damage == expected and not screen.director.playing,"P44E-INVALID-NO-SUCCESS-CUE-%d" % i)
	await dispose(screen)

func test_signal_reentry() -> void:
	var screen: Control = fresh()
	var director: Node = screen.director
	# A cue subscriber can synchronously skip; no coroutine continuation may restart visuals.
	director.cue_presented.connect(func(_cue: Dictionary) -> void: director.skip_all(), CONNECT_ONE_SHOT)
	check(screen.controller.submit(attack(screen)),"P44E-REENTRY-ACCEPTED")
	await process_frame
	var moving: bool = false
	for actor: Node2D in director.arena.get_children():
		if actor.position != actor.home or (actor.motion != null and actor.motion.is_running()): moving = true
	check(not moving,"P44E-REENTRY-SKIP-NO-RESUMED-MOTION")
	await create_timer(0.8).timeout
	check(director.presented_damage.is_empty() and not director.playing,"P44E-REENTRY-NO-LATE-DAMAGE")
	await dispose(screen)

func test_locale() -> void:
	var screen: Control = fresh()
	var reduced: CheckButton = settings(screen.hud,"BATTLE_REDUCED")
	var mute: CheckButton = settings(screen.hud,"BATTLE_MUTE")
	check(reduced != null and mute != null,"P44E-LOCALE-SETTINGS-EXIST")
	if reduced != null: reduced.button_pressed = true
	if mute != null: mute.button_pressed = true
	var before: String = Model.state_hash(screen.controller.snapshot())
	for locale: String in ["en","zh_TW"]:
		var generation: int = screen.director.generation
		screen.set_locale(locale)
		reduced = settings(screen.hud,"BATTLE_REDUCED")
		mute = settings(screen.hud,"BATTLE_MUTE")
		check(reduced != null and reduced.button_pressed and screen.director.reduced_motion and screen.director.overlay.reduced_motion,"P44E-LOCALE-REDUCED-CONSISTENT-"+locale)
		check(mute != null and mute.button_pressed and not screen.director.overlay.audio_enabled,"P44E-LOCALE-MUTE-CONSISTENT-"+locale)
		check(Model.state_hash(screen.controller.snapshot()) == before,"P44E-LOCALE-DOMAIN-HASH-"+locale)
		check(screen.director.generation == generation,"P44E-LOCALE-RESTORE-NO-SIGNAL-"+locale)
	# Fresh scene must have exactly one action subscriber after the old scene is destroyed.
	await dispose(screen)
	screen = fresh()
	var cmd: Dictionary = attack(screen)
	screen.action_requested.emit(cmd)
	check(screen.controller.tape().size() == 1 and screen.action_requested.get_connections().size() == 1,"P44E-SCENE-REENTER-SINGLE-SUBSCRIBER")
	await dispose(screen)

func test_reduced_pending() -> void:
	var screen: Control = fresh()
	check(screen.controller.submit(attack(screen)),"P44E-REDUCED-PENDING-ACCEPTED")
	var before: String = Model.state_hash(screen.controller.snapshot())
	var generation: int = screen.director.generation
	var toggle: CheckButton = settings(screen.hud,"BATTLE_REDUCED")
	if toggle != null: toggle.button_pressed = true
	check(screen.director.generation > generation and not screen.director.playing,"P44E-REDUCED-PENDING-CANCELLED")
	await create_timer(0.8).timeout
	check(screen.director.presented_damage.is_empty() and Model.state_hash(screen.controller.snapshot()) == before,"P44E-REDUCED-PENDING-NO-LATE-DAMAGE")
	await dispose(screen)

func key_event(code: int) -> InputEventKey:
	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = code
	event.physical_keycode = code
	return event

func test_input_map() -> void:
	var screen: Control = fresh()
	var before: String = Model.state_hash(screen.controller.snapshot())
	var saved: Array[InputEvent] = InputMap.action_get_events("battle_party_3")
	InputMap.action_erase_events("battle_party_3")
	InputMap.action_add_event("battle_party_3",key_event(KEY_F9))
	screen.Bindings.install()
	screen._input(key_event(KEY_F9))
	check(screen.selected_actor == "C" and InputMap.action_get_events("battle_party_3").size() == 1,"P44E-INPUT-PARTY-REMAP-PRESERVED")
	screen._input(key_event(KEY_RIGHT))
	check(not screen.pending_card.is_empty(),"P44E-INPUT-UI-RIGHT-SELECTS-CARD")
	screen._input(key_event(KEY_ESCAPE))
	check(screen.pending_card.is_empty() and Model.state_hash(screen.controller.snapshot()) == before,"P44E-INPUT-CANCEL-NO-DOMAIN-MUTATION")
	InputMap.action_erase_events("battle_party_3")
	for event: InputEvent in saved: InputMap.action_add_event("battle_party_3",event)
	screen._input(key_event(KEY_SPACE))
	check(screen.snapshot["reaction_window"].get("status","") == "DRAFTING","P44E-INPUT-END-TURN-MANUAL-WINDOW")
	before = Model.state_hash(screen.controller.snapshot())
	for code: int in [KEY_SPACE,KEY_ENTER,KEY_1]: screen._input(key_event(code))
	check(Model.state_hash(screen.controller.snapshot()) == before,"P44E-INPUT-REACTION-NO-IMPLICIT-PASS")
	await dispose(screen)

func test_defense() -> void:
	for protect: bool in [false,true]:
		var screen: Control = fresh()
		screen._command_requested("REDUCED_MOTION",{"enabled":true})
		screen._command_requested("END_PLAYER_PHASE",{})
		check(screen.snapshot["reaction_window"].get("status","") == "DRAFTING","P44E-DEFENSE-WINDOW-%s" % protect)
		var options: Array = screen._reaction_choices().filter(func(choice: Dictionary) -> bool: return choice["entry"]["kind"] == "BASIC_PROTECT")
		var public_target: String = screen.snapshot["published_intents"][0]["target_ids"][0]
		check(not options.is_empty() and options.all(func(choice: Dictionary) -> bool: return choice["entry"]["target_actor_id"] == public_target),"P44E-PROTECT-PUBLIC-TARGET-%s" % protect)
		var waiting: String = Model.state_hash(screen.controller.snapshot())
		await create_timer(0.7).timeout
		check(Model.state_hash(screen.controller.snapshot()) == waiting,"P44E-REACTION-NO-AUTO-PASS-%s" % protect)
		screen._command_requested("QUEUE_REACTION",{"entry":{"kind":"BASIC_GUARD","actor_id":"A","target_actor_id":"A"}})
		if protect:
			screen._command_requested("QUEUE_REACTION",{"entry":{"kind":"BASIC_PROTECT","actor_id":"B","target_actor_id":"A"}})
		var grid: Node = screen.hud.reaction_column.find_children("*","GridContainer",true,false)[0]
		check(grid.columns == 2 and grid.size_flags_horizontal == Control.SIZE_EXPAND_FILL,"P44E-REACTION-TWO-COLUMN-GRID-%s" % protect)
		var draft_labels_ok: bool = true
		var draft_labels: int = 0
		for row: Node in screen.hud.reaction_column.get_children():
			if row is HBoxContainer and row.get_child_count() > 0 and row.get_child(0) is Label:
				draft_labels += 1
				if row.get_child(0).size_flags_horizontal != Control.SIZE_EXPAND_FILL: draft_labels_ok = false
		check(draft_labels_ok and draft_labels == (2 if protect else 1),"P44E-REACTION-DRAFT-LABEL-EXPANDS-%s" % protect)
		screen._command_requested("CONFIRM_REACTIONS",{})
		var expected: Array = traces(screen.controller.snapshot()["events"])
		var actual: Array = screen.director.presented_damage
		check(not expected.is_empty() and actual == expected,"P44E-DEFENSE-EXACT-DOMAIN-TRACES-%s" % protect)
		check(kinds(screen).has("GUARD") and (not protect or kinds(screen).has("PROTECT")),"P44E-DEFENSE-CUES-%s" % protect)
		check(not actual.is_empty() and actual.all(func(d: Dictionary) -> bool: return d["recipient_id"] == ("B" if protect else "A") and d["guard_applied"] == not protect),"P44E-DEFENSE-RECIPIENT-GUARD-%s" % protect)
		print("P44E_DEFENSE protect=%s traces=%s" % [protect,JSON.stringify(actual)])
		check(screen.controller.replay_receipt()["matches"],"P44E-DEFENSE-REPLAY-%s" % protect)
		await dispose(screen)

func test_frame_profiles() -> void:
	var golden: Dictionary = Driver.run(F.SEED)
	check(golden["ok"],"P44E-PROFILE-GOLDEN-FIXTURE")
	if not golden["ok"]: return
	var saved_fps: int = Engine.max_fps
	for profile: Dictionary in [{"fps":60,"reduced":false},{"fps":10,"reduced":false},{"fps":10,"reduced":true}]:
		Engine.max_fps = profile["fps"]
		var screen: Control = fresh()
		screen._command_requested("REDUCED_MOTION",{"enabled":profile["reduced"]})
		var all_accepted: bool = true
		var start: int = Time.get_ticks_msec()
		for command: Dictionary in golden["tape"]:
			# The recorded tape already includes system advancement: commit each through
			# the real controller once, avoiding submit's extra automatic scheduler.
			if not screen.controller._commit(command):
				all_accepted = false
				break
			await process_frame
			if not profile["reduced"]: screen.director.skip_all()
		var label: String = "%dfps-reduced-%s" % [profile["fps"],profile["reduced"]]
		check(all_accepted,"P44E-PROFILE-TAPE-ACCEPTED-"+label)
		check(Model.state_hash(screen.controller.snapshot()) == golden["final_hash"],"P44E-PROFILE-STATE-HASH-"+label)
		var replay: Dictionary = screen.controller.replay_receipt()
		check(replay["accepted"] and replay["matches"],"P44E-PROFILE-REPLAY-"+label)
		check(Model.event_hash(screen.controller.snapshot()["events"]) == golden["event_hash"],"P44E-PROFILE-EVENT-HASH-"+label)
		print("P44E_PROFILE %s seed=%d commands=%d elapsed_ms=%d state_hash=%s event_hash=%s" % [label,F.SEED,screen.controller.tape().size(),Time.get_ticks_msec()-start,Model.state_hash(screen.controller.snapshot()),Model.event_hash(screen.controller.snapshot()["events"])])
		await dispose(screen)
	Engine.max_fps = saved_fps

func run() -> void:
	print("P44E_ENV engine=%s seed=%d content=%s authority=BALANCE_PROVISIONAL" % [Engine.get_version_info()["string"],F.SEED,F.CONTENT_VERSION])
	await test_skip_restart()
	await test_dedupe_rejection()
	await test_signal_reentry()
	await test_locale()
	await test_reduced_pending()
	await test_input_map()
	await test_defense()
	await test_frame_profiles()
	print("P44E_FAILED_CASES "+JSON.stringify(failures))
	print("P4_4_EDGE_REPORT executed=%d passed=%d failed=%d" % [executed,executed-failed,failed])
	quit(0 if failed == 0 else 1)
