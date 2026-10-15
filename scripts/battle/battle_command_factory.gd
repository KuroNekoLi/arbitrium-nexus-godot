extends RefCounted
## Converts UI identifiers to Domain intents. Never sends pricing/effect numbers.
const M5 = preload("res://scripts/domain/m5/integration/m5_domain_resolver.gd")

static func build(state: Dictionary, kind: String, fields: Dictionary = {}, serial: int = 0) -> Dictionary:
	var command: Dictionary = fields.duplicate(true)
	command["type"] = kind
	command["command_id"] = "p4:%d:%d:%s" % [int(state["event_seq"]),serial,kind]
	command["expected_event_seq"] = int(state["event_seq"])
	return command

## Optional content config is the sole feature gate. Existing five-arg calls
## retain their fixture command shape. No client-controlled costs or damage.
static func card(state: Dictionary, actor: String, instance: String, target: String,
		mode: String = "CHANTLESS", combo: bool = false,
		config: Dictionary = {}) -> Dictionary:
	var actors: Dictionary = state.get("core",{}).get("cards",{}).get("actors",{})
	var own: Dictionary = actors.get(actor,{})
	var definition: String = str(own.get("instances",{}).get(instance,{}).get("definition_id",""))
	var fields: Dictionary = {"actor_id":actor,"card_instance_id":instance,"target_actor_id":target}
	if config.get("m5_lv40_enabled",false) == true:
		fields["casting_mode"] = mode
		fields["combo_mode"] = "COMBO" if combo else "NORMAL"
		# Even invalid/foreign/missing instances retain a well-formed intent;
		# M5 authoritative hand/owner/definition checks must reject them.
		return build(state,"PLAY_LV40_CARD",fields)
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
	# Same M5 reducer and exact input; detached copies preserve state and RNG.
	return M5.apply(state.duplicate(true),command.duplicate(true),config.duplicate(true))
