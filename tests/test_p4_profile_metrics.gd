extends SceneTree
const Metrics = preload("res://tools/qa/p4_profile_metrics.gd")
const Profile = preload("res://tests/profile_p4.gd")
var passed: int = 0
var failed: int = 0
func check(name: String, ok: bool) -> void:
	if ok:
		passed += 1
		print("PASS ",name)
	else:
		failed += 1
		push_error("FAIL "+name)

func _initialize() -> void:
	var empty: Dictionary = Metrics.summarize([],"ms")
	check("P4-PROF-01-EMPTY-UNKNOWN",empty["ok"] and empty["p95"] == null and empty["samples"] == 0)
	var one: Dictionary = Metrics.summarize([13],"ms")
	check("P4-PROF-02-SINGLE",one["ok"] and one["mean"] == 13 and one["p50"] == 13 and one["p95"] == 13)
	var mixed: Dictionary = Metrics.summarize([1,5,null,9,3,7],"ms")
	check("P4-PROF-03-SORTED",mixed["ok"] and mixed["p50"] == 5 and absf(mixed["p95"]-8.6)<0.0001)
	check("P4-PROF-04-MISSING-NOT-ZERO",mixed["missing"] == 1 and mixed["samples"] == 5 and mixed["mean"] == 5)
	var absent: Dictionary = Metrics.summarize([null,null],"ms")
	check("P4-PROF-05-ALL-MISSING",absent["ok"] and absent["mean"] == null and absent["missing"] == 2)
	check("P4-PROF-06-NAN-REJECTED",not Metrics.summarize([NAN],"ms")["ok"])
	check("P4-PROF-07-INF-REJECTED",not Metrics.summarize([INF],"ms")["ok"])
	check("P4-PROF-08-NEGATIVE-REJECTED",not Metrics.summarize([-1],"ms")["ok"])
	check("P4-PROF-09-STRING-REJECTED",not Metrics.summarize(["1"],"ms")["ok"])
	check("P4-PROF-10-PERCENTILE-RANGE",Metrics.percentile([1.0,2.0],1.2) == null)
	check("P4-PROF-11-COLLECTION",Metrics.aggregate({"frame":[10,20]},
		{"frame":"ms"})["ok"])
	check("P4-PROF-12-MISSING-METRIC",not Metrics.aggregate({},{"frame":"ms"})["ok"])
	check("P4-PROF-13-SAFE-ID",Metrics.scoped_run_id("p4_20261015_001"))
	check("P4-PROF-14-TRAVERSAL-ID",not Metrics.scoped_run_id("../unsafe"))
	check("P4-PROF-15-SLASH-ID",not Metrics.scoped_run_id("x/y"))
	check("P4-PROF-16-SCOPE-REJECT",not Metrics.write_new("res://tests/p4_capture.png","x")["ok"])
	check("P4-PROF-17-TRAVERSAL-PATH",not Metrics.write_new("res://outputs/p4_performance/../escape.json","x")["ok"])
	for invalid: String in ["5junk","","5.5","5e1"," 5","5 ","-5","4","1001",
			"18446744073709551621"]:
		check("P4-PROF-18-INVALID-FRAME-COUNT-"+invalid,not Metrics.parse_frame_count(invalid,5,1000)["ok"])
	check("P4-PROF-19-SAMPLE-BOUNDARIES",Metrics.parse_frame_count("5",5,1000)["value"] == 5 and
		Metrics.parse_frame_count("1000",5,1000)["value"] == 1000)
	check("P4-PROF-20-WARMUP-BOUNDARIES",Metrics.parse_frame_count("3",3,600)["value"] == 3 and
		Metrics.parse_frame_count("600",3,600)["value"] == 600 and
		not Metrics.parse_frame_count("601",3,600)["ok"])
	check("P4-PROF-21-PROCESS-LABEL",Profile.UNITS.has("process_frame_ms") and
		not Profile.UNITS.has("script_process_ms"))
	print("P4_PROFILE_METRICS_REPORT executed=",passed+failed," passed=",passed," failed=",failed)
	quit(1 if failed else 0)
