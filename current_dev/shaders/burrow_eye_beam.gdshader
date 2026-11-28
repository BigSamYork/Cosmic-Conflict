shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, shadows_disabled;

uniform bool corona = false;

void fragment() {
	// Light at the cockpit fades out before the near plane can slice a
	// nearly head-on cylinder into a screen-sized polygon.
	float distance_fade = smoothstep(4.0, 17.0, length(VERTEX));
	float center = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	ALBEDO = corona ? vec3(1.0, 0.009, 0.004) : vec3(1.0, 0.115, 0.078);
	ALPHA = distance_fade * (corona ? 0.10 + 0.23 * center : 0.83);
}
