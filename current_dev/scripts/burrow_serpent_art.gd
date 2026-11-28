class_name BurrowSerpentArt
extends RefCounted
## Local +Z is the face. Place the burrow independently at the rupture site.

const SKIN_SHADER := preload("res://shaders/burrow_serpent.gdshader")
const SCALES := preload("res://assets/ground/burrow_serpent_scales.png")
const HIDE := Color("#536945")
const RIDGE := Color("#81916a")
const SEAM := Color("#34413a")
const THROAT := Color("#352332")
const GUM := Color("#844b55")
const IVORY := Color("#e1d3a5")
const EYE_OFFSET := Vector3(3.25, 1.24, 2.72)
const RECOMMENDED_CENTERS := 15
static var meshes: Dictionary[String, ArrayMesh] = {}

## The body is a single instanced draw. Each animal has its own charge material.
static func build() -> Node3D:
	_bake()
	var model := Node3D.new()
	var material := ShaderMaterial.new()
	material.shader = SKIN_SHADER
	material.set_shader_parameter("scales", SCALES)
	var links := MultiMeshInstance3D.new()
	links.name = "Body"
	links.multimesh = MultiMesh.new()
	links.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	links.multimesh.mesh = meshes["Body"]
	links.material_override = material
	links.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	model.add_child(links)
	var head := _attach(model, "Head", "Head", material)
	_attach(head, "UpperJaw", "UpperJaw", material)
	_attach(head, "LowerJaw", "LowerJaw", material)
	for eye_name in ["EyeLeft", "EyeRight"]:
		var eye := Node3D.new()
		eye.name = eye_name
		model.add_child(eye)
		_attach(eye, "Socket", "Socket", material).scale.x = -1.0 if eye_name == "EyeLeft" else 1.0
		_attach(eye, "Globe", "Eye", material)
		_attach(eye, "Injured", "InjuredEye", material).hide()
	return model

## Centers run from buried base to head and are model-local. Fifteen points
## spaced about 2.7 m apart yield a ~38 m animal. Jaw and charge are 0..1;
## eye_alive[0] belongs to EyeLeft and eye_alive[1] to EyeRight.
static func pose(model: Node3D, centers: PackedVector3Array, facing: Vector3, jaw_open: float, eye_alive: Array, charge: float) -> void:
	if centers.size() < 2:
		model.hide()
		return
	model.show()
	var links := model.get_node("Body") as MultiMeshInstance3D
	var count := centers.size() - 1
	if links.multimesh.instance_count != count:
		links.multimesh.instance_count = count
	var forward := facing.normalized() if facing.length_squared() > 0.00001 else Vector3.BACK
	var up := Vector3.FORWARD if absf(forward.y) > 0.985 else Vector3.UP
	var head_basis := Basis.looking_at(forward, up, true)
	var right := head_basis.x
	# Parallel-transport the head's right axis backwards around the arch.
	# An upright neck can pass vertical without its dorsal ridges flipping.
	for i in range(count - 1, -1, -1):
		var delta := centers[i + 1] - centers[i]
		var span := delta.length()
		var tangent := delta / span if span > 0.0001 else forward
		up = tangent.cross(right)
		if up.length_squared() < 0.0001:
			up = Vector3.FORWARD if absf(tangent.y) > 0.98 else Vector3.UP
		right = up.cross(tangent).normalized()
		up = tangent.cross(right).normalized()
		var along := (float(i) + 0.5) / count
		var width := 2.6 + 1.22 * sin(along * PI) + 0.22 * along - 0.71 * smoothstep(0.80,1.0,along)
		var basis := Basis(right * width, up * width * 0.89, tangent * maxf(span, 0.001))
		links.multimesh.set_instance_transform(i, Transform3D(basis, centers[i].lerp(centers[i+1], 0.5)))
	var head := model.get_node("Head") as MeshInstance3D
	head.transform = Transform3D(head_basis, centers[count])
	var gape := clampf(jaw_open, 0.0, 1.0)
	head.get_node("UpperJaw").rotation.x = -0.13 * gape
	head.get_node("LowerJaw").rotation.x = 0.035 + 0.45 * gape
	for side in 2:
		var sign_x := -1.0 if side == 0 else 1.0
		var eye := model.get_node("EyeLeft" if side == 0 else "EyeRight") as Node3D
		eye.transform = head.transform * Transform3D(Basis(Vector3.UP, sign_x * 0.32), EYE_OFFSET * Vector3(sign_x, 1, 1))
		var alive: bool = eye_alive[side] if side < eye_alive.size() else true
		eye.get_node("Globe").visible = alive
		eye.get_node("Injured").visible = not alive
	var material := links.material_override as ShaderMaterial
	material.set_shader_parameter("charge", clampf(charge, 0.0, 1.0))

## The lip and recessed cavity are one cached mesh. Reveal it when the turf
## opens. The chamber narrows to a throat five meters below the soil.
static func burrow() -> Node3D:
	_bake()
	var root := Node3D.new()
	var material := ShaderMaterial.new()
	material.shader = SKIN_SHADER
	material.set_shader_parameter("scales", SCALES)
	_attach(root, "TornPeat", "Burrow", material)
	return root

static func _attach(parent: Node3D, label: String, mesh_key: String, material: Material) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = label
	part.mesh = meshes[mesh_key]
	part.material_override = material
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(part)
	return part

static func _bake() -> void:
	if not meshes.is_empty():
		return
	for label in ["Body", "Head", "UpperJaw", "LowerJaw", "Socket", "Eye", "InjuredEye", "Burrow"]:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		match label:
			"Body": _body(st)
			"Head": _head(st)
			"UpperJaw": _jaw(st, 1.0)
			"LowerJaw": _jaw(st, -1.0)
			"Socket": _socket(st)
			"Eye": _eye(st, true)
			"InjuredEye": _eye(st, false)
			"Burrow": _burrow(st)
		st.index()
		meshes[label] = st.commit()

static func _body(st: SurfaceTool) -> void:
	# A narrow crease of soft hide runs between overlapping chitin plates.
	var rings: Array[PackedVector3Array] = []
	var shades := PackedColorArray([SEAM, Color("#586944"), HIDE, Color("#6a8053"), RIDGE, Color("#849168"), SEAM, SEAM])
	var sections := [Vector2(-0.68,0.78), Vector2(-0.54,0.89), Vector2(-0.35,0.96), Vector2(-0.05,1.03), Vector2(0.16,1.05), Vector2(0.26,1.06), Vector2(0.36,0.94), Vector2(0.66,0.82)]
	for section: Vector2 in sections:
		var ring := PackedVector3Array()
		for i in 32:
			var angle := TAU * i / 32.0
			var corrugation := 1.0 + 0.027*cos(angle * 7.0) + 0.016*sin(angle * 9.0)
			var radius := section.y * corrugation
			ring.append(Vector3(cos(angle)*radius, sin(angle)*radius, section.x + 0.105*sin(angle) + 0.04*cos(4.0*angle)))
		rings.append(ring)
	_loft(st, rings, shades, 0.49, 0.0, true, true, true)
	# Two lateral bristles and a low dorsal keel make the silhouette read in profile.
	for angle: float in [0.18, PI - 0.18, PI * 0.5]:
		var n := Vector3(cos(angle), sin(angle), 0)
		_tube(st, PackedVector3Array([n*0.94 + Vector3.BACK*0.16, n*1.09, n*1.13 + Vector3.FORWARD*0.38]), [0.135, 0.12, 0.008], [HIDE, RIDGE, Color("#aeab78")], 8, 0.34)
	for side: float in [-1.0, 1.0]:
		_oval(st, Vector3(side*1.015, -0.06, -0.02), Vector3(0.045, 0.045, 0.132), Color("#a6be64"), 0.5, 0.16)
		# Lapped, keeled scutes shield the flank; the pale belly stays flexible.
		for j in 5:
			var a := -0.66 + j * 0.42
			var n := Vector3(side*cos(a),sin(a),0)
			var crosswise := Vector3(-side*sin(a),cos(a),0)
			var plate := PackedVector3Array()
			var center := n*1.035 + Vector3.BACK*(0.01+0.07*sin(a))
			for edge: Vector2 in [Vector2(-0.19,0.13),Vector2(-0.14,0.29),Vector2(0.05,0.32),Vector2(0.21,0.12),Vector2(0.13,-0.20),Vector2(-0.08,-0.39)]:
				plate.append(center+crosswise*edge.x+Vector3.BACK*edge.y)
			_shell_plate(st, plate, center+n*0.105, Color("#65744c").lerp(Color("#85825a"),0.5+0.5*cos(j*1.8)), true)

static func _head(st: SurfaceTool) -> void:
	var rings: Array[PackedVector3Array] = []
	var sections := [Vector3(2.25,1.85,-3.0),Vector3(3.23,2.50,-2.1),Vector3(3.9,2.76,-0.88),Vector3(4.0,2.53,0.52),Vector3(3.73,2.12,1.75)]
	for station: Vector3 in sections:
		var ring := PackedVector3Array()
		for i in 40:
			var a := TAU * i / 40.0
			ring.append(Vector3(station.x*cos(a), station.y*sin(a), station.z + 0.31*cos(a*2.0)))
		rings.append(ring)
	_loft(st,rings,[SEAM,HIDE,Color("#72845c"),RIDGE,Color("#534c44")],0.54,0.0,true,false,true)
	# The throat narrows behind the jaws into a recessed, dark gullet.
	rings.clear()
	for station: Vector3 in [Vector3(3.75,2.28,2.45),Vector3(3.20,2.03,2.72),Vector3(2.90,1.66,2.50),Vector3(2.48,1.28,2.58),Vector3(1.57,0.88,2.28),Vector3(0.01,0.008,2.18)]:
		var ring := PackedVector3Array()
		for i in 40:
			var a := TAU * i / 40.0
			ring.append(Vector3(station.x*cos(a),station.y*sin(a),station.z+0.035*station.x*cos(8*a)))
		rings.append(ring)
	_loft(st,rings,[THROAT,Color("#723d4d"),Color("#472d3e"),Color("#643347"),Color("#221a25"),Color("#100d13")],0.83)
	_oval(st,Vector3(0,0.06,2.24),Vector3(0.90,0.49,0.12),Color("#130e16"),0.22)
	# A muscular pharynx closes the back of the mouth even as the neck
	# bends through a right angle; the last body segment stays behind it.
	_oval(st,Vector3(0,-0.30,1.23),Vector3(3.40,2.36,0.83),Color("#362632"),0.30)
	for side: float in [-1.0,1.0]:
		_oval(st, Vector3(side*3.08,1.15,2.0), Vector3(1.34,1.12,1.12), SEAM,0.51)
		# A hooded orbital ridge sweeps backwards into a crown horn.
		_tube(st, PackedVector3Array([Vector3(side*2.2,2.0,2.40),Vector3(side*3.05,2.38,2.48),Vector3(side*3.98,1.95,1.50),Vector3(side*4.16,1.93,-0.25),Vector3(side*4.50,2.30,-1.75)]), [0.28,0.46,0.55,0.45,0.012], [RIDGE,Color("#a1a16d"),HIDE,RIDGE,Color("#cac08a")],12,0.39)
		_tube(st, PackedVector3Array([Vector3(side*3.35,-0.12,1.87),Vector3(side*4.1,-0.37,1.3),Vector3(side*4.55,-0.57,-0.05),Vector3(side*4.83,-0.30,-1.02)]), [0.59,0.52,0.31,0.009], [SEAM,HIDE,RIDGE,IVORY],10,0.41)
		for i in 3:
			_oval(st, Vector3(side*(3.99-i*0.13),0.32,0.92-i*0.63),Vector3(0.109,0.155,0.27),Color("#a4b36d"),0.62,0.22)

static func _jaw(st: SurfaceTool, side: float) -> void:
	# The gum is a curved arch with a broad chitin outer lip and a fleshy inside.
	var rings: Array[PackedVector3Array] = []
	var shades := PackedColorArray()
	for i in 27:
		var a := PI * i / 26.0
		var radial := Vector3(cos(a),side*sin(a),0).normalized()
		var center := Vector3(3.36*cos(a),side*(0.05+1.38*sin(a)),2.11+2.0*sin(a))
		var ring := PackedVector3Array()
		for j in 12:
			var b := TAU*j/12.0
			ring.append(center + radial*cos(b)*(0.61+0.12*sin(a)) + Vector3.BACK * sin(b)*(0.78+0.15*sin(a)))
		rings.append(ring)
		shades.append(HIDE.lerp(Color("#a79b70"), 0.32+0.26*sin(a)))
	_loft(st,rings,shades,0.59,0.0,true,false,true)
	# The roof and floor continue into the hinge at the back. Their inner
	# surfaces carry soft palate folds, while the outer snout shields the gums.
	rings.clear()
	var profiles := [Vector3(1.04,0.94,-0.72),Vector3(1.10,0.96,0.86),Vector3(1.12,0.60,2.36),Vector3(1.03,0.31,3.42),Vector3(0.98,-0.14,3.61),Vector3(0.89,-0.28,3.36),Vector3(0.85,-0.16,2.85),Vector3(0.79,-0.27,2.65),Vector3(0.73,-0.15,2.48),Vector3(0.56,-0.28,1.86),Vector3(0.31,-0.24,1.37)]
	for p: Vector3 in profiles:
		var arch := PackedVector3Array()
		for j in 31:
			var a := PI*j/30.0
			var elevation := sin(a)
			arch.append(Vector3(3.37*p.x*cos(a),side*(0.11+(1.38*p.x+p.y)*elevation),lerpf(1.64,p.z,pow(elevation,0.68))))
		rings.append(arch)
	_loft(st,rings,[HIDE,Color("#607248"),RIDGE,Color("#7e8057"),Color("#72594d"),GUM,Color("#503441"),Color("#784552"),Color("#553342"),THROAT,Color("#31242d")],0.69,0.0,false,false,true)
	if side > 0.0:
		for sx:float in [-1.0,1.0]:
			_oval(st,Vector3(sx*1.18,1.93,3.37),Vector3(0.50,0.24,0.37),Color("#717e56"),0.53)
			_oval(st,Vector3(sx*1.18,2.03,3.59),Vector3(0.25,0.11,0.16),Color("#383e37"),0.52)
			for i in 3:
				var at := Vector3(sx*(1.12+i*0.59),1.93-i*0.17,3.04-i*0.21)
				var rim := PackedVector3Array([at+Vector3(-sx*0.50,0,0.46),at+Vector3(sx*0.40,-0.11,0.39),at+Vector3(sx*0.58,0.10,-0.29),at+Vector3(sx*0.16,0.38,-0.78),at+Vector3(-sx*0.48,0.21,-0.36)])
				_shell_plate(st,rim,at+Vector3(0,0.33,-0.03),RIDGE.darkened(0.05*i),true)
	# Teeth lean back towards the pharynx, interleaved when the mouth closes.
	var upper := side > 0
	var count := 15 if upper else 14
	for i in count:
		var a := 0.13 + (PI-0.26)*(float(i)+0.5)/count
		var radial := Vector3(cos(a),side*sin(a),0).normalized()
		var center := Vector3(3.35*cos(a),side*(0.05+1.38*sin(a)),2.11+2.0*sin(a)) - radial*0.48 + Vector3.BACK*0.38
		var long_fang := i == 3 or i == count-4
		var wear := 0.5 + 0.5*sin(i*4.31+side*1.24)
		var length := (1.66 if long_fang else 0.71) * (0.73 + 0.47*wear)
		var inward := (radial*0.64 + Vector3.UP*side*0.60).normalized()
		var tooth_base := Color("#795c44").lerp(Color("#b09c71"),wear)
		var enamel := Color("#b69c70").lerp(IVORY,wear)
		var hook := Vector3(sin(i*4.6)*0.10,0,-0.12-wear*0.19)
		_tube(st, PackedVector3Array([center,center-inward*0.22+Vector3.BACK*0.10,center-inward*length*0.71+Vector3.BACK*0.18,center-inward*length+hook]), [0.37 if long_fang else 0.19,0.32 if long_fang else 0.15,0.10,0.008+0.019*(1.0-wear)], [GUM,tooth_base,enamel,enamel.lightened(0.09)],8,0.54)
	if not upper:
		rings.clear()
		for section: Vector3 in [Vector3(0.44,0.27,1.1),Vector3(0.86,0.35,1.78),Vector3(1.02,0.37,2.40),Vector3(1.01,0.31,3.00),Vector3(0.78,0.24,3.65),Vector3(0.41,0.14,3.98),Vector3(0.02,0.015,4.24)]:
			var ring := PackedVector3Array()
			for i in 24:
				var a := TAU*i/24.0
				var groove := exp(-21.0*pow(cos(a),2.0))*maxf(0.0,sin(a))
				ring.append(Vector3(section.x*cos(a),-0.84 + 0.19*smoothstep(2.8,4.24,section.z) + section.y*(sin(a)-0.42*groove),section.z))
			rings.append(ring)
		_loft(st,rings,[THROAT,Color("#452c3c"),Color("#623448"),Color("#713d50"),Color("#6d3b4d"),Color("#573443"),THROAT],0.94)

static func _socket(st: SurfaceTool) -> void:
	var rings: Array[PackedVector3Array] = []
	# Raised osteoderms sit above a deep dark annulus. The inner horn of
	# the brow descends towards the nose, giving the two eyes a clear slant.
	for s: Vector3 in [Vector3(1.42,1.20,-0.36),Vector3(1.48,1.08,0.15),Vector3(1.25,0.90,0.54),Vector3(1.12,0.77,0.48),Vector3(0.94,0.65,0.33)]:
		var ring := PackedVector3Array()
		for i in 32:
			var a := TAU*i/32.0
			var lift := maxf(0.0,sin(a))
			ring.append(Vector3(s.x*cos(a),s.y*sin(a)+cos(a)*0.20,s.z+lift*0.22))
		rings.append(ring)
	_loft(st,rings,[SEAM,HIDE,Color("#66734d"),Color("#27332d"),Color("#211d1c")],0.39,0.0,true,false,true)
	_tube(st,PackedVector3Array([Vector3(-1.05,0.11,0.28),Vector3(-0.63,0.45,0.67),Vector3(0.10,0.70,0.75),Vector3(0.82,0.85,0.52),Vector3(1.46,0.72,-0.05)]),[0.04,0.18,0.22,0.28,0.025],[SEAM,Color("#3b4835"),Color("#546445"),HIDE,SEAM],10,0.44)

static func _eye(st: SurfaceTool, alive: bool) -> void:
	_oval(st, Vector3.ZERO, Vector3(1.10,0.92,0.68),Color("#7a693d") if alive else Color("#53393c"),0.85)
	if alive:
		_oval(st,Vector3(0,0,0.38),Vector3(0.91,0.76,0.41),Color("#c68837"),0.81,0.51)
		_oval(st,Vector3(0,0,0.61),Vector3(0.60,0.55,0.235),Color("#ebb356"),0.84,0.63)
		_oval(st,Vector3(0,0,0.765),Vector3(0.145,0.54,0.15),Color("#221e21"),0.48)
		_oval(st,Vector3(-0.22,0.25,0.80),Vector3(0.13,0.11,0.074),Color("#fcf1b9"),0.95,0.85)
	else:
		_tube(st,PackedVector3Array([Vector3(-0.65,0.29,0.49),Vector3(-0.25,0.08,0.73),Vector3(0.14,0.05,0.73),Vector3(0.61,-0.27,0.49)]),[0.035,0.12,0.12,0.024],[THROAT,Color("#813e48"),THROAT,THROAT],8,0.76)
	for sign_y: float in [-1.0,1.0]:
		var lid := PackedVector3Array()
		for j in 11:
			var a := PI*j/10.0
			lid.append(Vector3(cos(a)*1.02,sign_y*(0.10+sin(a)*0.61),0.25+sin(a)*0.28))
		_tube(st,lid,[0.045,0.14,0.16,0.19,0.21,0.23,0.21,0.19,0.16,0.14,0.045],[SEAM,SEAM,HIDE,HIDE,RIDGE,RIDGE,RIDGE,HIDE,HIDE,SEAM,SEAM],8,0.54)

static func _burrow(st: SurfaceTool) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 117811
	var radii := PackedFloat32Array()
	var lift := PackedFloat32Array()
	for i in 62:
		var a := TAU*i/62.0
		radii.append(1.0+0.075*sin(a*3.0+0.27)+0.045*cos(a*5.0)+rng.randf_range(-0.045,0.045))
		lift.append(rng.randf_range(0.0,1.0))
	var rings: Array[PackedVector3Array] = []
	for station: Vector3 in [Vector3(0.001,-5.70,0),Vector3(2.47,-4.65,0.31),Vector3(3.53,-2.09,0.49),Vector3(4.13,-0.34,0.39),Vector3(4.48,0.90,0.51),Vector3(4.95,1.02,0.68),Vector3(5.59,0.71,0.40),Vector3(6.76,0.19,0.21),Vector3(7.50,0.045,0)]:
		var ring := PackedVector3Array()
		for i in 62:
			var a := TAU*i/62.0
			var radius := radii[i]*station.x
			ring.append(Vector3(cos(a)*radius*1.08,station.y+lift[i]*station.z,sin(a)*radius*0.94))
		rings.append(ring)
	_loft(st,rings,[Color("#0c1011"),Color("#161917"),Color("#242722"),Color("#37362b"),Color("#3d3831"),Color("#635344"),Color("#605743"),Color("#4e5638"),Color("#3e4d33")],0.26)
	# Clods are thicker towards the break. Fine severed roots droop into the cavity.
	for i in 36:
		var a := i*2.39996+rng.randf_range(-0.09,0.09)
		var r := rng.randf_range(5.2,7.75)
		var size := rng.randf_range(0.30,1.08)
		var at := Vector3(cos(a)*r,0.18,sin(a)*r*0.94)
		var base := PackedVector3Array()
		var rim := PackedVector3Array()
		for k in 7:
			var v := a + TAU*k/7.0 + rng.randf_range(-0.19,0.19)
			var p := Vector3(cos(v)*1.20,0,sin(v)*0.81)*rng.randf_range(0.66,1.08)*size
			base.append(at+p*0.80+Vector3.DOWN*0.23)
			rim.append(at+p+Vector3.UP*(size*(0.37+0.25*cos(v-a))+rng.randf_range(-0.08,0.08)))
		_loft(st,[base,rim],[Color("#332f2e"),Color("#605144")],0.24)
		_shell_plate(st,rim,at+Vector3.UP*size*0.65,Color("#52523a").lerp(Color("#74714c"),rng.randf()))
	for i in 17:
		var a := i*2.39996+rng.randf_range(-0.10,0.10)
		var radial := Vector3(cos(a)*1.08,0,sin(a)*0.94)
		var at := radial*radii[roundi(fposmod(a,TAU)*62.0/TAU)%62]*4.64 + Vector3.UP*rng.randf_range(0.80,1.21)
		var offset := Vector3(-sin(a),0,cos(a))*rng.randf_range(-0.31,0.31)
		_tube(st,PackedVector3Array([at,at-radial*0.32+Vector3.UP*0.11,at-radial*0.65+offset+Vector3.DOWN*0.32,at-radial*0.88+offset+Vector3.DOWN*0.77]),[0.11,0.09,0.048,0.009],[Color("#70603f"),Color("#847347"),Color("#745d43"),Color("#594730")],6,0.24)

static func _oval(st: SurfaceTool, at: Vector3, size: Vector3, color: Color, wet: float, glow: float = 0.0) -> void:
	var rings: Array[PackedVector3Array] = []
	var colors := PackedColorArray()
	for row in 11:
		var phi := lerpf(0.001,PI-0.001,float(row)/10.0)
		var ring := PackedVector3Array()
		for i in 18:
			var a := TAU*i/18.0
			ring.append(at + Vector3(cos(a)*sin(phi),sin(a)*sin(phi),-cos(phi))*size)
		rings.append(ring)
		colors.append(color)
	_loft(st,rings,colors,wet,glow)

static func _tube(st: SurfaceTool, path: PackedVector3Array, widths: Array, colors: Array, steps: int, wet: float) -> void:
	var rings: Array[PackedVector3Array] = []
	var side := Vector3.RIGHT
	for i in path.size():
		var tangent := (path[mini(path.size()-1,i+1)] - path[maxi(0,i-1)]).normalized()
		if absf(tangent.dot(side)) > 0.94:
			side = Vector3.UP if absf(tangent.y) < 0.9 else Vector3.BACK
		var up := tangent.cross(side).normalized()
		side = up.cross(tangent).normalized()
		var ring := PackedVector3Array()
		for j in steps:
			var a := TAU*j/steps
			ring.append(path[i]+(side*cos(a)+up*sin(a))*float(widths[i]))
		rings.append(ring)
	_loft(st,rings,colors,wet)

static func _shell_plate(st: SurfaceTool, rim: PackedVector3Array, peak: Vector3, color: Color, scaled_skin: bool = false) -> void:
	for j in rim.size():
		var b := rim[(j+1)%rim.size()]
		var n := (peak-rim[j]).cross(b-rim[j]).normalized()
		for point: Vector3 in [rim[j],peak,b]:
			st.set_normal(n)
			st.set_uv(Vector2(0.37,0.0))
			st.set_uv2(Vector2(float(scaled_skin),0.0))
			st.set_color(color.lightened(0.06) if point == peak else color)
			st.add_vertex(point)

static func _loft(st: SurfaceTool, rings: Array[PackedVector3Array], colors: PackedColorArray, wet: float, glow: float = 0, closed: bool = true, belly: bool = false, scaled_skin: bool = false) -> void:
	var sides := rings[0].size()
	var normals := PackedVector3Array()
	for row in rings.size():
		var ring := rings[row]
		var prev := rings[maxi(row-1,0)]
		var next := rings[mini(row+1,rings.size()-1)]
		for j in sides:
			var around := ring[(j+1)%sides]-ring[posmod(j-1,sides)] if closed else ring[mini(j+1,sides-1)]-ring[maxi(j-1,0)]
			normals.append(around.cross(next[j]-prev[j]).normalized())
	for row in range(rings.size()-1):
		for j in range(sides if closed else sides-1):
			var a := row*sides+j
			var b := row*sides+(j+1)%sides
			for idx: int in [a,a+sides,b,a+sides,b+sides,b]:
				var k := floori(float(idx)/sides)
				var tint := colors[k]
				if belly:
					var ventral := smoothstep(0.18,0.94,-rings[k][idx%sides].y)
					tint = tint.lerp(Color("#aa9570"),0.66*ventral)
				st.set_color(tint)
				st.set_uv(Vector2(wet,glow))
				st.set_uv2(Vector2(float(scaled_skin and colors[k].g > colors[k].r*0.95),0.0))
				st.set_normal(normals[idx])
				st.add_vertex(rings[k][idx%sides])
