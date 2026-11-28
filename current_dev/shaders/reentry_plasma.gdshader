shader_type canvas_item;
render_mode unshaded, blend_add;

uniform sampler2D flow_map : repeat_enable, filter_linear_mipmap;
uniform float heat = 0.0;
uniform float flight_time = 0.0;
global uniform float ground_motion;

void fragment() {
    // Stream outward from the nose. Each shoulder has its own curved shock
    // front and the central sightline stays clear, even at peak heating.
    vec2 p = UV - vec2(0.5, 0.46);
    p.x *= clamp(SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x, 1.0, 2.6) / 1.7778;
    float side = p.x < 0.0 ? -1.0 : 1.0;
    float shoulder = abs(p.x);
    float along = shoulder - 0.44 * p.y;
    float cross_flow = p.y + 0.28 * shoulder + 1.28 * shoulder * shoulder;
    float t = flight_time * ground_motion;
    float curl = texture(flow_map, vec2(along * 0.64 - t * 0.14, cross_flow * 0.83 + side * 0.31)).r - 0.5;
    vec2 flow = vec2(along * 0.48 - t * 0.29 + side * 0.23, cross_flow * 2.9 + curl * 0.27);
    float body = texture(flow_map, flow).r;
    vec2 fine = texture(flow_map, flow * vec2(1.55, 2.2) + vec2(-t * 0.12, side * 0.16)).rg;
    float radial = length(p * vec2(1.77, 2.0));
    float edge = smoothstep(0.36, 0.82, radial) * smoothstep(0.03, 0.36, abs(p.x) + p.y * 0.62);
    float bank = smoothstep(0.24, 0.76, body * 0.74 + fine.r * 0.31);
    float filament = smoothstep(0.52, 0.81, fine.g) * smoothstep(0.30, 0.72, body);
    vec3 radiance = vec3(0.78, 0.14, 0.046) * (0.17 + 0.87 * bank);
    radiance += vec3(1.0, 0.59, 0.27) * filament * 1.60;
    radiance += vec3(0.20, 0.15, 0.36) * (1.0 - bank) * fine.r;
    COLOR = vec4(radiance, heat * edge * mix(0.22, 0.89, ground_motion));
}
