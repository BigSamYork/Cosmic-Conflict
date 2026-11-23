shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

global uniform vec3 sector_ambient;
uniform vec4 hide_color : source_color = vec4(0.26, 0.19, 0.22, 1.0);
uniform vec4 shell_color : source_color = vec4(0.22, 0.32, 0.27, 1.0);
uniform vec4 horn_color : source_color = vec4(0.68, 0.65, 0.42, 1.0);
uniform vec4 scar_color : source_color = vec4(0.48, 0.25, 0.27, 1.0);
varying vec3 local_position;
varying vec3 local_normal;

float hash3(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}

float tissue(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash3(i), hash3(i + vec3(1,0,0)), f.x),
	               mix(hash3(i + vec3(0,1,0)), hash3(i + vec3(1,1,0)), f.x), f.y),
	           mix(mix(hash3(i + vec3(0,0,1)), hash3(i + vec3(1,0,1)), f.x),
	               mix(hash3(i + vec3(0,1,1)), hash3(i + vec3(1,1,1)), f.x), f.y), f.z);
}

void vertex() {
	local_position = VERTEX;
	local_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

void fragment() {
	float kind = COLOR.r;
	float shell = step(0.16, kind) * (1.0-step(0.48,kind));
	float horn = step(0.48, kind) * (1.0-step(0.82,kind));
	float membrane = step(0.82,kind) * (1.0-step(0.96,kind));
	float scar = step(0.96,kind);
	vec3 pigment = mix(mix(mix(hide_color.rgb, shell_color.rgb, shell), horn_color.rgb, horn), scar_color.rgb, scar);
	float mottle = tissue(local_position * vec3(0.85,0.37,0.85));
	float grain = tissue(local_position * vec3(3.5,1.25,3.5));
	float angle = UV.x * 6.283185;
	float cords = sin(angle * 12.0 + mottle * 7.0 + sin(UV.y * 11.0));
	float growth = sin(UV.y * 85.0 + mottle * 7.0);
	float striae = mix(cords, growth, min(1.0, shell + horn));
	pigment *= 0.63 + mottle * 0.48 + grain * 0.19 + striae * 0.13;
	pigment *= mix(1.0, 0.58 + UV.y * 0.85, horn);
	float folds = abs(sin(angle * 5.0 + UV.y * 46.0 + 7.5 * mottle));
	pigment *= mix(0.65 + smoothstep(0.0,0.20,folds) * 0.37, 1.0, min(1.0,shell+horn));
	float ribs = abs(sin(UV.x * 56.55 + 2.0 * sin(UV.y * 8.0) + 1.5*mottle));
	vec3 wing = mix(vec3(0.018,0.018,0.013),vec3(0.080,0.058,0.038),mottle * (0.50+UV.y*0.50));
	pigment = mix(pigment,wing * (0.55+0.45*smoothstep(0.02,0.23,ribs)),membrane);
	float key = 0.46 + 0.62 * max(dot(normalize(local_normal), normalize(vec3(-0.38,0.7,0.65))),0.0);
	ALBEDO = pigment;
	ROUGHNESS = clamp(0.48 + grain*0.26 - shell*0.18 - horn*0.14 - scar*0.27,0.22,0.80);
	SPECULAR = 0.62;
	// Oblique swamp skylight catches the hard edges even on unlit flight stages.
	float rim = pow(1.0-abs(dot(normalize(NORMAL),normalize(VIEW))),3.0);
	EMISSION = (pigment * key * 0.93 + rim * vec3(0.043,0.068,0.049)) * mix(vec3(0.48),vec3(1.0),clamp(sector_ambient,vec3(0.0),vec3(1.0)));
}
