shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_prepass_alpha;
#include "palette.gdshaderinc"
#include "arrival_curve.gdshaderinc"

uniform vec4 hull_tint : source_color = vec4(1.0);
uniform float phase_time = 0.0;
uniform float effect_opacity : hint_range(0.0, 1.0) = 1.0;
varying vec3 local_position;

void vertex() {
	local_position = VERTEX;
	VERTEX = arrival_local_position(VERTEX, MODEL_MATRIX);
	COLOR.rgb = palette_to_output(COLOR.rgb);
}

void fragment() {
	float scan = pow(0.5 + 0.5 * sin(local_position.y * 1.7 + local_position.z * 0.4 - phase_time * 7.0), 10.0);
	vec3 signal = palette_to_output(vec3(0.37, 0.82, 0.91));
	ALBEDO = mix(COLOR.rgb * hull_tint.rgb, signal, 0.25 + scan * 0.45);
	EMISSION = signal * scan * 0.12;
	ALPHA = (0.18 + scan * 0.28) * effect_opacity;
}
