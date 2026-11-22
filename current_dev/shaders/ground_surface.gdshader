shader_type spatial;
render_mode unshaded, cull_disabled;

#include "ground_swatch.gdshaderinc"

void vertex() {
    position_on_course = VERTEX;
}

void fragment() {
    ALBEDO = ground_color(position_on_course) * COLOR.rgb;
}
