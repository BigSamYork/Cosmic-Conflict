shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

instance uniform float breach_time = 0.0;
instance uniform bool organic = false;
varying flat float life;
varying flat float seed;

void vertex() {
	seed = INSTANCE_CUSTOM.x;
	life = fract(breach_time * (0.38 + 0.13 * seed) + seed);
	vec3 flow = vec3(sin(seed * 6.283 + life * 2.6) * life * 1.7,
		organic ? 1.8 * life - 6.8 * life * life : 6.2 * life,
		life * (2.6 + 2.2 * seed));
	vec3 center = (MODELVIEW_MATRIX * vec4(flow, 1.0)).xyz;
	float width = organic ? 0.18 + 0.29 * seed : 0.32 + 1.15 * life;
	center.xy += (UV * 2.0 - 1.0) * vec2(width, organic ? width * 2.1 : width);
	POSITION = PROJECTION_MATRIX * vec4(center, 1.0);
}

void fragment() {
	vec2 p = 2.0 * UV - 1.0;
	float r = length(p);
	float fade = smoothstep(0.0, 0.12, life) * (1.0 - smoothstep(0.62, 1.0, life));
	vec3 color = organic ? mix(vec3(0.18, 0.009, 0.036), vec3(0.69, 0.046, 0.12), seed) :
		mix(vec3(0.98, 0.42, 0.10), vec3(0.24, 0.26, 0.29), smoothstep(0.02, 0.48, life));
	ALBEDO = OUTPUT_IS_SRGB ? pow(color, vec3(1.0 / 2.2)) : color;
	ALPHA = fade * (1.0 - smoothstep(organic ? 0.65 : 0.15, 1.0, r)) * (organic ? 0.88 : 0.66);
}
