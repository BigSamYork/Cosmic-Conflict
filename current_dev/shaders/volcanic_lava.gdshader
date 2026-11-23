shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_never;
#include "palette.gdshaderinc"
#include "arrival_curve.gdshaderinc"

uniform float effect_opacity : hint_range(0.0, 1.0) = 1.0;
uniform float activity = 0.0;
uniform float flow_amount = 0.0;
uniform float flow_time = 0.0;
varying vec3 bed;

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
float noise21(vec2 p) {
	vec2 c = floor(p), f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash21(c), hash21(c + vec2(1,0)), f.x), mix(hash21(c + vec2(0,1)), hash21(c + vec2(1)), f.x), f.y);
}
void vertex() {
	bed = VERTEX;
	VERTEX = arrival_local_position(VERTEX, MODEL_MATRIX);
}
void fragment() {
	float center = 1.0 - abs(UV.x * 2.0 - 1.0);
	// A viscous center slides past nearly stationary, cooler levees. Folded plates
	// of clinker ride the flow, exposing narrow yellow fissures between them.
	float drift = flow_time * (0.105 + 0.33 * smoothstep(0.0, 0.85, center));
	vec2 p = vec2(UV.x * 2.5 + dot(bed.xz, vec2(0.24, -0.14)), UV.y * 18.0 - drift);
	p.x += 0.38 * sin(p.y * 1.6 + noise21(p * 1.4)) + 0.21 * noise21(p * 3.6);
	float folds = abs(sin(p.y * 4.9 + 5.2 * noise21(vec2(p.x * 1.2, p.y * 0.83))));
	float fissure = 1.0 - smoothstep(0.04, 0.31 + 0.08 * center, folds);
	float toes = smoothstep(-0.05, 0.07, flow_amount - UV.y + 0.05 * center);
	float heat = toes * (0.23 + 0.77 * activity) * smoothstep(0.0, 0.42, center);
	float grit = noise21(p * 12.0);
	vec3 crust = mix(vec3(0.10,0.062,0.064), vec3(0.29,0.13,0.081), grit);
	vec3 melt = mix(vec3(0.92,0.23,0.035), vec3(1.0,0.80,0.28), fissure);
	ALBEDO = palette_to_output(mix(crust, melt, heat * (0.34 + 0.66 * fissure)));
	EMISSION = palette_to_output(melt) * (0.19 + 1.02 * fissure) * heat;
	ALPHA = effect_opacity;
}
