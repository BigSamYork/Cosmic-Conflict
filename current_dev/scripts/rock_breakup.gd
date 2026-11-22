class_name RockBreakup
extends Node3D

var chunks: Array[Node3D] = []
var velocities := PackedVector3Array()
var spins := PackedVector3Array()
var age: float = 0.0
var lifetime: float = 2.0
var solid_material: StandardMaterial3D
var line_material: ShaderMaterial
var polygons: BreakupEffect

func build(rock: Asteroid, shattered: bool) -> void:
	global_position = rock.global_position
	lifetime = 2.0 if shattered else 0.7
	line_material = VectorArt.line_material.duplicate()
	for i in range(7 if shattered else 2):
		var chunk: Node3D = AsteroidArt.create((rock.variant + i) % AsteroidArt.VARIANTS, Color("#8e8296"), true)
		var direction := Vector3(sin(i * 2.4 + rock.phase), cos(i * 1.7), cos(i * 2.4 + rock.phase)).normalized()
		var radius: float = rock.radius * (0.12 + (i % 3) * 0.025)
		chunk.position = direction * rock.radius * 0.45
		chunk.scale = Vector3.ONE * radius
		for mesh: MeshInstance3D in chunk.get_children():
			if mesh.mesh.has_meta("fragment_vertices"):
				if solid_material == null:
					solid_material = StandardMaterial3D.new()
					solid_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
					solid_material.cull_mode = BaseMaterial3D.CULL_DISABLED
					solid_material.vertex_color_use_as_albedo = true
					solid_material.vertex_color_is_srgb = true
					solid_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				mesh.material_override = solid_material
			else:
				mesh.material_override = line_material
		add_child(chunk)
		chunks.append(chunk)
		velocities.append(direction * (7.0 + i * 0.7))
		spins.append(AsteroidArt.tumble_velocity(11000 + i) * 5.0)
	polygons = BreakupEffect.new()
	add_child(polygons)
	polygons.build(rock, shattered, Color("#8e8296"), 48, lifetime, 8)

func advance(delta: float) -> void:
	age += delta
	var opacity: float = 1.0 - smoothstep(lifetime * 0.25, lifetime, age)
	solid_material.albedo_color.a = opacity
	line_material.set_shader_parameter("effect_opacity", opacity)
	line_material.set_shader_parameter("halo_strength", VectorArt.line_material.get_shader_parameter("halo_strength"))
	line_material.set_shader_parameter("stroke_width", VectorArt.line_material.get_shader_parameter("stroke_width"))
	for i in range(chunks.size()):
		chunks[i].position += velocities[i] * delta
		chunks[i].basis = Basis(spins[i].normalized(), spins[i].length() * delta) * chunks[i].basis
	polygons.advance(delta)

func complete() -> bool:
	return age >= lifetime
