shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_never;
#include "palette.gdshaderinc"
#include "arrival_curve.gdshaderinc"

uniform float effect_opacity : hint_range(0.0, 1.0) = 1.0;
uniform float activity = 0.0;
uniform float flow_amount = 0.0;
uniform float flow_time = 0.0;
varying vec3 location;

void vertex() {
	location = VERTEX;
	VERTEX = arrival_local_position(VERTEX, MODEL_MATRIX);
	COLOR.rgb = palette_to_output(COLOR.rgb);
}

void fragment() {
	float progress = clamp(1.0 - location.y / 4.4, 0.0, 1.0);
	float front = 1.0 - smoothstep(flow_amount - 0.06, flow_amount + 0.04, progress);
	float pulse = 0.8 + 0.2 * sin(progress * 24.0 - flow_time * 7.0);
	ALBEDO = COLOR.rgb * (0.65 + activity * pulse);
	ALPHA = front * activity * effect_opacity;
}
