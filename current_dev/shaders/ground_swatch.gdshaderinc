uniform sampler2D swatch : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
varying vec3 position_on_course;

vec3 ground_color(vec3 p) {
    vec3 stone = texture(swatch, p.xz / 26.0).rgb;
    vec3 slope = normalize(cross(dFdx(p), dFdy(p)));
    if (slope.y < 0.0) { slope = -slope; }
    float light = 0.61 + 0.43 * max(dot(slope, vec3(-0.40, 0.82, 0.41)), 0.0);
    return stone * light;
}
