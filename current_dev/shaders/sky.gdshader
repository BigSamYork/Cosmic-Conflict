shader_type sky;
global uniform vec3 sector_ambient;
#include "palette.gdshaderinc"
uniform float sun_height = 0.25;
uniform float icy_mix : hint_range(0.0, 1.0) = 0.0;
uniform float city_mix : hint_range(0.0, 1.0) = 0.0;
uniform float swamp_mix : hint_range(0.0, 1.0) = 0.0;
uniform float ocean_mix : hint_range(0.0, 1.0) = 0.0;
uniform float desert_mix : hint_range(0.0, 1.0) = 0.0;
uniform float atmosphere_mix : hint_range(0.0, 1.0) = 0.0;
uniform float weather_time = 0.0;
uniform vec3 storm_direction = vec3(0.0, 1.0, 0.0);
uniform float storm_glow = 0.0;
uniform float surface_time = 0.0;
uniform sampler2D cloud_atlas : hint_default_black, repeat_enable, filter_linear_mipmap;
uniform float planet_visibility : hint_range(0.0, 1.0) = 1.0;

float hash(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

vec2 disc_coords(vec3 ray, vec3 axis, float size) {
	vec3 right = normalize(cross(axis, vec3(0.0, 1.0, 0.0)));
	vec3 up = cross(right, axis);
	return vec2(dot(ray, right), dot(ray, up)) / (size * dot(ray, axis));
}

vec3 ring_color(vec3 color, vec2 p, float body, vec3 tint, float strength) {
	vec2 plane = mat2(vec2(0.94, -0.342), vec2(0.342, 0.94)) * p;
	float orbit = length(vec2(plane.x, plane.y / 0.36));
	float belt = smoothstep(1.36, 1.40, orbit) * (1.0 - smoothstep(1.79, 1.84, orbit));
	float lanes = 0.76 + 0.24 * cos((orbit - 1.40) * 40.0);
	// Only the near arc passes in front of the disc.
	return mix(color, tint * lanes, belt * strength * (plane.y < 0.0 ? 1.0 : 1.0 - body));
}

vec3 solar_disc(vec3 background, vec3 ray) {
	vec3 axis = normalize(vec3(-0.44, sun_height, -1.0));
	if (dot(ray, axis) < 0.98) {
		return background;
	}
	vec2 p = disc_coords(ray, axis, 0.075);
	float radius = length(p);
	background += vec3(0.16, 0.065, 0.013) * (1.0 - smoothstep(0.99, 1.44, radius));
	float limb = sqrt(max(0.0, 1.0 - radius * radius));
	float grain = sin(16.0 * p.y + sin(9.0 * p.x + 4.0 * limb)) *
		sin(12.0 * p.x - 7.0 * limb);
	vec3 photosphere = mix(vec3(0.96, 0.48, 0.17), vec3(1.0, 0.92, 0.63), limb * (0.91 + 0.09 * grain));
	float body = 1.0 - smoothstep(0.992, 1.008, radius);
	vec3 color = mix(background, photosphere, body);
	if (desert_mix > 0.0) {
		color = ring_color(color, p, body, vec3(0.88, 0.67, 0.39), desert_mix);
	}
	return color;
}

// Project a tilted annulus into the same space as the sphere so its far limb
// disappears behind the planet and its near limb can cast a shadow on the disc.
vec3 vespera_giant(vec3 background, vec3 p3, float body, float reveal) {
	vec2 p = mat2(vec2(0.96, 0.28), vec2(-0.28, 0.96)) * p3.xy;
	const vec3 pole = vec3(0.0, 0.916515, 0.4);
	vec3 sun = normalize(vec3(-0.60, 0.47, 0.64));
	vec3 sphere = vec3(p, p3.z);
	float latitude = dot(sphere, pole);
	float band = 0.5 + 0.5 * sin(latitude * 26.0 + 1.2 * sin(p.x * 3.0 + latitude * 6.0));
	vec3 gas = mix(vec3(0.48, 0.32, 0.37), vec3(0.91, 0.72, 0.57), 0.24 + 0.57 * band);
	float t = -dot(sphere, pole) / dot(sun, pole);
	float shadow_radius = length(sphere + sun * t);
	float shade = step(0.0, t) * smoothstep(1.20, 1.32, shadow_radius) * (1.0 - smoothstep(2.01, 2.13, shadow_radius));
	gas *= (0.15 + 0.85 * max(0.0, dot(sphere, sun))) * (1.0 - 0.46 * shade);
	vec3 color = mix(background, gas * reveal, body);
	vec3 ring = vec3(p, -p.y * pole.y / pole.z);
	float radius = length(ring);
	float edge = smoothstep(1.18, 1.25, radius) * (1.0 - smoothstep(2.08, 2.15, radius));
	float gap = smoothstep(0.018, 0.046, abs(radius - 1.74));
	float lanes = 0.70 + 0.19 * sin(radius * 49.0) + 0.09 * cos(radius * 105.0);
	float lit = 1.0 - 0.68 * step(dot(ring, sun), 0.0) * (1.0 - smoothstep(0.90, 1.05, length(cross(ring, sun))));
	vec3 dust = mix(vec3(0.74, 0.46, 0.31), vec3(0.96, 0.82, 0.67), smoothstep(1.27, 2.10, radius));
	float visible = mix(1.0, step(p3.z, ring.z), body);
	return mix(color, dust * lanes * lit * reveal, edge * (0.13 + 0.87 * gap) * visible);
}

vec3 lunar_disc(vec3 background, vec3 ray) {
	vec3 axis = normalize(vec3(0.62, 0.3, -1.0));
	bool giant = city_mix > 0.99 && atmosphere_mix < 0.01;
	if (giant) {
		axis = normalize(vec3(0.34, 0.12, -1.0));
	}
	if (planet_visibility <= 0.0 || dot(ray, axis) < (giant ? 0.964 : 0.98)) {
		return background;
	}
	vec2 p = disc_coords(ray, axis, 0.093);
	float r = length(p);
	float body = 1.0 - smoothstep(0.992, 1.008, r);
	vec3 n = vec3(p, sqrt(max(0.0, 1.0 - r * r)));
	if (giant) {
		return vespera_giant(background, n, body, planet_visibility);
	}
	vec3 rock = mix(vec3(0.60, 0.39, 0.35), vec3(0.60, 0.83, 0.90), icy_mix);
	rock = mix(rock, vec3(0.67, 0.46, 0.69), city_mix);
	rock = mix(rock, vec3(0.51, 0.61, 0.38), swamp_mix);
	rock = mix(rock, vec3(0.55, 0.70, 0.77), ocean_mix);
	rock = mix(rock, vec3(0.78, 0.62, 0.42), desert_mix);
	float crater = min(length(p - vec2(-0.29, 0.18)), length((p - vec2(0.39, -0.37)) * 1.6));
	float relief = 0.88 + 0.08 * sin(n.y * 19.0 + 2.0 * sin(n.x * 8.0 + n.z * 4.0))
		+ 0.15 * exp(-60.0 * abs(crater - 0.20)) - 0.16 * (1.0 - smoothstep(0.15, 0.20, crater));
	float light = 0.17 + 0.83 * max(0.0, dot(n, normalize(vec3(-0.64, 0.48, 0.60))));
	// Reveal by illuminating the surface, not by letting stars through it.
	vec3 color = mix(background, rock * relief * light * planet_visibility, body);
	if (icy_mix > 0.0) {
		color = ring_color(color, vec2(-p.x, p.y), body, vec3(0.60, 0.85, 0.96) * planet_visibility, icy_mix);
	}
	return color;
}

void sky() {
	float height = clamp(EYEDIR.y, 0.0, 1.0);
	COLOR = mix(mix(vec3(0.09, 0.032, 0.048), vec3(0.025, 0.065, 0.11), icy_mix), vec3(0.006, 0.012, 0.032), pow(height, 0.35));
	COLOR = mix(COLOR, mix(vec3(0.08, 0.025, 0.12), vec3(0.008, 0.008, 0.026), pow(height, 0.35)), city_mix);
	COLOR = mix(COLOR, mix(vec3(0.035, 0.075, 0.04), vec3(0.005, 0.014, 0.012), pow(height, 0.35)), swamp_mix);
	COLOR = mix(COLOR, mix(vec3(0.045, 0.11, 0.17), vec3(0.008, 0.018, 0.04), pow(height, 0.35)), ocean_mix);
	COLOR = mix(COLOR, mix(vec3(0.25, 0.14, 0.07), vec3(0.015, 0.012, 0.028), pow(height, 0.35)), desert_mix);
	vec3 cell = floor(EYEDIR * 480.0);
	float star = step(0.9987, hash(cell)) * pow(height, 0.3);
	COLOR += vec3(0.38, 0.62, 0.74) * star;
	vec2 drift = vec2(surface_time * 0.00065, 0.0) * atmosphere_mix;
	float longitude = atan(EYEDIR.x, -EYEDIR.z);
	vec3 air = texture(cloud_atlas, SKY_COORDS + drift).rgb;
	vec3 wisps = texture(cloud_atlas, vec2(SKY_COORDS.x * 2.0 + 0.41, SKY_COORDS.y + 0.25) - drift * 0.55).rgb;
	float ribbon = height - (0.27 + 0.17 * sin(longitude * 2.0 + 0.3) + 0.055 * cos(longitude * 5.0));
	float nebula = exp(-ribbon * ribbon * 19.0) * smoothstep(0.33, 0.79, air.r) * (0.44 + 0.86 * wisps.g);
	COLOR += mix(vec3(0.075, 0.065, 0.17), vec3(0.045, 0.14, 0.15), air.b) * nebula * (1.0 - 0.79 * atmosphere_mix);
	float volcanic = max(0.0, 1.0 - icy_mix - city_mix - swamp_mix - ocean_mix - desert_mix);
	float cloud_bank = smoothstep(0.27, 0.77, air.r * 0.74 + wisps.r * 0.26) * exp(-3.0 * height);
	vec3 haze = volcanic * vec3(0.23, 0.085, 0.048) + desert_mix * vec3(0.26, 0.18, 0.105) +
		swamp_mix * vec3(0.075, 0.16, 0.098) + city_mix * vec3(0.14, 0.074, 0.18) +
		icy_mix * vec3(0.09, 0.16, 0.21) + ocean_mix * vec3(0.095, 0.15, 0.19);
	COLOR += haze * cloud_bank * atmosphere_mix;
	float curtain = exp(-abs(ribbon + (air.r - 0.5) * 0.39) * 15.0) * smoothstep(0.18, 0.82, air.b);
	COLOR += atmosphere_mix * icy_mix * mix(vec3(0.045, 0.23, 0.17), vec3(0.13, 0.10, 0.23), wisps.r) * curtain;
	float skyglow = exp(-height * 10.0) * max(0.0, cos(longitude * 8.0 + air.r * 6.0));
	COLOR += atmosphere_mix * city_mix * skyglow * vec3(0.15, 0.061, 0.19);
	COLOR = solar_disc(COLOR, EYEDIR);
	float storm = 0.5 + 0.25 * sin(EYEDIR.x * 17.0 + EYEDIR.z * 11.0 + weather_time * 0.035)
		+ 0.25 * sin(EYEDIR.y * 22.0 - EYEDIR.z * 9.0 + weather_time * 0.022);
	float cloud = smoothstep(0.2, 0.75, storm) * smoothstep(-0.15, 0.2, EYEDIR.y);
	COLOR = mix(COLOR, mix(vec3(0.055, 0.11, 0.15), vec3(0.17, 0.24, 0.29), cloud),
		ocean_mix * atmosphere_mix * (0.65 + cloud * 0.35));
	float separation = max(0.0, 1.0 - dot(EYEDIR, storm_direction));
	float sheet = exp(-separation * 13.0) * (0.17 + 0.53 * air.r + 0.30 * cloud);
	COLOR += vec3(0.28, 0.34, 0.53) * sheet * storm_glow * atmosphere_mix * ocean_mix;
	COLOR = lunar_disc(COLOR, EYEDIR);
	COLOR = palette_to_output(COLOR * sector_ambient);
}
