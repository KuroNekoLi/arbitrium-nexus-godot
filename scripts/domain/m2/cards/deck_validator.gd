extends RefCounted
## Eligibility is explicit catalogue data. No engine-wide same-name cap,
## rarity quota or default ownership is inferred from absent configuration.

static func _fail(reason: String, index: int = -1) -> Dictionary:
	return {"ok": false, "error": reason, "index": index}

static func validate_loadout(context: Dictionary, card_ids: Variant,
		definitions: Dictionary, owned_counts: Dictionary, deck_rules: Dictionary = {}) -> Dictionary:
	var actor_id: String = str(context.get("actor_id", ""))
	var variant_id: String = str(context.get("variant_id", ""))
	var actor_tags: Variant = context.get("tags", [])
	if actor_id.strip_edges().is_empty() or variant_id.strip_edges().is_empty() or not actor_tags is Array:
		return _fail("INVALID_ACTOR_CONTEXT")
	if not card_ids is Array or card_ids.size() != 12:
		return _fail("LOADOUT_REQUIRES_EXACTLY_12_SP")
	var limits: Variant = deck_rules.get("max_copies_by_definition", {})
	if not limits is Dictionary:
		return _fail("INVALID_DECK_RULES")
	var counts: Dictionary = {}
	for i: int in range(card_ids.size()):
		if not card_ids[i] is String or str(card_ids[i]).strip_edges().is_empty():
			return _fail("INVALID_DEFINITION_ID", i)
		var card_id: String = str(card_ids[i])
		if not definitions.has(card_id) or not definitions[card_id] is Dictionary:
			return _fail("UNKNOWN_CARD_DEFINITION", i)
		var definition: Dictionary = definitions[card_id]
		if str(definition.get("id", "")) != card_id or str(definition.get("kind", "")) != "SP":
			return _fail("NOT_A_VALID_SP", i)
		var owner: String = str(definition.get("owner_actor_id", ""))
		if not owner.is_empty() and owner != actor_id:
			return _fail("ACTOR_INELIGIBLE", i)
		var variants: Variant = definition.get("allowed_variant_ids", [])
		if not variants is Array:
			return _fail("INVALID_CARD_ELIGIBILITY", i)
		if not variants.is_empty() and not variants.has(variant_id):
			return _fail("VARIANT_INELIGIBLE", i)
		var actors: Variant = definition.get("allowed_actor_ids", [])
		if not actors is Array:
			return _fail("INVALID_CARD_ELIGIBILITY", i)
		if not actors.is_empty() and not actors.has(actor_id):
			return _fail("ACTOR_INELIGIBLE", i)
		var required_tags: Variant = definition.get("required_actor_tags", [])
		if not required_tags is Array:
			return _fail("INVALID_CARD_ELIGIBILITY", i)
		for tag: Variant in required_tags:
			if not actor_tags.has(tag):
				return _fail("TAG_INELIGIBLE", i)
		counts[card_id] = int(counts.get(card_id, 0)) + 1
		# Card collection ownership is a hard validation prerequisite.
		if not owned_counts.has(card_id) or not owned_counts[card_id] is int or int(owned_counts[card_id]) < counts[card_id]:
			return _fail("INSUFFICIENT_OWNED_COPIES", i)
		if limits.has(card_id):
			if not limits[card_id] is int or int(limits[card_id]) < 0:
				return _fail("INVALID_DECK_RULES", i)
			if int(counts[card_id]) > int(limits[card_id]):
				return _fail("CONFIGURED_COPY_LIMIT", i)
	return {"ok": true, "error": "", "index": -1, "copies": counts}

static func validate_party(loadouts: Dictionary, contexts: Dictionary, definitions: Dictionary,
		ownership: Dictionary, deck_rules: Dictionary = {}) -> Dictionary:
	if loadouts.size() != 3 or contexts.size() != 3 or ownership.size() != 3:
		return _fail("REQUIRES_EXACTLY_THREE_ACTORS")
	for actor_key: Variant in loadouts:
		var actor_id: String = str(actor_key)
		if not contexts.has(actor_id) or not contexts[actor_id] is Dictionary:
			return _fail("MISSING_ACTOR_CONTEXT")
		if not ownership.has(actor_id) or not ownership[actor_id] is Dictionary:
			return _fail("MISSING_ACTOR_INVENTORY")
		var context: Dictionary = contexts[actor_id]
		if str(context.get("actor_id", "")) != actor_id:
			return _fail("ACTOR_CONTEXT_MISMATCH")
		var result: Dictionary = validate_loadout(context, loadouts[actor_id],
			definitions, ownership[actor_id], deck_rules)
		if not result["ok"]:
			result["actor_id"] = actor_id
			return result
	return {"ok": true, "error": ""}
