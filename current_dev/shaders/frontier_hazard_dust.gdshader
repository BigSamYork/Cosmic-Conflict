shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_never;
#include "palette.gdshaderinc"

varying float seed;

void vertex() {
	seed = float(INSTANCE_ID) * 7.23;
	// Keep the ellipse camera-facing but retain the individual puff's dimensions.
	mat4 lens = VIEW_MATRIX * MODEL_MATRIX;
	vec3 scale = vec3(length(lens[0].xyz), length(lens[1].xyz), length(lens[2].xyz));
	MODELVIEW_MATRIX = mat4(vec4(scale.x,0.0,0.0,0.0), vec4(0.0,scale.y,0.0,0.0),
		vec4(0.0,0.0,scale.z,0.0), lens[3]);
}

float hash2(vec2 p) {
	p = fract(p * vec2(0.107, 0.113));
	p += dot(p, p.yx + 19.19);
	return fract(p.x * p.y);
}
float cloud(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	f = f*f*(3.0-2.0*f);
	return mix(mix(hash2(cell), hash2(cell+vec2(1,0)), f.x),
		mix(hash2(cell+vec2(0,1)), hash2(cell+vec2(1,1)),f.x), f.y);
}
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	vec2 sample_at = p * 3.0 + vec2(seed, seed * 0.7);
	float billow = cloud(sample_at) * 0.68 + cloud(sample_at * 2.3) * 0.32;
	float density = 1.0-smoothstep(0.27, 0.92, length(p) + (billow-0.5)*0.36);
	ALBEDO = palette_to_output(COLOR.rgb * (0.65 + 0.35*billow));
	ALPHA = COLOR.a * density * (0.50 + 0.50*billow);
}
