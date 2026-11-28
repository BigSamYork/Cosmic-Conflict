shader_type spatial;
render_mode ambient_light_disabled, specular_disabled;

global uniform vec3 sector_ambient;
varying vec3 tissue_position;
varying vec3 tissue_normal;

float hash_cell(vec3 p) {
	p = fract(p * vec3(0.1031, 0.1030, 0.0973));
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}

float tissue_noise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	vec2 z = vec2(0, 1);
	return mix(mix(mix(hash_cell(i), hash_cell(i + z.yxx), f.x),
				   mix(hash_cell(i + z.xyx), hash_cell(i + z.yyx), f.x), f.y),
			   mix(mix(hash_cell(i + z.xxy), hash_cell(i + z.yxy), f.x),
				   mix(hash_cell(i + z.xyy), hash_cell(i + z.yyy), f.x), f.y), f.z);
}

void vertex() {
	tissue_position = VERTEX;
	tissue_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

void fragment() {
	vec3 p = tissue_position;
	vec3 n = normalize(tissue_normal);
	vec3 eye = normalize((INV_VIEW_MATRIX * vec4(VIEW, 0)).xyz);
	vec3 key = normalize(vec3(-0.45, 0.79, 0.64));
	float diffuse = max(dot(n, key), 0.0);
	float facing = max(dot(n, eye), 0.0);
	float broad = tissue_noise(4.0 * p);
	// Muscle bundles curve around the oblique ventricular axis under the epicardium.
	float fiber_axis = p.y + 0.44 * p.x + 0.6 * p.x * p.x + broad * 0.18;
	float grain = tissue_noise(vec3(fiber_axis * 45.0, p.x * 7.0, p.z * 11.0));
	float bundle = 1.0 - smoothstep(0.35, 0.55, grain);
	float resolved = 1.0 - smoothstep(0.006, 0.04, fwidth(fiber_axis));
	float muscle = 1.0 - smoothstep(0.1, 0.6, p.y);
	vec3 pigment = COLOR.rgb * (0.82 + 0.34 * broad);
	pigment *= 1.0 - 0.22 * resolved * muscle * bundle;
	vec3 lit = pigment * (0.44 + 0.89 * diffuse) * sector_ambient;
	float glint = max(dot(n, normalize(eye + key)), 0.0);
	float film = 0.035 * pow(glint, 7.0) + (0.19 + 0.12 * broad) * pow(glint, 66.0);
	lit += film * vec3(1.0, 0.83, 0.78) + pow(1.0 - facing, 3.0) * vec3(0.060, 0.017, 0.021);
	EMISSION = OUTPUT_IS_SRGB ? pow(max(lit, vec3(0.0)), vec3(1.0 / 2.2)) : lit;
	ALBEDO = pigment;
}

void light() {
	DIFFUSE_LIGHT += LIGHT_COLOR * ATTENUATION * max(dot(NORMAL, LIGHT), 0.0) / PI;
}
