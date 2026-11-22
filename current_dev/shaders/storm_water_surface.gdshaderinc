#include "palette.gdshaderinc"
#include "arrival_curve.gdshaderinc"
#include "sea_swell.gdshaderinc"
uniform sampler2D sea_detail : repeat_enable, filter_linear_mipmap_anisotropic;
#ifdef RIG_REFLECTION
uniform sampler2D scene_color : hint_screen_texture, repeat_disable, filter_linear;
uniform sampler2D scene_depth : hint_depth_texture, repeat_disable, filter_nearest;

vec4 reflected_structure(vec3 surface, vec3 ray, mat4 projection, mat4 inverse_projection) {
	float travel = 0.7;
	for (int i = 0; i < 12; i++) {
		travel = travel * 1.34 + 0.7;
		vec3 point = surface + ray * travel;
		vec4 clip = projection * vec4(point, 1.0);
		if (clip.w <= 0.0) { break; }
		vec2 uv = clip.xy / clip.w * 0.5 + 0.5;
		vec2 border = min(uv, 1.0 - uv);
		if (min(border.x, border.y) <= 0.002) { break; }
		float depth = textureLod(scene_depth, uv, 0.0).r;
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
		depth = depth * 2.0 - 1.0;
#endif
		vec4 hit = inverse_projection * vec4(uv * 2.0 - 1.0, depth, 1.0);
		float separation = hit.z / hit.w - point.z;
		if (separation >= 0.0 && separation < 0.5 + travel * 0.24) {
			float edge = smoothstep(0.002, 0.065, min(border.x, border.y));
			return vec4(textureLod(scene_color, uv, 0.0).rgb, edge * (1.0 - smoothstep(70.0, 128.0, travel)));
		}
	}
	return vec4(0.0);
}
#endif
#ifdef ARRIVAL_FADE
uniform float effect_opacity = 1.0;
#endif
varying vec2 water_position;
varying vec3 swell; // Course-space height derivatives and crest compression.

void vertex() {
	water_position = VERTEX.xz;
	swell = vec3(0.0);
	if (VERTEX.y > -8.0) {
		vec3 offset = sea_swell(water_position, swell);
		float edge = 1.0 - smoothstep(218.0, 288.0, abs(VERTEX.x));
		VERTEX += offset * edge;
		swell *= edge;
	}
	VERTEX = arrival_local_position(VERTEX, MODEL_MATRIX);
}

void fragment() {
	vec2 p = water_position;
	vec2 drift = vec2(0.48, 0.23) * wave_time;
	vec4 broad = texture(sea_detail, (p - drift) / 53.0);
	vec4 fine = texture(sea_detail, vec2(-p.y, p.x) / 17.0 - drift.yx * 0.048);
	float footprint = length(fwidth(p));
	float detail = 1.0 - smoothstep(0.7, 4.0, footprint);
	float film = smoothstep(0.09, 0.32, UV.x + (broad.a - 0.5) * 0.20);
	vec2 ripple = (broad.rg - 0.5) * 0.41 + vec2(fine.g - 0.5, 0.5 - fine.r) * 0.20;
	vec2 gradient = swell.xy / max(0.68, 1.0 - 0.47 * swell.z);
	gradient += ripple * detail * (1.0 - 0.83 * film);
	vec3 normal = normalize(MODEL_NORMAL_MATRIX * vec3(-gradient.x, 1.0, -gradient.y));
	vec3 eye = normalize(mat3(INV_VIEW_MATRIX) * VIEW);
	vec3 sky_ray = reflect(-eye, normal);
	float facing = clamp(dot(eye, normal), 0.0, 1.0);
	float fresnel = 0.021 + 0.979 * pow(1.0 - facing, 5.0);
	float cloud = 0.5 + 0.25 * sin(sky_ray.x * 17.0 + sky_ray.z * 11.0 + wave_time * 0.035)
		+ 0.25 * sin(sky_ray.y * 22.0 - sky_ray.z * 9.0 + wave_time * 0.022);
	vec3 sky = mix(vec3(0.105, 0.18, 0.24), vec3(0.42, 0.52, 0.59), smoothstep(0.16, 0.82, cloud));
	float sun = max(dot(sky_ray, normalize(vec3(-0.44, 0.25, -1.0))), 0.0);
	float moon = max(dot(sky_ray, normalize(vec3(0.62, 0.30, -1.0))), 0.0);
	vec3 glint = vec3(0.96, 0.76, 0.53) * pow(sun, 160.0) + vec3(0.48, 0.69, 0.77) * pow(moon, 130.0);
	float backlight = smoothstep(-0.07, 0.23, swell.z) * (0.5 + 0.5 * broad.a);
	vec3 body = mix(vec3(0.025, 0.115, 0.15), vec3(0.055, 0.32, 0.34), backlight);
	vec3 coat = 0.5 + 0.5 * cos(6.283 * (broad.a * 1.35 + facing * 0.62 + vec3(0.05, 0.37, 0.69)));
	body = mix(body, vec3(0.055, 0.062, 0.085) + coat * vec3(0.18, 0.14, 0.19), film * 0.93);
	vec3 water = mix(body, sky, 0.13 + 0.72 * fresnel) + glint * (0.18 + 0.74 * fresnel);
	float breaker = smoothstep(0.095, 0.22, swell.z + 0.082 * (broad.a - 0.5));
	float wash = smoothstep(0.16, 0.79, UV.y) * (0.50 + 0.46 * broad.a);
	float foam = clamp(breaker + wash, 0.0, 1.0) * (1.0 - 0.77 * film);
	float lace = mix(0.35, smoothstep(0.09, 0.83, fine.b * 0.74 + broad.b * 0.51), detail);
	water = mix(water, vec3(0.67, 0.80, 0.79), foam * (0.20 + 0.79 * lace));
	NORMAL = normalize(mat3(VIEW_MATRIX) * normal);
	EMISSION = palette_to_output(water);
#ifdef RIG_REFLECTION
	// Restrict ray marches to nearby water. The sky provides the offscreen reflection.
	if (length(VERTEX) < 160.0 && foam < 0.8) {
		vec4 reflected = reflected_structure(VERTEX, reflect(-VIEW, NORMAL), PROJECTION_MATRIX, INV_PROJECTION_MATRIX);
		float visibility = (1.0 - smoothstep(105.0, 160.0, length(VERTEX))) * (1.0 - foam);
		EMISSION = mix(EMISSION, reflected.rgb, reflected.a * visibility * (0.17 + 0.70 * fresnel));
	}
#endif
	ALBEDO = palette_to_output(mix(vec3(0.075, 0.19, 0.21), vec3(0.70), foam));
	ROUGHNESS = mix(0.26, 0.12, film) + 0.42 * foam;
	SPECULAR = 0.5;
#ifdef ARRIVAL_FADE
	ALPHA = effect_opacity;
#endif
}
