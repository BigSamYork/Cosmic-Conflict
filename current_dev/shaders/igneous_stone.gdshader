shader_type spatial;
render_mode cull_back;
uniform bool basalt = false;
uniform float glow = 0.7;
uniform float shape_seed = 0.0;
varying vec3 crust_pos;
float hash(vec3 p) {
	return fract(sin(dot(p, vec3(127.1,311.7,74.7))) * 43758.55);
}
float noise3(vec3 p) {
	vec3 c = floor(p), t = fract(p); t = t*t*(3.0-2.0*t);
	return mix(mix(mix(hash(c),hash(c+vec3(1,0,0)),t.x),mix(hash(c+vec3(0,1,0)),hash(c+vec3(1,1,0)),t.x),t.y),
		mix(mix(hash(c+vec3(0,0,1)),hash(c+vec3(1,0,1)),t.x),mix(hash(c+vec3(0,1,1)),hash(c+vec3(1)),t.x),t.y),t.z);
}
void vertex() {
	vec3 unit = normalize(VERTEX);
	crust_pos = unit + vec3(shape_seed);
	float pits = noise3(crust_pos * 4.4);
	VERTEX *= (0.85 + 0.28 * noise3(crust_pos*2.3) - 0.22 * smoothstep(0.51,0.83,pits));
}
void fragment() {
	float plate = noise3(crust_pos * 5.6 + 0.37 * noise3(crust_pos * 12.0));
	float seams = (1.0 - smoothstep(0.014,0.09,abs(plate - 0.49)));
	float grit = noise3(crust_pos * 34.0);
	vec3 shell = mix(vec3(0.036,0.030,0.030),vec3(0.25,0.20,0.17),plate*grit);
	vec3 hot = basalt ? vec3(1.8,0.32,0.012) : vec3(1.55,0.61,0.12);
	ALBEDO = shell;
	ROUGHNESS = 0.76 + 0.20*grit;
	METALLIC = basalt ? 0.02 : 0.37;
	EMISSION = shell*0.26 + glow * (0.035 + seams * (0.42 + 0.77*grit)) * hot;
}
