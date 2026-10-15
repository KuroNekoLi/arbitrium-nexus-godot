extends RefCounted
## M5.4 isolated content — recoil exists solely as a registered test SP/Last
## effect and cannot be written to a public command.
const Prior = preload("res://tests/fixtures/m5_3_fixture.gd")
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const Status = preload("res://scripts/domain/m5/status/status_resolver.gd")
const SEED: int = 20261014

static func config() -> Dictionary:
	var c: Dictionary = Prior.config()
	c["m5_4_outcome_enabled"] = true
	c["m5_4_content_version"] = "m5.4-outcome-provisional-v1"
	c["m5_3_sp_effects"]["setup"]["recoil_hp"] = 10
	c["m5_3_sp_effects"]["setup"]["recoil_barrier_mode"] = "BYPASS"
	c["m5_4_last_release_recoil"] = {"nova":{"amount":10,"barrier_mode":"BYPASS"}}
	# In Last Spell and next-phase status fixtures Boss may still attack,
	# but its declared damage does not kill a caster before the intended
	# release/tick boundary. All balancing values are TEST-ONLY.
	return c

static func paired_ko(seed: int = SEED) -> Dictionary:
	var state: Dictionary = Prior.initial(seed,{"A":"blank","B":"blank","C":"setup"})
	if state.is_empty():
		return {}
	for actor: String in ["A","B"]:
		state["core"]["battle"]["actors"][actor]["hp"] = 0
		state["core"]["battle"]["actors"][actor]["status"] = "INCAPACITATED"
	state["core"]["battle"]["actors"]["C"]["hp"] = 6
	state["core"]["battle"]["actors"]["Boss"]["hp"] = 7
	return state

static func enemy_defeat(seed: int = SEED) -> Dictionary:
	var state: Dictionary = Prior.initial(seed)
	if state.is_empty():
		return {}
	for actor: String in ["B","C"]:
		state["core"]["battle"]["actors"][actor]["hp"] = 0
		state["core"]["battle"]["actors"][actor]["status"] = "INCAPACITATED"
	state["core"]["battle"]["actors"]["A"]["hp"] = 8
	return state

static func last_release(seed: int = SEED) -> Dictionary:
	var state: Dictionary = Prior.initial(seed,{"A":"blank","B":"blank","C":"blank"})
	if state.is_empty():
		return {}
	for actor: String in ["B","C"]:
		state["core"]["battle"]["actors"][actor]["hp"] = 0
		state["core"]["battle"]["actors"][actor]["status"] = "INCAPACITATED"
	state["core"]["battle"]["actors"]["A"]["hp"] = 6
	state["core"]["battle"]["actors"]["Boss"]["hp"] = 7
	return state

static func tick_double_ko(seed: int = SEED) -> Dictionary:
	var state: Dictionary = paired_ko(seed)
	if state.is_empty():
		return {}
	state["core"]["battle"]["actors"]["Boss"]["hp"] = 9
	state["core"]["battle"]["actors"]["C"]["hp"] = 7
	var first: Dictionary = Status.grant(state["core"],"A","Boss","burn",
		"m54-initial-burn",config())
	if not first["ok"]:
		return {}
	var second: Dictionary = Status.grant(first["core"],"Boss","C","poison",
		"m54-initial-poison",config())
	if not second["ok"]:
		return {}
	state["core"] = second["core"]
	return state
