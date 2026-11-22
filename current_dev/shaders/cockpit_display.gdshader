shader_type canvas_item;
render_mode unshaded;

uniform vec3 inverse_row_0;
uniform vec3 inverse_row_1;
uniform vec3 inverse_row_2;
uniform vec4 atlas_rect;
varying vec2 panel_position;

void vertex() {
	panel_position = VERTEX;
}

void fragment() {
	vec3 point = vec3(panel_position, 1.0);
	vec2 panel_uv = vec2(dot(inverse_row_0, point), dot(inverse_row_1, point)) / dot(inverse_row_2, point);
	vec2 uv = atlas_rect.xy + TEXTURE_PIXEL_SIZE * 0.5 +
		clamp(panel_uv, vec2(0.0), vec2(1.0)) * (atlas_rect.zw - TEXTURE_PIXEL_SIZE);
	COLOR = texture(TEXTURE, uv);
}
