extends RefCounted
## M4.4 CORE-02 / PRE3-R13-R15. Pure Domain application of a VERIFIED
## HP-zero transition, NOT a public health-damage or kill command.
## All caller-visible commands must be gated by trusted encounter fixtures.
const M2 = preload("res://scripts/domain/m2/integration/m2_domain_resolver.gd")

static func incapacitate(core: Dictionary, actor_id: String,
		command_id: String, config: Dictionary) -> Dictionary:
	var battle: Dictionary = core["battle"]
	if not battle["allies"].has(actor_id) or not battle["actors"].has(actor_id):
		return {"ok":false,"error":"INVALID_INCAPACITATION_ACTOR"}
	if int(battle["actors"][actor_id].get("hp",-1)) != 0:
		return {"ok":false,"error":"INCAPACITATION_REQUIRES_ALREADY_ZERO_HP"}
	var s: Dictionary = core.duplicate(true)
	var existing: Dictionary = s["battle"]["actors"][actor_id]
	if str(existing["status"]) == "INCAPACITATED":
		return {"ok":false,"error":"ACTOR_ALREADY_INCAPACITATED"}
	var was_exhausted: bool = str(existing["status"]) == "EXHAUSTED" or \
			bool(s["battle"].get("last_spell_resolved_by_actor",{}).get(actor_id,false))
	existing["status"] = "INCAPACITATED"
	if was_exhausted:
		if not s["battle"].has("exhausted_lifetime_by_actor"):
			s["battle"]["exhausted_lifetime_by_actor"] = {}
		s["battle"]["exhausted_lifetime_by_actor"][actor_id] = true
	var events: Array = [{"kind":"ActorIncapacitated","actor_id":actor_id,
		"reason":"HP_REACHED_ZERO","hp":0,
		"hand_and_draw_frozen":true,"exhausted_lifetime":was_exhausted}]
	# Only a single active concentration per actor is allowed.
	var ids: Array = s["battle"]["casting_instances"].keys()
	ids.sort()
	for key: Variant in ids:
		var casting: Dictionary = s["battle"]["casting_instances"][key]
		if str(casting.get("caster_id","")) != actor_id:
			continue
		var cid: String = str(casting["casting_id"])
		if str(casting.get("kind","")) == "LAST_SPELL":
			# USER_APPROVED: no delayed effect, refund or reclaimed once-use.
			if not s["battle"].has("last_spell_invalidated_by_actor"):
				s["battle"]["last_spell_invalidated_by_actor"] = {}
			s["battle"]["last_spell_invalidated_by_actor"][actor_id] = {
				"casting_id":cid,"reason":"CASTER_INCAPACITATED",
				"command_id":command_id,
				"planned_resolve_round":int(casting["planned_resolve_round"]),
				"once_used":true
			}
			s["battle"]["casting_instances"].erase(key)
			events.append({"kind":"LastSpellInvalidated","casting_id":cid,
				"caster_id":actor_id,"reason":"CASTER_INCAPACITATED",
				"state":"INVALIDATED","once_used_retained":true,
				"mp_refund":0,"ap_refund":0,"overload_refund":0})
			events.append({"kind":"ScheduledEffectCancelled","casting_id":cid,
				"caster_id":actor_id,"reason":"CASTER_INCAPACITATED",
				"effect_applied":false})
		else:
			# PRE3-R13 ordinary Full Chant also fails on HP0, and it must
			# return its unique physical CardInstance to Discard, NO M-D22.
			var card: String = str(casting["card_instance_id"])
			var moved: Dictionary = M2.apply(s, {
				"type":"SETTLE_CASTING_CARD_M4","actor_id":actor_id,
				"card_instance_id":card,
				"command_id":command_id+":incap:"+cid,
				"expected_event_seq":int(s["event_seq"])
			},config)
			if not moved["accepted"]:
				return {"ok":false,"error":str(moved["error"])}
			s = moved["state"]
			for item: Dictionary in moved["events"]:
				events.append({"kind":"core_event","raw":item})
			s["battle"]["casting_instances"].erase(key)
			events.append({"kind":"CastingInvalidated","casting_id":cid,
				"caster_id":actor_id,"reason":"CASTER_INCAPACITATED",
				"mp_refund":0,"ap_refund":0})
			events.append({"kind":"ScheduledEffectCancelled","casting_id":cid,
				"caster_id":actor_id,"reason":"CASTER_INCAPACITATED",
				"effect_applied":false})
	return {"ok":true,"error":"","core":s,"timeline":events}

static func revive(core: Dictionary, actor_id: String, hp_restored: int) -> Dictionary:
	var battle: Dictionary = core["battle"]
	if not battle["allies"].has(actor_id) or not battle["actors"].has(actor_id):
		return {"ok":false,"error":"INVALID_REVIVE_TARGET"}
	if hp_restored <= 0 or hp_restored > int(battle["actors"][actor_id]["max_hp"]):
		return {"ok":false,"error":"INVALID_REVIVE_HP"}
	if str(battle["actors"][actor_id].get("status","")) != "INCAPACITATED" or \
			int(battle["actors"][actor_id]["hp"]) != 0:
		return {"ok":false,"error":"REVIVE_REQUIRES_INCAPACITATED"}
	var s: Dictionary = core.duplicate(true)
	var permanently_exhausted: bool = bool(s["battle"].get(
		"exhausted_lifetime_by_actor",{}).get(actor_id,false))
	s["battle"]["actors"][actor_id]["hp"] = hp_restored
	s["battle"]["actors"][actor_id]["status"] = "EXHAUSTED" if permanently_exhausted else "ACTIVE"
	# No restore of removed CastingInstance, costs or last_spell_used_by_actor.
	return {"ok":true,"error":"","core":s,"event":{
		"kind":"ActorRevivedFixture","actor_id":actor_id,"hp_after":hp_restored,
		"status_after":s["battle"]["actors"][actor_id]["status"],
		"casting_restored":false,"once_used_recovered":false}}
