shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never, fog_disabled;
#include "palette.gdshaderinc"

uniform float stroke_width = 6.0;
uniform float halo_strength = 0.9;
varying vec2 edge_and_extent;

void vertex() {
	// PrimaryArt's unit segment runs from local zero to -Z.
	vec4 muzzle = PROJECTION_MATRIX * MODELVIEW_MATRIX[3];
	vec4 target = PROJECTION_MATRIX * (MODELVIEW_MATRIX[3] - MODELVIEW_MATRIX[2]);
	vec4 clip = mix(muzzle, target, UV.x);
	vec2 delta = (target.xy * muzzle.w - muzzle.xy * target.w) * VIEWPORT_SIZE;
	vec2 normal = vec2(-delta.y, delta.x) / max(length(delta), 0.00001);
	float tip_scale = clamp(muzzle.w / max(target.w, 0.001), 0.55, 1.0);
	float extent = (stroke_width + 4.5 * halo_strength) * mix(1.0, tip_scale, UV.x);
	clip.xy += normal * UV.y * extent * 2.0 / VIEWPORT_SIZE * clip.w;
	POSITION = clip;
	// Cancel perspective interpolation across the two triangles of the ribbon.
	edge_and_extent = vec2(UV.y, 1.0) * extent * clip.w;
	COLOR.rgb = palette_to_output(COLOR.rgb);
}

void fragment() {
	float edge = abs(edge_and_extent.x / edge_and_extent.y) * (stroke_width + 4.5 * halo_strength);
	float core = 1.0 - smoothstep(stroke_width * 0.3, stroke_width * 0.8, edge);
	float halo = exp(-edge * 0.85) * 0.38 * halo_strength;
	ALBEDO = COLOR.rgb * 2.8;
	ALPHA = clamp(core + halo, 0.0, 1.0) * COLOR.a;
}
