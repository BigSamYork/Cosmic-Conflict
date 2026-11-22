shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_prepass_alpha;
global uniform vec3 sector_ambient;
#include "palette.gdshaderinc"
#include "arrival_curve.gdshaderinc"
#include "ground_swatch.gdshaderinc"

uniform vec4 base_color : source_color = vec4(1.0);
uniform bool use_vertex_color = false;
uniform bool use_swatch = false;
uniform float effect_opacity = 0.0;

void vertex() {
	position_on_course = VERTEX;
	VERTEX = arrival_local_position(VERTEX, MODEL_MATRIX);
	COLOR.rgb = palette_to_output(COLOR.rgb);
}

void fragment() {
	vec3 eye = normalize(transpose(mat3(MODEL_MATRIX)) * mat3(INV_VIEW_MATRIX) * VIEW);
	ALBEDO = use_swatch ? ground_color(position_on_course, eye) * COLOR.rgb : base_color.rgb * (use_vertex_color ? COLOR.rgb : vec3(1.0));
	ALBEDO *= sector_ambient;
	ALPHA = base_color.a * (use_vertex_color ? COLOR.a : 1.0) * effect_opacity;
}
