extends Node3D
## Meter-based local map: +X east, -Z north. Runways are data-backed;
## coastline, terminals and buildings are explicitly approximate art proxies.
const Ground = preload("res://scripts/airport_ground.gd")
var selected_route: MultiMeshInstance3D
var gate_nodes: Array[Label3D] = []
var scenery_detail: MultiMeshInstance3D
var land_polygons: Array[PackedVector2Array] = []
var land_bounds: Array[Rect2] = []
const G = preload("res://scripts/geometry.gd")
var airport: Dictionary
var threshold := Vector3.ZERO
var inbound := Vector3.LEFT
var city: MultiMeshInstance3D
var facade: ShaderMaterial
var cloud_material: ShaderMaterial
var paint_transforms: Array[Transform3D] = []
var light_transforms: Array[Transform3D] = []
var building_transforms: Array[Transform3D] = []
var building_colors: Array[Color] = []

func _ready() -> void:
	airport = JSON.parse_string(FileAccess.get_file_as_string("res://data/miami_airport.json"))
	_build_land()
	_build_airport()
	_build_ground_network()
	_build_city()
	_build_coastal_details()
	_build_airport_details()
	_build_landmarks()
	_build_clouds()

func geo(latitude: float, longitude: float) -> Vector3:
	var latitude_origin: float = airport.origin_latitude
	return Vector3((longitude-float(airport.origin_longitude))*111320.0*cos(deg_to_rad(latitude_origin)), 2.44, -(latitude-latitude_origin)*111320.0)

func coast_x(z: float) -> float:
	return 9800.0 + 500.0*sin(z/3700.0) + 240.0*sin(z/1100.0)

func _build_land() -> void:
	var ocean_mat := ShaderMaterial.new()
	ocean_mat.shader = preload("res://shaders/water.gdshader")
	var plane := PlaneMesh.new()
	plane.size = Vector2(100000,100000)
	G.instance(self,plane,Vector3(0,-0.8,0),ocean_mat).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var land_mat := ShaderMaterial.new()
	land_mat.shader = preload("res://shaders/ground.gdshader")
	var coast: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/miami_coast.json"))
	var shoals: Array[Transform3D] = []
	var beaches: Array[Transform3D] = []
	for row in coast.polygons:
		var outline := PackedVector2Array()
		for point in row.outer: outline.append(Vector2(point[0],point[1]))
		land_polygons.append(outline)
		var bounds := Rect2(outline[0],Vector2.ZERO)
		for point in outline: bounds = bounds.expand(point)
		land_bounds.append(bounds)
		G.polygon(self,outline,0.0,land_mat)
		for i in outline.size():
			var a := Vector3(outline[i].x,-0.65,outline[i].y)
			var b := Vector3(outline[(i+1)%outline.size()].x,-0.65,outline[(i+1)%outline.size()].y)
			if a.distance_to(b)<0.1: continue
			var basis := Basis.looking_at(b-a,Vector3.UP)
			shoals.append(Transform3D(basis.scaled(Vector3(160,0.05,a.distance_to(b))),(a+b)/2))
			var center := (a+b)/2
			# Sand only along the ocean-facing barrier shore, not all bay edges.
			if center.x>14200 and center.x<17000 and center.z>-9000 and center.z<6500:
				beaches.append(Transform3D(basis.scaled(Vector3(42,0.08,a.distance_to(b))),center+Vector3.UP*0.75))
	var shallow := ocean_mat.duplicate() as ShaderMaterial
	shallow.set_shader_parameter("deep_color",Color("377f85"))
	shallow.set_shader_parameter("shallow_color",Color("64aaa3"))
	_batch(shoals,shallow,"CoastalShallows")
	_batch(beaches,G.material(Color("d0c5a5")),"AtlanticBeach")
	# Original port island detail supplements the generalized coastline.
	var port := PackedVector2Array([Vector2(10300,2100),Vector2(12900,2050),Vector2(13000,2700),Vector2(10600,3100)])
	land_polygons.append(port)
	land_bounds.append(Rect2(10300,2050,2700,1050))
	G.polygon(self,port,0.7,_pavement(Color("8e9896"),true))

func _is_land(x: float, z: float) -> bool:
	var point := Vector2(x,z)
	for i in land_polygons.size():
		if land_bounds[i].has_point(point) and Geometry2D.is_point_in_polygon(point,land_polygons[i]): return true
	return false

func _build_airport() -> void:
	var grass := G.material(Color("525b38"))
	G.box(self,Vector3(5400,1.8,3100),Vector3(-200,1.0,0),grass)
	var asphalt := _pavement(Color("42494a"),false)
	var concrete := _pavement(Color("979c96"),true)
	G.box(self,Vector3(3300,0.15,920),Vector3(-200,2.0,330),concrete)
	for row in airport.runways:
		var start := geo(float(row.le_latitude_deg),float(row.le_longitude_deg))
		var end := geo(float(row.he_latitude_deg),float(row.he_longitude_deg))
		var direction := (end-start).normalized()
		var length := start.distance_to(end)
		var width := float(row.width_ft)*0.3048
		var strip := Node3D.new()
		add_child(strip)
		strip.position = start
		strip.look_at(end,Vector3.UP)
		var runway_mat := _pavement(Color("41484b"),false)
		runway_mat.set_shader_parameter("runway",true)
		runway_mat.set_shader_parameter("threshold",end)
		runway_mat.set_shader_parameter("inbound",-direction)
		G.box(strip,Vector3(width,0.10,length),Vector3(0,0,-length/2),runway_mat)
		# Taxiway proxy, outside the runway strip.
		G.box(strip,Vector3(22,0.08,length*0.9),Vector3(-width-65,-0.12,-length/2),asphalt)
		for offset in range(130,int(length)-130,65):
			_paint(strip,Vector3(1.0,0.025,30),Vector3(0,0.08,-offset))
		for side in [-1.0,1.0]:
			_paint(strip,Vector3(0.6,0.025,length-25),Vector3(side*(width/2-1),0.09,-length/2))
			for offset in range(0,int(length),55):
				light_transforms.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.6,0.35,0.6)),strip.to_global(Vector3(side*(width/2+2),0.18,-offset))))
		for reverse in [false,true]:
			var markings := Node3D.new()
			strip.add_child(markings)
			if reverse:
				markings.position.z = -length
				markings.rotation.y = PI
			var displacement: float = float(row.he_displaced_threshold_ft if reverse else row.le_displaced_threshold_ft)*0.3048
			markings.position += -markings.basis.z*displacement
			for i in range(-4,4):
				_paint(markings,Vector3(1.65,0.025,28),Vector3(float(i)*3.1+1.55,0.11,-25))
			for side in [-1.0,1.0]:
				_paint(markings,Vector3(5.5,0.025,42),Vector3(side*12,0.11,-310))
			var label := G.text3d(markings,str(row.he_ident if reverse else row.le_ident),Vector3(0,0.14,-82),48,Color("f3f1dc"),0.26)
			label.rotation.x = -PI/2
		if row.he_ident == "26R":
			threshold = end
			inbound = -direction
	# All paint and lamps are instanced, avoiding hundreds of draw calls.
	_batch(paint_transforms,G.material(Color("e3e3d7")),"RunwayPaint")
	var lamp := G.material(Color("fff4bd"))
	lamp.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	lamp.emission_enabled = true
	lamp.emission = Color("fff4bd")
	lamp.emission_energy_multiplier = 3.0
	_batch(light_transforms,lamp,"RunwayLights")
	var walls := G.material(Color("afb3b3"),0.75)
	var glass := G.material(Color("233e4d"),0.22,0.4)
	for x in [-1200,-600,0,600,1200]:
		G.box(self,Vector3(420,18,110),Vector3(x,11,310),walls)
		G.box(self,Vector3(390,7,112),Vector3(x,15,310),glass)
		for z in [120,500]:
			G.box(self,Vector3(54,12,320),Vector3(x,8,z),walls)
	G.cylinder(self,13,10,70,Vector3(-320,37,840),walls)
	G.cylinder(self,22,27,12,Vector3(-320,76,840),glass,12)
	G.cylinder(self,29,29,3,Vector3(-320,83,840),walls,12)

func _paint(parent: Node3D, size: Vector3, at: Vector3) -> void:
	paint_transforms.append(Transform3D(parent.global_basis.scaled(size),parent.to_global(at)))

func _batch(transforms: Array[Transform3D], material: Material, label: String) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = BoxMesh.new()
	mm.instance_count = transforms.size()
	for i in transforms.size(): mm.set_instance_transform(i,transforms[i])
	var node := MultiMeshInstance3D.new()
	node.name = label
	node.multimesh = mm
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)
	return node

func _build_city() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 260910
	facade = ShaderMaterial.new()
	facade.shader = preload("res://shaders/facade.gdshader")
	# A skyline cluster with original silhouettes; these are not surveyed buildings.
	for i in 130:
		var x := rng.randf_range(7300,9650)
		var z := rng.randf_range(1900,6500)
		if not _is_land(x,z): continue
		var height := rng.randf_range(38,200)
		_add_building(Vector3(x,height/2,z),Vector3(rng.randf_range(23,55),height,rng.randf_range(20,52)),rng.randf())
	# Distributed buildings are interleaved, so reducing visible count preserves coverage.
	for i in 20000:
		var x := rng.randf_range(-11000,14500)
		var z := rng.randf_range(-12500,14500)
		if i%2==0:
			x = rng.randf_range(3100,9800)
			z = rng.randf_range(-5500,9500)
		if not _is_land(x,z): continue
		if absf(x+200)<2950 and absf(z)<1800: continue
		x = floorf(x/155)*155+77.5+rng.randf_range(-34,34)
		z = floorf(z/155)*155+77.5+rng.randf_range(-34,34)
		if not _is_land(x,z): continue
		var height := rng.randf_range(5,23)
		if x>13600: height = rng.randf_range(15,100)
		_add_building(Vector3(x,height/2,z),Vector3(rng.randf_range(22,65),height,rng.randf_range(22,65)),rng.randf())
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = BoxMesh.new()
	mm.instance_count = building_transforms.size()
	for i in building_transforms.size():
		mm.set_instance_transform(i,building_transforms[i])
		mm.set_instance_color(i,building_colors[i])
	city = MultiMeshInstance3D.new()
	city.multimesh = mm
	city.material_override = facade
	city.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(city)

func _add_building(at: Vector3, size: Vector3, tone: float) -> void:
	building_transforms.append(Transform3D(Basis.IDENTITY.scaled(size),at))
	building_colors.append(Color(tone,0.6,0.7,1))

func _build_coastal_details() -> void:
	var bridge := G.material(Color("a6aba7"))
	for z in [900,2300,-6500]:
		G.box(self,Vector3(4400,5,26),Vector3(11900,8,z),bridge)
		for x in range(9900,14000,240):
			G.box(self,Vector3(10,10,10),Vector3(x,2,z),bridge)
	# Distant port cranes: repeated original steel structures.
	var steel := G.material(Color("5e858b"),0.65,0.25)
	for i in 8:
		var x := 10300.0+i*130.0
		for side in [-1,1]:
			G.beam(self,Vector3(x+side*24,0,2800),Vector3(x+side*18,75,2800),5,steel)
		G.beam(self,Vector3(x,76,2720),Vector3(x,76,2970),5,steel)
		G.beam(self,Vector3(x,76,2800),Vector3(x,115,2810),4,steel)
		G.beam(self,Vector3(x,115,2810),Vector3(x,76,2950),1.8,steel)

func _build_clouds() -> void:
	cloud_material = ShaderMaterial.new()
	cloud_material.shader = preload("res://shaders/clouds.gdshader")
	var plane := PlaneMesh.new()
	plane.size = Vector2(75000,75000)
	G.instance(self,plane,Vector3(0,1700,0),cloud_material).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func set_quality(level: int) -> void:
	var counts := [4000,10000,building_transforms.size()]
	city.multimesh.visible_instance_count = mini(counts[level],building_transforms.size())

func set_lighting(night_amount: float, cloud_tint: Color) -> void:
	facade.set_shader_parameter("night_amount",night_amount)
	cloud_material.set_shader_parameter("tint",cloud_tint)

func ground_point(point: Vector2, height: float = 0.0) -> Vector3:
	return threshold+inbound*point.x+inbound.cross(Vector3.UP)*point.y+Vector3.UP*(0.06+height)

func _ground_line(transforms: Array[Transform3D], a: Vector2, b: Vector2, width: float, y: float, thickness: float = 0.025) -> void:
	var start := ground_point(a,y)
	var end := ground_point(b,y)
	var basis := Basis.looking_at(end-start,Vector3.UP)
	transforms.append(Transform3D(basis.scaled(Vector3(width,thickness,start.distance_to(end)+0.04)),(start+end)/2))

func _build_ground_network() -> void:
	var pavement: Array[Transform3D] = []
	var yellow: Array[Transform3D] = []
	var blue: Array[Transform3D] = []
	var paths: Array[PackedVector2Array] = [Ground.exit_path(),PackedVector2Array([Vector2(500,200),Vector2(1750,200)])]
	for i in Ground.GATE_COUNT: paths.append(Ground.stand_path(i))
	for path in paths:
		for i in range(1,path.size()):
			_ground_line(pavement,path[i-1],path[i],28,-0.04,0.08)
			_ground_line(yellow,path[i-1],path[i],0.35,0.06)
			var length := path[i-1].distance_to(path[i])
			var normal := (path[i]-path[i-1]).normalized().orthogonal()*14
			for step in range(0,int(length),28):
				for side in [-1,1]:
					var point: Vector2 = path[i-1].lerp(path[i],float(step)/length)+normal*side
					blue.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.4,0.3,0.4)),ground_point(point,0.2)))
	_batch(pavement,_pavement(Color("454e50"),false),"TaxiwayPavement")
	_batch(yellow,G.material(Color("efc64d")),"TaxiCenterlines")
	var lamp := G.material(Color("488dfc"))
	lamp.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_batch(blue,lamp,"TaxiEdgeLights")
	var apron := Node3D.new()
	add_child(apron)
	apron.position = ground_point(Vector2.ZERO,-0.07)
	apron.look_at(apron.position+inbound,Vector3.UP)
	var concrete := _pavement(Color("9c9e94"),true)
	var wall := G.material(Color("c1c5bd"),0.75)
	var glass := G.material(Color("284955"),0.28,0.3)
	G.box(apron,Vector3(235,0.08,1100),Vector3(297.5,0,-1030),concrete)
	G.box(apron,Vector3(90,18,1080),Vector3(450,9,-1030),wall)
	G.box(apron,Vector3(2,9,1040),Vector3(404,11,-1030),glass)
	G.box(apron,Vector3(98,1.2,1090),Vector3(448,18.5,-1030),wall)
	var marking: Array[Transform3D] = []
	for i in Ground.GATE_COUNT:
		var station := Ground.gate_station(i)
		_ground_line(marking,Vector2(station-8,350),Vector2(station+8,350),0.65,0.08)
		# Lead-in lines and stop bars are shared with the actual guidance route.
		var label := G.text3d(self,Ground.gate_name(i),ground_point(Vector2(station,400),13),64,Color("a9e2c4"),0.15)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		gate_nodes.append(label)
		G.box(apron,Vector3(42,3.2,3.8),Vector3(382,4.5,-station-7),glass)
		G.box(apron,Vector3(4.5,4,7),Vector3(360,4.5,-station-4),wall)
		G.box(apron,Vector3(0.8,4,0.8),Vector3(365,2,-station-7),wall)
		# Stand boundaries, kept well outside the 36 m wingspan.
		for side in [-1,1]:
			_ground_line(marking,Vector2(station+side*29,290),Vector2(station+side*29,380),0.22,0.08)
	_batch(marking,G.material(Color("eddda3")),"GateStandPaint")
	var route_material := G.material(Color("a9e2c4"))
	route_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	selected_route = _batch([],route_material,"SelectedTaxiRoute")
	select_gate(4)

func select_gate(index: int) -> void:
	var path := Ground.route(index)
	var transforms: Array[Transform3D] = []
	for i in range(1,path.size()):
		var length := path[i-1].distance_to(path[i])
		for step in range(0,int(ceil(length)),12):
			var a := path[i-1].lerp(path[i],float(step)/length)
			var b := path[i-1].lerp(path[i],minf(float(step)+5,length)/length)
			_ground_line(transforms,a,b,0.8,0.11)
	selected_route.multimesh.instance_count = transforms.size()
	for i in transforms.size(): selected_route.multimesh.set_instance_transform(i,transforms[i])
	for i in gate_nodes.size(): gate_nodes[i].modulate = Color("a9e2c4") if i==index else Color("e4e5dc")

func _pavement(color: Color, concrete: bool) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/pavement.gdshader")
	material.set_shader_parameter("base_color",color)
	material.set_shader_parameter("concrete",concrete)
	return material

func _taxi_sign(at: Vector2, text: String, mandatory: bool = false) -> void:
	var node := Node3D.new()
	add_child(node)
	node.position = ground_point(at,1.1)
	node.look_at(node.position+inbound,Vector3.UP)
	var bg := G.material(Color("a82a2b") if mandatory else Color("191f20"))
	var white := G.material(Color("d5d6c5"))
	G.box(node,Vector3(5.8,1.15,0.18),Vector3.ZERO,bg)
	G.box(node,Vector3(0.13,0.6,0.13),Vector3(-2,-0.7,0),white)
	G.box(node,Vector3(0.13,0.6,0.13),Vector3(2,-0.7,0),white)
	G.text3d(node,text,Vector3(0,0,0.11),48,Color.WHITE if mandatory else Color("ffdb62"),0.019)

func _build_airport_details() -> void:
	_taxi_sign(Vector2(1710,24),"N  →  GATES")
	_taxi_sign(Vector2(1760,100),"26R",true)
	_taxi_sign(Vector2(1670,226),"A1–A10  →")
	var dark := G.material(Color("2c3b40"))
	var metal := G.material(Color("818e8e"),0.55,0.3)
	var walls := G.material(Color("c4c5b7"))
	var detail: Array[Transform3D] = []
	for i in 10:
		var station := Ground.gate_station(i)
		# Terminal window mullions, roof equipment and static ground-service carts.
		for offset in range(-40,41,8):
			_ground_line(detail,Vector2(station+offset,404),Vector2(station+offset,405),0.3,11,8.5)
		for offset in [-20,20]:
			var equipment := G.box(self,Vector3(7,2.3,4),ground_point(Vector2(station+offset,451),19.2),metal)
			equipment.look_at(equipment.position+inbound,Vector3.UP)
		var cart := Node3D.new()
		add_child(cart)
		cart.position = ground_point(Vector2(station+34,376),0)
		cart.look_at(cart.position+inbound,Vector3.UP)
		G.box(cart,Vector3(2,0.9,4.2),Vector3(0,0.9,0),walls)
		G.box(cart,Vector3(1.8,1.25,1.4),Vector3(0,1.8,-1.1),metal)
		for side in [-1,1]:
			for z in [-1.4,1.4]:
				var wheel := G.cylinder(cart,0.32,0.32,0.18,Vector3(side*1.0,0.35,z),dark,10)
				wheel.rotation.z = PI/2
		var pole := ground_point(Vector2(station+39,388),0)
		G.cylinder(self,0.22,0.13,18,pole+Vector3.UP*9,metal,8)
		G.box(self,Vector3(4,0.25,1.4),pole+Vector3.UP*18,metal)
	scenery_detail = _batch(detail,metal,"TerminalMullions")

func _build_landmarks() -> void:
	# Original simplified landmark studies; positions and dimensions approximate.
	var limestone := G.material(Color("d4c4a2"),0.85)
	var warm := G.material(Color("b4956b"),0.82)
	var glass := G.material(Color("31586a"),0.23,0.35)
	var white := G.material(Color("d2d5ce"),0.65)
	var freedom := Node3D.new()
	freedom.name = "FreedomTowerStudy"
	add_child(freedom)
	freedom.position = geo(25.7803,-80.1895)
	G.box(freedom,Vector3(48,12,31),Vector3(0,6,0),limestone)
	G.box(freedom,Vector3(23,38,22),Vector3(0,30,0),limestone)
	for y in [16,29,43,50]: G.box(freedom,Vector3(26,1.1,25),Vector3(0,y,0),warm)
	G.cylinder(freedom,10,8,11,Vector3(0,55,0),limestone,8)
	G.cylinder(freedom,7,6,8,Vector3(0,64,0),warm,8)
	G.cylinder(freedom,7,0,8,Vector3(0,72,0),limestone,16)
	for side in [-1,1]:
		for y in range(18,46,6):
			for x in [-7,0,7]: G.box(freedom,Vector3(2.2,3.7,0.18),Vector3(x,y,side*11.1),glass)
	var museum := Node3D.new()
	museum.name = "OneThousandMuseumStudy"
	add_child(museum)
	museum.position = geo(25.7846,-80.1899)
	G.box(museum,Vector3(37,200,38),Vector3(0,100,0),glass)
	G.box(museum,Vector3(42,12,43),Vector3(0,207,0),white)
	for side in [-1,1]:
		for direction in [-1,1]:
			var last := Vector3(side*18,0,direction*20)
			for i in range(1,13):
				var y := float(i)*17
				var at := Vector3(side*(12+6*absf(cos(y*PI/102))),y,direction*20)
				G.beam(museum,last,at,2.2,white)
				last = at
		for y in range(30,190,32): G.beam(museum,Vector3(-15,y,side*20),Vector3(15,y+16,side*20),1.0,white)
	# A denser Brickell cluster: broad podiums and stepped crowns.
	for i in 16:
		var tower := Node3D.new()
		add_child(tower)
		tower.position = Vector3(9200+(i%4)*155,0,3200+(i/4)*165)
		if not _is_land(tower.position.x,tower.position.z): tower.queue_free(); continue
		var h := 115.0+(i*37)%105
		G.box(tower,Vector3(70,12,65),Vector3(0,6,0),white)
		G.box(tower,Vector3(41,h,34),Vector3(0,h/2+12,0),glass)
		G.box(tower,Vector3(32,14,26),Vector3(0,h+18,0),white)
	_build_palms()

func _build_palms() -> void:
	# A single instanced trunk mesh and a single instanced crown mesh.
	var trunks: Array[Transform3D] = []
	var crowns: Array[Transform3D] = []
	for i in 40:
		var p := ground_point(Vector2(490+i*27,530),0)
		trunks.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.45,8,0.45)),p+Vector3.UP*4))
		crowns.append(Transform3D(Basis(Vector3.UP,float(i)*0.9),p+Vector3.UP*8))
	_batch(trunks,G.material(Color("796c4e")),"PalmTrunks")
	var leaves := SurfaceTool.new()
	leaves.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 9:
		var a := float(i)*TAU/9
		var forward := Vector3(cos(a),0,sin(a))
		var side := forward.cross(Vector3.UP)*0.4
		var middle := forward*2.5+Vector3.UP*0.6
		var end := forward*5.0-Vector3.UP*1.1
		for p in [Vector3.ZERO,middle-side,middle+side,middle-side,end,middle+side]: leaves.add_vertex(p)
	leaves.generate_normals()
	var leaf_material := G.material(Color("3c5940"))
	leaf_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var batch := _batch(crowns,leaf_material,"PalmCrowns")
	batch.multimesh.mesh = leaves.commit()
