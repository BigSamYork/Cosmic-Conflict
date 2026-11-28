shader_type spatial;
global uniform vec3 sector_ambient;
render_mode cull_disabled, ambient_light_disabled, specular_disabled, shadows_disabled;

#include "ground_swatch.gdshaderinc"

void vertex() {
    position_on_course = VERTEX;
    course_normal = NORMAL;
}

void fragment() {
    vec3 eye = normalize(transpose(mat3(MODEL_MATRIX)) * mat3(INV_VIEW_MATRIX) * VIEW);
    vec3 glow;
    vec3 stone = ground_color(position_on_course, eye, glow) * COLOR.rgb;
    // The canyon and glacier wind their triangles in opposite directions.
    NORMAL = faceforward(normalize(NORMAL), -VIEW, NORMAL);
    EMISSION = stone * sector_ambient + glow;
    ALBEDO = stone;
}
