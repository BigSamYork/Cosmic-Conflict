shader_type spatial;
render_mode unshaded, cull_back, depth_draw_never, fog_disabled;

uniform vec4 air_color : source_color;
uniform float shell_depth = 0.08;
uniform float reveal = 0.0;
varying vec3 shell_position;

void vertex() {
    VERTEX *= 1.0 + shell_depth;
    shell_position = VERTEX;
}

void fragment() {
    // In planet radii, follow the view ray through the air until it meets
    // either solid ground or the far limb. Low, dense air carries most light.
    vec3 eye = normalize(transpose(mat3(MODEL_MATRIX)) * mat3(INV_VIEW_MATRIX) * VIEW);
    float near_length = max(dot(shell_position, eye), 0.0);
    float impact = length(cross(shell_position, eye));
    float path = impact < 1.0 ? near_length - sqrt(max(0.0, 1.0 - impact * impact)) : 2.0 * near_length;
    float step_length = max(path, 0.0) / 6.0;
    vec3 sun = normalize(vec3(-0.3, 0.8, 0.5));
    vec3 scattered = vec3(0.0);
    float depth = 0.0;
    for (int i = 0; i < 6; i++) {
        vec3 point = shell_position - eye * (float(i) + 0.5) * step_length;
        float h = clamp((length(point) - 1.0) / shell_depth, 0.0, 1.0);
        float density = exp(-4.8 * h) * (1.0 - smoothstep(0.72, 1.0, h)) * step_length / shell_depth;
        float daylight = smoothstep(-0.16, 0.55, dot(normalize(point), sun));
        vec3 hue = mix(air_color.rgb, vec3(0.22, 0.43, 0.86), 0.58 * h);
        scattered += density * hue * (0.075 + 1.35 * daylight);
        depth += density;
    }
    ALBEDO = scattered / max(depth, 0.0001);
    ALPHA = reveal * (1.0 - exp(-0.72 * depth));
}
