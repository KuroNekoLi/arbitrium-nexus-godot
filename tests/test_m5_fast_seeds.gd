extends SceneTree
## Five deterministic fixture full battles, each with authentic full-tape replay.
## This is a fast smoke suite, NEVER M5.5's 100-seed acceptance replacement.
const Driver = preload("res://tests/fixtures/m5_full_battle_driver.gd")
const Zones = preload("res://scripts/domain/m2/cards/card_zone_resolver.gd")
const SEEDS: Array[int] = [20261014,20261015,20261029,20261060,20261113]
var passed: int = 0
var failed: int = 0

func _init() -> void:
	for seed: int in SEEDS:
		var report: Dictionary = Driver.run(seed)
		var ok: bool = report.get("ok",false)
		var replay: Dictionary = {}
		if ok:
			replay = Driver.replay(report)
			ok = replay.get("ok",false) and \
				str(replay.get("event_hash","")) == str(report.get("event_hash","")) and \
				str(replay.get("state_hash","")) == str(report.get("final_hash","")) and \
				["VICTORY","DEFEAT"].has(str(report.get("outcome",""))) and \
				int(report.get("accepted",0)) > 0 and int(report.get("rejected",1)) == 0 and \
				Zones.validate_state(report["final"]["core"]["cards"])
		if ok:
			passed += 1
			print("PASS M55-FAST-SEED-",seed)
		else:
			failed += 1
			printerr("FAIL M55-FAST-SEED-",seed," ",report.get("error","")," ",replay.get("error",""))
	print("M5_5_FAST_SEEDS_REPORT executed=%d passed=%d failed=%d" % [passed+failed,passed,failed])
	quit(0 if failed == 0 and passed == SEEDS.size() else 1)
