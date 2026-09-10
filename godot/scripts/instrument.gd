extends Control
## Preview instruments follow the camera demonstration, not the Python simulator.
var kind := "pfd"
var altitude_ft := 1400.0
var distance_nm := 4.5
var bank_deg := 0.0
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
	label_at("SPEED   G/S     LOC     DEMO",Vector2(22,35),23,GREEN)
	draw_rect(Rect2(104,100,304,270),Color("235376"))
	draw_rect(Rect2(104,228+bank_deg,304,142-bank_deg),Color("745440"))
	draw_line(Vector2(104,228+bank_deg),Vector2(408,228-bank_deg),WHITE,2)
	for offset in [-80,-40,40,80]:
		var width := 32.0 if absi(offset)==40 else 46.0
		draw_line(Vector2(256-width,228+offset),Vector2(256+width,228+offset),WHITE,2)
		label_at(str(absi(offset)/4),Vector2(270+width,235+offset),17)
	draw_line(Vector2(168,229),Vector2(228,229),Color("ffe588"),5)
	draw_line(Vector2(284,229),Vector2(344,229),Color("ffe588"),5)
	draw_line(Vector2(256,212),Vector2(256,246),Color("ffe588"),4)
	draw_line(Vector2(204,222),Vector2(308,222),Color("ee72da"),2)
	draw_line(Vector2(251,180),Vector2(251,275),Color("ee72da"),2)
	draw_rect(Rect2(18,102,77,270),Color("1c292f"))
	draw_rect(Rect2(418,102,82,270),Color("1c292f"))
	for i in range(-3,4):
		var y := 238.0+i*36
		label_at(str(145-i*10),Vector2(23,y),21)
		label_at(str(int(altitude_ft/100)*100-i*100),Vector2(420,y),19)
	draw_rect(Rect2(12,209,84,40),Color("050b10"))
	draw_rect(Rect2(12,209,84,40),Color("ffe588"),false,2)
	label_at("145",Vector2(28,238),29,GREEN)
	draw_rect(Rect2(414,209,96,40),Color("050b10"))
	draw_rect(Rect2(414,209,96,40),Color("ffe588"),false,2)
	label_at(str(int(altitude_ft)),Vector2(421,238),27,GREEN)
	label_at("RADIO  %04d" % int(maxf(0,altitude_ft-8)),Vector2(164,403),22,GREEN)
	label_at("260       267       280",Vector2(118,444),23)
	label_at("QNH 1013",Vector2(346,487),21,CYAN)
	label_at("CAT I",Vector2(28,487),21)

func _navigation() -> void:
	label_at("GS 145   TAS 145",Vector2(20,34),22)
	label_at("TRK 267 MAG",Vector2(290,34),21,GREEN)
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
			draw_arc(Vector2(x,y),65,deg_to_rad(140),deg_to_rad(310),50,GREEN,4)
			draw_line(Vector2(x,y),Vector2(x+40,y-45),GREEN,3)
			label_at("54.2" if row==0 else "620",Vector2(x-29,y+30),28,GREEN)
	label_at("N1",Vector2(243,94),23)
	label_at("EGT",Vector2(235,261),23)
	label_at("FOB     6 400 KG",Vector2(116,439),26,GREEN)
	label_at("GEAR DOWN    FLAPS FULL",Vector2(50,480),21,GREEN)
