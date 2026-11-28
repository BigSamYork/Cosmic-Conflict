shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

#include "res://shaders/blood.gdshaderinc"

instance uniform float burst_age = 0.0;
instance uniform bool orbital = false;
varying flat vec4 particle;
varying flat float progress;

void vertex() {
    particle = INSTANCE_CUSTOM; // Family, half-width, variation, lifespan.
    float t = burst_age;
    progress = clamp(t / particle.w, 0.0, 1.0);
    bool dust = particle.x < 0.5;
    bool blood = particle.x > 1.5 && particle.x < 2.5;
    bool mist = particle.x > 3.5;
    vec3 velocity = MODELVIEW_MATRIX[1].xyz;
    vec3 gravity = mat3(VIEW_MATRIX) * vec3(0.0, orbital ? 0.0 : dust ? 1.2 : mist ? -1.8 : -8.0, 0.0);
    float drag = 1.0 + t * (orbital ? 0.0 : (dust || mist) ? 3.5 : 0.7);
    vec3 center = MODELVIEW_MATRIX[3].xyz + velocity * t / drag + gravity * (0.5 * t * t);
    vec2 along = normalize(velocity.xy / (drag * drag) + gravity.xy * t + vec2(0.0001));
    if (!blood) {
        float spin = particle.z * 29.0 + t * (dust ? 0.7 : 5.0);
        along = vec2(cos(spin), sin(spin));
    }
    float extent = particle.y * ((dust || mist) ? 0.55 + progress * 1.8 : 1.0 - 0.35 * progress);
    vec2 offset = (UV * 2.0 - 1.0) * extent;
    offset.y *= blood ? mix(3.2, 1.06, smoothstep(0.0, 0.60, progress)) : 1.0;
    center.xy += vec2(along.y, -along.x) * offset.x + along * offset.y;
    POSITION = PROJECTION_MATRIX * vec4(center, 1.0);
}

void fragment() {
    vec2 p = UV * 2.0 - 1.0;
    float k = particle.z;
    vec3 color;
    float opacity;
    if (particle.x < 0.5) {
        float lobes = sin(p.x * 6.7 + k * 13.0) * sin(p.y * 5.3 + k * 9.0);
        float cloud = length(p) + lobes * 0.16;
        opacity = (1.0 - smoothstep(0.24, 0.97, cloud)) * 0.68;
        color = mix(vec3(0.13, 0.12, 0.14), vec3(0.64, 0.49, 0.38), k * 0.6 + (1.0 - cloud) * 0.35);
    } else if (particle.x > 3.5) {
        vec4 fog = blood_mist(p, k * 28.0);
        color = fog.rgb;
        opacity = fog.a;
    } else if (particle.x < 1.5 || particle.x > 2.5) {
        float edge = abs(p.x + p.y * 0.29) * 1.55 + abs(p.y) * 0.90;
        opacity = 1.0 - smoothstep(0.82, 1.00, edge);
        color = particle.x < 1.5 ? mix(vec3(0.30, 0.38, 0.44), vec3(1.0, 0.59, 0.19), k)
                                 : mix(vec3(0.22, 0.16, 0.12), vec3(0.74, 0.61, 0.46), k);
        color *= p.x > 0.0 ? 1.25 : 0.55;
    } else {
        vec4 bead = blood_bead(p, k);
        opacity = bead.a;
        color = bead.rgb;
    }
    ALBEDO = OUTPUT_IS_SRGB ? pow(max(color, vec3(0.0)), vec3(1.0 / 2.2)) : color;
    ALPHA = opacity * (1.0 - smoothstep(0.48, 1.0, progress));
}
