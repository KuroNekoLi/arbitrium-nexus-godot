@tool
extends RefCounted
## MOCK_ONLY Godot Inspector/Editor preview. Never creates M5 Domain state,
## Controller, signal subscriptions, card instances or command tape.
const Appearances = preload("res://scripts/battle/presentation/character_appearance_registry.gd")
const PartyCatalogue = preload("res://scripts/domain/m5/lv40/lv40_party_catalog.gd")
const CardFrame = preload("res://scripts/battle/ui/components/battle_card_frame.gd")

static func projection() -> Dictionary:
	var actors: Dictionary = {}
	for id: String in PartyCatalogue.party_ids() + ["Boss"]:
		actors[id] = {"hp": 2100 if id=="Boss" else 120,
			"max_hp": 2700 if id=="Boss" else 120,
			"mp": 14, "max_mp": 20,"status":"ACTIVE"}
	var names: Dictionary = {"Boss":str(PartyCatalogue.read().get("boss",{}).get("name_key","BATTLE_TITLE"))}
	for slot: String in PartyCatalogue.party_ids():
		names[slot] = str(PartyCatalogue.read()["actors"][slot]["name_key"])
	return {"actors":actors,"resources":{"current_ap":6,"base_ap":6,"rp":0},
		"phase":"PLAYER_PHASE","round":1,"outcome":"ONGOING",
		"reaction":{"status":"CLOSED","draft":[],"guard_actor_ids":[]},
		"casts":{},"barriers":{},"tactical":{"break_gauge":16,"break_max":22,
			"break_locked":false,"exposed":{}},
		"actor_name_keys":names,
		"intent":[{"enemy_id":"Boss","skill_id":"B01","name_key":"BATTLE_B01",
			"target_ids":["A"],"hit_count":1}]}

static func decorate_mock_hand(hud: Control) -> void:
	# Editor resource changes must not accumulate duplicate mock cards.
	for old: Node in hud.hand.get_children():
		if str(old.name).begins_with("MOCK_ONLY_Card_"):
			hud.hand.remove_child(old)
			old.queue_free()
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
	hud.last_preview.hide()
	hud.hand.show()
	# In the Godot EDITOR Control.tr() may resolve EditorTranslationServer
	# instead of Project translations. Never apply '%' to untranslated keys.
	# Display read-only labels with project catalogue strings explicitly.
	var labels: Dictionary = preload("res://scripts/battle/presentation/battle_translations.gd").validate_catalogues().get("catalogues",{}).get("zh_TW",{})
	hud.header.text = "玩家階段   ·   回合 1"
	hud.resources.text = "AP 6  ·  RP 0"
	hud._top.ap_value.text = "6 AP"
	hud._top.rp_value.text = "RP 0"
	hud._top.render_resource_values(projection()["resources"])
	hud.end_button.text = "結束回合"
	hud.feedback.text = "EDITOR MOCK_ONLY — 不會建立戰鬥／付款／重播"
	for id: String in PartyCatalogue.party_ids():
		var hero: Button = hud.roster[id]
		var index: int = PartyCatalogue.party_ids().find(id)
		var tint: Color = [Color("efc675"),Color("75d6ff"),Color("df9cff")][index]
		var name_key: String = str(PartyCatalogue.read()["actors"][id]["name_key"])
		hero.configure(id,str(labels.get(name_key,"角色 "+id)),
			Appearances.portrait_for(id),tint)
		hero.hp_label.text = "HP 120 / 120"
		hero.mana_label.text = "MP 14 / 20"
		hero.hp_bar.max_value = 120
		hero.hp_bar.value = 120
		hero.mana_bar.max_value = 20
		hero.mana_bar.value = 14
		hero.set_selected(index == 0)
		hero.get_node("Layout/Stats/Subtitle").text = "可行動"
	var enemy: PanelContainer = hud._enemy
	enemy.boss_title.text = str(labels.get("BATTLE_TITLE","Boss"))
	enemy.boss_stats.text = "HP 2100 / 2700"
	enemy.hp_bar.max_value = 2700
	enemy.hp_bar.value = 2100
	enemy.break_stats.text = "Break 16 / 22"
	enemy.break_bar.max_value = 22
	enemy.break_bar.value = 16
	enemy.intent.text = "敵人公開意圖（預覽資料）"
	enemy.intent_panel.show()
	hud._conditions_panel.hide()
	hud._context.hide()
	hud.reaction_panel.hide()
	hud.result_panel.hide()
	decorate_mock_hand(hud)
	_translate_preview(hud, labels)
	if mode == "Battle":
		return
	# Reuse the REAL LastSpellPreview Control, without invoking its runtime
	# target/quote legality or cost formatter in the editor.
	var slot_index: int = 0 if mode == "Last Spell Slot 1" else 1 if mode == "Last Spell Slot 2" else 2
	var actor: String = PartyCatalogue.party_ids()[slot_index]
	hud.hand.hide()
	var preview: Control = hud.last_preview
	preview.artwork.texture = Appearances.cg_for(actor)
	preview.title.text = str(labels.get("BATTLE_LAST","終極法術"))
	preview.scope_label.text = "敵方單體" if actor=="A" else "敵方全體" if actor=="B" else "我方全體"
	preview.description.text = "EDITOR MOCK_ONLY：目標預覽，不提交 Domain Command"
	preview.costs.text = ""
	preview.ap_value.text = "3 AP"
	preview.mp_value.text = "5 MP"
	preview.timing.text = "下一玩家階段"
	preview.activate_button.disabled = true
	preview.cancel_button.disabled = true
	preview.summary_title.text = preview.title.text
	preview.summary_description.text = preview.description.text
	preview.summary_target.text = preview.scope_label.text
	preview.show()
	_translate_preview(preview, labels)

static func _translate_preview(node: Node, labels: Dictionary) -> void:
	# EditorTranslationServer is separate from game translations. Resolve only
	# exact catalogue keys in this disposable view; never mutate source assets.
	if node is Label or node is Button:
		var text: String = node.get("text")
		if labels.has(text):
			node.set("text", labels[text])
	if node is Control and labels.has(node.tooltip_text):
		node.tooltip_text = str(labels[node.tooltip_text])
	for child: Node in node.get_children():
		_translate_preview(child, labels)
