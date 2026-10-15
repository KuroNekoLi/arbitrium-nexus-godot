extends RefCounted
## P2-D01–D04, P2-D08. Seeded, percentage-only, no d20.
const RNG = preload("res://scripts/domain/m1/combat_rng.gd")
static func resolve(rng: Dictionary, profile: Dictionary, source: Dictionary,
		recipient: Dictionary, balance: Dictionary) -> Dictionary:
	var mode: String = str(profile.get("hit_mode",""))
	if not ["RANDOM_PERCENT","GUARANTEED","CONDITIONAL"].has(mode):
		return {"ok":false,"error":"M51_INVALID_HIT_MODE"}
	if mode == "CONDITIONAL" and profile.get("condition_met",null) is not bool:
		return {"ok":false,"error":"M51_CONDITION_NOT_CONFIGURED"}
	var base: Variant = balance.get("base_hit_bp",null)
	var k: Variant = balance.get("accuracy_step_bp",null)
	if not base is int or not k is int or int(k) < 0:
		return {"ok":false,"error":"M51_INVALID_HIT_BALANCE"}
	var chance: int = clampi(int(base) + int(k) * (
		int(source["accuracy"]) - int(recipient["evasion"])),500,9500)
	if mode == "GUARANTEED":
		chance = 10000
	elif mode == "CONDITIONAL":
		chance = 10000 if bool(profile["condition_met"]) else 0
	var used: bool = mode == "RANDOM_PERCENT"
	var snapshot: Dictionary = rng.duplicate(true)
	var roll: int = -1
	if used:
		var drawn: Dictionary = RNG.next_int(snapshot)
		if not drawn["accepted"]:
			return {"ok":false,"error":str(drawn["error"])}
		snapshot = drawn["rng"]
		roll = int(drawn["value"]) % 10000
	return {"ok":true,"error":"","hit":chance == 10000 or (chance > 0 and roll < chance),
		"chance_bp":chance,"roll_bp":roll,"rng":snapshot,
		"rng_used":used,"rng_draw_index":int(snapshot["draw_index"]) if used else -1}
