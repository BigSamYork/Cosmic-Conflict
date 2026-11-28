uniform sampler2D swatch : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D deposits_map : repeat_enable, filter_linear_mipmap_anisotropic;
uniform int surface_id = 0;
varying vec3 position_on_course;
varying vec3 course_normal;
global uniform float ground_time;
global uniform float ground_motion;

#include "ignis_ground.gdshaderinc"
#include "cryo_ground.gdshaderinc"
#include "vespera_ground.gdshaderinc"
#include "xylo_ground.gdshaderinc"
#include "kharon_ground.gdshaderinc"

vec3 ground_color(vec3 p, vec3 eye, out vec3 glow) {
    glow = vec3(0.0);
    vec2 wind = vec2(sin(p.z * 0.009 + p.x * 0.025), cos(p.x * 0.016 - p.z * 0.004));
    vec3 slope = normalize(course_normal);
    float close_detail = 1.0 - smoothstep(0.3, 2.8, length(fwidth(p.xz)));
    vec4 deposit = texture(deposits_map, p.xz / 57.0 + wind * 0.07);
    if (surface_id == 0) {
        return ignis_ground(p, eye, slope, deposit, close_detail, ground_time, ground_motion, glow);
    } else if (surface_id == 1) {
        return cryo_ground(p, eye, slope, deposit, close_detail, ground_time, ground_motion);
    }
    // Two rotated projections and a broad deposit mask break up repeated tiles.
    vec2 uv = p.xz / 26.0;
    float deposits = 0.5 + 0.24 * sin(p.x * 0.031 + wind.y * 2.0) + 0.26 * sin(p.z * 0.013 + wind.x * 2.5);
    vec3 primary = texture(swatch, uv + 0.16 * wind).rgb;
    vec2 rotated = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8)) * uv * 0.53;
    vec3 secondary = texture(swatch, rotated + vec2(0.37, 0.81)).rgb;
    vec3 stone = mix(primary, secondary, smoothstep(0.15, 0.89, deposits) * 0.72);
    stone *= mix(vec3(0.77, 0.81, 0.88), vec3(1.13, 1.08, 0.94), deposits);
    float light = 0.61 + 0.43 * max(dot(slope, vec3(-0.40, 0.82, 0.41)), 0.0);
    stone *= light;
    if (surface_id == 2) {
        stone = vespera_ground(stone, p, eye, slope, deposit, close_detail, ground_time, ground_motion, glow);
    } else if (surface_id == 3) {
        stone = xylo_ground(stone, p, eye, slope, close_detail, ground_time, ground_motion);
    } else if (surface_id == 5) {
        stone = kharon_ground(stone, p, eye, slope, deposit, close_detail, ground_time, ground_motion);
    }
    return stone;
}
