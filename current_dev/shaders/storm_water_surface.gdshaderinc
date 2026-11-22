#include "palette.gdshaderinc"
#include "arrival_curve.gdshaderinc"
uniform float wave_time = 0.0;
#ifdef ARRIVAL_FADE
uniform float effect_opacity = 1.0;
#endif
varying float crest;
void vertex() {
	float wave = sin(VERTEX.x * 0.05 + VERTEX.z * 0.035 + wave_time * 1.5) * 0.9
		+ sin(VERTEX.z * 0.08 - wave_time * 1.1) * 0.5;
	VERTEX.y += wave;
	crest = wave;
	VERTEX = arrival_local_position(VERTEX, MODEL_MATRIX);
}
void fragment() {
	vec3 sea = mix(vec3(0.025, 0.12, 0.19), vec3(0.12, 0.42, 0.52), smoothstep(-1.3, 1.3, crest));
	sea = mix(sea, vec3(0.54, 0.76, 0.79), smoothstep(1.05, 1.35, crest) * 0.65);
	ALBEDO = palette_to_output(sea);
#ifdef ARRIVAL_FADE
	ALPHA = effect_opacity;
#endif
}
