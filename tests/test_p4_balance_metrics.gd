extends SceneTree
const Metrics = preload("res://tools/balance/lv40_research/metrics.gd")
const Policy = preload("res://tools/balance/lv40_godot_policy.gd")
var passed: int = 0
var failed: int = 0
func check(id: String, assertion: bool) -> void:
	if assertion:
		passed += 1
		print("PASS ",id)
	else:
		failed += 1
		push_error("FAIL "+id)

func _initialize() -> void:
	var empty: Dictionary = Metrics.distribution([])
	check("P46-STAT-01-EMPTY-IS-UNKNOWN",empty["ok"] and empty["count"] == 0 and empty["median"] == null)
	var one: Dictionary = Metrics.distribution([19])
	check("P46-STAT-02-SINGLE-NO-DIVZERO",one["ok"] and one["median"] == 19 and one["p95"] == 19)
	var mixed: Dictionary = Metrics.distribution([1,9,3,5,7])
	check("P46-STAT-03-ORDERED-MEAN",mixed["ok"] and mixed["mean"] == 5.0 and mixed["median"] == 5.0)
	check("P46-STAT-04-P95-INTERPOLATED",absf(float(mixed["p95"])-8.6) < 0.0001)
	check("P46-STAT-05-BAD-SAMPLE",not Metrics.distribution([1,"oops"])["ok"])
	check("P46-STAT-06-NAN-REJECTED",not Metrics.distribution([1,NAN])["ok"])
	check("P46-STAT-07-INF-REJECTED",not Metrics.distribution([INF])["ok"])
	check("P46-STAT-08-OUTSIDE-QUANTILE",Metrics.quantile([1.0,2.0],1.1) == null)
	var even: Dictionary = Metrics.distribution([1,2])
	check("P46-STAT-09-POLICY-MEDIAN-CONSISTENT",even["median"] == 1.5 and
		Policy.percentile([1,2],0.5) == even["median"])
	check("P46-STAT-10-POLICY-PERCENTILES",absf(float(Policy.percentile([1,2],0.1))-1.1)<0.0001 and
		absf(float(Policy.percentile([1,2],0.9))-1.9)<0.0001)
	check("P46-STAT-11-POLICY-INVALID",Policy.percentile([1,2],-0.1) == null and
		Policy.percentile([1,2],NAN) == null and Policy.percentile([null],0.5) == null)
	check("P46-STAT-12-POLICY-EMPTY",Policy.percentile([],0.5) == null)
	check("P46-STAT-13-POLICY-EVEN-FOUR",Policy.percentile([1,2,3,4],0.5) == 2.5)
	var tool_hashes: Dictionary = Policy.research_tool_hashes()
	var metrics_path: String = "res://tools/balance/lv40_research/metrics.gd"
	check("P46-SOURCE-01-METRICS-HASH",tool_hashes.has(metrics_path) and
		str(tool_hashes[metrics_path]).length() == 64 and
		tool_hashes[metrics_path] == FileAccess.get_sha256(metrics_path))
	check("P46-SOURCE-02-POLICY-HASH",tool_hashes.has("res://tools/balance/lv40_godot_policy.gd"))
	check("P46-CI-01-ZERO",Metrics.wilson95(0,100)[1] < 0.04)
	check("P46-CI-02-ONE",Metrics.wilson95(100,100)[0] > 0.96)
	check("P46-CI-03-EMPTY-UNKNOWN",Metrics.wilson95(0,0) == null)
	check("P46-CI-04-INVALID-REJECT",Metrics.wilson95(2,1) == null)
	var seeds: Dictionary = {
		"1":{"A":{"outcome":"win"},"B":{"outcome":"defeat"}},
		"2":{"A":{"outcome":"timeout"},"B":{"outcome":"win"}},
		"3":{"A":{"outcome":"error"},"B":{"outcome":"error"}},
		"4":{"A":{"outcome":"win"},"B":{"outcome":"win"}}
	}
	var paired: Dictionary = Metrics.paired(seeds,["A","B"],4)
	var row: Dictionary = paired["pairs"]["A_vs_B"]
	check("P46-PAIR-01-ALL-FOUR-COUNT",paired["complete"] and row["paired"] == 4)
	check("P46-PAIR-02-BOTH-AND-DISCORDANT",row["both_win"] == 1 and row["first_only_win"] == 1 and row["second_only_win"] == 1)
	check("P46-PAIR-03-FAILURES-RETAINED",row["neither_win"] == 1 and row["first_timeouts"] == 1 and row["first_errors"] == 1)
	check("P46-PAIR-04-PAIRED-DELTA-ZERO",row["win_delta"] == 0.0)
	seeds.erase("3")
	paired = Metrics.paired(seeds,["A","B"],4)
	check("P46-PAIR-05-MISSING-SEED-INCOMPLETE",paired["ok"] and not paired["complete"])
	seeds["3"] = {"A":{"outcome":"win"}}
	paired = Metrics.paired(seeds,["A","B"],4)
	check("P46-PAIR-06-MISSING-STRATEGY-INCOMPLETE",not paired["complete"])
	seeds["3"]["B"] = {"outcome":"invalid"}
	check("P46-PAIR-07-INVALID-OUTCOME-REJECT",not Metrics.paired(seeds,["A","B"],4)["ok"])
	check("P46-PAIR-08-EMPTY-STRATEGY-REJECT",not Metrics.paired(seeds,["A"],4)["ok"])
	for bad: Variant in [null,42,"win",[]]:
		var invalid: Dictionary = Metrics.paired({"1":{"A":bad,"B":{"outcome":"win"}}},["A","B"],1)
		check("P46-PAIR-09-BAD-REPORT-"+str(typeof(bad)),not invalid["ok"] and
			invalid["error"] == "INVALID_STRATEGY_REPORT")
	check("P46-PAIR-10-DUPLICATE-STRATEGY",not Metrics.paired(
		{"1":{"A":{"outcome":"win"}}},["A","A"],1)["ok"])
	check("P46-PAIR-11-BLANK-STRATEGY",not Metrics.paired({},["A",""],1)["ok"])
	check("P46-PAIR-12-UNPAIRED-BAD-REPORT",not Metrics.paired(
		{"1":{"A":null}},["A","B"],1)["ok"])
	check("P46-PAIR-13-NULL-SEED-REPORT",not Metrics.paired({"1":null},["A","B"],1)["ok"])
	print("P4_BALANCE_METRICS_REPORT executed=",passed+failed," passed=",passed," failed=",failed)
	quit(1 if failed else 0)
