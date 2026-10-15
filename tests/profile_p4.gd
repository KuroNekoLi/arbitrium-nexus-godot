extends SceneTree
## GUI-only, finite SceneTree performance profiler. Does NOT replay P4.4 GUI.
## Required output is tagged idle_scene; no automatic player Reaction or damage.
const Metrics = preload("res://tools/qa/p4_profile_metrics.gd")
const DEFAULT_SCENE: String = "res://scenes/battle/battle_screen.tscn"
const SIZES: Array[Vector2i] = [Vector2i(1280,720),Vector2i(1920,1080)]
const UNITS: Dictionary = {"frame_interval_ms":"ms (includes VSync)",
	"script_process_ms":"ms (Performance.TIME_PROCESS)",
	"render_cpu_ms":"ms (viewport render CPU only)",
	"render_gpu_ms":"ms (viewport GPU; null if unavailable)",
	"canvas_draw_calls":"draw calls (2D canvas)",
	"video_memory_bytes":"bytes (GPU, null if unavailable)",
	"texture_memory_bytes":"bytes (GPU, null if unavailable)"}
var _scene_path: String = DEFAULT_SCENE
var _profile: String = "p43_fixture"
var _run_id: String = ""
var _warmup: int = 60
var _samples: int = 180
var _failed: bool = false

func _initialize() -> void:
	call_deferred("_run")

func _fail(reason: String) -> void:
	_failed = true
	push_error("P4_PROFILE_FAIL "+reason)

func _arguments() -> bool:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--scene="):
			_scene_path = arg.trim_prefix("--scene=")
		elif arg.begins_with("--profile="):
			_profile = arg.trim_prefix("--profile=")
		elif arg.begins_with("--run-id="):
			_run_id = arg.trim_prefix("--run-id=")
		elif arg.begins_with("--warmup="):
			_warmup = int(arg.trim_prefix("--warmup="))
		elif arg.begins_with("--samples="):
			_samples = int(arg.trim_prefix("--samples="))
		else:
			_fail("UNKNOWN_ARGUMENT:"+arg)
	if _run_id.is_empty():
		_run_id = "p4_"+str(Time.get_ticks_usec())
	if not Metrics.scoped_run_id(_run_id) or not Metrics.scoped_run_id(_profile):
		_fail("UNSAFE_RUN_ID_OR_PROFILE")
	if not _scene_path.begins_with("res://scenes/battle/") or not _scene_path.ends_with(".tscn") or _scene_path.contains(".."):
		_fail("SCENE_OUTSIDE_APPROVED_SCOPE")
	if not FileAccess.file_exists(_scene_path):
		_fail("SCENE_NOT_FOUND")
	if _warmup < 3 or _warmup > 600 or _samples < 5 or _samples > 1000:
		_fail("INVALID_SAMPLE_LIMITS")
	return not _failed

func _series() -> Dictionary:
	var data: Dictionary = {}
	for key: String in UNITS:
		data[key] = []
	return data

func _sample(viewport: RID, series: Dictionary, interval_ms: float) -> void:
	series["frame_interval_ms"].append(interval_ms)
	var process: float = Performance.get_monitor(Performance.TIME_PROCESS)*1000.0
	series["script_process_ms"].append(process)
	var cpu: float = RenderingServer.viewport_get_measured_render_time_cpu(viewport)
	var gpu: float = RenderingServer.viewport_get_measured_render_time_gpu(viewport)
	series["render_cpu_ms"].append(cpu if cpu > 0.0 else null)
	series["render_gpu_ms"].append(gpu if gpu > 0.0 else null)
	var calls: int = RenderingServer.viewport_get_render_info(viewport,
		RenderingServer.VIEWPORT_RENDER_INFO_TYPE_CANVAS,
		RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME)
	series["canvas_draw_calls"].append(calls if calls > 0 else null)
	var video: float = Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)
	var textures: float = Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)
	series["video_memory_bytes"].append(video if video > 0.0 else null)
	series["texture_memory_bytes"].append(textures if textures > 0.0 else null)

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		_fail("HEADLESS_CANNOT_MEASURE_GPU_OR_CAPTURE")
	if not _arguments():
		quit(1)
		return
	if _failed:
		quit(1)
		return
	var folder: String = "res://outputs/p4_performance/"+_run_id
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(folder)):
		_fail("RUN_ID_ALREADY_EXISTS")
		quit(1)
		return
	var packed: PackedScene = load(_scene_path)
	if packed == null:
		_fail("SCENE_LOAD_FAILED")
		quit(1)
		return
	var metadata: Dictionary = {"status":"IMPLEMENTED_NOT_VERIFIED",
		"scene":_scene_path,"profile":_profile,"mode":"IDLE_SCENE_NOT_GAMEPLAY_REPLAY",
		"godot":Engine.get_version_info(),"os":OS.get_name(),
		"cpu":OS.get_processor_name(),"logical_cores":OS.get_processor_count(),
		"gpu":RenderingServer.get_video_adapter_name(),
		"gpu_api":RenderingServer.get_video_adapter_api_version(),
		"rendering_method":RenderingServer.get_current_rendering_method(),
		"rendering_driver":RenderingServer.get_current_rendering_driver_name(),
		"display_server":DisplayServer.get_name(),
		"vsync_mode":DisplayServer.window_get_vsync_mode(),
		"fps_cap":Engine.max_fps,
		"debug_build":OS.is_debug_build(),
		"warmup_frames":_warmup,"sample_frames":_samples,
		"notes":["VSync affects frame interval; CPU render time excludes script processing.",
			"Null means unavailable, not free GPU work.",
			"Visual stress and authentic combat tape NOT measured."]}
	var reports: Array = []
	for dimensions: Vector2i in SIZES:
		root.size = dimensions
		var scene: Node = packed.instantiate()
		root.add_child(scene)
		var rid: RID = root.get_viewport_rid()
		RenderingServer.viewport_set_measure_render_time(rid,true)
		for i: int in _warmup:
			await process_frame
		var samples: Dictionary = _series()
		var before: int = Time.get_ticks_usec()
		var max_seconds: int = maxi(30,int(ceil(float(_samples)/10.0)))
		var limit_ms: int = Time.get_ticks_msec()+max_seconds*1000
		for i: int in _samples:
			await process_frame
			var now: int = Time.get_ticks_usec()
			_sample(rid,samples,float(now-before)/1000.0)
			before = now
			if Time.get_ticks_msec() > limit_ms:
				_fail("SAMPLE_WALL_TIME_CAP:"+str(dimensions))
				break
		var measured: Dictionary = Metrics.aggregate(samples,UNITS)
		var label: String = str(dimensions.x)+"x"+str(dimensions.y)
		var file_name: String = folder+"/"+label+".png"
		var image: Image = root.get_texture().get_image()
		var capture: Dictionary = {"path":file_name,"width":0,"height":0,"error":""}
		if image == null:
			_fail("SCREENSHOT_IMAGE_UNAVAILABLE:"+label)
			capture["error"] = "NO_IMAGE"
		else:
			capture["width"] = image.get_width()
			capture["height"] = image.get_height()
			if capture["width"] != dimensions.x or capture["height"] != dimensions.y:
				_fail("CAPTURE_SIZE_MISMATCH:"+label)
				capture["error"] = "CAPTURE_SIZE_MISMATCH"
			else:
				var err: Error = DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
				if err != OK or FileAccess.file_exists(file_name):
					_fail("CAPTURE_PATH_UNAVAILABLE:"+label)
					capture["error"] = "CAPTURE_PATH_UNAVAILABLE"
				else:
					err = image.save_png(file_name)
					if err != OK:
						_fail("PNG_WRITE_FAILED:"+label+":"+str(err))
						capture["error"] = "PNG_WRITE_FAILED:"+str(err)
		if not measured["ok"]:
			_fail("METRICS_INVALID:"+str(measured["error"]))
		reports.append({"resolution":label,"capture":capture,"summary":measured,
			"actual_sample_count":samples["frame_interval_ms"].size()})
		RenderingServer.viewport_set_measure_render_time(rid,false)
		scene.queue_free()
		await process_frame
	var output: Dictionary = {"metadata":metadata,"reports":reports,
		"status":"FAILED" if _failed else "MEASURED_PENDING_HUMAN_REVIEW"}
	var saved: Dictionary = Metrics.write_new(folder+"/summary.json",JSON.stringify(output,"  "))
	if not saved["ok"]:
		_fail("METADATA_WRITE:"+str(saved["error"]))
	print("P4_PROFILE_REPORT status=",output["status"]," summaries=",reports.size(),
		" output=",folder," failed=",_failed)
	quit(1 if _failed else 0)
