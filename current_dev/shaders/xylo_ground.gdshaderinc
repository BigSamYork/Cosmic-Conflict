vec3 xylo_ground(vec3 stone, vec3 p, vec3 eye, vec3 slope, float detail, float t, float motion) {
	// Flooded hollows widen and join as the winding peat shelves fall away.
	vec2 basin_uv = p.xz * 0.020;
	float shelf = 0.22 * sin(basin_uv.x * 1.45 + 2.1 * sin(basin_uv.y))
		+ 0.17 * sin(basin_uv.y * 1.8 - basin_uv.x + 1.5 * sin(basin_uv.x * 0.73));
	float hummock = sin(p.z * 0.134 + 1.45 * sin(p.x * 0.128) + cos(p.z * 0.089 - p.x * 0.20));
	float hummock_detail = sin(p.x * 0.39 - p.z * 0.205 + 2.1 * hummock + sin(p.z * 0.64 + p.x * 0.19));
	float bank = 0.5 + 0.5 * hummock_detail;
	float shore = 0.302 + 0.065 * hummock + 0.014 * hummock_detail + shelf;
	float pools = smoothstep(0.31, 0.366, shore) * smoothstep(0.73, 0.97, slope.y);
	float damp = smoothstep(0.21, 0.33, shore);
	vec3 peat = mix(stone * vec3(1.08, 1.12, 0.80), stone * vec3(0.58, 0.68, 0.66), damp);
	float rim = 1.0 - smoothstep(0.007, 0.036, abs(shore - 0.32));
	peat += vec3(0.038, 0.052, 0.008) * rim * (0.3 + 0.7 * bank);

	// Subtle capillary ripples turn into a single broad reflection in the distance.
	float phase = p.z * 1.23 + p.x * 0.57 + sin(p.x * 0.38 + 2.2 * hummock) * 0.72;
	float wave = sin(phase - t * 1.38 * motion) * 0.63
		+ sin(phase * 1.82 + p.x * 0.27 + t * 0.78 * motion) * 0.37;
	float ripple = smoothstep(0.52, 0.94, wave) * detail;
	float fresnel = pow(1.0 - clamp(dot(eye, slope), 0.0, 1.0), 3.0);
	vec3 water = stone * vec3(0.18, 0.30, 0.30) + vec3(0.008, 0.025, 0.024);
	water += vec3(0.034, 0.096, 0.079) * fresnel * (0.7 + hummock * 0.3);
	water += vec3(0.027, 0.052, 0.047) * ripple * (0.25 + 0.75 * fresnel);
	// Small duckweed rafts gather on the sheltered edge of each hollow.
	float leaves = sin(dot(p.xz, vec2(1.61, 0.84)) + hummock_detail * 2.9) * 0.30 + bank;
	float raft = (1.0 - smoothstep(0.37, 0.46, shore)) * smoothstep(0.92, 1.18, leaves);
	return mix(peat, mix(water, vec3(0.12, 0.17, 0.035), raft * 0.59), pools);
}
