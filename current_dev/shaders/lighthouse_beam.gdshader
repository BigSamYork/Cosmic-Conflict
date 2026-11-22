shader_type spatial;
render_mode unshaded, blend_add, cull_back, depth_draw_never;

varying float distance_from_lens;

void vertex() {
	distance_from_lens = (24.0 - VERTEX.y) / 48.0;
}

void fragment() {
	ALBEDO = vec3(0.68, 0.89, 1.0);
	ALPHA = 0.23 * pow(clamp(1.0 - distance_from_lens, 0.0, 1.0), 1.55);
}
