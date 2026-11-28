// View-facing liquid bead. The dense center absorbs light; a thin edge
// transmits more red and the wet surface carries a small sharp reflection.
vec4 blood_bead(vec2 uv, float variation) {
	vec2 drop = vec2(uv.x * (1.12 - 0.31 * uv.y), uv.y);
	float radius_sq = dot(drop, drop);
	float depth = sqrt(max(0.0, 1.0 - radius_sq));
	vec3 normal = normalize(vec3(drop.x, -drop.y, depth) + vec3(0.0001));
	float glint = pow(max(dot(normal, vec3(-0.43, 0.56, 0.71)), 0.0), 32.0);
	vec3 thin = mix(vec3(0.32, 0.009, 0.007), vec3(0.54, 0.017, 0.012), variation);
	vec3 thick = mix(vec3(0.058, 0.0018, 0.0026), vec3(0.15, 0.003, 0.004), variation);
	return vec4(mix(thin, thick, depth) + vec3(0.52, 0.39, 0.33) * glint,
		1.0 - smoothstep(0.78, 1.0, radius_sq));
}

vec4 blood_mist(vec2 p, float phase) {
	float wisps = sin(p.x * 8.0 + phase) * sin(p.y * 6.0 - phase);
	float density = 1.0 - smoothstep(0.08, 0.98, length(p) + wisps * 0.16);
	return vec4(mix(vec3(0.15, 0.006, 0.004), vec3(0.39, 0.026, 0.016), density), density * 0.37);
}
