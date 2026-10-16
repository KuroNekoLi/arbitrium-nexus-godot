extends RefCounted
## Pure Domain projection. Both choices are simulated with the real reducer.
const M5 = preload("res://scripts/domain/m5/integration/m5_domain_resolver.gd")
const Prepared = preload("res://scripts/domain/m5/combo/prepared_combo_resolver.gd")
const Factory = preload("res://scripts/battle/battle_command_factory.gd")

static func targets(state: Dictionary, config: Dictionary, actor: String, card: String) -> Array:
	var result: Array = []
	for target: String in state["core"]["battle"]["actors"]:
		if Factory.preview(state,Factory.card(state,actor,card,target,"CHANTLESS",false,config),config)["accepted"]: result.append(target)
	return result

static func compare(state: Dictionary, command: Dictionary, config: Dictionary) -> Dictionary:
	var a: String = str(command["setup_actor_id"])
	var b: String = str(command["finisher_actor_id"])
	var ac: String = str(command["setup_card_instance_id"])
	var bc: String = str(command["finisher_card_instance_id"])
	var normal: Dictionary = Factory.card(state,b,bc,command["finisher_target_ids"][0],"CHANTLESS",false,config)
	var nr: Dictionary = Factory.preview(state,normal,config)
	var cr: Dictionary = Factory.preview(state,command,config)
	var nq: Dictionary = Prepared.quote(state,b,bc,config)
	var cq: Dictionary = cr.get("quotes",{})
	var result: Dictionary = {"normal_command":normal,"combo_command":command.duplicate(true),
		"normal_accepted":nr["accepted"],"normal_error":nr["error"],
		"combo_accepted":cr["accepted"],"combo_error":cr["error"],
		"normal_quote":nq,"combo_quotes":cq,"normal_events":nr["events"],"combo_events":cr["events"],
		"setup_definition":Prepared.definition(state,a,ac),"finisher_definition":Prepared.definition(state,b,bc)}
	if not cq.is_empty():
		result["combo_ap"] = int(cq["setup"]["ap_cost"])+int(cq["finisher"]["ap_cost"])
	return result
