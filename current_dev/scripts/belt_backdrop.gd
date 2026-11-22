class_name BeltBackdrop
extends Node3D

const BASE_ROCKS_PER_BATCH: int = 19
const PERIPHERAL_ROCKS_PER_BATCH: int = 60
const GIANT_SCALE: float = 5.0

var rocks: Array[Dictionary] = []
var batches: Array[Dictionary] = []
var animation_time: float = 0.0
var animation_pilot: Vector3

func _ready() -> void:
	set_process(false)

func build(course: Transform3D, giant_periphery: bool = false, arrival: PackedVector3Array = PackedVector3Array(), tint: Color = Color("#8e8296")) -> void:
	transform = course
	if giant_periphery:
		_build_cryo(course, [arrival])
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 49173
	var peripheral_rng := RandomNumberGenerator.new()
	peripheral_rng.seed = 72691
	for section in range(9):
		for variant in range(AsteroidArt.VARIANTS):
			var transforms: Array[Transform3D] = []
			var axes := PackedVector3Array()
			var speeds := PackedFloat32Array()
			for i in range(BASE_ROCKS_PER_BATCH + PERIPHERAL_ROCKS_PER_BATCH):
				var peripheral: bool = i >= BASE_ROCKS_PER_BATCH
				var source_rng: RandomNumberGenerator = peripheral_rng if peripheral else rng
				var travel: float = section * 480.0 + source_rng.randf_range(0, 480)
				var angle: float = source_rng.randf_range(0, TAU)
				var distance: float = source_rng.randf_range(160, 340) if peripheral else source_rng.randf_range(FlightState.WIDE_HALF_WIDTH + 20, 160)
				var radius: float = source_rng.randf_range(9.0, 20.0) if peripheral else source_rng.randf_range(4.0, 11.0)
				var at: Vector3 = FlightDirector.asteroid_point(travel) + Vector3(cos(angle) * distance, sin(angle) * distance * (0.65 if peripheral else 1.0), 0)
				var rotation := Basis.from_euler(Vector3(source_rng.randf() * TAU, source_rng.randf() * TAU, source_rng.randf() * TAU)).scaled(Vector3.ONE * radius)
				transforms.append(Transform3D(rotation, at))
				var velocity: Vector3 = AsteroidArt.tumble_velocity(8000 + rocks.size()) * 0.6
				axes.append(velocity.normalized())
				speeds.append(velocity.length())
				rocks.append({"position": course * at, "radius": radius, "peripheral": peripheral})
			_add_batch(AsteroidArt.create(variant, tint, true), transforms, axes, speeds, course * FlightDirector.asteroid_point(section * 480.0 + 240.0))

func _build_cryo(course: Transform3D, transits: Array[PackedVector3Array]) -> void:
	var field_end: float = FlightDirector.ASTEROID_SPEED * (FlightDirector.ASTEROID_DURATION + FlightDirector.BELT_COAST_DURATION) - 24.0
	var transit_bounds: Array[AABB] = []
	for path in transits:
		var bounds := AABB()
		if not path.is_empty():
			bounds.position = path[0]
			for point in path:
				bounds = bounds.expand(point)
		transit_bounds.append(bounds)
	var rng := RandomNumberGenerator.new()
	rng.seed = 49173
	var giant_rng := RandomNumberGenerator.new()
	giant_rng.seed = 72691
	for section in range(ceili(field_end / 480.0)):
		var center: Vector3 = course * FlightDirector.asteroid_point(section * 480.0 + 240)
		for variant in range(AsteroidArt.VARIANTS):
			var transforms: Array[Transform3D] = []
			var axes := PackedVector3Array()
			var speeds := PackedFloat32Array()
			for i in range(BASE_ROCKS_PER_BATCH):
				var travel: float = section * 480.0 + rng.randf_range(0, 480)
				var angle: float = rng.randf_range(0, TAU)
				var distance: float = rng.randf_range(FlightState.WIDE_HALF_WIDTH + 20, 160)
				var radius: float = rng.randf_range(4, 11)
				var at: Vector3 = FlightDirector.asteroid_point(travel) + Vector3(cos(angle) * distance, sin(angle) * distance, 0)
				var rotation := Basis.from_euler(Vector3(rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU)).scaled(Vector3.ONE * radius)
				var velocity: Vector3 = AsteroidArt.tumble_velocity(8000 + rocks.size()) * 0.6
				if travel + radius * 1.3 > field_end or not clears_exit(at, radius * 1.3) or not _clears_transits(course * at, radius, transits, transit_bounds):
					continue
				transforms.append(Transform3D(rotation, at))
				axes.append(velocity.normalized())
				speeds.append(velocity.length())
				rocks.append({"position": course * at, "radius": radius, "peripheral": false})
			_add_batch(AsteroidArt.create(variant, Color("#91b2cb"), true, true), transforms, axes, speeds, center)
		for shape in range(2):
			var transforms: Array[Transform3D] = []
			var axes := PackedVector3Array()
			var speeds := PackedFloat32Array()
			for i in range(150):
				var travel: float = section * 480.0 + giant_rng.randf_range(-120, 360)
				var normal_radius: float = giant_rng.randf_range(9, 20)
				var radius: float = normal_radius * GIANT_SCALE
				var angle: float = (i + 0.5) * TAU / 150 + shape * 0.37 + giant_rng.randf_range(-0.025, 0.025)
				var distance: float = radius * 1.3 + giant_rng.randf_range(FlightState.WIDE_HALF_WIDTH + 10, 125)
				var at: Vector3 = FlightDirector.asteroid_point(travel) + Vector3(cos(angle) * distance, sin(angle) * distance, 0)
				var rotation := Basis.from_euler(Vector3(giant_rng.randf() * TAU, giant_rng.randf() * TAU, giant_rng.randf() * TAU)).scaled(Vector3.ONE * radius)
				var velocity: Vector3 = AsteroidArt.tumble_velocity(27000 + rocks.size())
				var spin: float = giant_rng.randf_range(0.025, 0.23)
				# The whole tumbling envelope must pass behind the ship before it climbs.
				if travel + radius * 1.3 > field_end or not clears_exit(at, radius * 1.3) or not _clears_transits(course * at, radius, transits, transit_bounds):
					continue
				transforms.append(Transform3D(rotation, at))
				axes.append(velocity.normalized())
				speeds.append(spin)
				rocks.append({"position": course * at, "radius": radius, "normal_radius": normal_radius, "peripheral": true, "giant": true, "variant": AsteroidArt.GIANT_VARIANTS[shape], "spin": speeds[-1]})
			_add_batch(AsteroidArt.create(AsteroidArt.GIANT_VARIANTS[shape], Color("#9bb6cb"), true, true), transforms, axes, speeds, center, true)

static func clears_exit(position: Vector3, envelope: float) -> bool:
	var end: Transform3D = FlightDirector.asteroid_frame(FlightDirector.ASTEROID_SPEED * (FlightDirector.ASTEROID_DURATION + FlightDirector.BELT_COAST_DURATION))
	return (end.affine_inverse() * position).z >= envelope + 24

func _clears_transits(position: Vector3, radius: float, transits: Array[PackedVector3Array], bounds: Array[AABB]) -> bool:
	var clearance: float = radius * 1.3 + 18.0
	for index in range(transits.size()):
		var path: PackedVector3Array = transits[index]
		if path.is_empty() or not bounds[index].grow(clearance).has_point(position):
			continue
		for i in range(1, path.size()):
			var nearest: Vector3 = Geometry3D.get_closest_point_to_segment(position, path[i - 1], path[i])
			if position.distance_squared_to(nearest) < clearance * clearance:
				return false
	return true

func _add_batch(model: Node3D, transforms: Array[Transform3D], axes: PackedVector3Array, speeds: PackedFloat32Array, center: Vector3, giant: bool = false) -> void:
	if giant:
		# Smaller spatial batches let the renderer cull hidden sections of the ring.
		var local_center: Vector3 = to_local(center)
		for group in range(8):
			var poses: Array[Transform3D] = []
			var group_axes := PackedVector3Array()
			var group_speeds := PackedFloat32Array()
			for i in range(transforms.size()):
				var at: Vector3 = transforms[i].origin
				var bucket: int = int(at.x >= local_center.x) + 2 * int(at.y >= local_center.y) + 4 * int(at.z >= local_center.z)
				if bucket != group:
					continue
				poses.append(transforms[i])
				group_axes.append(axes[i])
				group_speeds.append(speeds[i])
			if not poses.is_empty():
				_create_batch(model, poses, group_axes, group_speeds, center, true)
	else:
		_create_batch(model, transforms, axes, speeds, center, false)
	model.free()

func _create_batch(model: Node3D, transforms: Array[Transform3D], axes: PackedVector3Array, speeds: PackedFloat32Array, center: Vector3, giant: bool) -> void:
	var meshes: Array[MultiMesh] = []
	var model_radius: float = 0.0
	for surface: MeshInstance3D in model.get_children():
		var bounds: AABB = surface.mesh.get_aabb()
		model_radius = maxf(model_radius, bounds.position.abs().max(bounds.end.abs()).length())
	var bounds := AABB()
	for i in range(transforms.size()):
		var scale: Vector3 = transforms[i].basis.get_scale()
		var radius: float = model_radius * maxf(scale.x, maxf(scale.y, scale.z)) + 2.0
		var envelope := AABB(transforms[i].origin - Vector3.ONE * radius, Vector3.ONE * radius * 2)
		bounds = envelope if i == 0 else bounds.merge(envelope)
	for surface: MeshInstance3D in model.get_children():
		var instances := MultiMesh.new()
		instances.transform_format = MultiMesh.TRANSFORM_3D
		instances.mesh = surface.mesh
		instances.instance_count = transforms.size()
		instances.custom_aabb = bounds
		for i in range(transforms.size()):
			instances.set_instance_transform(i, transforms[i])
		meshes.append(instances)
		var node := MultiMeshInstance3D.new()
		node.multimesh = instances
		node.material_override = surface.material_override
		if surface.has_meta("living_shell"):
			node.set_instance_shader_parameter(&"living_shell", true)
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.extra_cull_margin = 2
		node.set_meta("giant", giant)
		add_child(node)
	batches.append({"meshes": meshes, "transforms": transforms, "axes": axes, "speeds": speeds, "center": center, "giant": giant,
		"bounds_center": global_transform * bounds.get_center(), "bounds_radius": bounds.size.length() * 0.5})

func animate(time: float, pilot: Vector3) -> void:
	animation_time = time
	animation_pilot = pilot
	set_process(true)

func _process(_delta: float) -> void:
	# Coalesce physics ticks into one visual upload per rendered frame.
	set_process(false)
	var camera: Camera3D = get_viewport().get_camera_3d()
	for batch in batches:
		if animation_pilot.distance_squared_to(batch["center"]) > pow(VectorArt.VIEW_DISTANCE + 480.0, 2):
			continue
		# A complete rotating envelope behind the camera cannot contribute a pixel.
		if camera != null and camera.to_local(batch["bounds_center"]).z > batch["bounds_radius"]:
			continue
		var transforms: Array[Transform3D] = batch["transforms"]
		var axes: PackedVector3Array = batch["axes"]
		var speeds: PackedFloat32Array = batch["speeds"]
		var meshes: Array[MultiMesh] = batch["meshes"]
		for i in range(transforms.size()):
			var spun: Transform3D = transforms[i]
			spun.basis = Basis(axes[i], animation_time * speeds[i]) * spun.basis
			for mesh in meshes:
				mesh.set_instance_transform(i, spun)
