extends RefCounted
## Pure benchmark aggregation. Never classify missing measurements as zero.
static func summarize(values: Array, units: String) -> Dictionary:
	if values.is_empty():
		return {"ok":true,"unit":units,"samples":0,"mean":null,"p50":null,
			"p95":null,"peak":null,"missing":0}
	var sorted: Array[float] = []
	var missing: int = 0
	for value: Variant in values:
		if value == null:
			missing += 1
			continue
		if not (value is int or value is float):
			return {"ok":false,"error":"INVALID_TYPE","unit":units}
		var n: float = float(value)
		if is_nan(n) or is_inf(n) or n < 0.0:
			return {"ok":false,"error":"INVALID_MEASUREMENT","unit":units}
		sorted.append(n)
	if sorted.is_empty():
		return {"ok":true,"unit":units,"samples":0,"mean":null,"p50":null,
			"p95":null,"peak":null,"missing":missing}
	sorted.sort()
	var total: float = 0.0
	for n: float in sorted: total += n
	return {"ok":true,"unit":units,"samples":sorted.size(),"missing":missing,
		"mean":total/float(sorted.size()),"p50":percentile(sorted,0.5),
		"p95":percentile(sorted,0.95),"peak":sorted.back()}

static func percentile(sorted: Array[float], fraction: float) -> Variant:
	if sorted.is_empty() or fraction < 0.0 or fraction > 1.0:
		return null
	var k: float = (sorted.size()-1)*fraction
	var a: int = int(floor(k))
	var b: int = int(ceil(k))
	return lerpf(sorted[a],sorted[b],k-float(a))

static func aggregate(samples: Dictionary, units: Dictionary) -> Dictionary:
	var output: Dictionary = {}
	for metric: String in units:
		if not samples.has(metric) or not samples[metric] is Array:
			return {"ok":false,"error":"MISSING_SERIES:"+metric}
		var summary: Dictionary = summarize(samples[metric],str(units[metric]))
		if not summary["ok"]:
			return {"ok":false,"error":str(summary["error"])+":"+metric}
		output[metric] = summary
	return {"ok":true,"metrics":output}

static func scoped_run_id(value: String) -> bool:
	if value.is_empty() or value.length() > 64:
		return false
	for index: int in value.length():
		var ch: String = value[index]
		if not ((ch >= "a" and ch <= "z") or (ch >= "A" and ch <= "Z") or
				(ch >= "0" and ch <= "9") or ch == "-" or ch == "_"):
			return false
	return true

static func write_new(path: String, payload: String) -> Dictionary:
	# Scope and collision guards are applied *before* writing any bytes.
	if not path.begins_with("res://outputs/p4_performance/") or path.contains("..") or path.contains("\\"):
		return {"ok":false,"error":"OUTSIDE_OUTPUT_SCOPE"}
	if FileAccess.file_exists(path):
		return {"ok":false,"error":"ALREADY_EXISTS"}
	var folder: String = ProjectSettings.globalize_path(path.get_base_dir())
	if DirAccess.make_dir_recursive_absolute(folder) != OK:
		return {"ok":false,"error":"DIRECTORY_CREATE_FAILED"}
	var file: FileAccess = FileAccess.open(path,FileAccess.WRITE)
	if file == null:
		return {"ok":false,"error":"FILE_OPEN_FAILED:"+str(FileAccess.get_open_error())}
	file.store_string(payload)
	file.flush()
	var error: Error = file.get_error()
	file.close()
	if error != OK:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		return {"ok":false,"error":"FILE_WRITE_FAILED:"+str(error)}
	return {"ok":true,"error":""}
