uniform sampler2D swatch : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D deposits_map : repeat_enable, filter_linear_mipmap_anisotropic;
uniform int surface_id = 0;
varying vec3 position_on_course;

vec3 ground_color(vec3 p, vec3 eye) {
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
    stone *= light;
    vec4 deposit = texture(deposits_map, p.xz / 57.0 + wind * 0.07);
    float level_ground = smoothstep(0.67, 0.96, slope.y);
    float grazing = pow(1.0 - clamp(dot(eye, slope), 0.0, 1.0), 3.0);
    float close_detail = 1.0 - smoothstep(0.3, 2.8, length(fwidth(p.xz)));
    if (surface_id == 0) { // Ignis: orange heat escaping through cooled basalt.
        float crust = smoothstep(0.60, 0.78, deposit.a) * smoothstep(0.64, 0.94, deposit.b);
        stone += vec3(0.41, 0.071, 0.009) * crust * close_detail;
    } else if (surface_id == 1) { // Cryo: ice glaze with trapped white fractures.
        float glaze = level_ground * smoothstep(0.27, 0.78, deposit.a);
        stone = mix(stone, stone * vec3(0.46, 0.72, 0.86) + vec3(0.07, 0.18, 0.24) * grazing, glaze);
        stone += vec3(0.18, 0.25, 0.29) * smoothstep(0.79, 0.98, deposit.b) * glaze * close_detail;
    } else if (surface_id == 2 || surface_id == 3) { // Rain on asphalt; standing water in peat.
        float pool = level_ground * smoothstep(0.51, 0.60, deposit.a + 0.08 * deposits);
        float streak = 0.5 + 0.5 * sin(p.x * 0.39 + 6.0 * deposit.r + wind.x);
        vec3 sky = surface_id == 2 ? mix(vec3(0.052, 0.22, 0.26), vec3(0.23, 0.064, 0.21), streak) : vec3(0.092, 0.18, 0.112);
        stone = mix(stone, stone * 0.39 + sky * (0.22 + grazing * 0.84), pool);
        if (surface_id == 3) {
            stone += vec3(0.09, 0.11, 0.018) * (1.0 - smoothstep(0.01, 0.065, abs(deposit.a - 0.56))) * level_ground;
        }
    } else if (surface_id == 5) { // Kharon: wind-combed sand spilling over stone.
        float ridge = 0.5 + 0.5 * sin(p.z * 3.6 + p.x * 0.92 + wind.x * 4.0 + 2.3 * deposit.a);
        float sand = level_ground * smoothstep(0.33, 0.79, deposit.a);
        stone = mix(stone, stone * (0.73 + 0.49 * mix(0.5, ridge, close_detail)) + vec3(0.065, 0.038, 0.009), sand);
    }
    return stone;
}
