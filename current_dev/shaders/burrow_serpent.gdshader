shader_type spatial;
render_mode unshaded, cull_disabled;
#include "palette.gdshaderinc"
global uniform vec3 sector_ambient;
uniform float charge : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D scales : repeat_enable, filter_linear_mipmap_anisotropic;
varying vec3 skin_point;
varying vec3 creature_normal;
varying vec3 local_normal;

void vertex() {
	skin_point = VERTEX * vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	creature_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
	local_normal = NORMAL;
}

void fragment() {
	vec3 n = normalize(creature_normal);
	vec3 eye = normalize(mat3(INV_VIEW_MATRIX) * VIEW);
	if (dot(n, eye) < 0.0) { n = -n; }
	vec3 sun = normalize(vec3(-0.52, 0.77, 0.37));
	// UV.x is the wetness of each tissue. UV.y marks photophores and the iris.
	float wet = UV.x;
	vec3 p = skin_point;
	float mottling = sin(p.x * 6.1 + p.z * 4.0 + sin(p.y * 5.8 + p.x * 2.3))
		* sin(p.y * 8.2 - p.z * 2.7 + sin(p.x * 4.7));
	float visible_detail = 1.0 - smoothstep(0.09, 0.36, length(fwidth(p)));
	float dapple = sin(p.x * 2.6 + p.y * 1.9 + 0.8 * sin(p.z * 2.1))
		* cos(p.y * 3.2 - p.z * 2.8 + 0.7 * sin(p.x * 2.7));
	vec3 pigment = COLOR.rgb * (1.0 + (mottling * 0.085 + dapple * 0.115) * visible_detail);
	if (UV2.x > 0.5) {
		// Weighted projections wrap the scale rows over the brow and snout.
		vec3 weights = pow(abs(normalize(local_normal)), vec3(6.0));
		weights /= max(dot(weights, vec3(1.0)), 0.001);
		vec3 cells = texture(scales, p.zy * vec2(0.18, 0.22)).rgb * weights.x
			+ texture(scales, p.xz * vec2(0.18, 0.22)).rgb * weights.y
			+ texture(scales, p.xy * vec2(0.18, 0.22)).rgb * weights.z;
		float pigment_mask = (0.83 + 0.32 * cells.g) * (1.0 - 0.43 * cells.b);
		pigment *= mix(1.0, pigment_mask, UV2.x);
		// Screen-space surface gradients follow the flexed mesh, including
		// oblique and steep scales on the lips of the jaws.
		vec3 dx = dFdx(VERTEX), dy = dFdy(VERTEX);
		vec3 nv = normalize(mat3(VIEW_MATRIX) * n);
		vec3 u = cross(dy, nv), v = cross(nv, dx);
		float det = dot(dx, u);
		vec3 dh = sign(det) * (dFdx(cells.r) * u + dFdy(cells.r) * v) / max(0.000001, abs(det));
		n = normalize(mat3(INV_VIEW_MATRIX) * (nv - dh * 0.056 * visible_detail));
	}
	float key = max(dot(n, sun), 0.0);
	float rim = pow(1.0 - max(dot(n, eye), 0.0), 2.8);
	float spec = pow(max(dot(n, normalize(eye + sun)), 0.0), mix(12.0, 62.0, wet));
	vec3 lit = palette_to_output(pigment) * (0.42 + key * 0.74 + 0.10 * max(n.y, 0.0));
	lit += palette_to_output(vec3(0.54, 0.65, 0.58)) * (spec * (0.05 + 0.43 * wet) + rim * 0.078);
	ALBEDO = lit * (0.20 + 0.80 * sector_ambient)
		+ palette_to_output(pigment) * UV.y * (0.72 + charge * 1.80);
}
