extends RefCounted
## Translates input identifiers into existing schemas; never supplies effect values.
const M5 = preload("res://scripts/domain/m5/integration/m5_domain_resolver.gd")
static func build(state: Dictionary, kind: String, fields: Dictionary = {}, serial: int = 0) -> Dictionary:
	var command: Dictionary = fields.duplicate(true)
	command["type"] = kind
	command["command_id"] = "p4:%d:%d:%s" % [int(state["event_seq"]),serial,kind]
	command["expected_event_seq"] = int(state["event_seq"])
	return command
static func card(state: Dictionary, actor: String, instance: String, target: String,
		mode: String = "CHANTLESS", combo: bool = false) -> Dictionary:
	var own: Dictionary = state["core"]["cards"]["actors"].get(actor,{})
	var definition: String = str(own.get("instances",{}).get(instance,{}).get("definition_id",""))
	var fields: Dictionary = {"actor_id":actor,"card_instance_id":instance,"target_actor_id":target}
	var kind: String = "PLAY_TACTICAL_SP_M53"
	if definition in ["burn","ward","regen"]:
		kind = "USE_EFFECT_SP_M5"
	elif definition == "regular":
		kind = "CAST_SPELL_M4"
		fields["casting_mode"] = mode
	else:
		fields["combo_mode"] = "COMBO" if combo else "NORMAL"
	return build(state,kind,fields)
static func preview(state: Dictionary, command: Dictionary, config: Dictionary) -> Dictionary:
	# M5 is pure: dry-run on detached data uses precisely the submission validator.
	return M5.apply(state.duplicate(true),command,config.duplicate(true))
