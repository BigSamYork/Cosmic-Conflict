shader_type spatial;
render_mode unshaded, cull_disabled;
#include "palette.gdshaderinc"

uniform float age = 0.0;
uniform float wind : hint_range(0.0, 1.0) = 1.0;
varying vec3 normal_world;
varying vec3 strand_position;

void vertex() {
	strand_position = VERTEX;
	// Hair tips carry UV.y = 1, while roots and the undercoat remain attached.
	float sway = sin(age * 3.7 + VERTEX.y * 1.1 + VERTEX.z * .70);
	VERTEX.x += UV.y * UV.y * wind * (.055 + .075 * sway);
	normal_world = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

void fragment() {
	float strand = sin(UV.x * 42.0 + strand_position.y * 2.0) * .5 + .5;
	float fine = sin(UV.x * 76.0 + UV.y * 1.9) * .5 + .5;
	float clump = .83 + .12 * strand + .05 * fine;
	vec3 normal = normalize(normal_world);
	float facing = .52 + .48 * max(0.0, dot(normal, normalize(vec3(-.42,.76,.45))));
	float snow = .17 * smoothstep(.16,.9,normal.y);
	vec3 color = COLOR.rgb * clump * (.88 + .11 * UV.y) + vec3(snow*.8,snow*.9,snow);
	ALBEDO = palette_to_output(clamp(color,0.0,1.0)) * facing;
}
