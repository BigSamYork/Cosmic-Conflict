#include "palette.gdshaderinc"
#include "arrival_curve.gdshaderinc"
uniform float wave_time = 0.0;
#ifdef ARRIVAL_FADE
uniform float effect_opacity = 1.0;
#endif
varying float crest;
varying vec2 water_position;
void vertex() {
	water_position = VERTEX.xz;
	float wave = sin(VERTEX.x * 0.05 + VERTEX.z * 0.035 + wave_time * 1.5) * 0.9
		+ sin(VERTEX.z * 0.08 - wave_time * 1.1) * 0.5;
	VERTEX.y += wave;
	crest = wave;
	VERTEX = arrival_local_position(VERTEX, MODEL_MATRIX);
}
void fragment() {
	vec3 sea = mix(vec3(0.025, 0.12, 0.19), vec3(0.12, 0.42, 0.52), smoothstep(-1.3, 1.3, crest));
	vec2 p = water_position;
	float chop = sin(dot(p, vec2(0.55, 0.38)) + wave_time * 2.2 + 0.8 * sin(p.y * 0.13)) +
		0.62 * sin(dot(p, vec2(-0.29, 0.76)) - wave_time * 2.7);
	float detail = 1.0 - smoothstep(0.40, 2.1, length(fwidth(p)));
	float breakers = smoothstep(0.70, 1.47, crest + detail * 0.28 * chop);
	float froth = 0.57 + 0.43 * sin(p.x * 0.21 + sin(p.y * 0.35 - wave_time));
	sea = mix(sea, vec3(0.53, 0.74, 0.78), breakers * (0.32 + 0.48 * froth));
	sea += vec3(0.12, 0.18, 0.22) * smoothstep(0.98, 1.6, chop) * detail;
	ALBEDO = palette_to_output(sea);
#ifdef ARRIVAL_FADE
	ALPHA = effect_opacity;
#endif
}
