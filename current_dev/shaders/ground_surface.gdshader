shader_type spatial;
render_mode cull_disabled, ambient_light_disabled, specular_disabled, shadows_disabled;

#include "ground_swatch.gdshaderinc"

void vertex() {
    position_on_course = VERTEX;
}

void fragment() {
    vec3 stone = ground_color(position_on_course) * COLOR.rgb;
    vec3 face = normalize(cross(dFdx(VERTEX), dFdy(VERTEX)));
    NORMAL = face * (dot(face, VIEW) >= 0.0 ? 1.0 : -1.0);
    EMISSION = stone;
    ALBEDO = stone;
}
