shader_type spatial;
render_mode cull_disabled, ambient_light_disabled, specular_disabled, shadows_disabled;
global uniform vec3 sector_ambient;
global uniform float ground_time;
global uniform float ground_motion;
uniform float effect_opacity = 1.0;
#include "palette.gdshaderinc"
#include "arrival_curve.gdshaderinc"

varying vec3 blade_color;

void vertex() {
	vec2 bank = INSTANCE_CUSTOM.xy;
	vec2 heading = INSTANCE_CUSTOM.zw;
	float bend = UV.y * UV.y * clamp(VERTEX.y * 0.74, 0.0, 1.35);
	float gust = sin(dot(bank, vec2(0.093, 0.057)) - ground_time * 1.66);
	float flutter = sin(dot(bank, vec2(-0.10, 0.18)) + ground_time * 3.1 + VERTEX.x * 1.7 + VERTEX.z);
	// Undo each tuft's random yaw so a gust runs along the entire bank.
	vec2 wind = vec2(0.91, 0.41);
	vec2 local_wind = vec2(dot(wind, vec2(heading.x, -heading.y)), dot(wind, heading.yx));
	float lean = (0.18 + ground_motion * (gust * 0.63 + flutter * 0.19)) * bend;
	VERTEX.xz += local_wind * lean;
	VERTEX.y -= abs(lean) * bend * 0.18;
	// Individual blades cease to resolve beyond the near marsh.
	float distance_to_tuft = length(MODELVIEW_MATRIX[3].xyz);
	VERTEX *= 1.0 - smoothstep(110.0, 175.0, distance_to_tuft);
	VERTEX = arrival_local_position(VERTEX, MODEL_MATRIX);
	blade_color = palette_to_output(COLOR.rgb) * (1.0 + gust * bend * 0.058 * ground_motion);
}

void fragment() {
	if (effect_opacity < 1.0 && effect_opacity <= arrival_coverage_sample(FRAGCOORD.xy)) { discard; }
	ALBEDO = blade_color;
	EMISSION = blade_color * sector_ambient;
	ROUGHNESS = 0.84;
}
