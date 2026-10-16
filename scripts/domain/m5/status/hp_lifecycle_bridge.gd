extends RefCounted
## M5.2 HP lifecycle; status tick is a registered effect, never client HP input.
const Invalidation = preload("res://scripts/domain/m4/casting/casting_invalidation_resolver.gd")

static func heal(core: Dictionary, actor: String, amount: int) -> Dictionary:
	if amount <= 0 or not core["battle"]["actors"].has(actor):
		return {"ok":false,"error":"M52_INVALID_HEAL"}
	if bool(core["battle"].get("retired_from_field_by_actor",{}).get(actor,false)):
		return {"ok":false,"error":"ACTOR_RETIRED_FROM_FIELD"}
	var current: int = int(core["battle"]["actors"][actor]["hp"])
	if current == 0:
		return {"ok":false,"error":"M52_HEAL_CANNOT_REVIVE"}
	var result: Dictionary = core.duplicate(true)
	var after: int = mini(int(result["battle"]["actors"][actor]["max_hp"]),current+amount)
	result["battle"]["actors"][actor]["hp"] = after
	return {"ok":true,"core":result,"timeline":[{"kind":"HPHealed","actor_id":actor,
		"before":current,"after":after,"amount":after-current,"revive":false}]}

static func revive(core: Dictionary, actor: String, restored: int) -> Dictionary:
	if bool(core["battle"].get("retired_from_field_by_actor",{}).get(actor,false)):
		return {"ok":false,"error":"ACTOR_RETIRED_FROM_FIELD"}
	var outcome: Dictionary = Invalidation.revive(core,actor,restored)
	if not outcome["ok"]:
		return {"ok":false,"error":str(outcome["error"])}
	var record: Dictionary = outcome["event"].duplicate(true)
	record["kind"] = "ActorRevived"
	record["authority"] = "REGISTERED_PAID_SP"
	return {"ok":true,"core":outcome["core"],"timeline":[record]}

static func dot(core: Dictionary, actor: String, amount: int,
		barrier_mode: String, config: Dictionary, command_id: String) -> Dictionary:
	if bool(core["battle"].get("retired_from_field_by_actor", {}).get(actor, false)):
		return {"ok":true,"core":core.duplicate(true),"timeline":[{"kind":"StatusTickSkipped","actor_id":actor,"reason":"ACTOR_RETIRED_FROM_FIELD"}]}
	if amount <= 0 or not ["ABSORB","BYPASS"].has(barrier_mode) or \
			not core["battle"]["actors"].has(actor):
		return {"ok":false,"error":"M52_INVALID_DOT"}
	if int(core["battle"]["actors"][actor]["hp"]) <= 0:
		return {"ok":true,"core":core.duplicate(true),"timeline":[
			{"kind":"StatusTickSkipped","actor_id":actor,"reason":"ALREADY_INCAPACITATED"}]}
	var next: Dictionary = core.duplicate(true)
	var records: Array = []
	var before_hp: int = int(next["battle"]["actors"][actor]["hp"])
	var remain: int = amount
	if barrier_mode == "ABSORB":
		var shield: float = float(next["battle"].get("hp_barriers",{}).get(actor,0.0))
		if shield < 0.0:
			return {"ok":false,"error":"M52_INVALID_BARRIER"}
		var absorbed: float = minf(shield,float(amount))
		remain = maxi(0,int(floor(float(amount)-absorbed)))
		if absorbed > 0.0:
			next["battle"]["hp_barriers"][actor] = shield-absorbed
			records.append({"kind":"HPBarrierAbsorbed","target_actor_id":actor,
				"absorbed":absorbed,"remaining":shield-absorbed,"origin":"STATUS_DOT"})
	var dealt: int = mini(before_hp,remain)
	next["battle"]["actors"][actor]["hp"] = before_hp-dealt
	records.append({"kind":"StatusHPDamageApplied","target_actor_id":actor,
		"before":before_hp,"after":before_hp-dealt,"amount":dealt,
		"barrier_interaction":barrier_mode})
	if before_hp > 0 and before_hp-dealt == 0:
		if next["battle"]["allies"].has(actor):
			var down: Dictionary = Invalidation.incapacitate(next,actor,command_id,config)
			if not down["ok"]:
				return {"ok":false,"error":str(down["error"])}
			next = down["core"]
			records.append_array(down["timeline"])
		else:
			next["battle"]["actors"][actor]["status"] = "INCAPACITATED"
			records.append({"kind":"ActorIncapacitated","actor_id":actor,"hp":0,
				"reason":"STATUS_TICK_HP_ZERO"})
	return {"ok":true,"core":next,"timeline":records}

## M5.4 content-registered recoil after a legitimately paid and released
## effect. Reuse the M5.2 HP/Barrier/CORE-02 writer rather than creating
## another HP reducer. Only Domain-resolved ContentConfig supplies damage.
static func registered_recoil(core: Dictionary, actor: String, amount: int,
		barrier_mode: String, config: Dictionary, command_id: String) -> Dictionary:
	if amount <= 0 or not ["ABSORB","BYPASS"].has(barrier_mode):
		return {"ok":false,"error":"M54_INVALID_REGISTERED_RECOIL"}
	var resolved: Dictionary = dot(core,actor,amount,barrier_mode,config,command_id)
	if not resolved["ok"]:
		return resolved
	for event: Dictionary in resolved["timeline"]:
		if str(event.get("kind","")) == "StatusHPDamageApplied":
			event["kind"] = "RegisteredRecoilHPDamageApplied"
			event["source"] = "VERSIONED_COMMITTED_EFFECT"
		elif str(event.get("kind","")) == "HPBarrierAbsorbed":
			event["origin"] = "REGISTERED_RECOIL"
	return resolved
