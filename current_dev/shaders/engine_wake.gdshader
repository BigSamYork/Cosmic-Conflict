shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;

instance uniform vec4 exhaust_color : source_color = vec4(1.0,0.3,0.06,1.0);
instance uniform float flight_age = 0.0;
varying flat float fade;

void vertex() {
	float travel = fract(INSTANCE_CUSTOM.r + flight_age * 1.6);
	float angle = INSTANCE_CUSTOM.g * 6.28318 + travel * 4.0;
	float radius = 0.23 + travel * 0.37;
	vec3 at = vec3(cos(angle)*travel*0.28,sin(angle)*travel*0.28,0.79+travel*4.8);
	vec3 center = (MODELVIEW_MATRIX * vec4(at,1.0)).xyz;
	center.xy += (UV*2.0-1.0)*radius;
	fade = (1.0-travel)*(1.0-travel);
	POSITION = PROJECTION_MATRIX * vec4(center,1.0);
}

void fragment() {
	vec2 q = UV*2.0-1.0;
	float radial = dot(q,q);
	ALBEDO = mix(exhaust_color.rgb * 2.4,vec3(4.2,3.2,2.0),fade*exp(-radial*6.0));
	ALPHA = fade * exp(-radial*4.0);
}
