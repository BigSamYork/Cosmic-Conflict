shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_never;

#include "palette.gdshaderinc"
#include "arrival_curve.gdshaderinc"
uniform float effect_opacity : hint_range(0.0, 1.0) = 1.0;

uniform sampler2D density_map : repeat_disable, filter_linear_mipmap;
varying flat float turn;
varying flat float variety;

void vertex() {
	// Each cloud parcel faces the pilot while retaining its individual drift and scale.
	vec3 sx = MODEL_MATRIX[0].xyz;
	vec3 sy = MODEL_MATRIX[1].xyz;
	vec3 sz = MODEL_MATRIX[2].xyz;
	float width = (length(sx)+length(sz))*0.5;
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(vec4(INV_VIEW_MATRIX[0].xyz * width,0.0),
		vec4(INV_VIEW_MATRIX[1].xyz * length(sy),0.0), INV_VIEW_MATRIX[2], vec4(arrival_world_position(MODEL_MATRIX[3].xyz),1.0));
	turn = float(INSTANCE_ID) * 2.39996;
	variety = fract(float(INSTANCE_ID)*0.6181);
}
void fragment() {
	vec2 c = UV-vec2(0.5);
	float a = turn;
	vec2 uv = vec2(dot(c,vec2(cos(a),-sin(a))),dot(c,vec2(sin(a),cos(a))))+0.5;
	vec4 smoke = texture(density_map,clamp(uv,vec2(0.002),vec2(0.998)));
	// The density texture contains light-facing curls over a dense, self-occluding center.
	float light = 0.66 + smoke.g * 0.49 - 0.19 * c.y;
	ALBEDO = palette_to_output(COLOR.rgb) * light * mix(0.88,1.1,variety);
	ALPHA = COLOR.a * smoke.r * effect_opacity;
}
