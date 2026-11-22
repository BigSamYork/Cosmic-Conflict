shader_type spatial;
global uniform vec3 sector_ambient;
render_mode cull_disabled, ambient_light_disabled, specular_disabled;

uniform sampler2D geology : repeat_enable, filter_linear_mipmap_anisotropic;
uniform vec4 seam_color : source_color;
uniform bool glacial = false;
uniform float formation = 0.0;
varying vec3 local;

void vertex() {
	local = VERTEX;
}

void fragment() {
	vec3 p = local * (1.15 + 0.13 * formation) + vec3(formation * 0.37, formation * 0.21, 0.0);
	vec3 w = pow(abs(normalize(local)), vec3(4.0));
	w /= max(dot(w, vec3(1)), 0.001);
	vec3 ore = texture(geology,p.yz).rgb*w.x + texture(geology,p.xz).rgb*w.y + texture(geology,p.xy).rgb*w.z;
	vec3 rock = glacial ? vec3(0.24,0.39,0.48) : mix(vec3(0.14,0.097,0.09),vec3(0.26,0.25,0.27),fract(formation * 0.41));
	vec3 minerals = mix(rock, seam_color.rgb, 0.22 + 0.78 * ore.g);
	vec3 paint = minerals * (0.29 + 1.15 * ore.r + 0.5 * ore.b);
	vec3 normal = normalize(cross(dFdx(VERTEX), dFdy(VERTEX)));
	if (dot(normal, VIEW) < 0.0) { normal = -normal; }
	vec3 n = normalize(mat3(INV_VIEW_MATRIX) * normal);
	float key = 0.36 + 0.73 * max(dot(n, normalize(vec3(-0.47,0.76,0.39))), 0.0);
	float grains = dot(dFdx(ore.b) * vec2(1.0,0.0) + dFdy(ore.b) * vec2(0.0,1.0),vec2(-1.2,1.6));
	vec3 color = paint * key * clamp(1.0 + 2.1 * grains, 0.63, 1.32);
	ALBEDO = paint;
	NORMAL = normal;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	color *= sector_ambient;
	EMISSION = OUTPUT_IS_SRGB ? pow(color,vec3(1.0/2.2)) : color;
}

void light() {
	DIFFUSE_LIGHT += LIGHT_COLOR * ATTENUATION * max(dot(NORMAL,LIGHT),0.0) / PI;
}
