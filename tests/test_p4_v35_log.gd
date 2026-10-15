extends SceneTree
## V3.5.4 Bottom Right: action context surface + DomainEvent-sourced log rows.
## Oracle = the events actually emitted by BattleController.resolved; every row
## seq must exist in that stream and generic collapses must be contiguous.
const Scene = preload("res://scenes/battle/battle_screen.tscn")
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const Factory = preload("res://scripts/battle/battle_command_factory.gd")
const Formatter = preload("res://scripts/battle/presentation/battle_log_formatter.gd")
var executed: int = 0
var failed: int = 0
var captured: Array = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, id: String) -> void:
	executed += 1
	if not ok:
		failed += 1
	print(("PASS " if ok else "FAIL ") + id)

func encloses(outer: Control, inner: Control) -> bool:
	return outer.get_global_rect().grow(1.0).encloses(inner.get_global_rect())

func card_id(state: Dictionary, actor: String, definition: String) -> String:
	var own: Dictionary = state["core"]["cards"]["actors"][actor]
	for id: String in own["zones"]["hand"]:
		if own["instances"][id]["definition_id"] == definition:
			return id
	return ""

func run() -> void:
	root.size = Vector2i(1280, 720)
	var screen: Control = Scene.instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame
	screen._command_requested("REDUCED_MOTION", {"enabled": true})
	screen.controller.resolved.connect(func(_s: Dictionary, events: Array, _c: Dictionary) -> void:
		captured.append_array(events.duplicate(true)))
	var hud: Control = screen.hud
	var log_panel: Control = hud.get_node("BattleLogPanel")
	var ctx: Control = hud.get_node("Context")

	# Structure: facade kept, rows container present, context surfaces styled.
	check(log_panel.is_ancestor_of(hud.log_label) and log_panel.entry_list != null, "V35L-LOG-FACADE-AND-ROWS")
	check(log_panel.visible_rows().is_empty() and hud.log_label.visible, "V35L-EMPTY-NO-FABRICATED-ROWS")
	check(ctx.detail_scroll.is_ancestor_of(hud.details) and
		hud.details.get_parent().name == "DetailsInset", "V35L-DETAILS-INSET")
	check(not ctx.detail_scroll.is_ancestor_of(hud.confirm_button), "V35L-CONFIRM-STILL-STICKY")
	check(hud.confirm_button.get_theme_stylebox("normal") is StyleBoxFlat and
		hud.confirm_button.get_theme_stylebox("focus") is StyleBoxFlat, "V35L-CONFIRM-STYLED")

	# Pure formatter oracle cases (no Domain).
	var names := func(id: String) -> String: return "N" + id
	var tr_id := func(key: String) -> String: return screen.tr(key)
	var synthetic: Array = [
		{"event_seq": 10, "kind": "CardZoneChanged", "details": {}},
		{"event_seq": 11, "kind": "ResourcesPaid", "details": {}},
		{"event_seq": 12, "kind": "HPDamageApplied", "details": {"recipient_id": "Boss", "amount": 7}},
		{"event_seq": 13, "kind": "PlayerActionSettled", "details": {"actor_id": "A"}},
		{"event_seq": 15, "kind": "CastingStarted", "details": {}},
	]
	var rows: Array = Formatter.rows_for(synthetic, tr_id, names)
	check(rows.size() == 4, "V35L-FMT-COLLAPSE-COUNT")
	check(rows[0]["seq"] == 10 and rows[0]["seq_end"] == 11 and rows[0]["count"] == 2, "V35L-FMT-GENERIC-RANGE")
	check(rows[1]["category"] == "DAMAGE" and rows[1]["text"] == screen.tr("BATTLE_LOG_DAMAGE") % ["NBoss", 7],
		"V35L-FMT-DAMAGE-FIELDS")
	check(rows[2]["category"] == "ACTION" and rows[2]["text"] == screen.tr("BATTLE_LOG_ACTION") % "NA",
		"V35L-FMT-ACTION-FIELDS")
	check(rows[3]["category"] == "CAST" and rows[3]["text"] == screen.tr("BATTLE_CUE_CAST_START"), "V35L-FMT-CUE")
	check(Formatter.seq_label(rows[0]) == "#10–11" and Formatter.seq_label(rows[1]) == "#12", "V35L-FMT-SEQ-LABEL")
	var gap: Array = Formatter.rows_for([
		{"event_seq": 1, "kind": "X", "details": {}}, {"event_seq": 3, "kind": "Y", "details": {}}], tr_id, names)
	check(gap.size() == 2, "V35L-FMT-NONCONTIGUOUS-NOT-MERGED")
	var partial: Array = Formatter.rows_for([
		{"event_seq": 5, "kind": "HPDamageApplied", "details": {"amount": 3}}], tr_id, names)
	check(partial[0]["category"] == "GENERIC", "V35L-FMT-MISSING-FIELD-NOT-INFERRED")
	# V3.5.5 revision: resource / intent / reaction kinds restate their own fields.
	var wrap := func(inner: Dictionary) -> Dictionary: return {"core_event": {"event": {"details": inner}}}
	var skills := func(id: String) -> String: return "S" + id
	var typed: Array = Formatter.rows_for([
		{"event_seq": 20, "kind": "SPCostReservedOnly", "details": wrap.call({"actor_id": "C", "ap_paid": 1, "mp_cost": 2})},
		{"event_seq": 21, "kind": "PlayerResourcesClosed", "details": wrap.call({"ap_remaining": 5, "rp_created": 5})},
		{"event_seq": 22, "kind": "EnemyActionDeclared", "details": {"public_intent":
			{"enemy_id": "Boss", "skill_id": "boss_strike", "target_ids": ["A", "B"]}}},
		{"event_seq": 23, "kind": "ReactionWindowOpened", "details": {}},
		{"event_seq": 24, "kind": "SPCostReservedOnly", "details": wrap.call({"actor_id": "C"})},
	], tr_id, names, skills)
	check(typed[0]["category"] == "RESOURCE" and typed[0]["text"] == screen.tr("BATTLE_LOG_COST") % ["NC", 1, 2],
		"V35L-FMT-COST-FIELDS")
	check(typed[1]["category"] == "RESOURCE" and typed[1]["text"] == screen.tr("BATTLE_LOG_PHASE_CLOSED") % [5, 5],
		"V35L-FMT-PHASE-CLOSED-FIELDS")
	check(typed[2]["category"] == "INTENT" and typed[2]["text"] ==
		screen.tr("BATTLE_LOG_ENEMY_DECLARED") % ["NBoss", "Sboss_strike", "NA, NB"], "V35L-FMT-DECLARED-FIELDS")
	check(typed[3]["category"] == "DEFENSE", "V35L-FMT-REACTION-OPEN")
	check(typed[4]["category"] == "GENERIC", "V35L-FMT-COST-MISSING-FIELD-NOT-INFERRED")

	# Real Domain: play a full chant then end the phase.
	var before: String = Model.state_hash(screen.snapshot)
	var state: Dictionary = screen.controller.snapshot()
	var spell: String = card_id(state, "C", "regular")
	check(screen.controller.submit(Factory.card(state, "C", spell, "Boss", "FULL")), "V35L-REAL-CARD-ACCEPTED")
	await process_frame
	screen._command_requested("END_PLAYER_PHASE", {})
	await process_frame
	await process_frame
	hud = screen.hud
	log_panel = hud.get_node("BattleLogPanel")
	check(Model.state_hash(screen.snapshot) != before and not captured.is_empty(), "V35L-REAL-EVENTS-CAPTURED")
	var real_seqs: Dictionary = {}
	for event: Dictionary in captured:
		real_seqs[int(event["event_seq"])] = str(event["kind"])
	var shown: Array = log_panel.visible_rows()
	var all_real := true
	var contiguous := true
	for row: Dictionary in shown:
		for seq: int in range(int(row["seq"]), int(row["seq_end"]) + 1):
			contiguous = contiguous and real_seqs.has(seq)
		all_real = all_real and real_seqs.has(int(row["seq"])) and real_seqs[int(row["seq"])] == row["kind"]
	check(not shown.is_empty() and shown.size() <= log_panel.VISIBLE_ROWS, "V35L-REAL-ROWS-BOUNDED")
	check(all_real, "V35L-REAL-ROW-SEQ-KIND-MATCH")
	check(contiguous, "V35L-REAL-RANGES-ONLY-REAL-SEQS")
	var max_seq: int = 0
	for seq: int in real_seqs:
		max_seq = maxi(max_seq, seq)
	check(int(shown[-1]["seq_end"]) == max_seq, "V35L-REAL-NEWEST-IS-LAST-EVENT")
	var meaningful: int = shown.filter(func(r: Dictionary) -> bool: return r["category"] != "GENERIC").size()
	check(meaningful * 2 >= shown.size(), "V35L-REAL-ROWS-MOSTLY-SPECIFIC")
	var no_raw_keys := true
	for row: Dictionary in shown:
		no_raw_keys = no_raw_keys and not str(row["text"]).contains("BATTLE_")
	check(no_raw_keys, "V35L-REAL-NO-UNTRANSLATED-KEYS")
	var row_nodes: Array = log_panel.entry_list.get_children()
	check(row_nodes.size() == shown.size() and str(row_nodes[-1].get_node("Seq").text) == Formatter.seq_label(shown[-1]),
		"V35L-REAL-ROW-NODES-MATCH")
	var inside := true
	for node: Control in row_nodes:
		inside = inside and node.mouse_filter == Control.MOUSE_FILTER_IGNORE
	check(inside, "V35L-ROWS-NONBLOCKING")
	check(hud.log_label.text == "\n".join(shown.slice(maxi(0, shown.size() - 3)).map(
		func(r: Dictionary) -> String: return Formatter.plain(r))), "V35L-FACADE-MIRRORS-ROWS")

	# Locale rebuild re-translates from raw events (no stale text, same seqs).
	var seqs_before: Array = shown.map(func(r: Dictionary) -> int: return int(r["seq"]))
	screen.set_locale("en")
	await process_frame
	var rebuilt: Control = screen.hud.get_node("BattleLogPanel")
	var seqs_after: Array = rebuilt.visible_rows().map(func(r: Dictionary) -> int: return int(r["seq"]))
	check(seqs_after == seqs_before, "V35L-LOCALE-SAME-SEQS")
	var en_ok := true
	for row: Dictionary in rebuilt.visible_rows():
		en_ok = en_ok and row["text"] == Formatter.rows_for(
			captured.filter(func(e: Dictionary) -> bool: return int(e["event_seq"]) >= int(row["seq"]) and int(e["event_seq"]) <= int(row["seq_end"])),
			tr_id, screen.log_actor_name,
			func(skill: String) -> String: return screen.tr(str(screen.config.get("intent_name_keys", {}).get(
				skill, "BATTLE_" + skill.to_upper()))))[0]["text"]
	check(en_ok, "V35L-LOCALE-RETRANSLATED")
	for dim: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = dim
		await process_frame
		await process_frame
		var panel: Control = screen.hud.get_node("BattleLogPanel")
		var within := true
		for node: Control in panel.entry_list.get_children():
			within = within and encloses(panel, node.get_node("Seq"))
		check(within, "V35L-ROWS-INSIDE-%d" % dim.x)
	screen.queue_free()
	await process_frame
	print("V35_LOG_REPORT executed=%d passed=%d failed=%d" % [executed, executed - failed, failed])
	quit(0 if failed == 0 else 1)
