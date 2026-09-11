extends Control
## Preview instruments follow the camera demonstration, not the Python simulator.
const Ground = preload("res://scripts/airport_ground.gd")
var pitch_deg := 2.0
var radio_height_ft := 0.0
var gate_index := 4
var ground_position := Vector2.ZERO
var ground_direction := Vector2.RIGHT
var taxi_remaining := 0.0
var kind := "pfd"
var altitude_ft := 1400.0
var distance_nm := 4.5
var bank_deg := 0.0
var speed_knots := 145.0
var heading_deg := 267.4
var phase := "APPROACH"
var flap_ratio := 1.0
var reverse_ratio := 0.0
var spoiler_ratio := 0.0
var elapsed := 0.0
var font: Font
const GREEN := Color("71f8ad")
const WHITE := Color("edf7ff")
const CYAN := Color("6bcce7")

func _ready() -> void:
	font = ThemeDB.fallback_font

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= 0.1:
		elapsed = 0.0
		queue_redraw()

func label_at(text: String, at: Vector2, size_px: int = 22, color: Color = WHITE) -> void:
	draw_string(font,at,text,HORIZONTAL_ALIGNMENT_LEFT,-1,size_px,color)

func _draw() -> void:
	if font == null: return
	draw_rect(Rect2(0,0,512,512),Color("061015"))
	if kind == "pfd": _pfd()
	elif kind == "nd": _navigation()
	else: _engines()

func _pfd() -> void:
	label_at(phase+"   /   ASSIST",Vector2(22,35),23,GREEN)
	draw_rect(Rect2(104,100,304,270),Color("235376"))
	var horizon := clampf(228+pitch_deg*5.0,110,360)
	draw_rect(Rect2(104,horizon,304,370-horizon),Color("745440"))
	draw_line(Vector2(104,horizon),Vector2(408,horizon),WHITE,2)
	for offset in [-80,-40,40,80]:
		var width := 32.0 if absi(offset)==40 else 46.0
		draw_line(Vector2(256-width,horizon+offset),Vector2(256+width,horizon+offset),WHITE,2)
		label_at(str(absi(offset)/4),Vector2(270+width,horizon+7+offset),17)
	draw_line(Vector2(168,229),Vector2(228,229),Color("ffe588"),5)
	draw_line(Vector2(284,229),Vector2(344,229),Color("ffe588"),5)
	draw_line(Vector2(256,212),Vector2(256,246),Color("ffe588"),4)
	draw_line(Vector2(204,222),Vector2(308,222),Color("ee72da"),2)
	draw_line(Vector2(251,180),Vector2(251,275),Color("ee72da"),2)
	draw_rect(Rect2(18,102,77,270),Color("1c292f"))
	draw_rect(Rect2(418,102,82,270),Color("1c292f"))
	for i in range(-3,4):
		var y := 238.0+i*36
		label_at(str(maxi(0,int(speed_knots)-i*10)),Vector2(23,y),21)
		label_at(str(int(altitude_ft/100)*100-i*100),Vector2(420,y),19)
	draw_rect(Rect2(12,209,84,40),Color("050b10"))
	draw_rect(Rect2(12,209,84,40),Color("ffe588"),false,2)
	label_at(str(int(speed_knots)),Vector2(28,238),29,GREEN)
	draw_rect(Rect2(414,209,96,40),Color("050b10"))
	draw_rect(Rect2(414,209,96,40),Color("ffe588"),false,2)
	label_at(str(int(altitude_ft)),Vector2(421,238),27,GREEN)
	label_at("RADIO  %04d" % int(radio_height_ft),Vector2(164,403),22,GREEN)
	label_at("HDG       %03d" % int(heading_deg),Vector2(118,444),23)
	label_at("QNH 1013",Vector2(346,487),21,CYAN)
	label_at("CAT I",Vector2(28,487),21)

func _navigation() -> void:
	if phase in ["ROLLOUT","TAXI READY","TAXI","PARKED"]:
		_ground_map()
		return
	label_at("GS %03d KT" % int(speed_knots),Vector2(20,34),22)
	label_at("HDG %03d" % int(heading_deg),Vector2(290,34),21,GREEN)
	var center := Vector2(256,390)
	for radius in [105.0,210.0,315.0]:
		draw_arc(center,radius,PI,TAU,80,Color("526768"),1.3)
	for degrees in range(-80,81,10):
		var angle := deg_to_rad(degrees-90)
		var outer := center+Vector2(cos(angle),sin(angle))*315
		var inner := center+Vector2(cos(angle),sin(angle))*301
		draw_line(inner,outer,WHITE,2)
	draw_line(center,Vector2(256,98),GREEN,3)
	draw_rect(Rect2(245,123,22,58),WHITE,false,2)
	label_at("KMIA 26R",Vector2(278,145),23,GREEN)
	draw_colored_polygon(PackedVector2Array([center+Vector2(0,-19),center+Vector2(-13,13),center+Vector2(0,6),center+Vector2(13,13)]),Color("ffe588"))
	label_at("DIST   %.1f NM" % distance_nm,Vector2(24,470),24,GREEN)
	label_at("10",Vector2(270,191),19)
	label_at("VISUAL PREVIEW",Vector2(292,497),16,CYAN)

func _engines() -> void:
	label_at("ENGINES",Vector2(192,38),24)
	for i in 2:
		var x := 146.0+i*220
		for row in 2:
			var y := 146.0+row*163
			draw_arc(Vector2(x,y),65,deg_to_rad(140),deg_to_rad(400),60,Color("899fa1"),3)
			var value := (22+reverse_ratio*48) if row==0 else (350+reverse_ratio*270)
			var fraction := value/(100.0 if row==0 else 900.0)
			var angle := deg_to_rad(140+fraction*260)
			draw_arc(Vector2(x,y),65,deg_to_rad(140),angle,50,GREEN,4)
			draw_line(Vector2(x,y),Vector2(x,y)+Vector2(cos(angle),sin(angle))*58,GREEN,3)
			label_at(("%.1f" % (22+reverse_ratio*48)) if row==0 else str(int(350+reverse_ratio*270)),Vector2(x-29,y+30),28,GREEN)
	label_at("N1",Vector2(243,94),23)
	label_at("EGT",Vector2(235,261),23)
	label_at("FOB     6 400 KG",Vector2(116,439),26,GREEN)
	label_at("FLAPS %d%%   SPLR %d%%" % [int(flap_ratio*100),int(spoiler_ratio*100)],Vector2(50,480),21,GREEN)
	if reverse_ratio>0.1: label_at("REV         REV",Vector2(96,76),23,GREEN)
	elif phase=="PARKED": label_at("PARKING BRAKE",Vector2(120,76),23,GREEN)

func _map_point(p: Vector2) -> Vector2:
	return Vector2(492-p.x*0.22,428-p.y*0.75)

func _ground_map() -> void:
	label_at("AIRPORT / NORTH APRON",Vector2(20,34),23,CYAN)
	label_at("GS %02d KT" % int(speed_knots),Vector2(20,67),21,GREEN)
	label_at("GATE A%d" % (gate_index+1),Vector2(327,67),21,GREEN)
	draw_rect(Rect2(49,102,340,55),Color("233b45"))
	for i in 10:
		var stand := _map_point(Vector2(Ground.gate_station(i),350))
		draw_line(stand,_map_point(Vector2(Ground.gate_station(i),200)),Color("4b6466"),2)
		label_at(str(i+1),stand+Vector2(-5,-15),18,GREEN if i==gate_index else WHITE)
	draw_line(Vector2(492,428),Vector2(42,428),Color("667273"),12)
	label_at("26R",Vector2(444,409),20)
	var route := Ground.route(gate_index)
	for i in range(1,route.size()): draw_line(_map_point(route[i-1]),_map_point(route[i]),GREEN,3,true)
	var at := _map_point(ground_position)
	var direction := Vector2(-ground_direction.x, -ground_direction.y).normalized()
	var side := direction.orthogonal()
	draw_colored_polygon(PackedVector2Array([at+direction*11,at-direction*7+side*7,at-direction*7-side*7]),Color("ffe588"))
	label_at("%.0f M TO STAND" % taxi_remaining,Vector2(22,483),22,GREEN)
	label_at("ASSIST",Vector2(391,483),18,CYAN)
