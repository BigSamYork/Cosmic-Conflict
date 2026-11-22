shader_type spatial;
render_mode unshaded, cull_back, blend_mix, depth_draw_never;
#include "palette.gdshaderinc"
#include "arrival_curve.gdshaderinc"

uniform float effect_opacity : hint_range(0.0, 1.0) = 1.0;

void vertex() {
	VERTEX = arrival_local_position(VERTEX, MODEL_MATRIX);
	COLOR.rgb = palette_to_output(COLOR.rgb);
}

void fragment() {
	float facing = abs(dot(normalize(NORMAL), normalize(VIEW)));
	float outline = smoothstep(0.015, 0.22, facing);
	float light = 0.38 + 0.62 * max(0.0, dot(normalize(NORMAL), normalize(vec3(-0.4, 0.8, 0.4))));
	ALBEDO = COLOR.rgb * mix(0.16, light, outline);
	ALPHA = COLOR.a * effect_opacity;
}
