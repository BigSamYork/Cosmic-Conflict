shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

instance uniform float age = 0.0;
instance uniform float radius = 1.0;
instance uniform bool organic = false;
varying flat vec4 seed;
varying flat float life;

void vertex() {
	seed = INSTANCE_CUSTOM; // kind, direction around the blast, noise phase, launch delay
	bool smoke = seed.x > 0.25 && seed.x < 0.65;
	bool spark = seed.x >= 0.65;
	float t = max(0.0, age - seed.w);
	life = clamp(t / (smoke ? 2.7 : spark ? 1.5 : 1.15), 0.0, 1.0);
	float angle = seed.y * 6.28318;
	vec3 dir = normalize(vec3(cos(angle), sin(angle), 2.0 * seed.z - 1.0));
	float distance_out = spark ? t * (1.4 + seed.z) : (1.0 - exp(-2.9*t)) * (0.2 + 0.8 * seed.z);
	vec3 offset = dir * distance_out;
	offset.y += smoke ? 0.21 * t * t : -0.13 * t * t;
	vec3 center = (VIEW_MATRIX * vec4(MODEL_MATRIX[3].xyz + radius * offset, 1.0)).xyz;
	float size = smoke ? 0.21 + life * 0.68 : 0.14 + 0.41 * sin(3.14159 * life);
	vec2 quad = UV * 2.0 - 1.0;
	if (spark) {
		vec2 axis = normalize((mat3(VIEW_MATRIX) * dir).xy + vec2(0.0001));
		center.xy += radius * (axis * quad.y * 0.19 + vec2(axis.y,-axis.x) * quad.x * 0.029) * (1.0 - life);
	} else {
		center.xy += radius * size * quad;
	}
	if (age < seed.w) { life = 1.0; }
	POSITION = PROJECTION_MATRIX * vec4(center, 1.0);
}

void fragment() {
	vec2 q = UV * 2.0 - 1.0;
	float phase = seed.z * 23.0;
	float detail = sin(q.x * 8.0 + phase + life * 4.0) * sin(q.y * 7.0 - phase)
		+ 0.38 * sin(dot(q, vec2(15.0, 11.0)) + phase);
	float d = length(q) + detail * 0.11;
	float fade = 1.0 - smoothstep(0.48, 1.0, life);
	float coverage = 1.0 - smoothstep(0.23, 1.0, d);
	vec3 c;
	if (seed.x < 0.25) {
		vec3 rim = organic ? vec3(0.70,0.024,0.09) : vec3(1.7,0.16,0.024);
		c = mix(rim, organic ? vec3(1.7,0.6,0.18) : vec3(4.8,2.3,0.54), clamp((1.0-d) * (1.25-life),0.0,1.0));
	} else if (seed.x < 0.65) {
		vec3 ash = organic ? vec3(0.15,0.016,0.033) : vec3(0.078,0.075,0.091);
		c = mix(ash, vec3(0.52,0.26,0.12), (0.4 + 0.16 * detail) * (1.0-life));
		coverage *= 0.78;
	} else {
		c = organic ? vec3(1.4,0.17,0.21) : vec3(4.5,1.6,0.18);
		coverage = exp(-dot(q,q)*3.4);
	}
	ALBEDO = c;
	ALPHA = clamp(coverage * fade, 0.0, 1.0);
}
