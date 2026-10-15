extends VBoxContainer
const Roster = preload("res://scenes/ui/hero_roster_item.tscn")
const Portraits: Texture2D = preload("res://assets/portraits/party_portraits.png")
const ICON_BARRIER: Texture2D = preload("res://assets/ui/v35/status_barrier.svg")
const ICON_GUARD: Texture2D = preload("res://assets/ui/v35/status_guard.svg")
const ICON_CASTING: Texture2D = preload("res://assets/ui/v35/status_casting.svg")
const ICON_EXHAUSTED: Texture2D = preload("res://assets/ui/v35/status_exhausted.svg")
const ICON_INCAPACITATED: Texture2D = preload("res://assets/ui/v35/status_incapacitated.svg")
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

## V3.5.1: badges are derived ONLY from projection fields that already exist
## (barriers, reaction.guard_actor_ids, casts, actor.status). Absent data → no badge.
static func status_badges_for(projection: Dictionary, id: String, translate: Callable) -> Array:
	var badges: Array = []
	var barrier: Variant = projection.get("barriers", {}).get(id, 0)
	if float(barrier) > 0.0:
		badges.append({"id": "BARRIER", "icon": ICON_BARRIER,
			"tooltip": translate.call("BATTLE_BARRIER") % str(barrier)})
	if projection.get("reaction", {}).get("guard_actor_ids", []).has(id):
		badges.append({"id": "GUARD", "icon": ICON_GUARD, "tooltip": translate.call("BATTLE_GUARD")})
	for cast: Dictionary in projection.get("casts", {}).values():
		if str(cast.get("caster_id", "")) == id:
			badges.append({"id": "CASTING", "icon": ICON_CASTING,
				"tooltip": translate.call("BATTLE_STABILITY") % [cast.get("current_stability", 0), cast.get("focus_ward", 0)]})
			break
	var status: String = str(projection.get("actors", {}).get(id, {}).get("status", ""))
	if status == "EXHAUSTED":
		badges.append({"id": "EXHAUSTED", "icon": ICON_EXHAUSTED, "tooltip": translate.call("BATTLE_EXHAUSTED")})
	elif status == "INCAPACITATED":
		badges.append({"id": "INCAPACITATED", "icon": ICON_INCAPACITATED, "tooltip": translate.call("BATTLE_INCAPACITATED")})
	return badges

func render_party(projection: Dictionary, selected_actor: String) -> String:
	var selected_info: String = ""
	var translate: Callable = func(key: String) -> String: return tr(key)
	for id: String in roster:
		var status_key: String = "BATTLE_" + str(projection["actors"][id]["status"])
		var name_key: String = str(projection.get("actor_name_keys",{}).get(id,"BATTLE_HERO_"+id))
		roster[id].configure(id, tr(name_key), roster[id].portrait.texture, roster[id].accent)
		roster[id].update_projection(projection["actors"][id], tr(status_key))
		roster[id].set_selected(id == selected_actor)
		var badges: Array = status_badges_for(projection, id, translate)
		roster[id].set_status_badges(badges)
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
