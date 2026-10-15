extends RefCounted
## Plugged into M3 eligibility and its existing pay-on-confirm JIT queue.
const Protect = preload("res://scripts/domain/m3/reaction/basic_protect_resolver.gd")
const Effects = preload("res://scripts/domain/m5/lv40/lv40_effects.gd")

static func check(core: Dictionary, action: Dictionary, window: Dictionary,
		entry: Dictionary, effect: String, active: bool) -> Dictionary:
	if not core["battle"].has("lv40"):
		return {"ok":false,"error":"LV40_REACTION_NOT_ENABLED"}
	var actor: String = str(entry["actor_id"])
	var target: String = str(entry.get("target_actor_id",""))
	if effect == "LV40_PROTECT_COUNTER":
		if actor != "A":
			return {"ok":false,"error":"LV40_REACTION_WRONG_OWNER"}
		return Protect.check(core,action,window,actor,target,active)
	if actor != "C":
		return {"ok":false,"error":"LV40_REACTION_WRONG_OWNER"}
	var intent: Dictionary = action["public_intent"]
	if not active or str(intent.get("target_scope","")) != "SINGLE" or int(intent.get("hit_count",0)) < 1 or bool(intent.get("direct_casting_disruption",false)):
		return {"ok":false,"error":"LV40_NO_SINGLE_HP_TRIGGER"}
	var recipient: String = str(window.get("damage_recipient_actor_id",""))
	if recipient.is_empty():
		recipient = str(intent["target_ids"][0])
	if target != recipient:
		return {"ok":false,"error":"LV40_NOT_CURRENT_RECIPIENT"}
	return {"ok":true}

static func execute(state: Dictionary, action: Dictionary, entry: Dictionary,
		effect: String) -> Dictionary:
	var next: Dictionary = state.duplicate(true)
	var records: Array = []
	var target: String = str(entry["target_actor_id"])
	if effect == "LV40_PROTECT_COUNTER":
		var redirect: Dictionary = Protect.apply(next["reaction_window"],str(entry["actor_id"]),target,action)
		if not redirect["ok"]:
			return redirect
		next["reaction_window"] = redirect["window"]
		next["reaction_window"]["lv40_counter_actor_id"] = str(entry["actor_id"])
		records.append({"kind":redirect["effect"]["kind"],"details":redirect["effect"]})
		target = str(entry["actor_id"])
	var shield: Dictionary = Effects.barrier(next["core"],target,
		80 if effect == "LV40_PROTECT_COUNTER" else 130,int(next["core"]["battle"]["round"]))
	next["core"] = shield["core"]
	for e: Dictionary in shield["timeline"]:
		records.append({"kind":e["kind"],"details":e})
	return {"ok":true,"state":next,"records":records}
