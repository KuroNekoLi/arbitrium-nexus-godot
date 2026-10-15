extends RefCounted
## Offline deterministic research driver, never a player controller.
## All transitions (including legal dry-runs) go through the unique M5.apply.
const M5 = preload("res://scripts/domain/m5/integration/m5_domain_resolver.gd")
const Model = preload("res://scripts/domain/m1/combat_model.gd")
const M4 = preload("res://scripts/domain/m4/integration/m4_domain_resolver.gd")
const M2 = preload("res://scripts/domain/m2/integration/m2_domain_resolver.gd")
const Zones = preload("res://scripts/domain/m2/cards/card_zone_resolver.gd")
const ENCOUNTER: String = "res://scripts/domain/m5/lv40/lv40_encounter.gd"
const POLICY_VERSION: String = "p46-policy-v1-provisional"
const STRATEGIES: Array[String] = ["BALANCED","AGGRESSIVE","DEFENSIVE","CAST_SUPPORT"]
const ACTORS: Array[String] = ["A","B","C"]
const TARGETS: Array[String] = ["Boss","A","B","C"]
const MAX_ROUNDS: int = 24
const MAX_COMMANDS: int = 1200
const MAX_EVENTS: int = 16000
const MAX_PROBES: int = 50000
const REACTION_CARDS: Array[String] = ["R05","T05"]
const ATTACK_CARDS: Array[String] = ["U01","R01","R02","R03","R06","R07",
	"A01","A02","A04","A06","A07","T09","T10"]
const DUAL_CARDS: Array[String] = ["U01","A01","A02","A04","A06","T09"]

static func fixed_seeds() -> Array:
	# The existing Domain PRNG and Lv40 initial() require positive seeds.
	return range(1,101)

static func profile(strategy: String) -> Dictionary:
	match strategy:
		"BALANCED": return {"reserve_ap":2,"attack":55,"heal":100,"barrier":65,"full":-20,"ward":45,"last":45}
		"AGGRESSIVE": return {"reserve_ap":1,"attack":100,"heal":35,"barrier":15,"full":-50,"ward":5,"last":85}
		"DEFENSIVE": return {"reserve_ap":3,"attack":30,"heal":125,"barrier":100,"full":-30,"ward":50,"last":20}
		"CAST_SUPPORT": return {"reserve_ap":2,"attack":50,"heal":90,"barrier":80,"full":70,"ward":160,"last":130}
	return {}

static func load_encounter() -> Dictionary:
	if not FileAccess.file_exists(ENCOUNTER):
		return {"ok":false,"error":"NOT_IMPLEMENTED:LV40_ENCOUNTER_API"}
	var script: Script = load(ENCOUNTER)
	if script == null or not script.has_method("config") or not script.has_method("initial"):
		return {"ok":false,"error":"NOT_IMPLEMENTED:LV40_CONFIG_INITIAL"}
	return {"ok":true,"script":script}

static func empty_metrics() -> Dictionary:
	return {"ap_spent":0,"mp_spent":0,"rp_spent":0,"ap_borrowed":0,
		"ap_by_actor":{"A":0,"B":0,"C":0},"mp_by_actor":{"A":0,"B":0,"C":0},
		"heal":0,"overheal":null,"heal_events":0,"heal_events_with_requested":0,
		"barrier_absorb":0.0,"boss_barrier_absorb":0.0,"casting_started":0,"casting_completion":0,
		"casting_interrupt":0,"casting_invalidated":0,"lastspell_started":0,
		"lastspell_completion":0,"lastspell_invalidated":0,"lastspell_delayed":0,
		"lastspell_weakened":0,"focus_ward_used":0,"card_uses":{},"coverage":{},
		"hand_samples":0,"deadhand_samples":0,"card_samples":{},"card_dead":{},
		"mp_bottleneck_samples":0,"reserve_limited_candidates":0,
		"metric_status":{"overheal":"NOT_IMPLEMENTED:REQUESTED_HEAL_NOT_EXPOSED"}}

static func context(seed: int, strategy: String, initial: Dictionary, config: Dictionary) -> Dictionary:
	return {"seed":seed,"strategy":strategy,"initial":initial.duplicate(true),
		"state":initial.duplicate(true),"config":config.duplicate(true),"tape":[],
		"events":[],"steps":[],"decisions":[],"probes":0,"rejected_probes":0,
		"rejection_reasons":{},"error":"","timeout":"","metrics":empty_metrics(),
		"sampled":{},"swapped":{},"capabilities":{},"failure_command":{}}

static func command(ctx: Dictionary, kind: String, fields: Dictionary = {}) -> Dictionary:
	var result: Dictionary = fields.duplicate(true)
	result["type"] = kind
	result["command_id"] = "p46:%s:%s:%s:%s" % [ctx["strategy"],ctx["seed"],ctx["tape"].size(),kind]
	result["expected_event_seq"] = int(ctx["state"]["event_seq"])
	return result

static func probe(ctx: Dictionary, cmd: Dictionary) -> Dictionary:
	if ctx["probes"] >= MAX_PROBES:
		ctx["timeout"] = "PROBE_CAP"
		return {"accepted":false,"error":"PROBE_CAP"}
	ctx["probes"] += 1
	var before: String = Model.state_hash(ctx["state"])
	var config_hash: String = Model.state_hash(ctx["config"])
	var input: Dictionary = ctx["state"].duplicate(true)
	var cfg: Dictionary = ctx["config"].duplicate(true)
	var result: Dictionary = M5.apply(input,cmd.duplicate(true),cfg)
	if Model.state_hash(input) != before or Model.state_hash(cfg) != config_hash:
		ctx["error"] = "DRY_RUN_MUTATED_INPUT_OR_CONFIG"
		ctx["failure_command"] = cmd.duplicate(true)
	if not result.get("accepted",false):
		ctx["rejected_probes"] += 1
		var reason: String = str(result.get("error","MISSING_REJECTION_REASON"))
		ctx["rejection_reasons"][reason] = int(ctx["rejection_reasons"].get(reason,0))+1
		if Model.state_hash(result.get("state",{})) != before or not result.get("events",[]).is_empty():
			ctx["error"] = "NONATOMIC_REJECTION:"+reason
			ctx["failure_command"] = cmd.duplicate(true)
		if reason.contains("NOT_IMPLEMENTED") or reason.contains("UNIMPLEMENTED") or reason.contains("UNREGISTERED") or reason.begins_with("MISSING_") or reason.contains("NOT_CONFIGURED"):
			ctx["capabilities"][str(cmd["type"])+":"+str(cmd.get("card_instance_id",""))] = "NOT_IMPLEMENTED:"+reason
	return result

static func commit(ctx: Dictionary, cmd: Dictionary, dry: Dictionary = {}) -> bool:
	if not ctx["error"].is_empty() or not ctx["timeout"].is_empty(): return false
	if ctx["tape"].size() >= MAX_COMMANDS or ctx["state"]["events"].size() >= MAX_EVENTS:
		ctx["timeout"] = "COMMAND_OR_EVENT_CAP"
		return false
	var preview: Dictionary = dry if not dry.is_empty() else probe(ctx,cmd)
	if not preview.get("accepted",false):
		if ctx["timeout"].is_empty(): ctx["error"] = "REQUIRED_POLICY_COMMAND_REJECTED:"+str(preview.get("error",""))
		ctx["failure_command"] = cmd.duplicate(true)
		return false
	if not ctx["error"].is_empty(): return false
	var result: Dictionary = M5.apply(ctx["state"].duplicate(true),cmd.duplicate(true),ctx["config"].duplicate(true))
	if not result.get("accepted",false):
		ctx["error"] = "COMMIT_AFTER_LEGAL_PREVIEW_REJECTED"
		ctx["failure_command"] = cmd.duplicate(true)
		return false
	if Model.state_hash(result["state"]) != Model.state_hash(preview["state"]) or Model.event_hash(result["events"]) != Model.event_hash(preview["events"]):
		ctx["error"] = "DRY_RUN_COMMIT_DIVERGENCE"
		ctx["failure_command"] = cmd.duplicate(true)
		return false
	ctx["state"] = result["state"]
	ctx["tape"].append(cmd.duplicate(true))
	ctx["events"].append_array(result["events"])
	ctx["steps"].append({"command_id":cmd["command_id"],"state_hash":Model.state_hash(result["state"]),"event_hash":Model.event_hash(result["events"])})
	collect_events(ctx["metrics"],result["events"])
	if not M2.validate_state(ctx["state"]["core"]) or not M4.validate_state(ctx["state"]) or not Zones.validate_state(ctx["state"]["core"]["cards"]):
		ctx["error"] = "POST_COMMAND_DOMAIN_INVARIANT"
		ctx["failure_command"] = cmd.duplicate(true)
	if ctx["state"]["events"].size() > MAX_EVENTS: ctx["timeout"] = "EVENT_CAP"
	return ctx["error"].is_empty() and ctx["timeout"].is_empty()

static func battle(ctx: Dictionary) -> Dictionary:
	return ctx["state"]["core"]["battle"]

static func score(ctx: Dictionary, cmd: Dictionary, definition: String) -> int:
	# Scores use current public state/IDs only, never sampled future damage/RNG.
	var p: Dictionary = profile(ctx["strategy"])
	var b: Dictionary = battle(ctx)
	var actor: String = str(cmd.get("actor_id","A"))
	var target: String = str(cmd.get("target_actor_id","Boss"))
	var unit: Dictionary = b["actors"][target]
	var missing_hp: int = int(unit["max_hp"])-int(unit["hp"])
	var value: int = -1000
	if ATTACK_CARDS.has(definition):
		value = int(p["attack"])
		if actor == "B": value += 15
		if ["R01","R07","A06"].has(definition): value += 8
		if str(cmd["casting_mode"]) == "FULL": value += int(p["full"])
	elif ["U05","T01","T03","T06"].has(definition):
		if target == "Boss" or missing_hp < 100: return -1000
		value = int(p["heal"])+mini(80,int(100.0*missing_hp/maxi(1,int(unit["max_hp"]))))
	elif ["U02","T04","R08"].has(definition):
		if target == "Boss" or float(b.get("hp_barriers",{}).get(target,0)) > 0: return -1000
		value = int(p["barrier"])
		if str(unit["status"]) == "CONCENTRATING": value += 30
	elif definition == "U03" or definition == "T07":
		value = int(p["ward"])
		for cast: Dictionary in b.get("casting_instances",{}).values():
			if str(cast.get("caster_id","")) == target and int(cast.get("focus_ward",0)) >= 8:
				return -1000
	elif definition == "U04" or definition == "T08":
		if target == "Boss" or int(unit["max_mp"])-int(unit["mp"]) < 2: return -1000
		value = 75 if target == "B" else 45
	elif definition == "A05": value = 140
	elif definition == "A03": value = int(p["attack"])-15
	elif definition == "BASIC":
		value = int(p["attack"])-25
		if not b["basic_attack_mp_restore_used_by_actor"].get(actor,true) and int(b["actors"][actor]["max_mp"])-int(b["actors"][actor]["mp"]) >= 2: value += 60
	elif definition == "LAST":
		if int(b["round"]) < 3 and ctx["strategy"] != "CAST_SUPPORT": return -1000
		value = int(p["last"])
		if actor == "B" and ctx["strategy"] == "CAST_SUPPORT": value += 25
		if actor == "C": value -= 45
	if str(cmd.get("combo_mode","NORMAL")) == "COMBO": value += 12
	return value

static func player_candidates(ctx: Dictionary) -> Array:
	var candidates: Array = []
	var b: Dictionary = battle(ctx)
	for actor: String in ACTORS:
		if str(b["actors"][actor]["status"]) != "ACTIVE" or int(b["actors"][actor]["hp"]) <= 0: continue
		var own: Dictionary = ctx["state"]["core"]["cards"]["actors"][actor]
		var hand: Array = own["zones"]["hand"].duplicate()
		hand.sort()
		for instance: String in hand:
			var definition: String = str(own["instances"][instance]["definition_id"])
			if REACTION_CARDS.has(definition): continue
			var targets: Array = ["Boss"] if ATTACK_CARDS.has(definition) or definition == "A05" else ["A","B","C"]
			if definition == "A03": targets = [actor]
			for target: String in targets:
				for mode: String in (["CHANTLESS","FULL"] if DUAL_CARDS.has(definition) else ["CHANTLESS"]):
					for combo: String in (["NORMAL","COMBO"] if definition == "A06" and mode == "CHANTLESS" else ["NORMAL"]):
						var cmd: Dictionary = command(ctx,"PLAY_LV40_CARD",{"actor_id":actor,"target_actor_id":target,"card_instance_id":instance,"casting_mode":mode,"combo_mode":combo})
						candidates.append({"command":cmd,"definition":definition,"score":score(ctx,cmd,definition)})
		var basic: Dictionary = command(ctx,"BASIC_ATTACK_RESOURCE_ONLY",{"actor_id":actor,"target_actor_id":"Boss"})
		candidates.append({"command":basic,"definition":"BASIC","score":score(ctx,basic,"BASIC")})
		for target: String in (["C"] if actor == "C" else ["Boss"]):
			var last: Dictionary = command(ctx,"ACTIVATE_LAST_SPELL_M4",{"actor_id":actor,"target_actor_id":target,"casting_mode":"FULL","confirmed":true})
			candidates.append({"command":last,"definition":"LAST","score":score(ctx,last,"LAST")})
	return candidates

static func player_step(ctx: Dictionary) -> bool:
	var best: Dictionary = {}
	var best_score: int = -999
	var legal_cards: Dictionary = {}
	var reserve: int = int(profile(ctx["strategy"])["reserve_ap"])
	for candidate: Dictionary in player_candidates(ctx):
		var cmd: Dictionary = candidate["command"]
		var dry: Dictionary = probe(ctx,cmd)
		if not ctx["error"].is_empty() or not ctx["timeout"].is_empty(): return false
		if not dry.get("accepted",false): continue
		var instance: String = str(cmd.get("card_instance_id",""))
		if not instance.is_empty(): legal_cards[instance] = true
		if int(dry["state"]["core"]["battle"]["party_resources"]["current_ap"]) < reserve:
			ctx["metrics"]["reserve_limited_candidates"] += 1
			continue
		if int(candidate["score"]) > best_score:
			best_score = int(candidate["score"])
			best = {"command":cmd,"dry":dry,"definition":candidate["definition"]}
	sample_hand(ctx,legal_cards)
	if not best.is_empty() and best_score > 0:
		ctx["decisions"].append({"step":ctx["tape"].size(),"definition":best["definition"],"score":best_score})
		if commit(ctx,best["command"],best["dry"]):
			var key: String = str(best["definition"])
			ctx["metrics"]["card_uses"][key] = int(ctx["metrics"]["card_uses"].get(key,0))+1
			return true
		return false
	# Legal swap only when no worthwhile action remains; once per actor/round.
	for actor: String in ACTORS:
		var swap_key: String = str(battle(ctx)["round"])+":"+actor
		if ctx["swapped"].has(swap_key): continue
		ctx["swapped"][swap_key] = true
		var own: Dictionary = ctx["state"]["core"]["cards"]["actors"][actor]
		var hand: Array = own["zones"]["hand"].duplicate()
		hand.sort()
		for instance: String in hand:
			if legal_cards.has(instance): continue
			var swap: Dictionary = command(ctx,"FREE_SWAP",{"actor_id":actor,"card_instance_id":instance})
			var dry: Dictionary = probe(ctx,swap)
			if dry.get("accepted",false): return commit(ctx,swap,dry)
	return commit(ctx,command(ctx,"END_PLAYER_PHASE"))

static func sample_hand(ctx: Dictionary, legal_cards: Dictionary) -> void:
	var metrics: Dictionary = ctx["metrics"]
	for actor: String in ACTORS:
		var key: String = str(battle(ctx)["round"])+":"+actor
		if ctx["sampled"].has(key) or str(battle(ctx)["actors"][actor]["status"]) != "ACTIVE": continue
		ctx["sampled"][key] = true
		var own: Dictionary = ctx["state"]["core"]["cards"]["actors"][actor]
		var samples: int = 0
		var legal: int = 0
		for instance: String in own["zones"]["hand"]:
			var definition: String = str(own["instances"][instance]["definition_id"])
			if REACTION_CARDS.has(definition): continue
			samples += 1
			metrics["card_samples"][definition] = int(metrics["card_samples"].get(definition,0))+1
			if legal_cards.has(instance): legal += 1
			else: metrics["card_dead"][definition] = int(metrics["card_dead"].get(definition,0))+1
		metrics["hand_samples"] += 1
		if samples == 0 or legal == 0: metrics["deadhand_samples"] += 1
		if int(battle(ctx)["actors"][actor]["mp"]) == 0: metrics["mp_bottleneck_samples"] += 1

static func reaction_step(ctx: Dictionary) -> bool:
	var window: Dictionary = ctx["state"]["reaction_window"]
	var wid: String = str(window["window_id"])
	var used: Array = []
	for entry: Dictionary in window.get("draft",[]): used.append(str(entry["actor_id"]))
	var target: String = str(window.get("original_target_actor_id",""))
	for actor: String in ACTORS:
		if used.has(actor): continue
		var options: Array = []
		if ctx["strategy"] == "CAST_SUPPORT" and target != actor and ACTORS.has(target):
			options.append({"kind":"BASIC_PROTECT","actor_id":actor,"target_actor_id":target})
		if ctx["strategy"] != "AGGRESSIVE":
			var own: Dictionary = ctx["state"]["core"]["cards"]["actors"][actor]
			for instance: String in own["zones"]["hand"]:
				if REACTION_CARDS.has(str(own["instances"][instance]["definition_id"])):
					options.append({"kind":"REACTION_SP_FIXTURE","actor_id":actor,"target_actor_id":target,"card_instance_id":instance})
		options.append({"kind":"BASIC_GUARD","actor_id":actor,"target_actor_id":actor})
		for entry: Dictionary in options:
			var cmd: Dictionary = command(ctx,"QUEUE_REACTION",{"window_id":wid,"entry":entry})
			var dry: Dictionary = probe(ctx,cmd)
			if not dry.get("accepted",false): continue
			# Drafting alone does not validate the aggregate RP/MP budget.
			var preview_ctx: Dictionary = context(ctx["seed"],ctx["strategy"],dry["state"],ctx["config"])
			var confirm: Dictionary = command(preview_ctx,"CONFIRM_REACTIONS",{"window_id":wid})
			confirm["command_id"] = str(cmd["command_id"])+":budget-preview"
			var checked: Dictionary = probe(preview_ctx,confirm)
			ctx["probes"] += int(preview_ctx["probes"])
			if not preview_ctx["error"].is_empty(): ctx["error"] = preview_ctx["error"]
			if ctx["probes"] >= MAX_PROBES: ctx["timeout"] = "PROBE_CAP"
			if checked.get("accepted",false): return commit(ctx,cmd,dry)
	# These are explicit offline policy choices, never a human UI timeout.
	return commit(ctx,command(ctx,"PASS_REACTION" if used.is_empty() else "CONFIRM_REACTIONS",{"window_id":wid}))

static func next_step(ctx: Dictionary) -> bool:
	var state: Dictionary = ctx["state"]
	match str(state["phase"]):
		"PLAYER_PHASE": return player_step(ctx)
		"AWAITING_PLAYER_START":
			if int(battle(ctx)["round"]) >= MAX_ROUNDS:
				ctx["timeout"] = "ROUND_CAP"
				return false
			return commit(ctx,command(ctx,"START_PLAYER_PHASE"))
		"ENEMY_PHASE":
			var active: String = str(state["active_enemy_action_id"])
			if active.is_empty():
				if int(state["enemy_cursor"]) < state["enemy_actions"].size():
					return commit(ctx,command(ctx,"DECLARE_NEXT_ENEMY_ACTION"))
				return commit(ctx,command(ctx,"END_ENEMY_PHASE"))
			var window: Dictionary = state["reaction_window"]
			if window.is_empty(): return commit(ctx,command(ctx,"OPEN_REACTION_WINDOW",{"enemy_action_id":active}))
			if str(window["status"]) == "DRAFTING": return reaction_step(ctx)
			return commit(ctx,command(ctx,"RESOLVE_ENEMY_ATTACK_M5",{"enemy_action_id":active}))
	ctx["error"] = "NOT_IMPLEMENTED:PHASE:"+str(state["phase"])
	return false

static func collect_events(metrics: Dictionary, events: Array) -> void:
	for wrapped: Dictionary in events:
		var event: Dictionary = wrapped
		var detail: Dictionary = event.get("details",{})
		# Unwrap payment envelopes once; never count outer and nested copies.
		while detail.get("core_event",null) is Dictionary:
			event = detail["core_event"]
			if event.get("event",null) is Dictionary: event = event["event"]
			detail = event.get("details",{})
		var kind: String = str(event.get("kind",""))
		if detail.is_empty(): detail = event
		metrics["coverage"][kind] = int(metrics["coverage"].get(kind,0))+1
		var actor: String = str(detail.get("actor_id",detail.get("caster_id","")))
		if kind == "SPCostReservedOnly" or kind == "BasicAttackResourceCommitted":
			metrics["ap_spent"] += int(detail.get("ap_paid",0))
			metrics["ap_borrowed"] += int(detail.get("ap_borrowed",0))
			metrics["mp_spent"] += int(detail.get("mp_cost",0))
			if ACTORS.has(actor):
				metrics["ap_by_actor"][actor] += int(detail.get("ap_paid",0))
				metrics["mp_by_actor"][actor] += int(detail.get("mp_cost",0))
		elif kind == "ReactionResourcesCommitted":
			metrics["rp_spent"] += int(detail.get("rp_paid",0))
			metrics["mp_spent"] += int(detail.get("mp_paid",0))
			if ACTORS.has(actor): metrics["mp_by_actor"][actor] += int(detail.get("mp_paid",0))
		elif kind == "RPSpent": metrics["rp_spent"] += int(detail.get("actual",0))
		elif kind == "HPHealed":
			metrics["heal"] += int(detail.get("amount",0))
			metrics["heal_events"] += 1
			if detail.has("requested_amount"):
				metrics["heal_events_with_requested"] += 1
				metrics["overheal"] = int(metrics["overheal"] if metrics["overheal"] != null else 0)+maxi(0,int(detail["requested_amount"])-int(detail.get("amount",0)))
		elif kind == "DamageTrace" or kind == "HPBarrierAbsorbed":
			var target: String = str(detail.get("recipient_id",detail.get("target_actor_id","")))
			var absorbed: float = float(detail.get("barrier_absorbed",detail.get("absorbed",0)))
			if target == "Boss": metrics["boss_barrier_absorb"] += absorbed
			else: metrics["barrier_absorb"] += absorbed
		var mapping: Dictionary = {"CastingStarted":"casting_started","CastingReleased":"casting_completion",
			"CastingInterrupted":"casting_interrupt","CastingCancelled":"casting_invalidated",
			"LastSpellCommitted":"lastspell_started","LastSpellReleased":"lastspell_completion",
			"LastSpellInvalidated":"lastspell_invalidated","LastSpellDestabilizedDelayed":"lastspell_delayed",
			"LastSpellDestabilizedWeakened":"lastspell_weakened","FocusWardGranted":"focus_ward_used"}
		if mapping.has(kind):
			# Keep Boss interruption separate from party completion denominators.
			if actor == "Boss" and kind == "CastingInterrupted":
				metrics["boss_casting_interrupt"] = int(metrics.get("boss_casting_interrupt",0))+1
			else: metrics[mapping[kind]] += 1
	if metrics["heal_events"] > 0 and metrics["heal_events"] == metrics["heal_events_with_requested"]:
		metrics["metric_status"]["overheal"] = "OBSERVED"
	else:
		metrics["overheal"] = null
		metrics["metric_status"]["overheal"] = "NOT_IMPLEMENTED:REQUESTED_HEAL_NOT_EXPOSED"

static func run(seed: int, strategy: String, encounter: Script) -> Dictionary:
	var original: Dictionary = encounter.call("initial",seed)
	var config: Dictionary = encounter.call("config")
	var ctx: Dictionary = context(seed,strategy,original,config)
	if profile(strategy).is_empty() or original.is_empty() or not M4.validate_state(original):
		return {"seed":seed,"strategy":strategy,"outcome":"error","error":"INVALID_POLICY_OR_INITIAL","replay":{"ok":false}}
	while str(battle(ctx)["outcome"]) == "ONGOING":
		if int(battle(ctx)["round"]) > MAX_ROUNDS:
			ctx["timeout"] = "ROUND_CAP"
			break
		if not next_step(ctx): break
	var final: Dictionary = ctx["state"]
	var outcome: String = str(battle(ctx)["outcome"])
	var result: String = "timeout"
	if not ctx["error"].is_empty(): result = "error"
	elif outcome == "VICTORY": result = "win"
	elif outcome == "DEFEAT": result = "defeat"
	var hp: Dictionary = {}
	for actor: String in TARGETS: hp[actor] = int(battle(ctx)["actors"][actor]["hp"])
	var report: Dictionary = {"policy_version":POLICY_VERSION,"balance":"BALANCE_PROVISIONAL",
		"seed":seed,"strategy":strategy,"profile":profile(strategy),"outcome":result,
		"domain_outcome":outcome,"error":ctx["error"],"timeout_reason":ctx["timeout"],"failure_command":ctx["failure_command"],
		"rounds":int(battle(ctx)["round"]),"hp":hp,"metrics":ctx["metrics"],
		"accepted":ctx["tape"].size(),"probes":ctx["probes"],"rejected_probes":ctx["rejected_probes"],
		"rejection_reasons":ctx["rejection_reasons"],"capabilities":ctx["capabilities"],
		"initial":ctx["initial"],"config":ctx["config"],"tape":ctx["tape"],"events":ctx["events"],
		"final":final,"steps":ctx["steps"],"decisions":ctx["decisions"],
		"initial_hash":Model.state_hash(ctx["initial"]),"config_hash":Model.state_hash(ctx["config"]),
		"event_hash":Model.event_hash(ctx["events"]),"full_event_hash":Model.event_hash(final["events"]),
		"state_hash":Model.state_hash(final),"tape_hash":Model.event_hash(ctx["tape"]),
		"ruleset_version":battle(ctx).get("ruleset_version","UNKNOWN"),
		"rng_version":battle(ctx).get("rng",{}).get("algorithm","UNKNOWN"),
		"content_version":config.get("m5_lv40_content_version",config.get("content_version","NOT_IMPLEMENTED:CONTENT_VERSION"))}
	report["replay"] = replay(report)
	if not report["replay"]["ok"]:
		report["outcome"] = "error"
		report["error"] = "REPLAY_FAILED:"+str(report["replay"]["error"])
	return report

static func replay(report: Dictionary) -> Dictionary:
	for field: String in ["initial","initial_hash","config","config_hash","final","state_hash","tape","tape_hash","steps","events","event_hash","full_event_hash"]:
		if not report.has(field): return {"ok":false,"error":"INCOMPLETE_REPORT:"+field}
	if report["steps"].size() != report["tape"].size(): return {"ok":false,"error":"STEP_COUNT"}
	for pair: Array in [["initial","initial_hash"],["config","config_hash"],["final","state_hash"]]:
		if Model.state_hash(report[pair[0]]) != report[pair[1]]: return {"ok":false,"error":"SNAPSHOT_HASH:"+str(pair[0])}
	if Model.event_hash(report["tape"]) != report["tape_hash"]: return {"ok":false,"error":"TAPE_HASH"}
	if Model.event_hash(report["events"]) != report["event_hash"]: return {"ok":false,"error":"EVENT_LOG_HASH"}
	var state: Dictionary = report["initial"].duplicate(true)
	var emitted: Array = []
	for index: int in range(report["tape"].size()):
		var result: Dictionary = M5.apply(state,report["tape"][index],report["config"].duplicate(true))
		if not result.get("accepted",false): return {"ok":false,"error":"REJECTED_STEP:"+str(index)}
		state = result["state"]
		emitted.append_array(result["events"])
		if Model.state_hash(state) != report["steps"][index]["state_hash"] or Model.event_hash(result["events"]) != report["steps"][index]["event_hash"]:
			return {"ok":false,"error":"STEP_HASH:"+str(index)}
	var ok: bool = Model.state_hash(state) == report["state_hash"] and Model.event_hash(emitted) == report["event_hash"] and Model.event_hash(state["events"]) == report["full_event_hash"]
	return {"ok":ok,"error":"" if ok else "FINAL_EVENT_STATE_HASH_MISMATCH"}

static func allowed_output(prefix: String) -> bool:
	return not prefix.contains("..") and not prefix.contains("\\") and not prefix.get_file().is_empty() and ["res://outputs","res://outputs/p4_logs"].has(prefix.get_base_dir()) and prefix.get_file().begins_with("lv40_balance")

static func write_json(path: String, data: Dictionary) -> bool:
	var file: FileAccess = FileAccess.open(path,FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify(data,"\t"))
	file.close()
	return true

static func run_matrix(prefix: String) -> Dictionary:
	if not allowed_output(prefix): return {"status":"ERROR","error":"OUTPUT_OUTSIDE_SCOPE","games":0}
	# Immutable attempt slots: all artifacts preserved; never overwrite a run.
	if DirAccess.dir_exists_absolute(prefix) or FileAccess.file_exists(prefix+"_summary.json"):
		return {"status":"ERROR","error":"ATTEMPT_ALREADY_EXISTS","games":0}
	var siblings: int = 0
	for root: String in ["res://outputs","res://outputs/p4_logs"]:
		for directory: String in DirAccess.get_directories_at(root):
			if directory.begins_with("lv40_balance") and FileAccess.file_exists(root+"/"+directory+"/attempt.json"): siblings += 1
	if siblings >= 3: return {"status":"ERROR","error":"THREE_ATTEMPT_LIMIT","games":0}
	var api: Dictionary = load_encounter()
	if not api["ok"]: return {"status":"NOT_IMPLEMENTED","error":api["error"],"games":0}
	if DirAccess.make_dir_recursive_absolute(prefix) != OK: return {"status":"ERROR","error":"OUTPUT_DIRECTORY","games":0}
	var git_output: Array = []
	var git_exit: int = OS.execute("git",["-C",ProjectSettings.globalize_path("res://"),"rev-parse","HEAD"],git_output,true)
	var meta: Dictionary = {"policy_version":POLICY_VERSION,"godot":Engine.get_version_info(),
		"git_head":str(git_output[0]).strip_edges() if git_exit == 0 and not git_output.is_empty() else "UNAVAILABLE",
		"authority":"BALANCE_PROVISIONAL","seeds":fixed_seeds(),"strategies":STRATEGIES,
		"limits":{"rounds":MAX_ROUNDS,"commands":MAX_COMMANDS,"events":MAX_EVENTS,"probes":MAX_PROBES},
		"source_files":{}}
	for path: String in [ENCOUNTER,"res://scripts/domain/m5/integration/m5_domain_resolver.gd","res://tools/balance/lv40_godot_policy.gd"]:
		meta["source_files"][path] = FileAccess.get_sha256(path)
	# Hash all Domain code and versioned data dependencies, including dirty files.
	meta["source_files"].merge(source_hashes("res://scripts/domain"),true)
	meta["source_files"].merge(source_hashes("res://resources/combat"),true)
	if not write_json(prefix+"/attempt.json",meta): return {"status":"ERROR","error":"ATTEMPT_METADATA","games":0}
	var csv: FileAccess = FileAccess.open(prefix+"/games.csv",FileAccess.WRITE)
	if csv == null: return {"status":"ERROR","error":"CSV_OPEN","games":0}
	csv.store_csv_line(PackedStringArray(["strategy","seed","outcome","rounds","hp_A","hp_B","hp_C","hp_Boss","ap_spent","mp_spent","heal","overheal","barrier_absorb","casting_completion","casting_interrupt","lastspell_completion","deadhand_frequency","event_hash","state_hash","tape_hash","replay_ok","error"]))
	var summary: Dictionary = {"status":"RESEARCH_ONLY","balance":"BALANCE_PROVISIONAL","games":0,"errors":0,"replay_failures":0,"written":true,"strategies":{},"metadata":meta}
	for strategy: String in STRATEGIES:
		var stats: Dictionary = {"win":0,"defeat":0,"timeout":0,"error":0,"rounds":[],"win_rounds":[],"capabilities":{},"metric_status":{},"metric_totals":{},"hp_totals":{"A":0,"B":0,"C":0,"Boss":0},"config_hashes":{},"ap_by_actor":{"A":0,"B":0,"C":0},"card_uses":{},"card_samples":{},"card_dead":{}}
		for seed: int in fixed_seeds():
			var report: Dictionary = run(seed,strategy,api["script"])
			summary["games"] += 1
			stats[report["outcome"]] += 1
			if report["outcome"] == "error": summary["errors"] += 1
			if not report["replay"]["ok"]: summary["replay_failures"] += 1
			if not report.has("metrics"):
				var empty_row: PackedStringArray = [strategy,str(seed),"error"]
				for _column: int in range(18): empty_row.append("NOT_AVAILABLE")
				empty_row.append(str(report.get("error","INVALID_INITIAL")))
				csv.store_csv_line(empty_row)
				csv.flush()
				summary["written"] = write_json(prefix+"/"+strategy+"_"+str(seed)+".json",report) and summary["written"]
				continue
			stats["rounds"].append(report["rounds"])
			if report["outcome"] == "win": stats["win_rounds"].append(report["rounds"])
			stats["capabilities"].merge(report["capabilities"],true)
			var m: Dictionary = report["metrics"]
			stats["config_hashes"][report["config_hash"]] = true
			for actor: String in TARGETS: stats["hp_totals"][actor] += report["hp"][actor]
			for actor: String in ACTORS: stats["ap_by_actor"][actor] += m["ap_by_actor"][actor]
			for key: String in ["card_uses","card_samples","card_dead"]:
				for card: String in m[key]: stats[key][card] = int(stats[key].get(card,0))+int(m[key][card])
			for key: String in ["ap_spent","mp_spent","rp_spent","heal","barrier_absorb","casting_started","casting_completion","casting_interrupt","lastspell_started","lastspell_completion","lastspell_invalidated","hand_samples","deadhand_samples"]:
				stats["metric_totals"][key] = float(stats["metric_totals"].get(key,0))+float(m[key])
			stats["metric_status"].merge(m["metric_status"],true)
			var frequency: float = float(m["deadhand_samples"])/maxi(1,int(m["hand_samples"]))
			var row: Array = [strategy,seed,report["outcome"],report["rounds"]]
			for actor: String in ["A","B","C","Boss"]: row.append(report["hp"][actor])
			for key: String in ["ap_spent","mp_spent","heal","overheal","barrier_absorb","casting_completion","casting_interrupt","lastspell_completion"]:
				row.append("NOT_IMPLEMENTED" if m[key] == null else m[key])
			row.append_array([frequency,report["event_hash"],report["state_hash"],report["tape_hash"],report["replay"]["ok"],report["error"]])
			var strings: PackedStringArray = []
			for cell: Variant in row: strings.append(str(cell))
			csv.store_csv_line(strings)
			csv.flush()
			summary["written"] = write_json(prefix+"/"+strategy+"_"+str(seed)+".json",report) and summary["written"]
			print("P46_GAME ",strategy," seed=",seed," outcome=",report["outcome"]," replay=",report["replay"]["ok"])
		stats["rounds"].sort()
		stats["win_rounds"].sort()
		stats["win_rate"] = float(stats["win"])/100.0
		stats["win_rate_wilson95"] = wilson95(int(stats["win"]),100)
		stats["win_rounds_p50"] = percentile(stats["win_rounds"],0.5)
		stats["rounds_p10"] = percentile(stats["rounds"],0.1)
		stats["rounds_p90"] = percentile(stats["rounds"],0.9)
		stats["deadhand_frequency"] = float(stats["metric_totals"].get("deadhand_samples",0))/maxf(1,float(stats["metric_totals"].get("hand_samples",0)))
		stats["casting_completion_rate"] = float(stats["metric_totals"].get("casting_completion",0))/float(stats["metric_totals"]["casting_started"]) if float(stats["metric_totals"].get("casting_started",0)) > 0 else null
		stats["casting_interrupt_rate"] = float(stats["metric_totals"].get("casting_interrupt",0))/float(stats["metric_totals"]["casting_started"]) if float(stats["metric_totals"].get("casting_started",0)) > 0 else null
		summary["strategies"][strategy] = stats
	csv.close()
	var current_hashes: Dictionary = source_hashes("res://scripts/domain")
	current_hashes.merge(source_hashes("res://resources/combat"),true)
	for path: String in meta["source_files"]:
		if FileAccess.get_sha256(path) != meta["source_files"][path]:
			summary["status"] = "ERROR_SOURCE_CHANGED_DURING_RUN"
			summary["errors"] += 1
	for path: String in current_hashes:
		if not meta["source_files"].has(path):
			summary["status"] = "ERROR_SOURCE_CHANGED_DURING_RUN"
			summary["errors"] += 1
	summary["written"] = write_json(prefix+"/summary.json",summary) and summary["written"]
	return summary

static func source_hashes(root: String) -> Dictionary:
	var result: Dictionary = {}
	for file: String in DirAccess.get_files_at(root):
		if file.get_extension() in ["gd","json","tres"]:
			result[root+"/"+file] = FileAccess.get_sha256(root+"/"+file)
	for directory: String in DirAccess.get_directories_at(root):
		result.merge(source_hashes(root+"/"+directory))
	return result

static func wilson95(wins: int, count: int) -> Array:
	if count <= 0: return []
	var p: float = float(wins)/count
	var z2: float = 1.96*1.96
	var denominator: float = 1.0+z2/count
	var center: float = (p+z2/(2.0*count))/denominator
	var half: float = 1.96*sqrt(p*(1.0-p)/count+z2/(4.0*count*count))/denominator
	return [maxf(0,center-half),minf(1,center+half)]

static func percentile(sorted: Array, fraction: float) -> Variant:
	if sorted.is_empty(): return null
	return sorted[mini(sorted.size()-1,int(floor((sorted.size()-1)*fraction)))]
