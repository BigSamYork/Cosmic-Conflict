shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never, fog_disabled;
#include "palette.gdshaderinc"
#include "arrival_curve.gdshaderinc"

uniform float halo_strength : hint_range(0.0, 1.0) = 0.65;
uniform float stroke_width = 1.4;
uniform float fade_start = 850.0;
uniform float fade_end = 1150.0;
uniform float effect_opacity : hint_range(0.0, 1.0) = 1.0;
uniform float emission_gain = 1.0;
varying float view_depth;

void vertex() {
	vec4 view = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec4 other = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX + NORMAL, 1.0));
	if (arrival_curvature > 0.0) {
		view = VIEW_MATRIX * vec4(arrival_world_position((MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz), 1.0);
		other = PROJECTION_MATRIX * (VIEW_MATRIX * vec4(arrival_world_position((MODEL_MATRIX * vec4(VERTEX + NORMAL, 1.0)).xyz), 1.0));
	}
	vec4 clip = PROJECTION_MATRIX * view;
	vec2 delta = other.xy / max(abs(other.w), 0.001) - clip.xy / max(abs(clip.w), 0.001);
	vec2 direction = normalize(delta * VIEWPORT_SIZE + vec2(0.00001, 0.0));
	vec2 sideways = vec2(-direction.y, direction.x);
	float extent = stroke_width + halo_strength * 4.5;
	clip.xy += sideways * UV.y * extent * 2.0 / VIEWPORT_SIZE * clip.w;
	// A view-space bias works with either depth convention without clipping distant strokes.
	vec4 biased = PROJECTION_MATRIX * (view + vec4(0.0, 0.0, min(0.025, abs(view.z) * 0.01), 0.0));
	clip.z = biased.z * clip.w / biased.w;
	POSITION = clip;
	view_depth = -view.z;
	COLOR.rgb = palette_to_output(COLOR.rgb);
}

void fragment() {
	float distance_to_line = abs(UV.y) * (stroke_width + halo_strength * 4.5);
	float core = 1.0 - smoothstep(stroke_width * 0.3, stroke_width * 0.8, distance_to_line);
	float halo = exp(-distance_to_line * 0.85) * 0.38 * halo_strength;
	ALBEDO = COLOR.rgb * emission_gain;
	ALPHA = clamp(core + halo, 0.0, 1.0) * (1.0 - smoothstep(fade_start, fade_end, view_depth)) * COLOR.a * effect_opacity;
}
