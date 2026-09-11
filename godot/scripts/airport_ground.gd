extends RefCounted
## Fictional north apron, deliberately clear of the other active runway strips.
## Coordinates: x metres along 26R inbound, y metres to its right (north).
const GATE_COUNT := 10
const TAXI_START := 1550.0
const STOP_OFFSET := 350.0
const LANE_OFFSET := 200.0
const TURN_RADIUS := 55.0

static func gate_station(index: int) -> float:
	return 600.0+90.0*clampi(index,0,GATE_COUNT-1)

static func gate_name(index: int) -> String:
	return "A%d" % (clampi(index,0,GATE_COUNT-1)+1)

static func exit_path() -> PackedVector2Array:
	var points := PackedVector2Array([Vector2(TAXI_START,0),Vector2(1750,0)])
	_arc(points,Vector2(1750,55),-PI/2,0)
	points.append(Vector2(1805,145))
	_arc(points,Vector2(1750,145),0,PI/2)
	return points

static func stand_path(index: int) -> PackedVector2Array:
	var station := gate_station(index)
	var points := PackedVector2Array([Vector2(station+55,200)])
	_arc(points,Vector2(station+55,255),-PI/2,-PI)
	points.append(Vector2(station,STOP_OFFSET))
	return points

static func route(index: int) -> PackedVector2Array:
	var points := exit_path()
	points.append_array(stand_path(index))
	return points

static func _arc(points: PackedVector2Array, center: Vector2, start: float, finish: float) -> void:
	for i in range(1,19):
		var angle := lerpf(start,finish,float(i)/18.0)
		points.append(center+Vector2(cos(angle),sin(angle))*TURN_RADIUS)
