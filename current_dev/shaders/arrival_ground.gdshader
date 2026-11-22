shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_prepass_alpha;
#include "palette.gdshaderinc"
#include "arrival_curve.gdshaderinc"

uniform vec4 base_color : source_color = vec4(1.0);
uniform bool use_vertex_color = false;
uniform float effect_opacity = 0.0;

void vertex() {
	VERTEX = arrival_local_position(VERTEX, MODEL_MATRIX);
	COLOR.rgb = palette_to_output(COLOR.rgb);
}

void fragment() {
	ALBEDO = base_color.rgb * (use_vertex_color ? COLOR.rgb : vec3(1.0));
	ALPHA = base_color.a * (use_vertex_color ? COLOR.a : 1.0) * effect_opacity;
}
