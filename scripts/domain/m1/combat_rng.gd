extends RefCounted
## PH3-M1-RNG-001: versioned Park-Miller RNG. Never depend on Godot UI/OS randomness.
## Pure functions: the supplied state is never mutated.
const MODULUS: int = 2147483647
const MULTIPLIER: int = 48271
const ALGORITHM: String = "park-miller-48271-v1"

static func normalize(seed_value: int) -> int:
	var value: int = seed_value % MODULUS
	if value <= 0:
		value += MODULUS - 1
	return value

static func initial_state(seed_value: int) -> Dictionary:
	return {"algorithm": ALGORITHM, "state": normalize(seed_value), "draw_index": 0}

static func next_int(rng_snapshot: Dictionary) -> Dictionary:
	if rng_snapshot.get("algorithm", "") != ALGORITHM:
		return {"accepted": false, "error": "UNSUPPORTED_RNG_VERSION"}
	var current: int = normalize(int(rng_snapshot.get("state", 0)))
	var next_value: int = (current * MULTIPLIER) % MODULUS
	var next_rng: Dictionary = rng_snapshot.duplicate(true)
	next_rng["state"] = next_value
	next_rng["draw_index"] = int(next_rng.get("draw_index", 0)) + 1
	return {"accepted": true, "value": next_value, "rng": next_rng, "error": ""}
