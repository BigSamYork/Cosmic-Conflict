shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

uniform vec4 strikes[3];
uniform vec3 axes[3];
uniform bool organic = false;
uniform bool cloaked = false;
varying vec3 surface;

void vertex() {
    // Keep the mark in model space as the part turns, in world-sized units.
    surface = VERTEX * vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
}

void fragment() {
    if (cloaked) { discard; }
    float d = 9.0;
    for (int i = 0; i < 3; i++) {
        if (strikes[i].w <= 0.0) { continue; }
        vec3 offset = surface - strikes[i].xyz;
        float depth = dot(offset, axes[i]);
        // The ray can contact a gameplay collider ahead of the visible skin.
        vec3 radial = offset - axes[i] * clamp(depth, -0.4, 4.8);
        d = min(d, length(radial) / strikes[i].w);
    }
    float grain = sin(dot(surface, vec3(7.1, 2.7, 4.8))) * sin(dot(surface, vec3(2.6, 6.2, 3.0)));
    d += grain * 0.14 + sin(surface.y * 13.0 + surface.z * 4.1) * 0.048;
    if (d > 1.0) { discard; }
    vec3 center = organic ? vec3(0.14, 0.003, 0.021) : vec3(0.018, 0.014, 0.017);
    vec3 edge = organic ? vec3(0.76, 0.027, 0.083) : vec3(0.62, 0.235, 0.053);
    vec3 stain = mix(center, edge, smoothstep(0.40, 0.84, d) * (0.77 + grain * 0.23));
    ALBEDO = OUTPUT_IS_SRGB ? pow(stain, vec3(1.0 / 2.2)) : stain;
    ALPHA = (1.0 - smoothstep(0.75, 1.0, d)) * 0.94;
}
