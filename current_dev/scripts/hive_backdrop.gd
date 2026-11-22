class_name HiveBackdrop
extends BeltBackdrop

func build_hive(course: Transform3D, arrival: PackedVector3Array) -> void:
	transform = course
	var field_end: float = FlightDirector.ASTEROID_SPEED * (FlightDirector.ASTEROID_DURATION + FlightDirector.BELT_COAST_DURATION) - 24
	var paths: Array[PackedVector3Array] = [arrival]
	var bounds := AABB()
	if not arrival.is_empty():
		bounds.position = arrival[0]
		for point in arrival:
			bounds = bounds.expand(point)
	var path_bounds: Array[AABB] = [bounds]
	var rng := RandomNumberGenerator.new()
	rng.seed = 78341
	for section in range(ceili(field_end / 480.0)):
		for kind in range(3):
			var mother: bool = kind == 0
			var transforms: Array[Transform3D] = []
			var axes := PackedVector3Array()
			var speeds := PackedFloat32Array()
			var count: int = 14 if mother else 45
			for i in range(count):
				var travel: float = section * 480 + rng.randf_range(-100, 380)
				var scale: float = rng.randf_range(18, 30) if mother else rng.randf_range(7, 17)
				var envelope: float = scale * (3.12 if mother else 1.4)
				var angle: float = (i + rng.randf()) * TAU / count
				var distance: float = envelope + rng.randf_range(65, 160)
				var at: Vector3 = FlightDirector.asteroid_point(travel) + Vector3(cos(angle) * distance, sin(angle) * distance, 0)
				var rotation := Basis.from_euler(Vector3(rng.randf_range(-0.15, 0.15), rng.randf_range(-0.6, 0.6), rng.randf_range(-0.3, 0.3))) if mother else Basis.from_euler(Vector3(rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU))
				var velocity: Vector3 = Vector3.UP * rng.randf_range(0.003, 0.012) if mother else AsteroidArt.tumble_velocity(section * 301 + kind * 77 + i) * 0.25
				if travel + envelope > field_end or not clears_exit(at, envelope) or not _clears_transits(course * at, envelope / 1.3, paths, path_bounds):
					continue
				transforms.append(Transform3D(rotation.scaled(Vector3.ONE * scale), at))
				axes.append(velocity.normalized())
				speeds.append(velocity.length())
				rocks.append({"position": course * at, "radius": envelope / 1.3, "peripheral": true, "kind": "mother" if mother else "egg"})
			var model: Node3D = XyloArt.hive_mother() if mother else XyloArt.egg_ship(kind - 1, true)
			_add_batch(model, transforms, axes, speeds, course * FlightDirector.asteroid_point(section * 480 + 240))
			batches[-1]["kind"] = "mother" if mother else "egg"
