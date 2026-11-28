shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

#include "res://shaders/blood.gdshaderinc"

instance uniform float age = 0.0;
instance uniform float radius = 1.0;
instance uniform bool orbital = false;
instance uniform bool whole_body = false;
varying flat vec4 seed;
varying flat float life;

float variation(float i) {
	return fract(sin(i * 78.233 + 2.71) * 4375.853);
}

void vertex() {
	seed = INSTANCE_CUSTOM;
	float index = float(INSTANCE_ID);
	bool mist = seed.x < 0.25;
	bool spurt = seed.x >= 0.67;
	// The cardiac rupture has an initial ejection and a second wave as the
	// body gives way. Torn smaller organs empty in one short burst.
	float delay = seed.w * 0.22 + ((whole_body && seed.z > 0.58) ? 1.20 : 0.0);
	float t = max(age - delay, 0.0);
	life = age < delay ? 1.0 : clamp(t / (mist ? 1.35 : 1.65 + seed.z * 0.75), 0.0, 1.0);
	// Fluid leaves adjacent tears in a few uneven fans. Droplet width,
	// speed and direction vary independently within each fan.
	float angle = spurt ? mix(-0.59, 0.86, variation(index + 5.0)) + floor(variation(index) * 3.0) * 2.1 : variation(index + 4.1) * 6.28318;
	vec3 direction = normalize(vec3(cos(angle), sin(angle), mix(-0.35, 0.85, variation(index + 8.0))));
	float speed = mix(0.60, 2.5, variation(index + 21.0));
	vec3 velocity = mat3(MODELVIEW_MATRIX) * direction * speed;
	float drag = orbital ? 1.0 : 1.0 + t * (mist ? 1.8 : 0.32);
	vec3 fall = mat3(VIEW_MATRIX) * vec3(0.0, orbital ? 0.0 : (mist ? -0.10 : -0.72), 0.0);
	vec3 center = MODELVIEW_MATRIX[3].xyz + radius * (velocity * t / drag + fall * t * t * 0.5);
	vec2 axis = normalize((velocity / (drag * drag) + fall * t).xy + vec2(0.0001));
	vec2 q = UV * 2.0 - 1.0;
	float width = mist ? (0.10 + life * 0.42) : mix(0.019, 0.065, variation(index + 9.0));
	float stretch = mix(spurt ? 3.6 : 1.65, 1.0, smoothstep(0.0, 0.27, life));
	center.xy += radius * width * (axis * q.y * (mist ? 1.0 : stretch) + vec2(axis.y, -axis.x) * q.x);
	POSITION = PROJECTION_MATRIX * vec4(center, 1.0);
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	vec4 fluid = seed.x < 0.25 ? blood_mist(p, seed.y * 28.0) : blood_bead(p, seed.z);
	ALBEDO = OUTPUT_IS_SRGB ? pow(fluid.rgb, vec3(1.0 / 2.2)) : fluid.rgb;
	ALPHA = fluid.a * (1.0 - smoothstep(0.65, 1.0, life));
}
