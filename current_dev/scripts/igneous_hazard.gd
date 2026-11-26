extends Node3D

# The encounter director controls age, so pausing and crossing the contact time
# in one physics step produce the same pose as normal flight.
const CONTACT := 2.5
const DUST_COUNT := 38
const CHIP_COUNT := 22
const WALKER_SCALE := 1.6
const STONE := preload("res://shaders/igneous_stone.gdshader")
const WAKE := preload("res://shaders/igneous_wake.gdshader")


var walker_encounter := false
var walker: Node3D
var sector := "kharon"
var source_world := Vector3.INF
var stone := MeshInstance3D.new()
var wake := MeshInstance3D.new()
var scar := MeshInstance3D.new()
var dust := MultiMeshInstance3D.new()
var chips := MultiMeshInstance3D.new()
var light := OmniLight3D.new()
var wake_ink := ShaderMaterial.new()
var stones_ink := ShaderMaterial.new()
var crust := StandardMaterial3D.new()
var start := Vector3.ZERO
var ground_y := 0.0
var launch_set := false
var spokes := PackedVector3Array()
var sizes := PackedFloat32Array()
var seed_value := 0.0
var seeded_offset := Vector3.ZERO

func _ready() -> void:
	if walker_encounter:
		walker = preload("res://scripts/kharon_piledriver.gd").new()
		walker.scale = Vector3.ONE * WALKER_SCALE
		walker.ground_height = _walker_floor
		add_child(walker)
	var body := SphereMesh.new()
	body.radius = 1.0
	body.height = 2.0
	body.radial_segments = 36
	body.rings = 22
	stones_ink.shader = STONE
	stones_ink.set_shader_parameter("basalt",sector == "ignis")
	stones_ink.set_shader_parameter("shape_seed",seed_value)
	stone.mesh = body
	stone.material_override = stones_ink
	add_child(stone)
	wake_ink.shader = WAKE
	wake_ink.set_shader_parameter("basalt",sector == "ignis")
	wake.mesh = _wake_mesh()
	wake.material_override = wake_ink
	wake.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(wake)
	var puff := QuadMesh.new()
	puff.size = Vector2(4.0,4.0)
	_build_batch(dust,puff,VolcanoEruption.ash_material(),DUST_COUNT)
	var shard := SphereMesh.new()
	shard.radial_segments = 8
	shard.rings = 4
	var shard_material := StandardMaterial3D.new()
	shard_material.vertex_color_use_as_albedo = true
	shard_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_build_batch(chips,shard,shard_material,CHIP_COUNT)
	crust.vertex_color_use_as_albedo = true
	crust.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	crust.cull_mode = BaseMaterial3D.CULL_DISABLED
	crust.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	scar.material_override = crust
	scar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(scar)
	light.light_color = Color("#ff893d") if sector == "ignis" else Color("#ffc28d")
	light.omni_attenuation = 1.4
	light.omni_range = 24.0
	add_child(light)
	# The director may position this instance immediately after adding it.
	stone.hide()
	wake.hide()
	scar.hide()
	chips.hide()
	dust.hide()
	light.hide()

func _seed_event() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(global_position.round())
	seed_value = rng.randf_range(-9,9)
	seeded_offset = Vector3(rng.randf_range(48,78) * (-1 if rng.randi()%2 else 1),rng.randf_range(90,120),rng.randf_range(-90,-36))
	for i in range(DUST_COUNT + CHIP_COUNT):
		var angle := i * 2.39996 + rng.randf_range(-0.18,0.18)
		spokes.append(Vector3(cos(angle), rng.randf(), sin(angle)))
		sizes.append(rng.randf_range(0.65,1.3))
	stones_ink.set_shader_parameter("shape_seed",seed_value)

func _build_batch(node: MultiMeshInstance3D, mesh: Mesh, mat: Material, count: int) -> void:
	node.multimesh = MultiMesh.new()
	node.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	node.multimesh.use_colors = true
	node.multimesh.mesh = mesh
	node.multimesh.instance_count = count
	node.material_override = mat
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)

func _floor(x: float,z: float) -> float:
	var point := transform * Vector3(x,0,z)
	var distance := -point.z
	var lane := point.x - FlightState.rail_point(distance).x
	if sector == "kharon":
		point.y = FrontierArt.floor_point(lane,distance,sector).y
	else:
		point.y = VectorArt.ground_point(lane,distance,true).y
	return (transform.affine_inverse() * point).y

static func _wake_mesh() -> ArrayMesh:
	# -Z is the axis from the leading stone back through its trailing sheath.
	var mesh := SurfaceTool.new()
	mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in 12:
		for side in 16:
			for k: Vector2i in [Vector2i(0,0),Vector2i(0,1),Vector2i(1,0),Vector2i(1,0),Vector2i(0,1),Vector2i(1,1)]:
				var t := (row+k.y)/12.0
				var u := (side+k.x)/16.0
				var axis := Vector3(cos(u*TAU),sin(u*TAU),0)
				var r := (1.0+0.16*sin(t*21.0+TAU*u*3.0))*pow(maxf(0,1-t),0.62)
				mesh.set_normal(axis)
				mesh.set_uv(Vector2(u,t))
				mesh.add_vertex(axis*r + Vector3.FORWARD*t)
	return mesh.commit()

func _crater_mesh() -> ArrayMesh:
	var mesh := SurfaceTool.new()
	mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	var radii := [0.0,1.2,2.8,3.9,5.8,7.8]
	var heights := [0.10,0.13,0.23,0.69,0.23,0.045]
	var colors := [Color("#191719"),Color("#322620"),Color("#40302d"),Color("#947859"),Color("#6c564a"),Color("#79614c")]
	for row in range(radii.size()-1):
		for i in 40:
			for k: Vector2i in [Vector2i(0,0),Vector2i(1,0),Vector2i(0,1),Vector2i(1,0),Vector2i(1,1),Vector2i(0,1)]:
				var band := row + k.y
				var a := (i+k.x)*TAU/40.0
				var width := 1.0 + 0.13*sin(a*5+seed_value) + 0.075*cos(a*9)
				var radius: float = radii[band]*width
				var x := radius*cos(a)
				var z := radius*sin(a)*0.87
				var c: Color = colors[band]
				if sector=="ignis":
					c = Color("#431b10").lerp(Color("#ff792a"),0.12+0.82*pow(maxf(0,cos(a*9+radius)),7.0)) if band<3 else c.darkened(0.32)
				c.a = 0.0 if band==5 else 0.95
				mesh.set_color(c)
				mesh.add_vertex(Vector3(x,_floor(x,z)+float(heights[band])*width,z))
	return mesh.commit()

func _trajectory(t: float) -> Vector3:
	if sector == "ignis":
		return start*(1.0-t) + Vector3.UP*(4*t*(1-t)*maxf(21.0,start.length()*0.23))
	return start*(1.0-pow(maxf(0,t),1.25))

func advance_event(age: float, reduced: bool) -> void:
	if not launch_set:
		_seed_event()
		start = to_local(source_world) if source_world.is_finite() else seeded_offset
		if sector=="ignis" and not source_world.is_finite():
			start.y = _floor(start.x,start.z)+VolcanoEruption.CRATER_HEIGHT
		ground_y = _floor(0,0)
		scar.mesh = _crater_mesh()
		launch_set = true
	if walker_encounter:
		_advance_walker(age,reduced)
		return
	var t := clampf(age/CONTACT,0,1)
	var after := age-CONTACT
	var air := after<0
	var fade := 1-smoothstep(2.25,3.0,after)
	stone.visible = air
	wake.visible = air
	scar.visible = not air
	light.visible = fade>0.005
	if air:
		stone.position = _trajectory(t)
		stone.basis = Basis.from_euler(Vector3(age*2.6,age*.9,age*1.8)).scaled(Vector3(2.2,1.6,1.8))
		var tangent := _trajectory(t-.002) - _trajectory(t+.002)
		var reference := Vector3.RIGHT if absf(tangent.normalized().y)>0.96 else Vector3.UP
		var speed := 9.0 if sector=="ignis" else 28.0
		wake.basis = Basis.looking_at(tangent.normalized(),reference)*Basis.from_scale(Vector3(2.2,2.2,speed))
		wake.position = stone.position
		wake_ink.set_shader_parameter("phase",age)
		wake_ink.set_shader_parameter("intensity",0.55 if reduced else 1.0)
		light.position = stone.position
		light.light_energy = (0.62 if reduced else 1.05)*(0.5+t)
	else:
		light.position = Vector3.UP*1.5
		light.light_energy = (1.8 if reduced else 4.6)*exp(-after*3.4) + 0.20*fade
		crust.albedo_color.a = fade
	_update_ejecta(age,reduced)

func _walker_floor(x: float, z: float) -> float:
	return _floor(x*WALKER_SCALE,z*WALKER_SCALE)/WALKER_SCALE

func _advance_walker(age: float, reduced: bool) -> void:
	walker.advance(age)
	if walker.destroyed and walker.disabled_at < CONTACT:
		dust.hide()
		chips.hide()
		scar.hide()
		return
	var after := age - CONTACT
	if after >= 0:
		_update_ejecta(age,reduced)
		scar.show()
		crust.albedo_color.a = 1.0 - smoothstep(2.25,3.0,after)
		return
	# Fine sand trails behind the moving footplates; no meteor or comet trail is drawn.
	chips.hide()
	dust.show()
	var count := 12 if reduced else 20
	dust.multimesh.visible_instance_count = count
	for i in count:
		var foot: Node3D = walker.shoes[i%4]
		var lag := (i / 4) * 0.26
		var at := foot.position * WALKER_SCALE + Vector3(-lag*2.1,0.35+lag*0.43,spokes[i].z*lag)
		var scale_by := (0.84+lag*0.6)*sizes[i]
		var size := Vector3(1.3,0.42,0.93)*scale_by
		var tint := Color("#af906c")
		tint.a = (0.13+0.14*(1.0-walker.foot_lifts[i%4])) * (1.0-smoothstep(1.82,2.35,age))
		dust.multimesh.set_instance_transform(i, Transform3D(Basis.from_scale(size),at))
		dust.multimesh.set_instance_color(i,tint)

func _update_ejecta(age: float,reduced: bool) -> void:
	var after := age-CONTACT
	var fade := 1.0-smoothstep(1.95,3.0,after)
	dust.visible = fade>0
	chips.visible = age>0.32 and after<2.4
	var count := 21 if reduced else DUST_COUNT
	dust.multimesh.visible_instance_count = count
	for i in count:
		var s := spokes[i]
		var at: Vector3
		var size: Vector3
		var tint: Color
		if after<0:
			# Wind-torn smoke parcels remain on earlier positions along the body's arc.
			var lag := (i+1.0)/count*0.58
			var prior := clampf((age-lag)/CONTACT,0,1)
			at = _trajectory(prior) + Vector3(s.x,s.y,s.z)*lag*3
			size = Vector3.ONE * (1.15+lag*3.5)*sizes[i]
			tint = Color("#62525a") if sector=="ignis" else Color("#a59c99")
			tint.a = (0.20 if reduced else 0.39)*smoothstep(0,0.20,age-lag)
		else:
			# A low rolling ejecta curtain and a slower buoyant column have distinct motion.
			var rim := i%3!=0
			var speed := (10.5+s.y*6.8) if rim else (0.8+s.y*1.7)
			at = Vector3(s.x,0,s.z)*(1.6+speed*(1-exp(-after*1.15)))
			at.y = lerpf(0.0,ground_y,smoothstep(0.05,0.8,after)) + (1.1+after*(0.9+s.y) if rim else after*(4.2+2.8*s.y))
			if walker_encounter:
				# The mechanical ram kicks sand sideways under the bridge rather than
				# sending a meteor's hot vertical column through the machinery.
				at.y = ground_y + (at.y-ground_y)*0.38
			at.x += after*after*0.35
			size = Vector3(1.25,0.7 if rim else 1.45,1.18)*(1.25+after*(1.8+s.y))*sizes[i]
			tint = Color("#655049") if sector=="ignis" else Color("#b0926a")
			tint = tint.lerp(Color("#ffd1a0") if sector=="ignis" else Color("#ffe1aa"), 0.7*exp(-after*4.4))
			tint.a = fade*(0.34 if reduced else 0.66)*smoothstep(-0.025,0.18,after)
			if walker_encounter:
				tint.a *= 0.64
				size.y *= 0.63
		dust.multimesh.set_instance_transform(i,Transform3D(Basis.from_scale(size),at))
		dust.multimesh.set_instance_color(i,tint)
	if not chips.visible:
		return
	if after<0:
		# Small ablation fragments peel away from the leading mass, each on its own path.
		var count_in_air := 3 if reduced else 6
		chips.multimesh.visible_instance_count = count_in_air
		for i in count_in_air:
			var lag := 0.04 + (i + 1)*0.035
			var at := _trajectory(clampf((age-lag)/CONTACT,0,1))
			at += spokes[DUST_COUNT+i] * (1.6 + i*0.53) * smoothstep(0.35,1.25,age)
			var size := 0.69 - 0.055*i
			var basis := Basis.from_euler(Vector3(age*3.0+i,age*2.1,i))*Basis.from_scale(Vector3(0.68,1.13,1.5)*size)
			chips.multimesh.set_instance_transform(i,Transform3D(basis,at))
			chips.multimesh.set_instance_color(i,Color("#ffc28c").lerp(Color("#c2462a"),i/7.0))
		return
	var shards := 12 if reduced else CHIP_COUNT
	chips.multimesh.visible_instance_count = shards
	for i in shards:
		var s := spokes[DUST_COUNT+i]
		var speed := 6.0+6.5*s.y
		var at := Vector3(s.x*speed,9+6*s.y,s.z*speed)*after - Vector3.UP*9.6*after*after
		var size := maxf(0.002,(0.28+sizes[DUST_COUNT+i]*.49)*(1-smoothstep(1.55,2.4,after)))
		at.y = maxf(ground_y+0.12,at.y)
		var basis := Basis.from_euler(Vector3(i*1.6+after*3.7,after*4.7,i))*Basis.from_scale(Vector3(0.68,1.13,1.8)*size)
		chips.multimesh.set_instance_transform(i,Transform3D(basis,at))
		chips.multimesh.set_instance_color(i,Color("#ffad5b").lerp(Color("#564239"),smoothstep(0.15,1.0,after)))
