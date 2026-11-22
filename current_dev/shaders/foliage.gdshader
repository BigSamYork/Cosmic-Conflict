shader_type spatial;
global uniform vec3 sector_ambient;
render_mode cull_disabled, ambient_light_disabled, specular_disabled;
#include "sea_swell.gdshaderinc"

varying vec3 leaf_normal;
varying float canopy_height;

void vertex() {
	vec2 patch = INSTANCE_CUSTOM.xy;
	canopy_height = max(VERTEX.y, 0.0);
	float gust = sin(wave_time * 1.25 + patch.x * 0.13 + patch.y * 0.061);
	float flutter = sin(wave_time * 2.1 + VERTEX.x + VERTEX.z + patch.y * 0.094);
	VERTEX.xz += vec2(gust + 0.21 * flutter, 0.34 * flutter) * min(canopy_height * canopy_height * 0.0055, 0.81);
	if (INSTANCE_CUSTOM.z > 0.5) {
		vec3 gradient;
		vec3 swell = sea_swell(patch, gradient);
		VERTEX.y += swell.y / max(0.01, INSTANCE_CUSTOM.w);
	}
	leaf_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

void fragment() {
	vec3 n = normalize(leaf_normal);
	vec3 sun = normalize(vec3(-0.46, 0.81, 0.36));
	float front = dot(n, sun);
	vec3 pigment = COLOR.rgb;
	vec3 leaf = pigment * (0.47 + 0.64 * max(front, 0.0));
	leaf += pigment * vec3(0.40, 0.53, 0.23) * max(-front, 0.0);
	leaf *= mix(0.86, 1.06, smoothstep(0.0, 3.0, canopy_height));
	if (UV.x > 0.8) { leaf = pigment * 1.6; }
	leaf *= sector_ambient;
	EMISSION = OUTPUT_IS_SRGB ? pow(leaf, vec3(1.0 / 2.2)) : leaf;
	ALBEDO = pigment;
	ROUGHNESS = 0.86;
}
