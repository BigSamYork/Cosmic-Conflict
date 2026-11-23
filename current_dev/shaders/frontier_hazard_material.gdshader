shader_type spatial;
render_mode cull_disabled, unshaded;
#include "palette.gdshaderinc"

uniform bool ice = false;
uniform float power : hint_range(0.0, 1.0) = 1.0;
varying vec3 local;
varying vec3 world_normal;
varying float lit;

void vertex() {
	local = VERTEX;
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
	lit = UV.x;
}

float grain(vec3 p) {
	p = fract(p * 0.163 + 0.27);
	p += dot(p, p.yzx + 13.17);
	return fract((p.x + p.y) * p.z);
}

void fragment() {
	vec3 n = normalize(world_normal);
	float diffuse = 0.33 + 0.67 * max(0.0, dot(n, normalize(vec3(-0.48, 0.79, 0.37))));
	float rim = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), 2.8);
	float micro = grain(floor(local * 11.0));
	vec3 tint = COLOR.rgb;
	if (ice) {
		float strata = local.y * 25.6 + local.z * 1.8 + local.x * 2.15;
		strata += 0.78 * sin(local.x * 5.3 + local.z * 3.7) + 0.18 * sin(local.z * 15.4);
		float seam = smoothstep(0.93, 1.0, sin(strata));
		float trapped_air = smoothstep(0.975, 0.998, grain(floor(local * vec3(28.0,72.0,33.0))));
		float vein_distance = abs(fract(local.x*1.6 + local.y*1.8 + local.z*.68 + sin(local.y*9.2+local.z*4.1)*.18)-.50);
		float vein = 1.0 - smoothstep(.006,.028,vein_distance);
		tint *= 0.83 + 0.17 * diffuse;
		tint += vec3(0.09, 0.24, 0.25) * (seam * 0.69 + vein*.84 + trapped_air * 0.52 + rim * 0.82);
	} else {
		float score = smoothstep(0.982, 1.0, sin(local.y * 43.0 + local.z * 1.3 + sin(local.z)));
		tint *= 0.86 + 0.13 * micro - score * 0.12;
		tint += rim * vec3(0.15, 0.17, 0.2);
	}
	vec3 color = palette_to_output(clamp(tint, 0.0, 1.0));
	ALBEDO = color * mix(diffuse, 1.0, lit);
	ALBEDO += palette_to_output(COLOR.rgb) * lit * power * 1.3;
}
