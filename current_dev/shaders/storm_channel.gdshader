shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, fog_disabled;

uniform float stroke_age = -0.26;
uniform bool quiet = false;
varying float descent;

void vertex() {
	vec4 p = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec4 end = PROJECTION_MATRIX * (p + MODELVIEW_MATRIX * vec4(NORMAL, 0.0));
	vec4 clip = PROJECTION_MATRIX * p;
	vec2 tangent = (end.xy / max(abs(end.w), 0.01) - clip.xy / max(abs(clip.w), 0.01)) * VIEWPORT_SIZE;
	vec2 cross_section = normalize(vec2(-tangent.y, tangent.x) + vec2(0.00001));
	float width = mix(2.2, 6.2, COLOR.a) * clamp(110.0 / max(-p.z, 1.0), 0.55, 1.7);
	clip.xy += cross_section * UV.y * width * 2.0 / VIEWPORT_SIZE * clip.w;
	POSITION = clip;
	descent = clamp(1.0 - VERTEX.y / 105.0, 0.0, 1.0);
}

void fragment() {
	float t = stroke_age;
	float front = smoothstep(-0.26, -0.005, t);
	float leader = 0.30 * (1.0 - smoothstep(front - 0.04, front + 0.008, descent));
	float intensity = leader;
	if (t >= 0.0) {
		float returning = smoothstep(1.0 - 70.0 * t - 0.07, 1.0 - 70.0 * t, descent);
		intensity = quiet ? 0.70 * exp(-3.5 * t) : 0.10 * exp(-2.0 * t) + 1.62 * returning * exp(-14.0 * t);
		if (!quiet && t >= 0.22) { intensity += 1.04 * exp(-17.0 * (t - 0.22)); }
		if (!quiet && t >= 0.53) { intensity += 0.62 * exp(-15.0 * (t - 0.53)); }
	}
	float distance_to_core = abs(UV.y);
	float core = exp(-40.0 * distance_to_core * distance_to_core);
	float glow = exp(-4.7 * distance_to_core);
	ALBEDO = (vec3(0.26, 0.40, 1.0) * glow + vec3(0.92, 0.98, 1.0) * core * 2.1) * COLOR.rgb;
	ALPHA = min(1.0, intensity * COLOR.a) * (1.0 - smoothstep(0.85, 1.0, distance_to_core));
}
