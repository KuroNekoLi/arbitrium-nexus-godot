extends SceneTree
const Metrics = preload("res://tools/balance/lv40_research/metrics.gd")
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
	print("P4_BALANCE_METRICS_REPORT executed=",passed+failed," passed=",passed," failed=",failed)
	quit(1 if failed else 0)
