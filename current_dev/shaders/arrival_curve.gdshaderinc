uniform mat4 arrival_ground_to_world;
uniform mat4 arrival_world_to_ground;
uniform float arrival_radius = 4000.0;
uniform float arrival_clearance = 80.0;
uniform float arrival_curvature = 0.0;

vec3 arrival_world_position(vec3 world_position) {
	if (arrival_curvature <= 0.0) {
		return world_position;
	}
	vec3 ground = (arrival_world_to_ground * vec4(world_position, 1.0)).xyz;
	vec3 radial = normalize(vec3(ground.x, arrival_radius, ground.z));
	vec3 curved = radial * (arrival_radius + ground.y + arrival_clearance);
	curved.y -= arrival_radius + arrival_clearance;
	vec3 curved_world = (arrival_ground_to_world * vec4(curved, 1.0)).xyz;
	return mix(world_position, curved_world, arrival_curvature);
}

vec3 arrival_local_position(vec3 vertex, mat4 model) {
	if (arrival_curvature <= 0.0) {
		return vertex;
	}
	return (inverse(model) * vec4(arrival_world_position((model * vec4(vertex, 1.0)).xyz), 1.0)).xyz;
}
