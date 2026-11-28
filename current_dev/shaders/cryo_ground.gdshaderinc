uniform sampler2D cryo_snow_map : repeat_enable, filter_linear_mipmap_anisotropic;

vec3 cryo_ground(vec3 p, vec3 eye, vec3 slope, vec4 deposit, float detail, float t, float motion) {
    // Wind crosses the canyon at a shallow angle to its ice road.
    vec2 wind = vec2(dot(p.xz, vec2(0.92, -0.39)), dot(p.xz, vec2(0.39, 0.92)));
    vec2 drift_uv = wind / vec2(47.0, 32.0);
    drift_uv.y += 0.062 * sin(wind.x * 0.094 + 1.7 * deposit.a);
    vec2 drift = texture(cryo_snow_map, drift_uv).rg;
    float shelter = smoothstep(0.34, 1.0, slope.y) * (0.64 + 0.33 * slope.y - 0.09 * slope.x);
    float snow = smoothstep(0.22, 0.75, 0.58 * drift.g + 0.42 * deposit.a + 0.29 * shelter - 0.15);
    float grazing = pow(1.0 - clamp(dot(eye, slope), 0.0, 1.0), 3.0);

    // Broad mineral bands run along the buried glacier. Cloudy inclusions
    // interrupt the bands without outlining polygons on the ice face.
    vec2 strata_uv = vec2(p.z * 0.009 + p.x * 0.002, p.y * 0.062 + p.x * 0.014);
    strata_uv.y += 0.14 * drift.g + 0.08 * sin(p.z * 0.036);
    vec2 strata = texture(cryo_snow_map, strata_uv).rg;
    float inclusion = smoothstep(0.30, 0.91, 0.37 * strata.r + 0.63 * strata.g);
    vec3 ice = mix(vec3(0.070, 0.20, 0.30), vec3(0.28, 0.47, 0.53), inclusion);
    ice += grazing * vec3(0.033, 0.074, 0.090);
    // The low valley floor exposes a soft blue channel under patchy snow.
    // Its banks follow the land, including both passes where the route forks.
    float channel = (1.0 - smoothstep(0.5, 5.0, p.y)) * smoothstep(0.17, 0.82, drift.g + 0.17 * deposit.a);
    snow *= 1.0 - 0.59 * channel;
    // Small scallops and icy grains survive up close while the mip chain
    // resolves them back to white on the thin strip at the horizon.
    vec3 scour = texture(cryo_snow_map, drift_uv * vec2(5.8, 6.4) + vec2(0.13, 0.46)).rgb;
    float relief = mix(0.62, 0.76 * drift.r + 0.24 * scour.r, detail);
    vec3 snowpack = mix(vec3(0.22, 0.36, 0.48), vec3(0.82, 0.91, 0.94), relief);
    snowpack *= (0.76 + 0.20 * shelter) * (0.89 + 0.11 * strata.g + 0.07 * scour.g);
    vec3 ground = mix(ice, snowpack, snow * (0.57 + 0.38 * shelter));

    if (motion > 0.0) {
        // Gusts advect across fixed ridges. Slower veils pass behind finer,
        // faster filaments, tracing wind direction even at a grazing angle.
        // Project the view ray to a shallow layer of powder above the crust.
        // Cap the grazing offset to keep far slopes stable and leave crests clean.
        vec2 suspended = eye.xz * (0.36 / max(dot(eye, slope), 0.16));
        vec2 gust_point = wind + vec2(dot(suspended, vec2(0.92, -0.39)), dot(suspended, vec2(0.39, 0.92)));
        vec2 flow = gust_point / vec2(45.0, 29.0);
        flow.y += 0.073 * sin(wind.x * 0.093 + wind.y * 0.045 - t * 0.39);
        float veil = texture(cryo_snow_map, flow - vec2(0.049, 0.003) * t).b;
        float wisps = texture(cryo_snow_map, flow * vec2(1.61, 1.44) + vec2(0.34, 0.51) - vec2(0.11, 0.008) * t).b;
        float plume = smoothstep(0.12, 0.71, veil * 0.84 + wisps * 0.46);
        ground = mix(ground, vec3(0.87, 0.94, 0.97), plume * motion * (0.19 + 0.41 * shelter));
    }
    return ground;
}
