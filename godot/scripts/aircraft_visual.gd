extends Node3D
## Original procedural A320neo-inspired study, not a production aircraft asset.
const G = preload("res://scripts/geometry.gd")
const Instrument = preload("res://scripts/instrument.gd")
var interior: Node3D
var exterior: Node3D
var instruments: Array[Control] = []
var viewports: Array[SubViewport] = []
var fan_nodes: Array[Node3D] = []
var flap_nodes: Array[Node3D] = []
var spoiler_nodes: Array[Node3D] = []
var reverser_nodes: Array[Node3D] = []

func _ready() -> void:
	_build_interior()
	_build_exterior()

func _build_interior() -> void:
	interior = Node3D.new()
	interior.name = "Cockpit"
	add_child(interior)
	var panel := G.material(Color("48595c"),0.8)
	var dark := G.material(Color("171f23"),0.95)
	var trim := G.material(Color("828c88"),0.6)
	var metal := G.material(Color("81878b"),0.3,0.7)
	var cream := G.material(Color("dad4c3"),0.65)
	G.box(interior,Vector3(3.2,0.08,3.7),Vector3(0,-0.15,0),dark)
	G.box(interior,Vector3(2.85,0.72,0.30),Vector3(0,0.66,-1.36),panel)
	G.box(interior,Vector3(3.0,0.13,0.62),Vector3(0,1.05,-1.30),dark)
	G.box(interior,Vector3(1.15,0.20,0.17),Vector3(0,1.17,-1.27),panel)
	for x in [-0.43,-0.15,0.15,0.43]:
		G.box(interior,Vector3(0.20,0.065,0.012),Vector3(x,1.20,-1.17),dark)
		G.text3d(interior,"145" if x<0 else "03000",Vector3(x,1.20,-1.155),23,Color("efce80"),0.0008)
		var knob := G.cylinder(interior,0.024,0.024,0.025,Vector3(x,1.13,-1.14),cream)
		knob.rotation.x = PI/2
	G.text3d(interior,"SPD      HDG       ALT      V/S",Vector3(0,1.25,-1.17),18,cream.albedo_color,0.0009)
	var kinds := ["pfd","nd","engines","pfd"]
	for i in 4:
		var x: float = [-1.02,-0.48,0.20,0.91][i]
		G.box(interior,Vector3(0.505,0.505,0.05),Vector3(x,0.70,-1.17),dark)
		var viewport := SubViewport.new()
		viewport.size = Vector2i(512,512)
		viewport.disable_3d = true
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		add_child(viewport)
		var instrument := Instrument.new()
		instrument.kind = kinds[i]
		instrument.size = Vector2(512,512)
		viewport.add_child(instrument)
		instruments.append(instrument)
		viewports.append(viewport)
		var screen_mat := StandardMaterial3D.new()
		screen_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		screen_mat.albedo_texture = viewport.get_texture()
		var quad := QuadMesh.new()
		quad.size = Vector2(0.445,0.445)
		G.instance(interior,quad,Vector3(x,0.70,-1.135),screen_mat)
		for side in [-1,1]:
			for y in [0.56,0.69,0.82]:
				G.box(interior,Vector3(0.016,0.024,0.012),Vector3(x+side*0.237,y,-1.13),trim)
	# Windshield framing: large clear openings with a slim center mullion.
	var top := [Vector3(-1.58,2.05,-0.10),Vector3(-1.08,2.40,-1.47),Vector3(0,2.50,-1.56),Vector3(1.08,2.40,-1.47),Vector3(1.58,2.05,-0.10)]
	var bottom := [Vector3(-1.66,1.04,-0.30),Vector3(-1.38,1.10,-1.88),Vector3(0,1.12,-2.02),Vector3(1.38,1.10,-1.88),Vector3(1.66,1.04,-0.30)]
	for i in top.size():
		G.beam(interior,top[i],bottom[i],0.045 if i==2 else 0.065,panel)
		if i<top.size()-1:
			G.beam(interior,top[i],top[i+1],0.11,panel)
			G.beam(interior,bottom[i],bottom[i+1],0.10,dark)
	G.box(interior,Vector3(3.15,0.12,1.80),Vector3(0,2.45,0.06),panel)
	G.box(interior,Vector3(0.62,0.035,1.05),Vector3(0,2.36,-0.08),dark)
	for i in 7:
		for side in [-1,1]:
			G.box(interior,Vector3(0.05,0.02,0.06),Vector3(side*0.16,2.33,-0.48+i*0.13),trim)
	for side in [-1,1]:
		G.box(interior,Vector3(0.28,1.10,2.4),Vector3(side*1.57,0.43,0),panel)
		G.box(interior,Vector3(0.25,0.045,1.5),Vector3(side*1.40,1.0,0),dark)
		# Side stick and captain/first officer armrest.
		G.cylinder(interior,0.035,0.025,0.16,Vector3(side*1.38,1.10,-0.12),dark)
		G.box(interior,Vector3(0.09,0.04,0.12),Vector3(side*1.38,1.20,-0.12),dark)
		G.box(interior,Vector3(0.48,0.13,0.50),Vector3(side*0.66,0.30,0.64),dark)
		G.box(interior,Vector3(0.48,0.70,0.16),Vector3(side*0.66,0.70,0.93),dark)
	G.box(interior,Vector3(0.39,0.60,1.28),Vector3(0,0.20,0.03),panel)
	G.box(interior,Vector3(0.36,0.035,0.84),Vector3(0,0.52,-0.18),dark)
	for side in [-1,1]:
		G.beam(interior,Vector3(side*0.073,0.54,-0.26),Vector3(side*0.073,0.79,-0.42),0.025,metal)
		G.box(interior,Vector3(0.13,0.06,0.08),Vector3(side*0.073,0.79,-0.42),cream)
	G.text3d(interior,"A320neo  /  VISUAL STUDY",Vector3(-0.66,0.34,-1.16),17,cream.albedo_color,0.0012)

func _build_exterior() -> void:
	exterior = Node3D.new()
	exterior.name = "Airframe"
	add_child(exterior)
	var white := G.material(Color("dedfda"),0.36,0.18)
	white.cull_mode = BaseMaterial3D.CULL_DISABLED
	var navy := G.material(Color("235363"),0.55,0.12)
	navy.cull_mode = BaseMaterial3D.CULL_DISABLED
	var dark := G.material(Color("111b21"),0.7)
	var aluminium := G.material(Color("a3a9ab"),0.28,0.75)
	var body := G.cylinder(exterior,1.94,1.94,26.4,Vector3(0,0.4,14.2),white,40)
	body.rotation.x = PI/2
	var nose := SphereMesh.new()
	nose.radius = 1.94
	nose.height = 3.88
	var nose_node := G.instance(exterior,nose,Vector3(0,0.4,1.0),white)
	nose_node.scale = Vector3(1,1,1.8)
	var tail := G.cylinder(exterior,1.94,0.34,7.7,Vector3(0,0.5,31.2),white,40)
	tail.rotation.x = PI/2
	G.profile(exterior,PackedVector2Array([Vector2(25.8,1.8),Vector2(29.5,7.5),Vector2(31.0,7.5),Vector2(33.5,1.8)]),0.22,navy)
	for side in [-1,1]:
		var wing := PackedVector2Array([Vector2(side*1.5,11.5),Vector2(side*17.9,20),Vector2(side*17.9,20.8),Vector2(side*1.5,17.7)])
		G.polygon(exterior,wing,-0.20,white)
		G.box(exterior,Vector3(0.17,1.8,1.35),Vector3(side*17.9,0.60,20.6),navy).rotation.z = side*deg_to_rad(15)
		G.polygon(exterior,PackedVector2Array([Vector2(side*1.0,28),Vector2(side*6.8,31.3),Vector2(side*6.8,32.4),Vector2(side*1.0,31.4)]),1.0,white)
		# Hinged trailing-edge surfaces: flap droops; spoiler rises after touchdown.
		for section in 2:
			var x: float = side*(2.0+section*6.8)
			var z := 17.7+section*1.4
			var flap := Node3D.new()
			exterior.add_child(flap)
			flap.position = Vector3(x,-0.18,z)
			G.polygon(flap,PackedVector2Array([Vector2(0,0),Vector2(side*6.5,1.35),Vector2(side*6.5,2.3),Vector2(0,1.5)]),0,white)
			flap_nodes.append(flap)
			var spoiler := Node3D.new()
			exterior.add_child(spoiler)
			spoiler.position = Vector3(x,0.0,z-1.4)
			G.polygon(spoiler,PackedVector2Array([Vector2(0,0),Vector2(side*5.8,1.2),Vector2(side*5.8,2.0),Vector2(0,0.8)]),0,aluminium)
			spoiler_nodes.append(spoiler)
		# Subtle flap and aileron seams improve the wing inspection view.
		G.beam(exterior,Vector3(side*2.0,-0.16,17.8),Vector3(side*16.2,-0.16,20.7),0.022,aluminium)
		var engine := G.cylinder(exterior,1.2,1.15,2.4,Vector3(side*5.8,-1.55,13.2),white,32)
		engine.rotation.x = PI/2
		var cascade := G.cylinder(exterior,1.08,1.08,1.15,Vector3(side*5.8,-1.55,14.8),dark,24)
		cascade.rotation.x = PI/2
		var sleeve := G.cylinder(exterior,1.16,1.13,1.05,Vector3(side*5.8,-1.55,14.85),white,24)
		sleeve.rotation.x = PI/2
		reverser_nodes.append(sleeve)
		var inlet := G.cylinder(exterior,1.02,1.02,0.06,Vector3(side*5.8,-1.55,11.96),dark,32)
		inlet.rotation.x = PI/2
		var hub := G.cylinder(exterior,0.22,0.0,0.5,Vector3(side*5.8,-1.55,11.7),aluminium,20)
		hub.rotation.x = -PI/2
		var fans := Node3D.new()
		exterior.add_child(fans)
		fans.position = Vector3(side*5.8,-1.55,11.88)
		for i in 18:
			var angle := float(i)*TAU/18
			var blade := G.box(fans,Vector3(0.05,0.75,0.025),Vector3(sin(angle)*0.61,cos(angle)*0.61,0),aluminium)
			blade.rotation.z = -angle+0.18
		fan_nodes.append(fans)
		for i in 25:
			G.box(exterior,Vector3(0.025,0.23,0.17),Vector3(side*1.90,1.10,3.3+i*0.86),navy)
		G.box(exterior,Vector3(0.5,1.1,0.45),Vector3(side*2.2,-2.15,17.4),aluminium)
		for offset in [-0.32,0.32]:
			var wheel := G.cylinder(exterior,0.40,0.40,0.24,Vector3(side*2.2+offset,-2.76,17.4),dark)
			wheel.rotation.z = PI/2
	G.box(exterior,Vector3(0.14,1.1,0.14),Vector3(0,-2.0,2.5),aluminium)
	for x in [-0.18,0.18]:
		var wheel := G.cylinder(exterior,0.29,0.29,0.16,Vector3(x,-2.87,2.5),dark)
		wheel.rotation.z = PI/2

func update_arrival(state: RefCounted, altitude: float, delta: float) -> void:
	for instrument in instruments:
		instrument.altitude_ft = altitude
		instrument.distance_nm = maxf(0,-state.station)/1852.0
		instrument.bank_deg = 0.0
		instrument.speed_knots = state.speed_ms*1.94384
		instrument.phase = state.phase
		instrument.flap_ratio = state.flap_ratio
		instrument.reverse_ratio = state.reverse_ratio
		instrument.spoiler_ratio = state.spoiler_ratio
		instrument.heading_deg = fposmod(267.4-rad_to_deg(state.direction_2d.angle()),360)
	for fan in fan_nodes: fan.rotation.z += delta*(5+state.reverse_ratio*24+state.speed_ms*0.12)
	for flap in flap_nodes: flap.rotation.x = deg_to_rad(35)*state.flap_ratio
	for spoiler in spoiler_nodes: spoiler.rotation.x = -deg_to_rad(55)*state.spoiler_ratio
	for sleeve in reverser_nodes: sleeve.position.z = 14.85+state.reverse_ratio*0.85

func set_cockpit_visible(value: bool) -> void:
	interior.visible = value
	exterior.visible = not value
	for viewport in viewports:
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if value else SubViewport.UPDATE_DISABLED
