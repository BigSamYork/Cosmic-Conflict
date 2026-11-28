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
	course_normal = NORMAL;
	VERTEX = arrival_local_position(VERTEX, MODEL_MATRIX);
	COLOR.rgb = palette_to_output(COLOR.rgb);
}

void fragment() {
	// Large overlapping terrain batches cannot be reliably sorted by their center.
	// Fade their coverage, not their depth: closer ground must always win.
	float coverage = base_color.a * (use_vertex_color ? COLOR.a : 1.0) * effect_opacity;
	if (coverage < 1.0 && coverage <= arrival_coverage_sample(FRAGCOORD.xy)) { discard; }
	vec3 eye = normalize(transpose(mat3(MODEL_MATRIX)) * mat3(INV_VIEW_MATRIX) * VIEW);
	if (use_swatch) {
		vec3 glow;
		vec3 stone = ground_color(position_on_course, eye, glow);
		ALBEDO = stone * COLOR.rgb * sector_ambient + glow;
	} else {
		ALBEDO = base_color.rgb * (use_vertex_color ? COLOR.rgb : vec3(1.0)) * sector_ambient;
	}
}
