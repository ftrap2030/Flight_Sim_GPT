extends Node3D
## Meter-based local map: +X east, -Z north. Runways are data-backed;
## coastline, terminals and buildings are explicitly approximate art proxies.
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
	_build_city()
	_build_coastal_details()
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
	var shore := PackedVector2Array([Vector2(-26000,-24000),Vector2(-26000,26000)])
	for z in range(26000,-24001,-500):
		shore.append(Vector2(coast_x(float(z)),float(z)))
	var land_mat := ShaderMaterial.new()
	land_mat.shader = preload("res://shaders/ground.gdshader")
	G.polygon(self,shore,0.0,land_mat)
	# A narrow, approximate barrier island establishes the bay and ocean horizon.
	var island := PackedVector2Array()
	for z in range(-20000,16001,1000):
		island.append(Vector2(13600+350*sin(float(z)/4200),z))
	for z in range(16000,-20001,-1000):
		island.append(Vector2(14500+350*sin(float(z)/4200),z))
	G.polygon(self,island,0.8,land_mat)
	var sand := G.material(Color("bcb89b"))
	sand.cull_mode = BaseMaterial3D.CULL_DISABLED
	var beach := PackedVector2Array()
	for z in range(-20000,16001,1000):
		beach.append(Vector2(14460+350*sin(float(z)/4200),z))
	for z in range(16000,-20001,-1000):
		beach.append(Vector2(14580+350*sin(float(z)/4200),z))
	G.polygon(self,beach,0.9,sand)

func _build_airport() -> void:
	var grass := G.material(Color("525b38"))
	G.box(self,Vector3(5400,1.8,3100),Vector3(-200,1.0,0),grass)
	var asphalt := G.material(Color("30383b"),0.97)
	var concrete := G.material(Color("8d8d82"),0.92)
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
		G.box(strip,Vector3(width,0.10,length),Vector3(0,0,-length/2),asphalt)
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
		var height := rng.randf_range(38,200)
		_add_building(Vector3(x,height/2,z),Vector3(rng.randf_range(23,55),height,rng.randf_range(20,52)),rng.randf())
	# Distributed buildings are interleaved, so reducing visible count preserves coverage.
	for i in 20000:
		var x := rng.randf_range(-11000,14500)
		var z := rng.randf_range(-12500,14500)
		if i%2==0:
			x = rng.randf_range(3100,9800)
			z = rng.randf_range(-5500,9500)
		if x > coast_x(z) and x < 13750: continue
		if absf(x+200)<2950 and absf(z)<1800: continue
		x = floorf(x/155)*155+77.5+rng.randf_range(-34,34)
		z = floorf(z/155)*155+77.5+rng.randf_range(-34,34)
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
	for z in [0,5200,-6000]:
		G.box(self,Vector3(4400,5,26),Vector3(11900,8,z),bridge)
		for x in range(9900,14000,240):
			G.box(self,Vector3(10,10,10),Vector3(x,2,z),bridge)
	# Distant port cranes: repeated original steel structures.
	var steel := G.material(Color("5e858b"),0.65,0.25)
	for i in 8:
		var x := 10300.0+i*130.0
		for side in [-1,1]:
			G.beam(self,Vector3(x+side*24,0,3300),Vector3(x+side*18,75,3300),5,steel)
		G.beam(self,Vector3(x,76,3220),Vector3(x,76,3470),5,steel)
		G.beam(self,Vector3(x,76,3300),Vector3(x,115,3310),4,steel)
		G.beam(self,Vector3(x,115,3310),Vector3(x,76,3450),1.8,steel)

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
