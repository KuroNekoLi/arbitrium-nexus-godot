extends RefCounted
## Pure offline statistics for a paired, complete 4x100 candidate-balance matrix.
## Failed / timed-out observations are retained in every denominator.

static func distribution(samples: Array) -> Dictionary:
	if samples.is_empty():
		return {"ok":true,"count":0,"mean":null,"median":null,"p95":null,"min":null,"max":null}
	var sorted: Array[float] = []
	for value: Variant in samples:
		if not (value is int or value is float):
			return {"ok":false,"error":"NON_NUMERIC_SAMPLE"}
		var number: float = float(value)
		if is_nan(number) or is_inf(number):
			return {"ok":false,"error":"INVALID_FLOAT_SAMPLE"}
		sorted.append(number)
	sorted.sort()
	var total: float = 0.0
	for number: float in sorted:
		total += number
	var n: int = sorted.size()
	return {"ok":true,"count":n,"mean":total/float(n),
		"median":quantile(sorted,0.5),"p95":quantile(sorted,0.95),
		"min":sorted[0],"max":sorted[n-1]}

## Inclusive linear interpolation of sorted indices. Never treat empty as zero.
static func quantile(sorted: Array[float], probability: float) -> Variant:
	if sorted.is_empty() or probability < 0.0 or probability > 1.0:
		return null
	var position: float = probability*float(sorted.size()-1)
	var low: int = int(floor(position))
	var high: int = int(ceil(position))
	return lerpf(sorted[low],sorted[high],position-float(low))

static func wilson95(wins: int, trials: int) -> Variant:
	if trials < 1 or wins < 0 or wins > trials:
		return null
	var z: float = 1.9599639845
	var p: float = float(wins)/float(trials)
	var z2: float = z*z
	var divider: float = 1.0+z2/float(trials)
	var center: float = (p+z2/(2.0*float(trials)))/divider
	var half: float = z*sqrt(p*(1.0-p)/float(trials)+z2/(4.0*float(trials)*float(trials)))/divider
	return [maxf(0.0,center-half),minf(1.0,center+half)]

## by_seed maps each fixed seed to a dictionary of strategy→{outcome,...}.
## Paired deltas compare identical seeds; timeout and error remain non-wins.
static func paired(by_seed: Dictionary, strategies: Array[String], expected_seeds: int = 100) -> Dictionary:
	if expected_seeds < 1:
		return {"ok":false,"error":"INVALID_EXPECTED_SEEDS"}
	if strategies.size() < 2:
		return {"ok":false,"error":"NOT_ENOUGH_STRATEGIES"}
	var samples: Array = []
	var pair_stats: Dictionary = {}
	for first: int in strategies.size():
		for second: int in range(first+1,strategies.size()):
			var pair_key: String = strategies[first]+"_vs_"+strategies[second]
			pair_stats[pair_key] = {"paired":0,"both_win":0,"first_only_win":0,
				"second_only_win":0,"neither_win":0,"first_timeouts":0,
				"second_timeouts":0,"first_errors":0,"second_errors":0,
				"win_delta":null}
	for seed: Variant in by_seed:
		var reports: Variant = by_seed[seed]
		if not reports is Dictionary:
			return {"ok":false,"error":"INVALID_SEED_REPORT"}
		for first: int in strategies.size():
			for second: int in range(first+1,strategies.size()):
				var p: String = strategies[first]+"_vs_"+strategies[second]
				if not reports.has(strategies[first]) or not reports.has(strategies[second]):
					continue
				var a: String = str(reports[strategies[first]].get("outcome",""))
				var b: String = str(reports[strategies[second]].get("outcome",""))
				if not ["win","defeat","timeout","error"].has(a) or not ["win","defeat","timeout","error"].has(b):
					return {"ok":false,"error":"INVALID_OUTCOME"}
				var row: Dictionary = pair_stats[p]
				row["paired"] += 1
				row["first_timeouts"] += int(a == "timeout")
				row["second_timeouts"] += int(b == "timeout")
				row["first_errors"] += int(a == "error")
				row["second_errors"] += int(b == "error")
				if a == "win" and b == "win":
					row["both_win"] += 1
				elif a == "win":
					row["first_only_win"] += 1
				elif b == "win":
					row["second_only_win"] += 1
				else:
					row["neither_win"] += 1
	for key: String in pair_stats:
		var row: Dictionary = pair_stats[key]
		if int(row["paired"]) > 0:
			row["win_delta"] = float(int(row["first_only_win"])-int(row["second_only_win"]))/float(row["paired"])
	return {"ok":true,"expected_seeds":expected_seeds,"observed_seed_count":by_seed.size(),
		"complete":by_seed.size() == expected_seeds and pair_stats.values().all(
			func(p: Dictionary) -> bool: return int(p["paired"]) == expected_seeds),
		"pairs":pair_stats}
