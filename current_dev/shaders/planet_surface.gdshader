shader_type spatial;
global uniform vec3 sector_ambient;
render_mode unshaded, cull_disabled, depth_draw_opaque;
#include "palette.gdshaderinc"

uniform int terrain_style = 0;
uniform float reveal : hint_range(0.0, 1.0) = 1.0;
uniform float surface_time = 0.0;
varying vec3 surface_direction;

float hash3(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}

float noise3(vec3 p) {
	vec3 cell = floor(p);
	vec3 t = fract(p);
	t = t * t * (3.0 - 2.0 * t);
	return mix(
		mix(mix(hash3(cell), hash3(cell + vec3(1, 0, 0)), t.x),
			mix(hash3(cell + vec3(0, 1, 0)), hash3(cell + vec3(1, 1, 0)), t.x), t.y),
		mix(mix(hash3(cell + vec3(0, 0, 1)), hash3(cell + vec3(1, 0, 1)), t.x),
			mix(hash3(cell + vec3(0, 1, 1)), hash3(cell + vec3(1, 1, 1)), t.x), t.y), t.z);
}

float terrain(vec3 p) {
	float value = 0.0;
	float weight = 0.55;
	for (int i = 0; i < 4; i++) {
		value += noise3(p) * weight;
		p = p * 2.1 + vec3(7.1, 3.8, 1.9);
		weight *= 0.48;
	}
	return value;
}

void vertex() {
	surface_direction = normalize(VERTEX);
	NORMAL = surface_direction;
}

void fragment() {
	vec3 n = normalize(surface_direction);
	float continent = terrain(n * 4.8 + vec3(float(terrain_style) * 9.0, 0, 0));
	float fine = noise3(n * 95.0);
	float ridge = abs(terrain(n * 24.0) - 0.48);
	float land = smoothstep(0.39, 0.52, continent);
	vec3 color = mix(vec3(0.08, 0.09, 0.15), vec3(0.42, 0.22, 0.17), land);
	vec3 atmosphere = vec3(0.48, 0.19, 0.10);
	float emission = 0.0;
	if (terrain_style == 0) {
		float lava = (1.0 - smoothstep(0.009, 0.027, ridge)) * land;
		color = mix(color, vec3(1.0, 0.34, 0.045), lava * 0.9);
		emission = lava * 0.24;
	} else if (terrain_style == 1) {
		float ice = smoothstep(0.30, 0.62, abs(n.y) + continent * 0.38);
		color = mix(vec3(0.08, 0.23, 0.37), vec3(0.75, 0.9, 0.94), max(ice, land * 0.75));
		color = mix(color, vec3(0.20, 0.47, 0.62), (1.0 - smoothstep(0.006, 0.021, ridge)) * ice * 0.65);
		atmosphere = vec3(0.25, 0.58, 0.75);
	} else if (terrain_style == 2) {
		vec2 uv = vec2(atan(n.z, n.x) / 6.2831853 + 0.5, acos(clamp(n.y, -1.0, 1.0)) / 3.14159265);
		vec2 grid = abs(fract(uv * vec2(180.0, 90.0)) - 0.5);
		float roads = smoothstep(0.46, 0.49, max(grid.x, grid.y));
		float district = step(0.42, hash3(vec3(floor(uv * vec2(180.0, 90.0)), 4.0)));
		color = mix(vec3(0.07, 0.07, 0.13), vec3(0.29, 0.14, 0.35), land);
		color = mix(color, mix(vec3(0.68, 0.26, 0.65), vec3(0.25, 0.82, 0.85), district), roads * (0.25 + 0.65 * land));
		emission = roads * district * 0.15;
		atmosphere = vec3(0.48, 0.22, 0.65);
	} else if (terrain_style == 4) {
		float storm = sin(n.x * 26.0 + n.z * 17.0 + continent * 16.0 + surface_time * 0.025);
		color = mix(vec3(0.025, 0.12, 0.23), vec3(0.22, 0.53, 0.63), continent);
		color = mix(color, vec3(0.65, 0.75, 0.80), smoothstep(0.1, 0.9, storm) * 0.6);
		atmosphere = vec3(0.20, 0.55, 0.75);
	} else if (terrain_style == 5) {
		float dunes = 0.5 + 0.5 * sin(n.y * 140.0 + continent * 30.0);
		color = mix(vec3(0.32, 0.17, 0.08), vec3(0.78, 0.55, 0.26), continent * 0.7 + dunes * 0.3);
		color = mix(color, vec3(0.14, 0.20, 0.23), (1.0 - smoothstep(0.006, 0.018, ridge)) * land);
		atmosphere = vec3(0.75, 0.42, 0.14);
	} else {
		color = mix(vec3(0.045, 0.16, 0.13), vec3(0.29, 0.43, 0.10), land);
		color = mix(color, vec3(0.55, 0.67, 0.12), (1.0 - smoothstep(0.012, 0.04, ridge)) * land * 0.7);
		atmosphere = vec3(0.30, 0.53, 0.13);
	}
	float clouds = smoothstep(0.57, 0.74, terrain(n * 11.0 + vec3(surface_time * 0.002, 2.0, 0.0)));
	color = mix(color, vec3(0.76, 0.79, 0.81), clouds * (terrain_style == 0 ? 0.20 : 0.48));
	color *= 0.86 + fine * 0.20;
	float light = 0.13 + 0.87 * max(0.0, dot(n, normalize(vec3(-0.3, 0.8, 0.5))));
	float rim = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), 3.0);
	ALBEDO = palette_to_output(color * light * sector_ambient + atmosphere * rim * 0.16) * reveal;
	EMISSION = palette_to_output(color) * emission * reveal;
}
