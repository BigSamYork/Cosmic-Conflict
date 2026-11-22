shader_type spatial;
render_mode unshaded, cull_disabled;

uniform bool read_heat = false;

void fragment() {
	vec3 sensor_normal = normalize(cross(dFdx(VERTEX), dFdy(VERTEX)));
	float angle = abs(dot(sensor_normal, normalize(VIEW)));
	float heat = 0.09 + 0.18 * angle;
	if (read_heat) {
		heat = clamp(0.11 + max(0.0, COLOR.r - COLOR.b) * 3.2 + angle * 0.13, 0.0, 1.0);
	}
	vec3 infrared = mix(vec3(0.015, 0.02, 0.075), vec3(0.29, 0.15, 0.46), smoothstep(0.05, 0.42, heat));
	infrared = mix(infrared, vec3(1.0, 0.37, 0.07), smoothstep(0.34, 0.68, heat));
	infrared = mix(infrared, vec3(1.0, 0.96, 0.7), smoothstep(0.7, 1.0, heat));
	ALBEDO = infrared * (0.96 + 0.04 * sin(FRAGCOORD.y * 1.57));
}
