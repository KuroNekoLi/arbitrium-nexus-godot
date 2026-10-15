extends VBoxContainer
const Roster = preload("res://scenes/ui/hero_roster_item.tscn")
const Portraits: Texture2D = preload("res://assets/portraits/party_portraits.png")
signal actor_requested(actor: String)
var roster: Dictionary = {}

func _ready() -> void:
	add_theme_constant_override("separation", 9)
	for i: int in 3:
		var actor: String = ["A", "B", "C"][i]
		var view: Button = Roster.instantiate()
		view.custom_minimum_size = Vector2(260, 100)
		add_child(view)
		view.get_node("Layout/Stats").add_theme_constant_override("separation", 0)
		var portrait := AtlasTexture.new()
		portrait.atlas = Portraits
		portrait.region = Rect2(i * 724, 0, 724, 724)
		view.configure(actor, tr("BATTLE_HERO_" + actor), portrait, [Color("efc675"), Color("75d6ff"), Color("df9cff")][i])
		view.hero_selected.connect(func(id: String) -> void: actor_requested.emit(id))
		roster[actor] = view

func render_party(projection: Dictionary, selected_actor: String) -> String:
	var selected_info: String = ""
	for id: String in roster:
		var status_key: String = "BATTLE_" + str(projection["actors"][id]["status"])
		var name_key: String = str(projection.get("actor_name_keys",{}).get(id,"BATTLE_HERO_"+id))
		roster[id].configure(id, tr(name_key), roster[id].portrait.texture, roster[id].accent)
		roster[id].update_projection(projection["actors"][id], tr(status_key))
		roster[id].set_selected(id == selected_actor)
		var info: PackedStringArray = [tr("BATTLE_BARRIER") % str(projection["barriers"].get(id, 0))]
		if projection["reaction"].get("guard_actor_ids", []).has(id):
			info.append(tr("BATTLE_GUARD"))
		for cast: Dictionary in projection["casts"].values():
			if cast["caster_id"] == id:
				info.append(tr("BATTLE_STABILITY") % [cast["current_stability"], cast["focus_ward"]])
		roster[id].tooltip_text = "\n".join(info)
		if id == selected_actor:
			selected_info = tr(name_key) + " · " + " · ".join(info)
	return selected_info
