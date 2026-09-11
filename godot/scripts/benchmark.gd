extends RefCounted
## Capture frame timing, engine counters and graphics allocations separately.
## These counters do not measure macOS total process or unified-memory footprint.
var active := false
var frames: Array[float] = []
var samples: Array[Dictionary] = []
var seconds := 0.0
var sample_clock := 0.0
var start_settings: Dictionary = {}

func begin(settings: Dictionary) -> void:
	frames.clear()
	samples.clear()
	seconds = 0.0
	sample_clock = 0.0
	start_settings = settings.duplicate(true)
	active = true

func tick(delta: float, current_settings: Dictionary) -> void:
	if not active: return
	seconds += delta
	sample_clock += delta
	frames.append(delta*1000)
	if sample_clock >= 1.0:
		sample_clock = 0.0
		samples.append({"seconds":snappedf(seconds,0.01),"fps":Engine.get_frames_per_second(),"engine_static_mib":float(Performance.get_monitor(Performance.MEMORY_STATIC))/1048576.0,"render_video_mib":float(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED))/1048576.0,"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"settings":current_settings.duplicate(true)})

func finish() -> String:
	if not active: return ""
	active = false
	var sorted := frames.duplicate()
	sorted.sort()
	var report := {"schema_version":1,"duration_seconds":seconds,"frames":frames.size(),"average_fps":float(frames.size())/maxf(seconds,0.001),"frame_ms_median":percentile(sorted,0.5),"frame_ms_p95":percentile(sorted,0.95),"frame_ms_p99":percentile(sorted,0.99),"os":OS.get_name(),"processor":OS.get_processor_name(),"renderer":RenderingServer.get_current_rendering_method(),"gpu":RenderingServer.get_video_adapter_name(),"engine":Engine.get_version_info().string,"initial_settings":start_settings,"samples":samples,"memory_note":"Engine static and video counters are separate diagnostics, not total app or unified-memory usage. Validate process footprint and system memory pressure on the target Mac."}
	var folder := "user://benchmarks"
	DirAccess.make_dir_recursive_absolute(folder)
	var stamp := Time.get_datetime_string_from_system().replace(":","-")
	var path := folder+"/miami-"+stamp+".json"
	var file := FileAccess.open(path,FileAccess.WRITE)
	if file == null: return ""
	file.store_string(JSON.stringify(report,"\t")+"\n")
	file.close()
	return ProjectSettings.globalize_path(path)

static func percentile(values: Array[float], fraction: float) -> float:
	if values.is_empty(): return 0.0
	return values[mini(int(ceil(fraction*values.size()))-1,values.size()-1)]
