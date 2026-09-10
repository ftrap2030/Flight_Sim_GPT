extends Node3D
const World = preload("res://scripts/miami_world.gd")
const Aircraft = preload("res://scripts/aircraft_visual.gd")
const Hud = preload("res://scripts/hud.gd")
const Benchmark = preload("res://scripts/benchmark.gd")
const START_DISTANCE_M := 8400.0
const PREVIEW_SPEED_MS := 74.6
const GLIDESLOPE_DEG := 3.0
var world: Node3D
var aircraft: Node3D
var camera: Camera3D
var environment: Environment
var sun: DirectionalLight3D
var hud: CanvasLayer
var benchmark := Benchmark.new()
var remaining_m := START_DISTANCE_M
var paused := false
var view_index := 0
var quality_index := 1
var lighting_index := 0
var weather_index := 0
var render_scale := 0.85
var elapsed := 0.0
var look_offset := Vector2.ZERO
var capture_path := ""
var capture_after := 4.0
var capture_view := 0
var capture_light := 0
var capture_requested := false
var screenshot_hide_ui := false
var smoke_test := false

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="): capture_path = arg.trim_prefix("--capture=")
		if arg.begins_with("--capture-after="): capture_after = float(arg.trim_prefix("--capture-after="))
		if arg.begins_with("--view="): capture_view = int(arg.trim_prefix("--view="))
		if arg.begins_with("--light="): capture_light = int(arg.trim_prefix("--light="))
		if arg=="--hide-ui": screenshot_hide_ui = true
		if arg=="--smoke-test": smoke_test = true
	world = World.new()
	world.name = "Miami"
	add_child(world)
	_build_environment()
	aircraft = Aircraft.new()
	add_child(aircraft)
	camera = Camera3D.new()
	camera.near = 0.07
	camera.far = 65000.0
	camera.fov = 73
	aircraft.add_child(camera)
	camera.current = true
	hud = Hud.new()
	hud.app = self
	add_child(hud)
	set_quality(1)
	set_lighting(clampi(capture_light,0,2))
	set_weather(0)
	select_view(clampi(capture_view,0,2))
	set_frame_limit(true)
	_update_aircraft(0.0)
	if screenshot_hide_ui: hud.hide()
	if smoke_test: call_deferred("_run_smoke_test")

func _build_environment() -> void:
	sun = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 1300.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.light_angular_distance = 0.6
	add_child(sun)
	environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("426f9e")
	sky_material.sky_horizon_color = Color("bfc6cb")
	sky_material.ground_bottom_color = Color("394742")
	sky_material.ground_horizon_color = Color("bfc6cb")
	sky_material.sky_curve = 0.18
	sky.sky_material = sky_material
	sky.radiance_size = Sky.RADIANCE_SIZE_256
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("a9c1d2")
	environment.ambient_light_energy = 0.58
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	environment.tonemap_exposure = 1.05
	environment.fog_enabled = true
	environment.fog_density = 0.000038
	environment.fog_sky_affect = 0.08
	environment.fog_aerial_perspective = 0.4
	var env_node := WorldEnvironment.new()
	env_node.environment = environment
	add_child(env_node)

func _process(delta: float) -> void:
	elapsed += delta
	if not paused:
		remaining_m -= PREVIEW_SPEED_MS*delta
		if remaining_m < 130.0: remaining_m = START_DISTANCE_M
	_update_aircraft(delta)
	benchmark.tick(delta,settings_snapshot())
	if not capture_path.is_empty() and elapsed>=capture_after and not capture_requested:
		capture_requested = true
		_save_capture.call_deferred()

func _update_aircraft(delta: float) -> void:
	var height := remaining_m*tan(deg_to_rad(GLIDESLOPE_DEG))+16.0
	aircraft.position = world.threshold-world.inbound*remaining_m+Vector3.UP*height
	aircraft.look_at(aircraft.position+world.inbound,Vector3.UP)
	var sway := 0.0 if paused else sin(elapsed*0.42)*0.002
	aircraft.rotate_object_local(Vector3.BACK,sway)
	aircraft.update_preview((aircraft.position.y+1.6)/0.3048,remaining_m/1852,sway*60,delta if not paused else 0.0)
	_update_camera()

func _update_camera() -> void:
	if view_index==0:
		camera.position = Vector3(-0.57,1.65,0.90)
		camera.rotation = Vector3(deg_to_rad(-12)+look_offset.y,look_offset.x,0)
	elif view_index==1:
		camera.position = Vector3(-7,3,18)
		camera.look_at(aircraft.to_global(Vector3(-17,0.2,20)),Vector3.UP)
		camera.rotate_object_local(Vector3.UP,look_offset.x)
		camera.rotate_object_local(Vector3.RIGHT,look_offset.y)
	else:
		camera.position = Vector3(-25,11,54)
		camera.look_at(aircraft.to_global(Vector3(0,0.5,12)),Vector3.UP)
		camera.rotate_object_local(Vector3.UP,look_offset.x)
		camera.rotate_object_local(Vector3.RIGHT,look_offset.y)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_RIGHT:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if event.pressed else Input.MOUSE_MODE_VISIBLE
		if event.pressed and event.button_index==MOUSE_BUTTON_WHEEL_UP: camera.fov = clampf(camera.fov-3,38,85)
		if event.pressed and event.button_index==MOUSE_BUTTON_WHEEL_DOWN: camera.fov = clampf(camera.fov+3,38,85)
	if event is InputEventMouseMotion and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED:
		look_offset.x = clampf(look_offset.x-event.relative.x*0.002,-1.4,1.4)
		look_offset.y = clampf(look_offset.y-event.relative.y*0.002,-0.7,0.6)
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_1: select_view(0)
			KEY_2: select_view(1)
			KEY_3: select_view(2)
			KEY_SPACE: toggle_pause()
			KEY_R: restart()
			KEY_T: set_lighting((lighting_index+1)%3)
			KEY_F1: hud.info_panel.visible = not hud.info_panel.visible
			KEY_H: hud.visible = not hud.visible
			KEY_B: toggle_benchmark()
			KEY_ESCAPE:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				look_offset = Vector2.ZERO

func select_view(index: int) -> void:
	view_index = clampi(index,0,2)
	look_offset = Vector2.ZERO
	aircraft.set_cockpit_visible(view_index==0)
	camera.fov = 73 if view_index==0 else 57
	if hud: hud.update_buttons()

func set_quality(index: int) -> void:
	quality_index = clampi(index,0,2)
	render_scale = [0.65,0.85,1.0][quality_index]
	get_viewport().scaling_3d_scale = render_scale
	get_viewport().msaa_3d = Viewport.MSAA_DISABLED if quality_index==0 else Viewport.MSAA_2X
	sun.directional_shadow_max_distance = [650.0,1300.0,2200.0][quality_index]
	world.set_quality(quality_index)
	if hud: hud.quality_select.select(quality_index)

func set_lighting(index: int) -> void:
	lighting_index = clampi(index,0,2)
	var rotations := [Vector3(-17,-115,0),Vector3(-56,-145,0),Vector3(-3,-100,0)]
	sun.rotation_degrees = rotations[lighting_index]
	sun.light_color = [Color("ffe0ad"),Color("fff6e6"),Color("e4ad97")][lighting_index]
	sun.light_energy = [1.10,1.20,0.45][lighting_index]
	environment.ambient_light_energy = [0.62,0.68,0.43][lighting_index]
	environment.fog_light_color = [Color("c3c0ac"),Color("abbfcd"),Color("7b8fbc")][lighting_index]
	var sky_material := environment.sky.sky_material as ProceduralSkyMaterial
	sky_material.sky_top_color = [Color("426f9e"),Color("386eaa"),Color("182b50")][lighting_index]
	sky_material.sky_horizon_color = [Color("d2b894"),Color("b9cddd"),Color("858ba9")][lighting_index]
	sky_material.ground_horizon_color = sky_material.sky_horizon_color
	world.set_lighting([0.05,0.0,0.85][lighting_index],[Color("fff0d5"),Color("edf5ff"),Color("9aabd0")][lighting_index])
	if hud: hud.lighting_select.select(lighting_index)

func set_weather(index: int) -> void:
	weather_index = clampi(index,0,2)
	world.cloud_material.set_shader_parameter("coverage",[0.5,0.05,0.88][weather_index])
	environment.fog_density = [0.000038,0.000024,0.000065][weather_index]
	if hud: hud.cloud_select.select(weather_index)

func set_frame_limit(enabled: bool) -> void:
	Engine.max_fps = 30 if enabled else 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if enabled else DisplayServer.VSYNC_DISABLED)

func toggle_pause() -> void:
	paused = not paused
	hud.update_buttons()

func restart() -> void:
	remaining_m = START_DISTANCE_M
	look_offset = Vector2.ZERO
	hud.notify("Approach restarted")

func settings_snapshot() -> Dictionary:
	return {"quality":quality_index,"scale":render_scale,"view":view_index,"lighting":lighting_index,"weather":weather_index,"fps_limit":Engine.max_fps,"paused":paused}

func toggle_benchmark() -> void:
	if benchmark.active:
		var path := benchmark.finish()
		hud.notify("Benchmark saved — open the reports folder" if not path.is_empty() else "Could not save benchmark")
		print("BENCHMARK_REPORT: ",path)
	else:
		benchmark.begin(settings_snapshot())
		hud.notify("Recording frame times and engine counters")

func open_benchmark_folder() -> void:
	DirAccess.make_dir_recursive_absolute("user://benchmarks")
	OS.shell_open(ProjectSettings.globalize_path("user://benchmarks"))

func _save_capture() -> void:
	await RenderingServer.frame_post_draw
	var error := get_viewport().get_texture().get_image().save_png(capture_path)
	if error!=OK:
		push_error("Screenshot could not be saved: "+capture_path)
		get_tree().quit(2)
	else:
		print("CAPTURE_SAVED: ",capture_path)
		get_tree().quit()

func _run_smoke_test() -> void:
	await get_tree().process_frame
	var failures: Array[String] = []
	if world.airport.runways.size()!=4: failures.append("Expected four data-backed runway pairs")
	if absf(world.inbound.length()-1.0)>0.001: failures.append("Approach direction is not normalized")
	if world.threshold.y<2.0: failures.append("Runway elevation is missing")
	for i in 3:
		select_view(i)
		set_quality(i)
		set_lighting(i)
		set_weather(i)
		_update_aircraft(0.02)
		if not camera.global_position.is_finite(): failures.append("Invalid camera transform")
		if aircraft.interior.visible != (i==0): failures.append("Cockpit visibility is wrong")
		if world.city.multimesh.visible_instance_count>world.city.multimesh.instance_count: failures.append("Invalid instance count")
	toggle_pause()
	var before := remaining_m
	_process(0.1)
	if remaining_m!=before: failures.append("Pause did not freeze approach position")
	toggle_pause()
	_process(0.1)
	if remaining_m>=before: failures.append("Approach did not advance")
	restart()
	if remaining_m!=START_DISTANCE_M: failures.append("Restart did not restore distance")
	var fixture := Benchmark.new()
	fixture.begin(settings_snapshot())
	for i in 120: fixture.tick(1.0/30.0,settings_snapshot())
	var report_path := fixture.finish()
	if report_path.is_empty(): failures.append("Benchmark report was not saved")
	else:
		var report: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(report_path))
		if absf(float(report.average_fps)-30.0)>0.01: failures.append("Benchmark FPS calculation failed")
		if report.frames!=120: failures.append("Benchmark frame count failed")
		DirAccess.remove_absolute(report_path)
	if failures.is_empty():
		print("MIAMI_SMOKE_TEST_OK: runways, cameras, presets, pause, restart, benchmark")
		get_tree().quit()
	else:
		for message in failures: push_error(message)
		get_tree().quit(2)
