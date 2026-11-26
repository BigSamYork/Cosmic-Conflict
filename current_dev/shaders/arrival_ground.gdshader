shader_type spatial;
render_mode unshaded, cull_disabled;
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
	// Large overlapping terrain batches cannot be reliably sorted by their center.
	// Fade their coverage, not their depth: closer ground must always win.
	float coverage = base_color.a * (use_vertex_color ? COLOR.a : 1.0) * effect_opacity;
	ivec2 p = ivec2(FRAGCOORD.xy) & ivec2(3);
	int a = ((p.x & 1) ^ (p.y & 1)) * 2 + (p.y & 1);
	int b = ((p.x >> 1) ^ (p.y >> 1)) * 2 + (p.y >> 1);
	if (coverage <= (float(4 * a + b) + 0.5) / 16.0) { discard; }
	vec3 eye = normalize(transpose(mat3(MODEL_MATRIX)) * mat3(INV_VIEW_MATRIX) * VIEW);
	ALBEDO = use_swatch ? ground_color(position_on_course, eye) * COLOR.rgb : base_color.rgb * (use_vertex_color ? COLOR.rgb : vec3(1.0));
	ALBEDO *= sector_ambient;
}
