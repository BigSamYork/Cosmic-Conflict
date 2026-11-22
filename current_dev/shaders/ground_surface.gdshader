shader_type spatial;
global uniform vec3 sector_ambient;
render_mode cull_disabled, ambient_light_disabled, specular_disabled, shadows_disabled;

#include "ground_swatch.gdshaderinc"

void vertex() {
    position_on_course = VERTEX;
}

void fragment() {
    vec3 eye = normalize(transpose(mat3(MODEL_MATRIX)) * mat3(INV_VIEW_MATRIX) * VIEW);
    vec3 stone = ground_color(position_on_course, eye) * COLOR.rgb;
    vec3 face = normalize(cross(dFdx(VERTEX), dFdy(VERTEX)));
    NORMAL = face * (dot(face, VIEW) >= 0.0 ? 1.0 : -1.0);
    EMISSION = stone * sector_ambient;
    ALBEDO = stone;
}
