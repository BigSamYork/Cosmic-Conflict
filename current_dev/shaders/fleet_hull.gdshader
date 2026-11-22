shader_type spatial;
render_mode unshaded, cull_disabled;

// The game uses an unlit world. A broad key and cool reflected light give the
// curved armor a consistent volume even in the first-person hangar viewport.
varying vec3 hull_normal;
varying vec3 local_position;

uniform float pulse_strength : hint_range(0.0, 1.0) = 1.0;

instance uniform bool parked = false;

void vertex() {
    hull_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
    local_position = VERTEX;
}

void fragment() {
    vec3 n = normalize(hull_normal);
    vec3 eye = normalize((INV_VIEW_MATRIX * vec4(VIEW, 0.0)).xyz);
    vec3 key = vec3(-0.46, 0.81, 0.36);
    float facing = max(dot(n, eye), 0.0);
    float rim = pow(1.0 - facing, 3.0);
    float finish = UV.x;
    float glass = 1.0 - smoothstep(0.01, 0.03, abs(finish - 0.44));
    float metal = smoothstep(0.19, 0.29, finish);
    float shine = pow(max(dot(n, normalize(eye + key)), 0.0), mix(19.0, 67.0, metal));
    vec3 reflect_dir = reflect(-eye, n);
    float sky_band = smoothstep(-0.12, 0.08, reflect_dir.y) * (1.0 - smoothstep(0.28, 0.57, reflect_dir.y));
    vec3 paint = COLOR.rgb;
    // glTF COLOR_0 is linear. Compatibility writes its unshaded result to sRGB.
    vec3 color = paint * (0.34 + 0.76 * max(0.0, dot(n, key)) + 0.14 * max(n.y, 0.0));
    color += vec3(0.66, 0.82, 0.97) * (shine * (0.13 + 0.38 * metal) + rim * (0.035 + 0.12 * glass));
    color += sky_band * (vec3(0.08, 0.34, 0.47) * glass + paint * metal * 0.23);
    if (finish > 0.69 && finish < 0.78) {
        if (parked) {
            discard;
        }
        float tail = clamp(UV.y, 0.0, 1.0);
        float cells = 0.5 + 0.5 * cos(tail * 15.0 - TIME * 7.0 * pulse_strength);
        vec3 plasma = mix(vec3(0.09, 0.32, 0.80), paint, (1.0 - tail) * 0.9);
        color = plasma * (0.55 + cells * 0.8) + vec3(0.77, 0.88, 0.92) * pow(1.0 - tail, 3.0);
    } else if (finish > 0.8) {
        float phase = local_position.x * 1.7 + local_position.z * 0.8;
        float pulse = sin(TIME * 3.4 + phase) * 0.09;
        if (finish > 0.9) {
            pulse = -0.38 + 0.6 * smoothstep(0.76, 0.97, sin(TIME * 2.7 + phase * 0.1));
        }
        color = paint * (1.45 + pulse * pulse_strength);
    }
    ALBEDO = OUTPUT_IS_SRGB ? pow(max(color, vec3(0.0)), vec3(1.0 / 2.2)) : color;
}
