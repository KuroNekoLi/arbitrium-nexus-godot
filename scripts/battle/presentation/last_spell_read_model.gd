extends RefCounted
## Detached presentation projection. Team/scope come from content; legal anchors
## come from the same M5 preview that activation uses.
const Targeting = preload("res://scripts/domain/m5/lv40/last_spell_targeting.gd")
const Last = preload("res://scripts/domain/m4/last_spell/last_spell_resolver.gd")
const Factory = preload("res://scripts/battle/battle_command_factory.gd")

static func project(state: Dictionary, actor: String, config: Dictionary) -> Dictionary:
	var data: Dictionary = Targeting.definition(config, actor)
	var ids: Array = Targeting.candidates(state["core"], actor, config)
	# Legacy engineering fixtures predate scope metadata. Preserve their generic
	# targeting view, rather than assigning them a retail ability or fake scope.
	if data.is_empty() and not config.get("m5_lv40_enabled", false):
		data = {"team":"UNKNOWN", "scope":"SINGLE"}
		ids = state["core"]["battle"]["actors"].keys()
	var inspected: Dictionary = Last.inspect(state["core"], actor, config)
	var targets: Array = []
	for id: String in ids:
		var command: Dictionary = Factory.build(state, "ACTIVATE_LAST_SPELL_M4",
			{"actor_id":actor,"target_actor_id":id,"confirmed":true,"casting_mode":"FULL"})
		var accepted: bool = Factory.preview(state, command, config)["accepted"]
		var unit: Dictionary = state["core"]["battle"]["actors"][id]
		targets.append({"id":id,"hp":unit["hp"],"max_hp":unit["max_hp"],"legal":accepted})
	return {"targeting":data,"inspection":inspected,"targets":targets,
		"slot":config.get("last_spell_slots", {}).get(actor, {}).duplicate(true)}
