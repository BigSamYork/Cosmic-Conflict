uniform float wave_time = 0.0;

void add_wave(vec2 p, vec2 dir, float k, float amplitude, float phase_offset,
		inout vec3 displacement, inout vec3 gradient) {
	float phase = dot(dir, p) * k - sqrt(9.81 * k) * wave_time + phase_offset;
	float s = sin(phase);
	float c = cos(phase);
	displacement += amplitude * vec3(0.47 * dir.x * c, s, 0.47 * dir.y * c);
	gradient.xy += dir * (amplitude * k * c);
	gradient.z += amplitude * k * s;
}

vec3 sea_swell(vec2 p, out vec3 gradient) {
	vec3 offset = vec3(0.0);
	gradient = vec3(0.0);
	add_wave(p, vec2(0.60, 0.80), 0.084, 1.16, 0.3, offset, gradient);
	add_wave(p, vec2(-0.28, 0.96), 0.152, 0.64, 2.1, offset, gradient);
	add_wave(p, vec2(0.91, 0.415), 0.256, 0.28, 4.7, offset, gradient);
	return offset;
}
