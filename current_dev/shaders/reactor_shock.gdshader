shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
instance uniform float elapsed = 0.0;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float angle = atan(p.y, p.x);
	float r = length(p) + 0.009 * sin(8.0 * angle + elapsed * 7.0);
	float front = exp(-abs(r - 0.91) * 125.0);
	float wake = exp(-abs(r - 0.84) * 32.0);
	float wisps = 0.55 + 0.45 * sin(11.0 * angle + 1.4 * sin(5.0 * angle));
	ALBEDO = mix(vec3(0.29, 0.60, 0.82), vec3(1.9, 0.97, 0.42), front);
	ALPHA = (front * 0.82 + wake * 0.38 * wisps) * (1.0 - smoothstep(0.06, 0.96, elapsed));
}
