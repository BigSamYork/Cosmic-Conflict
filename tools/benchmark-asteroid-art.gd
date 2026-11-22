extends SceneTree

# Run with Godot --headless --path current_dev --script <absolute path to this file>.
func _initialize() -> void:
	var times := PackedFloat64Array()
	var geometry := PackedByteArray()
	for sample in range(7):
		VectorArt.model_cache.clear()
		var start := Time.get_ticks_usec()
		var models: Array[Node3D] = []
		for variant in range(5):
			models.append(AsteroidArt.create(variant, Color.GRAY, variant >= 3, variant >= 3))
		times.append((Time.get_ticks_usec() - start) / 1000.0)
		for model in models:
			if sample == 0:
				for surface: MeshInstance3D in model.get_children():
					for attribute in surface.mesh.surface_get_arrays(0):
						if attribute != null:
							geometry.append_array(attribute.to_byte_array())
			model.free()
	times.sort()
	var hash_context := HashingContext.new()
	hash_context.start(HashingContext.HASH_SHA256)
	hash_context.update(geometry)
	print("ASTEROID_COLD_BUILD median_ms=%.2f samples=%d mesh_sha256=%s" % [times[3], times.size(), hash_context.finish().hex_encode()])
	quit()
