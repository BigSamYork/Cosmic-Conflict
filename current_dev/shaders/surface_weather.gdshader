shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, depth_draw_never;

uniform vec4 tint : source_color;
uniform vec4 conditions;
uniform float flight_time = 0.0;
varying float opacity;

void vertex() {
	vec4 seed = INSTANCE_CUSTOM;
	float depth = fract(seed.z - flight_time * (0.21 + 0.06 * seed.w));
	float z = -(3.0 + depth * 68.0);
	float x = (fract(seed.x + flight_time * conditions.z * 0.012) - 0.5) * 87.0 + 0.45 * sin(flight_time + 13.0 * seed.y);
	float y = (fract(seed.y - flight_time * conditions.y * 0.022) - 0.5) * 47.0;
	vec2 extent = conditions.x * vec2(0.67 + seed.w, conditions.w);
	vec2 particle = VERTEX.xy * extent;
	particle.x -= particle.y * 0.11 * conditions.z;
	VERTEX = vec3(x + particle.x, y + particle.y, z);
	opacity = smoothstep(0.0, 0.095, depth) * (1.0 - smoothstep(0.78, 1.0, depth)) * (0.42 + 0.45 * seed.w);
}

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	ALBEDO = tint.rgb * 1.36;
	ALPHA = opacity * (1.0 - smoothstep(0.22, 1.0, dot(uv, uv)));
}
