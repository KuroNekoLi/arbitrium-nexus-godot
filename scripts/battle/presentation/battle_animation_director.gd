extends Node
## Consumes accepted receipts only. Visual timings have no reducer callbacks.
signal idle()
signal cue_presented(cue: Dictionary)
const Mapper = preload("res://scripts/battle/presentation/battle_cue_mapper.gd")
const SpellCatalog = preload("res://scripts/battle/presentation/spell_animation_catalog.gd")
var arena: Node2D
var overlay: Control
var queue: Array[Dictionary] = []
var playing: bool = false
var presented_damage: Array[Dictionary] = []
var seen: Dictionary = {}
var presented_cues: Array[Dictionary] = []
var generation: int = 0
var reduced_motion: bool = false
var pending_timers: Array[SceneTreeTimer] = []

func enqueue(events: Array, command: Dictionary) -> void:
	var fresh: Array = []
	for event: Dictionary in events:
		var id: String = str(event["command_id"])+":"+str(event["event_seq"])
		if seen.has(id): continue
		seen[id] = true
		fresh.append(event)
	if fresh.is_empty(): return
	queue.append({"events":fresh.duplicate(true),"command":command.duplicate(true)})
	if not playing: _play_next()

func _actor(id: String) -> Node2D:
	for node: Node2D in arena.get_children():
		if node.actor_id == id: return node
	return null

func _play_next() -> void:
	if queue.is_empty():
		playing = false
		idle.emit()
		return
	playing = true
	var current_generation: int = generation
	var item: Dictionary = queue.pop_front()
	var command: Dictionary = item["command"]
	var events: Array = item["events"]
	var cues: Array[Dictionary] = Mapper.map_events(events)
	var style: String = SpellCatalog.receipt_style(command,events)
	var magic: bool = SpellCatalog.is_projectile(style) or SpellCatalog.is_support(style) or command["type"] == "CAST_SPELL_M4"
	var cast_started: bool = false
	for cue: Dictionary in cues:
		presented_cues.append(cue.duplicate(true))
		cue_presented.emit(cue)
		if not is_inside_tree() or current_generation != generation: return
		if cue["kind"] in ["CAST_RELEASE","LAST_RELEASE"]:
			magic = true
		if cue["kind"] in ["CAST_START","LAST_START"]:
			cast_started = true
		var unit: Node2D = _actor(str(cue["actor_id"]))
		if cue["kind"] == "PROTECT":
			unit = _actor(str(cue["detail"]["to_actor_id"]))
		if cue["kind"] != "DAMAGE" and cue["kind"] not in ["CAST_RELEASE","LAST_RELEASE"] and unit != null:
			overlay.burst(unit.position+Vector2(0,-100),true,Color("94c9ff"))
	var source: String = str(command.get("actor_id",""))
	var recipient: String = str(command.get("target_actor_id","Boss"))
	var damage_targets: Array[String] = []
	for event: Dictionary in events:
		if event["kind"] == "DamageTrace":
			var detail: Dictionary = event["details"]
			source = str(detail["source_actor_id"])
			recipient = str(detail["recipient_id"])
			if not damage_targets.has(recipient):
				damage_targets.append(recipient)
		if event["kind"] in ["CastingReleased","LastSpellReleased"]:
			source = str(event["details"].get("caster_id",source))
			if event["details"].has("target_actor_id"):
				recipient = str(event["details"]["target_actor_id"])
	var attacker: Node2D = _actor(source)
	var target: Node2D = _actor(recipient)
	var has_damage: bool = not damage_targets.is_empty()
	if attacker != null and magic:
		if not reduced_motion:
			attacker.play_spell_cast()
		overlay.casting_pulse(attacker.position+Vector2(0,-attacker.visual_height*0.65),style)
	if cast_started and not has_damage:
		# Full Chant commits schedule damage for a later phase. Do not fire early.
		_play_next()
		return
	if has_damage and attacker != null and target != null:
		if not magic and not reduced_motion:
			attacker.play_attack(target.position)
		elif magic and SpellCatalog.is_projectile(style):
			var origin: Vector2 = attacker.position + Vector2(55,-attacker.visual_height*0.65)
			for id: String in damage_targets:
				var victim: Node2D = _actor(id)
				if victim != null:
					overlay.launch_projectile(origin,victim.position+Vector2(0,-victim.visual_height*0.6),style)
		overlay.sound(magic)
		if not reduced_motion:
			var windup: SceneTreeTimer = get_tree().create_timer(0.36 if magic and SpellCatalog.is_projectile(style) else 0.19)
			pending_timers.append(windup)
			await windup.timeout
			pending_timers.erase(windup)
			if not is_inside_tree() or current_generation != generation: return
	elif not has_damage and attacker != null and SpellCatalog.is_support(style):
		overlay.sound(true)
		if style == "PARTY_HEAL":
			for actor: Node2D in arena.get_children():
				if actor.actor_id != "Boss" and actor.visible:
					overlay.support_pulse(actor.position+Vector2(0,-actor.visual_height*0.60),style)
		elif target != null:
			overlay.support_pulse(target.position+Vector2(0,-target.visual_height*0.60),style)
	for event: Dictionary in events:
		if event["kind"] != "DamageTrace": continue
		var detail: Dictionary = event["details"]
		presented_damage.append(detail.duplicate(true))
		var victim: Node2D = _actor(str(detail["recipient_id"]))
		if victim == null: continue
		victim.play_hit()
		overlay.burst(victim.position+Vector2(0,-100),magic,
			SpellCatalog.tint(style) if magic else Color("ffdf96"))
		var number := Label.new()
		number.mouse_filter = Control.MOUSE_FILTER_IGNORE
		number.text = str(detail["hp_damage"]) if detail["hit"] else tr("BATTLE_MISS")
		number.add_theme_font_size_override("font_size",30)
		number.add_theme_color_override("font_color",Color("fff0bb"))
		number.add_theme_color_override("font_outline_color",Color("18202e"))
		number.add_theme_constant_override("outline_size",6)
		number.position = victim.position + Vector2(-25+int(detail["hit_index"])*38,-victim.visual_height*0.7)
		overlay.add_child(number)
		var tween: Tween = number.create_tween().set_parallel(true)
		if not reduced_motion: tween.tween_property(number,"position:y",number.position.y-50,0.6)
		tween.tween_property(number,"modulate:a",0.0,0.6)
		tween.chain().tween_callback(number.queue_free)
	if has_damage and not reduced_motion:
		var recovery: SceneTreeTimer = get_tree().create_timer(0.4)
		pending_timers.append(recovery)
		await recovery.timeout
		pending_timers.erase(recovery)
		if not is_inside_tree() or current_generation != generation: return
	_play_next()

func play_card(artwork: Texture2D, origin: Vector2, target: Vector2) -> void:
	if reduced_motion:
		overlay.burst(target,true,Color("9dcaff"))
		return
	var ghost := TextureRect.new()
	ghost.texture = artwork
	ghost.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ghost.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	ghost.size = Vector2(146,90)
	ghost.position = origin
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(ghost)
	var tween: Tween = ghost.create_tween()
	tween.tween_property(ghost,"position",target-ghost.size*0.5,0.3).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(ghost,"scale",Vector2(0.5,0.5),0.3)
	tween.tween_property(ghost,"modulate:a",0.0,0.16)
	tween.tween_callback(ghost.queue_free)

func _exit_tree() -> void:
	queue.clear()
	generation += 1
	_cancel_waits()
	playing = false

func _cancel_waits() -> void:
	# SceneTreeTimers outlive a freed scene. Wake suspended continuations only
	# after generation changes so they return without further visual work.
	for timer: SceneTreeTimer in pending_timers.duplicate():
		timer.timeout.emit()
	pending_timers.clear()

func skip_all() -> void:
	generation += 1
	_cancel_waits()
	queue.clear()
	playing = false
	for actor: Node2D in arena.get_children(): actor.reset_motion()
	overlay.clear_effects()
	idle.emit()

func reset_session() -> void:
	skip_all()
	seen.clear()
	presented_cues.clear()
	presented_damage.clear()
