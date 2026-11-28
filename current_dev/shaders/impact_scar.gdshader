shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

uniform vec4 strikes[3];
uniform vec3 axes[3];
uniform bool organic = false;
uniform bool orbital = false;
uniform bool cloaked = false;
varying vec3 surface;
varying vec3 down;

void vertex() {
    // Keep the mark in model space as the part turns, in world-sized units.
    surface = VERTEX * vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
    down = -vec3(normalize(MODEL_MATRIX[0].xyz).y, normalize(MODEL_MATRIX[1].xyz).y, normalize(MODEL_MATRIX[2].xyz).y);
}

void fragment() {
    if (cloaked) { discard; }
    float d = 9.0;
    float rivulet = 0.0;
    for (int i = 0; i < 3; i++) {
        if (strikes[i].w <= 0.0) { continue; }
        vec3 offset = surface - strikes[i].xyz;
        float depth = dot(offset, axes[i]);
        // The ray can contact a gameplay collider ahead of the visible skin.
        vec3 radial = offset - axes[i] * clamp(depth, -0.4, 4.8);
        d = min(d, length(radial) / strikes[i].w);
        if (organic && !orbital) {
            // Project gravity onto the struck face. On upward-facing skin,
            // the blood stays near the puncture instead of running sideways.
            vec3 tangent = down - axes[i] * dot(down, axes[i]);
            float slope = length(tangent);
            tangent /= max(slope, 0.001);
            float radius = strikes[i].w;
            float run = clamp(dot(radial, tangent) / radius, 0.0, 2.4 * slope);
            vec3 side = cross(axes[i], tangent);
            vec3 track = radial / radius - tangent * run - side * sin(run * 3.4 + float(i)) * run * 0.054;
            float width = 0.20 - run * 0.044;
            rivulet = max(rivulet, 1.0 - smoothstep(width * 0.4, width + 0.055, length(track)));
        }
    }
    float grain = sin(dot(surface, vec3(7.1, 2.7, 4.8))) * sin(dot(surface, vec3(2.6, 6.2, 3.0)));
    d += grain * 0.14 + sin(surface.y * 13.0 + surface.z * 4.1) * 0.048;
    if (d > 1.0 && rivulet < 0.01) { discard; }
    vec3 center = organic ? vec3(0.038, 0.001, 0.002) : vec3(0.018, 0.014, 0.017);
    vec3 edge = organic ? vec3(0.38, 0.009, 0.007) : vec3(0.62, 0.235, 0.053);
    vec3 stain = mix(center, edge, smoothstep(0.40, 0.84, d) * (0.77 + grain * 0.23));
    if (organic) {
        stain = mix(stain, vec3(0.22, 0.004, 0.004), rivulet * smoothstep(0.6, 1.0, d));
        float sheen = (1.0 - smoothstep(0.004, 0.04, abs(d - 0.65))) * smoothstep(0.13, 0.75, grain);
        stain += vec3(0.34, 0.21, 0.16) * sheen;
    }
    ALBEDO = OUTPUT_IS_SRGB ? pow(stain, vec3(1.0 / 2.2)) : stain;
    ALPHA = max(1.0 - smoothstep(0.75, 1.0, d), rivulet * 0.9) * 0.94;
}
