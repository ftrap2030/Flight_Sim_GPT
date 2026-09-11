extends RefCounted
## Small shared geometry vocabulary; every asset is generated locally.

static func material(color: Color, roughness: float = 0.7, metal: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metal
	return m

static func box(parent: Node3D, size: Vector3, at: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return instance(parent, mesh, at, mat)

static func instance(parent: Node3D, mesh: Mesh, at: Vector3, mat: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = mat
	node.position = at
	parent.add_child(node)
	return node

static func cylinder(parent: Node3D, bottom: float, top: float, height: float, at: Vector3, mat: Material, sides: int = 16) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = bottom
	mesh.top_radius = top
	mesh.height = height
	mesh.radial_segments = sides
	mesh.rings = 1
	return instance(parent, mesh, at, mat)

static func beam(parent: Node3D, a: Vector3, b: Vector3, width: float, mat: Material) -> MeshInstance3D:
	var node := box(parent, Vector3(width, width, a.distance_to(b)), (a + b) / 2.0, mat)
	if absf((b - a).normalized().dot(Vector3.UP)) < 0.99:
		node.look_at_from_position(node.position, b, Vector3.UP)
	else:
		node.look_at_from_position(node.position, b, Vector3.RIGHT)
	return node

static func polygon(parent: Node3D, outline: PackedVector2Array, height: float, mat: Material) -> MeshInstance3D:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	for p in outline:
		vertices.append(Vector3(p.x, height, p.y))
		normals.append(Vector3.UP)
		uvs.append(p / 100.0)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = Geometry2D.triangulate_polygon(outline)
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return instance(parent, mesh, Vector3.ZERO, mat)

static func text3d(parent: Node3D, text: String, at: Vector3, size: int, color: Color, pixels: float = 0.002) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font_size = size
	label.pixel_size = pixels
	label.modulate = color
	label.outline_size = 0
	label.no_depth_test = false
	label.position = at
	parent.add_child(label)
	return label

static func profile(parent: Node3D, outline: PackedVector2Array, thickness: float, mat: Material) -> MeshInstance3D:
	# Extrude a vertical (longitudinal, height) profile across the aircraft.
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var indices := Geometry2D.triangulate_polygon(outline)
	for side in [-1.0,1.0]:
		for index in indices:
			var point := outline[index]
			surface.add_vertex(Vector3(side*thickness/2,point.y,point.x))
	for i in outline.size():
		var a := outline[i]
		var b := outline[(i+1)%outline.size()]
		var corners := [Vector3(-thickness/2,a.y,a.x),Vector3(thickness/2,a.y,a.x),Vector3(thickness/2,b.y,b.x),Vector3(-thickness/2,b.y,b.x)]
		for index in [0,1,2,0,2,3]: surface.add_vertex(corners[index])
	surface.generate_normals()
	return instance(parent,surface.commit(),Vector3.ZERO,mat)

static func loft(parent: Node3D, rings: Array[Vector3], mat: Material, sides: int = 48) -> MeshInstance3D:
	# Ring = (longitudinal z, radius, center y). Shared smooth normals and UVs.
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for j in rings.size():
		var previous := rings[maxi(0,j-1)]
		var following := rings[mini(rings.size()-1,j+1)]
		var slope := (following.y-previous.y)/maxf(0.001,following.x-previous.x)
		for i in range(sides+1):
			var a := TAU*float(i)/sides
			vertices.append(Vector3(cos(a)*rings[j].y,sin(a)*rings[j].y+rings[j].z,rings[j].x))
			normals.append(Vector3(cos(a),sin(a),-slope).normalized())
			uvs.append(Vector2(float(i)/sides,rings[j].x/37.0))
			if j<rings.size()-1 and i<sides:
				var k := j*(sides+1)+i
				indices.append_array(PackedInt32Array([k,k+sides+1,k+1,k+1,k+sides+1,k+sides+2]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return instance(parent,mesh,Vector3.ZERO,mat)

static func surface(parent: Node3D, points: PackedVector3Array, mat: Material) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(1,points.size()-1):
		for p in [points[0],points[i],points[i+1]]: st.add_vertex(p)
	st.generate_normals()
	return instance(parent,st.commit(),Vector3.ZERO,mat)

static func wing(parent: Node3D, side: float, mat: Material) -> MeshInstance3D:
	# Closed swept wing, with a rounded leading edge and a tapered trailing edge.
	var stations := [Vector3(1.5,11.5,17.7),Vector3(6,13.8,18.6),Vector3(12,17.0,19.7),Vector3(17.9,20,20.8)]
	var profile := [Vector2(0,0),Vector2(0.04,0.55),Vector2(0.25,1),Vector2(0.65,0.65),Vector2(1,0),Vector2(0.65,-0.5),Vector2(0.25,-0.65),Vector2(0.04,-0.35)]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in range(stations.size()-1):
		for i in profile.size():
			var corners := PackedVector3Array()
			for pair in [Vector2i(j,i),Vector2i(j+1,i),Vector2i(j+1,(i+1)%profile.size()),Vector2i(j,(i+1)%profile.size())]:
				var station: Vector3 = stations[pair.x]
				var point: Vector2 = profile[pair.y]
				var thickness := lerpf(0.24,0.035,(station.x-1.5)/16.4)
				corners.append(Vector3(side*station.x,-0.2+point.y*thickness,lerpf(station.y,station.z,point.x)))
			for index in [0,1,2,0,2,3]: st.add_vertex(corners[index])
	st.generate_normals()
	return instance(parent,st.commit(),Vector3.ZERO,mat)
