extends RefCounted
## Deterministic assisted arrival, independent of rendering and the Python model.
const Ground = preload("res://scripts/airport_ground.gd")
const START_DISTANCE := 8400.0
const APPROACH_SPEED := 74.6
const TOUCHDOWN_STATION := 320.0
const CONTACT_HEIGHT := 3.16
var phase := "APPROACH"
var station := -START_DISTANCE
var position_2d := Vector2(-START_DISTANCE,0)
var direction_2d := Vector2.RIGHT
var height := 0.0
var pitch_deg := 2.0
var speed_ms := APPROACH_SPEED
var flap_ratio := 0.5
var spoiler_ratio := 0.0
var reverse_ratio := 0.0
var gate_index := 4
var taxi_target_ms := 0.0
var auto_taxi := false
var parking_brake := false
var route := PackedVector2Array()
var route_segment := 0
var route_offset := 0.0
var taxi_remaining := 0.0
var time := 0.0
var touchdown_time := -1.0

func _init() -> void:
	reset()

func reset() -> void:
	phase = "APPROACH"
	station = -START_DISTANCE
	position_2d = Vector2(station,0)
	direction_2d = Vector2.RIGHT
	height = CONTACT_HEIGHT*cos(deg_to_rad(2))+17.4*sin(deg_to_rad(2))+16.0+START_DISTANCE*tan(deg_to_rad(3))
	pitch_deg = 2.0
	speed_ms = APPROACH_SPEED
	flap_ratio = 0.5
	spoiler_ratio = 0.0
	reverse_ratio = 0.0
	taxi_target_ms = 0.0
	auto_taxi = false
	parking_brake = false
	route = Ground.route(gate_index)
	route_segment = 0
	route_offset = 0.0
	taxi_remaining = _route_length()
	time = 0.0
	touchdown_time = -1.0

func select_gate(index: int) -> bool:
	if phase in ["TAXI","PARKED"]: return false
	gate_index = clampi(index,0,Ground.GATE_COUNT-1)
	route = Ground.route(gate_index)
	taxi_remaining = _route_length()
	return true

func skip_to_final() -> void:
	reset()
	station = -900.0
	position_2d = Vector2(station,0)
	height = CONTACT_HEIGHT*cos(deg_to_rad(2))+17.4*sin(deg_to_rad(2))+16.0-station*tan(deg_to_rad(3))
	flap_ratio = 1.0

func tick(delta: float, speed_input: float = 0.0, brake: bool = false) -> void:
	# Bound stalls/background-tab deltas; substeps keep rollout/taxi stable.
	var remaining := clampf(delta,0,0.25)
	while remaining>0.000001:
		var dt := minf(remaining,1.0/60.0)
		_step(dt,speed_input,brake)
		remaining -= dt

func _step(dt: float, speed_input: float, brake: bool) -> void:
	time += dt
	if phase in ["APPROACH","FLARE"]:
		flap_ratio = move_toward(flap_ratio,1.0,dt/12.0)
		station += speed_ms*dt
		position_2d = Vector2(station,0)
		if station<0:
			height = CONTACT_HEIGHT*cos(deg_to_rad(2))+17.4*sin(deg_to_rad(2))+16.0-station*tan(deg_to_rad(3))
		else:
			phase = "FLARE"
			var t := clampf(station/TOUCHDOWN_STATION,0,1)
			var h := (2*t*t*t-3*t*t+1)*16.0+(t*t*t-2*t*t+t)*TOUCHDOWN_STATION*(-tan(deg_to_rad(3)))
			pitch_deg = lerpf(2.0,5.0,smoothstep(0,1,t))
			height = h+CONTACT_HEIGHT*cos(deg_to_rad(pitch_deg))+17.4*sin(deg_to_rad(pitch_deg))
			speed_ms = lerpf(APPROACH_SPEED,65.0,t)
			if station>=TOUCHDOWN_STATION:
				phase = "ROLLOUT"
				touchdown_time = time
				station = TOUCHDOWN_STATION
				position_2d.x = station
	elif phase=="ROLLOUT":
		var age := time-touchdown_time
		spoiler_ratio = move_toward(spoiler_ratio,1,dt*2)
		var reverse_target := 1.0 if age>0.8 and speed_ms>30.0 else 0.0
		reverse_ratio = move_toward(reverse_ratio,reverse_target,dt*1.2)
		pitch_deg = move_toward(pitch_deg,0,dt*1.7)
		height = CONTACT_HEIGHT*cos(deg_to_rad(pitch_deg))+17.4*sin(deg_to_rad(pitch_deg))
		# Brakes plus reverse; integrate speed squared against remaining pavement.
		var decel := speed_ms*speed_ms/(2.0*maxf(Ground.TAXI_START-station,0.01))
		var next_speed := maxf(0,speed_ms-decel*dt)
		station += (speed_ms+next_speed)*0.5*dt
		speed_ms = next_speed
		position_2d = Vector2(station,0)
		if speed_ms<0.3 or station>=Ground.TAXI_START:
			station = Ground.TAXI_START
			position_2d = Vector2(station,0)
			speed_ms = 0
			phase = "TAXI READY"
			pitch_deg = 0
			height = CONTACT_HEIGHT
			reverse_ratio = 0
	elif phase in ["TAXI READY","TAXI"]:
		if brake:
			taxi_target_ms = 0
			auto_taxi = false
		else:
			if absf(speed_input)>0.01: auto_taxi = false
			taxi_target_ms = clampf(taxi_target_ms+speed_input*dt*2.0,0,7.7)
		var target := 7.7 if auto_taxi else taxi_target_ms
		if parking_brake: target = 0
		# Stop smoothly at the selected stand; final turn/stand limited to ~6 kt.
		if route_segment>=route.size()-20: target = minf(target,3.0)
		target = minf(target,sqrt(maxf(0,2.0*0.7*taxi_remaining)))
		speed_ms = move_toward(speed_ms,target,dt*(2.8 if brake else 0.8))
		if speed_ms>0.001:
			phase = "TAXI"
			_advance_route(speed_ms*dt)
		if position_2d.y>75:
			flap_ratio = move_toward(flap_ratio,0,dt/8.0)
			spoiler_ratio = move_toward(spoiler_ratio,0,dt)
		if taxi_remaining<0.05:
			phase = "PARKED"
			speed_ms = 0
			taxi_target_ms = 0
			auto_taxi = false
			parking_brake = true
			flap_ratio = 0
			spoiler_ratio = 0

func _advance_route(distance: float) -> void:
	taxi_remaining = maxf(0,taxi_remaining-distance)
	while distance>0 and route_segment<route.size()-1:
		var a := route[route_segment]
		var b := route[route_segment+1]
		var length := a.distance_to(b)
		var step := minf(distance,length-route_offset)
		route_offset += step
		distance -= step
		position_2d = a.lerp(b,route_offset/length)
		var tangent := (b-a).normalized()
		# Interpolate tangents across short curve segments to avoid yaw steps.
		var following := tangent
		if route_segment+2<route.size(): following = (route[route_segment+2]-b).normalized()
		direction_2d = tangent.lerp(following,route_offset/length).normalized()
		if route_offset>=length-0.00001:
			route_segment += 1
			route_offset = 0
	station = position_2d.x

func _route_length() -> float:
	var length := 0.0
	for i in range(1,route.size()): length += route[i-1].distance_to(route[i])
	return length

func on_ground() -> bool:
	return phase in ["ROLLOUT","TAXI READY","TAXI","PARKED"]
