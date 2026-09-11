extends SceneTree
const Arrival = preload("res://scripts/arrival.gd")
const Ground = preload("res://scripts/airport_ground.gd")
var failures: Array[String] = []

func check(ok: bool, message: String) -> void:
	if not ok and message not in failures: failures.append(message)

func _initialize() -> void:
	for gate in 10:
		var state := Arrival.new()
		state.select_gate(gate)
		state.skip_to_final()
		var saw_reverse := false
		var saw_spoilers := false
		var last_speed := 100.0
		var taxi_tested := false
		for frame in 24000:
			var previous := state.position_2d
			var previous_height := state.height
			state.tick(1.0/30)
			check(state.position_2d.is_finite() and is_finite(state.height),"Finite arrival transforms")
			check(state.position_2d.distance_to(previous)<3,"No teleport between arrival phases")
			check(absf(state.height-previous_height)<0.5,"Continuous flare height")
			check(state.speed_ms>=0,"Never move backwards")
			if state.reverse_ratio>0.1:
				saw_reverse = true
				check(state.on_ground(),"Reverse must stay inhibited in flight")
			if state.spoiler_ratio>0.5: saw_spoilers = true
			if state.phase=="ROLLOUT":
				check(state.speed_ms<=last_speed,"Rollout must decelerate")
				last_speed = state.speed_ms
				var wheels := state.height-Arrival.CONTACT_HEIGHT*cos(deg_to_rad(state.pitch_deg))-17.4*sin(deg_to_rad(state.pitch_deg))
				check(absf(wheels)<0.001,"Main wheels must remain on pavement")
			if state.phase=="TAXI READY":
				check(state.station<2000,"Rollout stops before runway end")
				var stopped := state.position_2d
				for i in 30: state.tick(1.0/30)
				check(state.position_2d==stopped,"Taxi waits for user input")
				state.auto_taxi = true
			if state.phase=="TAXI":
				check(state.speed_ms<=7.701,"Taxi speed capped at 15 knots")
				check(state.position_2d.y>=0,"Taxi stays north of arrival runway")
				check(not state.select_gate((gate+1)%10),"Gate locked during taxi")
				if not taxi_tested and state.speed_ms>4:
					taxi_tested = true
					for i in 90: state.tick(1.0/30,0,true)
					check(state.speed_ms==0 and not state.auto_taxi,"Manual brake overrides auto taxi")
					for i in 90: state.tick(1.0/30,1)
					check(state.speed_ms>0,"User throttle resumes taxi")
					state.parking_brake = true
					for i in 300: state.tick(1.0/30)
					check(state.speed_ms==0,"Parking brake holds aircraft")
					state.parking_brake = false
					state.auto_taxi = true
			if state.phase=="PARKED": break
		check(state.phase=="PARKED","All ten gates reachable")
		check(saw_reverse and saw_spoilers,"Touchdown deploys reverse and spoilers")
		check(state.position_2d.distance_to(Vector2(Ground.gate_station(gate),Ground.STOP_OFFSET))<0.06,"Selected gate stop accuracy")
		check(state.speed_ms==0 and state.parking_brake,"Gate parking stops and sets brake")
		check(state.flap_ratio==0 and state.spoiler_ratio==0,"Landing surfaces stowed at gate")
		state.reset()
		check(state.phase=="APPROACH" and state.reverse_ratio==0 and state.gate_index==gate,"Restart clears arrival state and keeps selected gate")
	if failures.is_empty():
		print("ARRIVAL_TEST_OK: ten gates, flare continuity, wheel contact, reverse, brakes, user throttle, route and restart")
		quit()
	else:
		for message in failures: push_error(message)
		quit(2)
