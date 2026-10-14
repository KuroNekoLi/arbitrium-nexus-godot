extends RefCounted
## M2.3: CardDefinition is a catalogue template; a CardInstance is one
## physical SP card belonging to exactly one actor and exactly one zone.
## Same definition_id may be configured in several independent instances.

static func create(actor_id: String, definition_id: String, slot: int) -> Dictionary:
	if actor_id.strip_edges().is_empty() or definition_id.strip_edges().is_empty() or slot < 0 or slot >= 12:
		return {}
	return {
		"instance_id": actor_id + ":sp:" + str(slot).pad_zeros(2),
		"definition_id": definition_id,
		"owner_actor_id": actor_id,
		"loadout_slot": slot
	}

static func create_loadout(actor_id: String, definition_ids: Array) -> Dictionary:
	if definition_ids.size() != 12:
		return {}
	var instances: Dictionary = {}
	for i: int in range(definition_ids.size()):
		if not definition_ids[i] is String:
			return {}
		var instance: Dictionary = create(actor_id, definition_ids[i], i)
		if instance.is_empty() or instances.has(instance["instance_id"]):
			return {}
		instances[instance["instance_id"]] = instance
	return instances
