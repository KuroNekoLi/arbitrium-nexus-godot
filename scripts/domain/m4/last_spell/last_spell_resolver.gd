extends RefCounted
## M4.3 Last Spell slot and lifecycle on existing M2/M3 battle state.
## No card/hand/draw zone. Content costs always charged by M2.
const Cost = preload("res://scripts/domain/m2/economy/cost_resolver.gd")
const M2 = preload("res://scripts/domain/m2/integration/m2_domain_resolver.gd")

static func inspect(core: Dictionary, actor_id: String, config: Dictionary) -> Dictionary:
	var battle: Dictionary = core["battle"]
	if not battle["allies"].has(actor_id):
		return {"ok":false,"error":"ACTOR_NOT_FOUND"}
	var slots: Variant = config.get("last_spell_slots", null)
	if not slots is Dictionary or not slots.has(actor_id) or not slots[actor_id] is Dictionary:
		return {"ok":false,"error":"LAST_SPELL_SLOT_NOT_CONFIGURED"}
	var slot: Dictionary = slots[actor_id]
	if not bool(slot.get("unlocked",false)):
		return {"ok":false,"error":"LAST_SPELL_LOCKED"}
	var spell_id: String = str(slot.get("spell_id",""))
	var catalog: Variant = config.get("last_spell_cost_definitions",null)
	if spell_id.is_empty() or not catalog is Dictionary or not catalog.has(spell_id) or not catalog[spell_id] is Dictionary:
		return {"ok":false,"error":"LAST_SPELL_MISSING_COST"}
	var cost: Dictionary = catalog[spell_id]
	if str(cost.get("card_id","")) != spell_id:
		return {"ok":false,"error":"LAST_SPELL_COST_MISMATCH"}
	if int(battle.get("last_spell_used_by_actor",{}).get(actor_id,0)) != 0:
		return {"ok":false,"error":"LAST_SPELL_ALREADY_USED"}
	if battle["phase"] != "PLAYER_PHASE" or battle["outcome"] != "ONGOING":
		return {"ok":false,"error":"INVALID_PHASE"}
	if str(battle["actors"][actor_id]["status"]) != "ACTIVE" or int(battle["actors"][actor_id]["hp"]) <= 0:
		return {"ok":false,"error":"ACTOR_UNAVAILABLE"}
	for casting: Variant in battle["casting_instances"].values():
		if str(casting.get("caster_id","")) == actor_id:
			return {"ok":false,"error":"CASTER_ALREADY_CONCENTRATING"}
	var delay: Variant = slot.get("planned_delay_rounds",null)
	var stability: Variant = slot.get("base_stability",null)
	if not delay is int or int(delay) != 2 or not stability is int or int(stability) <= 0:
		return {"ok":false,"error":"MISSING_LAST_SPELL_TIMELINE_FIXTURE"}
	var quote: Dictionary = Cost.quote(battle,{"actor_id":actor_id,"card":cost,
		"casting_mode":"FULL"},config.get("costs",{}))
	if not quote["ok"]:
		return {"ok":false,"error":str(quote["error"])}
	return {"ok":true,"error":"","actor_id":actor_id,"spell_id":spell_id,
		"slot":slot.duplicate(true),"cost":cost.duplicate(true),
		"quote":quote,"requires_confirmation":true,
		"irreversible":true,"only_mode":"FULL",
		"risk":"DELAY_OR_WEAKEN_ON_DISRUPTION",
		"success_consequence":"EXHAUSTED_FOR_REMAINDER_OF_BATTLE"}

static func commit(core: Dictionary, actor_id: String, target_id: String,
		command_id: String, config: Dictionary) -> Dictionary:
	var proposal: Dictionary = inspect(core,actor_id,config)
	if not proposal["ok"]:
		return proposal
	if target_id.is_empty() or not core["battle"]["actors"].has(target_id) or \
			int(core["battle"]["actors"][target_id]["hp"]) <= 0:
		return {"ok":false,"error":"INVALID_LAST_SPELL_TARGET"}
	var paid: Dictionary = M2.apply(core,{"type":"COMMIT_LAST_SPELL_COST_M4",
		"command_id":command_id,"actor_id":actor_id,
		"expected_event_seq":int(core["event_seq"])},config)
	if not paid["accepted"]:
		return {"ok":false,"error":str(paid["error"])}
	var next: Dictionary = paid["state"]
	var confirmed: bool = false
	var actual_ap: int = -1
	var actual_mp: int = -1
	for item: Dictionary in paid["events"]:
		if str(item["event"]["kind"]) == "SPCostReservedOnly":
			actual_ap = int(item["event"]["details"]["ap_cost"])
			actual_mp = int(item["event"]["details"]["mp_cost"])
			confirmed = true
	if not confirmed:
		return {"ok":false,"error":"MISSING_AUTHORITATIVE_PAYMENT_RECEIPT"}
	var casting_id: String = "last:" + command_id
	if next["battle"]["casting_instances"].has(casting_id):
		return {"ok":false,"error":"DUPLICATE_LAST_SPELL_INSTANCE"}
	var slot: Dictionary = proposal["slot"]
	var last: Dictionary = {
		"kind":"LAST_SPELL","casting_id":casting_id,
		"caster_id":actor_id,"card_instance_id":"","spell_id":proposal["spell_id"],
		"target_snapshot":{"actor_id":target_id},
		"mode":"FULL","state":"CASTING","last_spell_state":"CASTING",
		"started_round":int(next["battle"]["round"]),
		"planned_resolve_round":int(next["battle"]["round"]) + int(slot["planned_delay_rounds"]),
		"base_stability":int(slot["base_stability"]),
		"current_stability":int(slot["base_stability"]),
		"focus_ward":0,"disruption_events":[],
		"delay_used":false,"disrupted_count":0,
		"outcome_modifier_numerator":1,"outcome_modifier_denominator":1,
		"resonance_stacks":0,"concentration":true,"committed_once":true,
		"can_cancel":false,"paid_mp":actual_mp,"paid_ap":actual_ap,
		"effect_resolution":"DEFERRED_TO_M5",
		"balance_authority":"BALANCE_PROVISIONAL"}
	next["battle"]["casting_instances"][casting_id] = last
	if not next["battle"].has("last_spell_used_by_actor"):
		next["battle"]["last_spell_used_by_actor"] = {}
	next["battle"]["last_spell_used_by_actor"][actor_id] = 1
	next["battle"]["actors"][actor_id]["status"] = "CONCENTRATING"
	return {"ok":true,"error":"","core":next,"instance":last,"events":paid["events"]}

static func settle(core: Dictionary, spell: Dictionary, round_index: int) -> Dictionary:
	if str(spell.get("kind","")) != "LAST_SPELL" or str(spell.get("state","")) != "CASTING":
		return {"ok":false,"error":"INVALID_LAST_SPELL_RELEASE"}
	var actor: String = str(spell["caster_id"])
	if int(core["battle"]["actors"][actor]["hp"]) <= 0:
		return {"ok":false,"error":"LAST_SPELL_HP0_NEEDS_M4_4_INVALIDATION"}
	if str(core["battle"]["actors"][actor]["status"]) != "CONCENTRATING":
		return {"ok":false,"error":"LAST_SPELL_CASTER_NOT_CONCENTRATING"}
	var target: String = str(spell["target_snapshot"]["actor_id"])
	if not core["battle"]["actors"].has(target) or int(core["battle"]["actors"][target]["hp"]) <= 0:
		return {"ok":false,"error":"RELEASE_TARGET_TBD"}
	var s: Dictionary = core.duplicate(true)
	s["battle"]["casting_instances"].erase(str(spell["casting_id"]))
	s["battle"]["actors"][actor]["status"] = "EXHAUSTED"
	# Successful Last Spell retires this actor from the active battlefield.
	# Keep the roster and once-per-battle records for deterministic replay.
	if not s["battle"].has("retired_from_field_by_actor"):
		s["battle"]["retired_from_field_by_actor"] = {}
	s["battle"]["retired_from_field_by_actor"][actor] = true
	# Lifetime Exhausted persists through HP0 and a legitimate Revive.
	if not s["battle"].has("last_spell_resolved_by_actor"):
		s["battle"]["last_spell_resolved_by_actor"] = {}
	s["battle"]["last_spell_resolved_by_actor"][actor] = true
	var records: Array = [
		{"kind":"LastSpellReleased","casting_id":str(spell["casting_id"]),
			"caster_id":actor,"spell_id":str(spell["spell_id"]),
			"planned_round":round_index,"cost_repaid":false,
			"outcome_modifier_numerator":int(spell["outcome_modifier_numerator"]),
			"outcome_modifier_denominator":int(spell["outcome_modifier_denominator"])},
		{"kind":"LastSpellEffectDeferredToM5","casting_id":str(spell["casting_id"]),
			"spell_id":str(spell["spell_id"]),
			"target_snapshot":spell["target_snapshot"].duplicate(true),
			"effect_execution":"NOT_IMPLEMENTED_M5","hp_delta":0,
			"modifier_numerator":int(spell["outcome_modifier_numerator"]),
			"modifier_denominator":int(spell["outcome_modifier_denominator"])},
		{"kind":"ActorExhausted","actor_id":actor,
			"can_initiate_actions":false,"still_targetable":false,"retired_from_field":true}
	]
	return {"ok":true,"core":s,"timeline":records}
