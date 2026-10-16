@tool
extends RefCounted
## MOCK_ONLY Godot Inspector/Editor preview. Never creates M5 Domain state,
## Controller, signal subscriptions, card instances or command tape.
const Appearances = preload("res://scripts/battle/presentation/character_appearance_registry.gd")
const CardFrame = preload("res://scripts/battle/ui/components/battle_card_frame.gd")

static func projection() -> Dictionary:
	var actors: Dictionary = {}
	for id: String in ["A","B","C","Boss"]:
		actors[id] = {"hp": 2100 if id=="Boss" else 120,
			"max_hp": 2700 if id=="Boss" else 120,
			"mp": 14, "max_mp": 20,"status":"ACTIVE"}
	return {"actors":actors,"resources":{"current_ap":6,"base_ap":6,"rp":0},
		"phase":"PLAYER_PHASE","round":1,"outcome":"ONGOING",
		"reaction":{"status":"CLOSED","draft":[],"guard_actor_ids":[]},
		"casts":{},"barriers":{},"tactical":{"break_gauge":16,"break_max":22,
			"break_locked":false,"exposed":{}},
		"actor_name_keys":{"A":"BATTLE_HERO_A","B":"BATTLE_HERO_B",
			"C":"BATTLE_HERO_C","Boss":"BATTLE_TITLE"},
		"intent":[{"enemy_id":"Boss","skill_id":"B01","name_key":"BATTLE_B01",
			"target_ids":["A"],"hit_count":1}]}

static func decorate_mock_hand(hud: Control) -> void:
	# Shares the production BattleCardFrame, not the runtime SimpleCards Card
	# that can install input/tweens. Panels never set an owner or enter the tape.
	var appearances: Array[String] = ["U01","U02","U03","U04"]
	hud.hand.empty_state.hide()
	for i: int in appearances.size():
		var appearance: Resource = load("res://resources/ui/appearances/"+appearances[i]+".tres")
		if appearance == null:
			continue
		var frame := PanelContainer.new()
		frame.name = "MOCK_ONLY_Card_"+str(i)
		frame.position = Vector2(10+i*168, 10)
		frame.size = Vector2(158, 218)
		frame.custom_minimum_size = Vector2(158,218)
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_theme_stylebox_override("panel", CardFrame.outer_frame(appearance.accent,true))
		hud.hand.add_child(frame) # transient no owner; not saved to scene
		CardFrame.build(frame,appearance,"1 AP",true,"")

static func show(hud: Control, mode: String) -> void:
	hud.render(projection(),"A",[],[])
	decorate_mock_hand(hud)
	if mode == "Battle":
		return
	var actor: String = "A" if mode == "Last Spell Ren" else "B" if mode == "Last Spell Akane" else "C"
	var team: String = "ALLY" if actor == "C" else "ENEMY"
	var scope: String = "SINGLE" if actor == "A" else "ALL"
	var id_set: Array = ["A","B","C"] if team == "ALLY" else ["Boss"]
	var targets: Array = []
	for id: String in id_set:
		targets.append({"id":id,"name":hud.tr("BATTLE_HERO_"+id) if id != "Boss" else hud.tr("BATTLE_TITLE"),
			"portrait":Appearances.portrait_for(id),"legal":true,
			"rect":Rect2(Vector2(380,320),Vector2(130,160))})
	hud.hand.hide()
	hud.last_preview.present(hud.tr("BATTLE_LAST"),{
		"ok":true,"quote":{"ap_cost":3,"mp_cost":5},"slot":{"planned_delay_rounds":1}},
		Appearances.portrait_for(actor),targets,"",{
		"actor_id":actor,"targeting":{"team":team,"scope":scope,
			"description_key":"BATTLE_LAST_WARNING"},
		"selected_id":str(id_set[0])})
