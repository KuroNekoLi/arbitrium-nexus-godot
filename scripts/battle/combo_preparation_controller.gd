extends RefCounted
## Uncommitted UI selections only. Holds no mutable Domain references.
const Prepared = preload("res://scripts/domain/m5/combo/prepared_combo_resolver.gd")
const Preview = preload("res://scripts/battle/presentation/combo_preview.gd")
const Factory = preload("res://scripts/battle/battle_command_factory.gd")
var state: String = "IDLE"
var setup_actor_id: String = ""
var setup_card_instance_id: String = ""
var setup_target_ids: Array = []
var finisher_actor_id: String = ""
var finisher_card_instance_id: String = ""
var finisher_target_ids: Array = []
var recipe_id: String = ""
var revision: int = -1
var candidates: Array = []

func clear(outcome: String = "CANCELLED") -> void:
	state = outcome
	setup_actor_id = ""
	setup_card_instance_id = ""
	setup_target_ids.clear()
	finisher_actor_id = ""
	finisher_card_instance_id = ""
	finisher_target_ids.clear()
	recipe_id = ""
	candidates.clear()
	revision = -1

func select_setup(snapshot: Dictionary, actor: String, card: String) -> void:
	clear("IDLE")
	candidates = Prepared.potentials(snapshot,actor,card)
	if candidates.is_empty(): return
	setup_actor_id = actor
	setup_card_instance_id = card
	revision = int(snapshot["event_seq"])
	state = "SETUP_SELECTED"

func partners() -> Array:
	var ids: Array = []
	for entry: Dictionary in candidates:
		if not ids.has(entry["actor_id"]): ids.append(entry["actor_id"])
	return ids

func select_partner(actor: String) -> bool:
	if not partners().has(actor): return false
	finisher_actor_id = actor
	finisher_card_instance_id = ""
	recipe_id = ""
	state = "PARTNER_SELECTED"
	return true

func finishers() -> Array:
	var result: Array = []
	for entry: Dictionary in candidates:
		if entry["actor_id"] == finisher_actor_id and not result.has(entry["card_instance_id"]): result.append(entry["card_instance_id"])
	return result

func select_finisher(card: String) -> bool:
	if not finishers().has(card): return false
	finisher_card_instance_id = card
	finisher_target_ids.clear()
	var options: Array = recipe_options()
	recipe_id = str(options[0]) if options.size() == 1 else ""
	state = "FINISHER_SELECTED"
	return true

func recipe_options() -> Array:
	var result: Array = []
	for entry: Dictionary in candidates:
		if entry["actor_id"] == finisher_actor_id and entry["card_instance_id"] == finisher_card_instance_id: result.append(entry["recipe_id"])
	return result

func command(snapshot: Dictionary) -> Dictionary:
	var result: Dictionary = Factory.build(snapshot,"COMMIT_PREPARED_COMBO_V2",{
		"setup_actor_id":setup_actor_id,"setup_card_instance_id":setup_card_instance_id,"setup_target_ids":setup_target_ids.duplicate(),
		"finisher_actor_id":finisher_actor_id,"finisher_card_instance_id":finisher_card_instance_id,"finisher_target_ids":finisher_target_ids.duplicate(),"recipe_id":recipe_id})
	result["expected_event_seq"] = revision
	return result

func reconcile(snapshot: Dictionary) -> bool:
	if setup_actor_id.is_empty(): return true
	if int(snapshot["event_seq"]) != revision or not Prepared.active(snapshot,setup_actor_id) or (not finisher_actor_id.is_empty() and not Prepared.active(snapshot,finisher_actor_id)):
		clear("INVALIDATED")
		return false
	return true
