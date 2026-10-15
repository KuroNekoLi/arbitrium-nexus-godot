extends Node
## Consumes accepted receipts only. Visual timings have no reducer callbacks.
signal idle()
var arena: Node2D
var overlay: Control
var queue: Array[Dictionary] = []
var playing: bool = false
var presented_damage: Array[Dictionary] = []

func enqueue(events: Array, command: Dictionary) -> void:
	queue.append({"events":events.duplicate(true),"command":command.duplicate(true)})
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
	var item: Dictionary = queue.pop_front()
	var command: Dictionary = item["command"]
	var source: String = str(command.get("actor_id",""))
	var recipient: String = str(command.get("target_actor_id","Boss"))
	var has_damage: bool = false
	for event: Dictionary in item["events"]:
		if event["kind"] == "DamageTrace":
			has_damage = true
			source = str(event["details"]["source_actor_id"])
			recipient = str(event["details"]["recipient_id"])
	var attacker: Node2D = _actor(source)
	var target: Node2D = _actor(recipient)
	if has_damage and attacker != null and target != null:
		attacker.play_attack(target.position)
		await get_tree().create_timer(0.19).timeout
		if not is_inside_tree(): return
	for event: Dictionary in item["events"]:
		if event["kind"] != "DamageTrace": continue
		var detail: Dictionary = event["details"]
		presented_damage.append(detail.duplicate(true))
		var victim: Node2D = _actor(str(detail["recipient_id"]))
		if victim == null: continue
		victim.play_hit()
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
		tween.tween_property(number,"position:y",number.position.y-50,0.6)
		tween.tween_property(number,"modulate:a",0.0,0.6)
		tween.chain().tween_callback(number.queue_free)
	if has_damage:
		await get_tree().create_timer(0.4).timeout
		if not is_inside_tree(): return
	_play_next()

func play_card(artwork: Texture2D, origin: Vector2, target: Vector2) -> void:
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
