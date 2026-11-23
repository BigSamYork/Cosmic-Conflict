shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
uniform float phase = 0.0;
uniform bool basalt = false;
uniform float intensity = 1.0;
void fragment() {
	float tail = UV.y;
	float eddies = 0.50 + 0.5 * sin(35.0*tail - 12.0*phase + 4.5*sin(UV.x*43.982 + tail*8.0));
	float haze = pow(1.0-tail,1.5)*(0.26 + 0.74*eddies);
	float edge = pow(1.0 - abs(dot(normalize(NORMAL),normalize(VIEW))),1.5);
	vec3 tip = basalt ? vec3(1.3,0.28,0.016) : vec3(1.4,0.77,0.37);
	vec3 wake = basalt ? vec3(0.49,0.028,0.006) : vec3(0.21,0.37,0.59);
	ALBEDO = mix(tip,wake,smoothstep(0.02,0.74,tail));
	ALPHA = min(0.75, haze*(0.32+edge)*intensity);
}
