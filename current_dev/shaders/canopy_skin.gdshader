shader_type spatial;
render_mode unshaded, cull_disabled;

instance uniform float grip_age = 0.0;
varying vec3 skin_position;

float hash(vec3 p) {
	p = fract(p * vec3(0.1031, 0.1030, 0.0973));
	p += dot(p, p.yxz + 33.33);
	return fract((p.x + p.y) * p.z);
}

float tissue(vec3 p) {
	vec3 cell = floor(p);
	vec3 f = fract(p);
	f *= f * (3.0 - 2.0 * f);
	vec4 base = vec4(hash(cell), hash(cell + vec3(0, 1, 0)), hash(cell + vec3(0, 0, 1)), hash(cell + vec3(0, 1, 1)));
	cell.x += 1.0;
	vec4 next = vec4(hash(cell), hash(cell + vec3(0, 1, 0)), hash(cell + vec3(0, 0, 1)), hash(cell + vec3(0, 1, 1)));
	vec4 x = mix(base, next, f.x);
	return mix(mix(x.x, x.y, f.y), mix(x.z, x.w, f.y), f.z);
}

void vertex() {
	skin_position = VERTEX;
	float flex = sin(grip_age * 3.8 + VERTEX.y * 3.0);
	VERTEX.z += 0.022 * flex * exp(-3.0 * dot(VERTEX.xy, VERTEX.xy));
	VERTEX.y += 0.016 * sin(grip_age * 2.3 + VERTEX.x * 3.0) * smoothstep(0.75, 1.4, abs(VERTEX.x));
}

void fragment() {
	vec3 p = skin_position;
	float mottling = tissue(p * 8.0) + 0.45 * tissue(p * 22.0);
	float capillary = tissue(p * vec3(16, 8, 10) + 1.6 * mottling);
	float vein = 1.0 - smoothstep(0.012, 0.064, abs(capillary - 0.49));
	float grain = tissue(p * 76.0);
	float pores = smoothstep(0.72, 0.85, grain);
	vec3 skin = COLOR.rgb * (0.48 + 0.64 * mottling);
	skin *= mix(vec3(1), vec3(0.63, 0.28, 0.38), vein * (0.2 + 0.56 * mottling));
	skin *= 1.0 - 0.30 * pores;

	// The Blender mesh tags the recessed oral disc with its own finish.
	float disc = 1.0 - smoothstep(0.01, 0.03, abs(UV.x - 0.44));
	vec2 uv = (p.xy - vec2(0, 0.05)) / vec2(0.29, 0.51);
	float radius = length(uv) + 0.028 * sin(atan(uv.y, uv.x) * 8.0 + grip_age * 2.0);
	float ridge = 0.5 + 0.5 * sin(40.0 * radius - grip_age * 2.4 + mottling);
	vec3 throat = mix(vec3(0.009, 0.001, 0.004), vec3(0.31, 0.038, 0.062), smoothstep(0.22, 0.84, radius) * (0.4 + 0.6 * ridge));
	skin = mix(skin, throat, disc);
	vec3 n = normalize(NORMAL);
	vec3 key = normalize(vec3(-0.48, 0.69, 0.61));
	float wet = pow(max(0.0, dot(n, normalize(key + VIEW))), 48.0) * (0.25 + 0.58 * grain);
	vec3 color = skin * (0.26 + 0.83 * max(0.0, dot(n, key))) + vec3(0.97, 0.80, 0.73) * wet;
	ALBEDO = OUTPUT_IS_SRGB ? pow(color, vec3(1.0 / 2.2)) : color;
}
