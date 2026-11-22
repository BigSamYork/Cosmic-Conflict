uniform sampler2D swatch : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
varying vec3 position_on_course;

vec3 ground_color(vec3 p) {
    // Two rotated projections and a broad deposit mask break up repeated tiles.
    vec2 uv = p.xz / 26.0;
    vec2 wind = vec2(sin(p.z * 0.009 + p.x * 0.025), cos(p.x * 0.016 - p.z * 0.004));
    float deposits = 0.5 + 0.24 * sin(p.x * 0.031 + wind.y * 2.0) + 0.26 * sin(p.z * 0.013 + wind.x * 2.5);
    vec3 primary = texture(swatch, uv + 0.16 * wind).rgb;
    vec2 rotated = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8)) * uv * 0.53;
    vec3 secondary = texture(swatch, rotated + vec2(0.37, 0.81)).rgb;
    vec3 stone = mix(primary, secondary, smoothstep(0.15, 0.89, deposits) * 0.72);
    stone *= mix(vec3(0.77, 0.81, 0.88), vec3(1.13, 1.08, 0.94), deposits);
    vec3 slope = normalize(cross(dFdx(p), dFdy(p)));
    if (slope.y < 0.0) { slope = -slope; }
    float light = 0.61 + 0.43 * max(dot(slope, vec3(-0.40, 0.82, 0.41)), 0.0);
    return stone * light;
}
