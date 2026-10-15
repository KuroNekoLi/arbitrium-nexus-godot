extends RefCounted
## Crit only after hit and only on explicitly eligible HP damage.
const RNG = preload("res://scripts/domain/m1/combat_rng.gd")
static func resolve(rng: Dictionary, eligible: bool, source: Dictionary) -> Dictionary:
	var rate: int = int(source.get("crit_rate_bp",-1))
	var bonus: int = int(source.get("crit_bonus_bp",-1))
	if rate < 0 or rate > 10000 or bonus < 0:
		return {"ok":false,"error":"M51_INVALID_CRIT_STATS"}
	if not eligible:
		return {"ok":true,"critical":false,"rng":rng.duplicate(true),
			"rng_draw_index":-1,"roll_bp":-1}
	var drawn: Dictionary = RNG.next_int(rng)
	if not drawn["accepted"]:
		return {"ok":false,"error":str(drawn["error"])}
	var roll: int = int(drawn["value"]) % 10000
	return {"ok":true,"critical":roll < rate,"rng":drawn["rng"],
		"rng_draw_index":int(drawn["rng"]["draw_index"]),"roll_bp":roll}
