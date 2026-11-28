shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

#include "res://shaders/blood.gdshaderinc"

instance uniform float breach_time = 0.0;
instance uniform bool organic = false;
instance uniform bool orbital = false;
instance uniform float pressure = 1.0;
instance uniform float heart_phase = -1.0;
instance uniform vec3 jet_axis = vec3(0.0, 0.0, 1.0);
varying flat float life;
varying flat float seed;

void vertex() {
	seed = INSTANCE_CUSTOM.x;
	// Keep a small hot seam at the source and stagger the other eight puffs
	// evenly so they cannot all drift away from the mount at the same time.
	life = seed == 0.0 ? 0.0 : fract(breach_time * 0.44 + (float(INSTANCE_ID) - 1.0) / 8.0);
	vec3 flow = vec3(sin(seed * 6.283 + life * 2.6) * life * 1.7,
		6.2 * life,
		life * (2.6 + 2.2 * seed));
	vec3 center = (MODELVIEW_MATRIX * vec4(flow, 1.0)).xyz;
	vec2 quad = UV * 2.0 - 1.0;
	if (organic) {
		// Two short ejections per beat with larger gaps between beats.
		float delay = floor(seed * 3.0) / 3.0 + fract(seed * 3.0) * 0.17;
		float beat = breach_time * 0.76;
		if (heart_phase >= 0.0) {
			// Beads leave the freshly torn lip as the ventricle contracts.
			beat = heart_phase - 0.24;
			delay = mix(seed * 0.19, delay, pressure);
		}
		life = seed == 0.0 ? 0.0 : fract(beat - delay);
		float push = (2.0 + 4.9 * pressure) * (0.6 + 0.4 * seed);
		vec3 side = normalize(cross(jet_axis, abs(jet_axis.y) > 0.95 ? vec3(1.0, 0.0, 0.0) : vec3(0.0, 1.0, 0.0)));
		float spread = heart_phase >= 0.0 ? mix(0.33, 1.0, pressure) : 1.0;
		vec3 launch = jet_axis * push + spread * (side * sin(seed * 17.0) * 1.6 + cross(side, jet_axis) * (1.0 + seed));
		float gravity = orbital ? 0.0 : 6.4;
		vec3 velocity = (mat3(MODELVIEW_MATRIX) * launch);
		vec3 fall = mat3(VIEW_MATRIX) * vec3(0.0, -gravity, 0.0);
		center = MODELVIEW_MATRIX[3].xyz + velocity * life + fall * life * life;
		vec2 axis = normalize(velocity.xy + 2.0 * life * fall.xy + vec2(0.0001));
		float width = seed == 0.0 ? 0.63 : (0.16 + seed * 0.21) * (0.64 + pressure * 0.55);
		if (heart_phase >= 0.0 && seed == 0.0) {
			width *= 0.67 + 0.24 * exp(-90.0 * (heart_phase - 0.24) * (heart_phase - 0.24));
		}
		center.xy += (vec2(axis.y, -axis.x) * quad.x + axis * quad.y * mix(2.1, 1.1, life)) * width;
	} else {
		center.xy += quad * (0.32 + 1.15 * life);
	}
	POSITION = PROJECTION_MATRIX * vec4(center, 1.0);
}

void fragment() {
	vec2 p = 2.0 * UV - 1.0;
	float r = length(p);
	float fade = smoothstep(0.0, 0.12, life) * (1.0 - smoothstep(0.62, 1.0, life));
	if (seed == 0.0) {
		fade = 0.82 + 0.12 * sin(breach_time * 3.0);
	}
	vec3 color = mix(vec3(0.98, 0.42, 0.10), vec3(0.24, 0.26, 0.29), smoothstep(0.02, 0.48, life));
	float opacity = (1.0 - smoothstep(0.15, 1.0, r)) * 0.66;
	if (organic) {
		vec4 bead = blood_bead(p, seed);
		color = bead.rgb;
		opacity = bead.a;
	}
	ALBEDO = OUTPUT_IS_SRGB ? pow(color, vec3(1.0 / 2.2)) : color;
	ALPHA = fade * opacity;
}
