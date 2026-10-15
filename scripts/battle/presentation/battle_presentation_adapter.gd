extends RefCounted
## Detached projection; callers cannot mutate authoritative state through a VM.
static func project(state: Dictionary) -> Dictionary:
	var battle: Dictionary = state["core"]["battle"]
	return {"actors":battle["actors"].duplicate(true),
		"resources":battle["party_resources"].duplicate(true),
		"hands":state["core"]["cards"]["actors"].duplicate(true),
		"phase":str(state["phase"]), "round":int(battle["round"]),
		"outcome":str(battle["outcome"]), "event_seq":int(state["event_seq"]),
		"intent":state["published_intents"].duplicate(true),
		"reaction":state["reaction_window"].duplicate(true),
		"barriers":battle.get("hp_barriers",{}).duplicate(true),
		"casts":battle["casting_instances"].duplicate(true),
		"tactical":battle.get("m53", {}).duplicate(true)}
