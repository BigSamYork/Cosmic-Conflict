// Gradient of a raindrop and its following wave. Both die out before they
// reach the cell edge, so adjacent impacts can have independent timings.
vec2 vespera_drop(vec2 q, float time, float footprint) {
    vec2 cell = floor(q);
    vec3 seed = fract(vec3(cell.x, cell.y, cell.x) * vec3(0.1031, 0.1030, 0.0973));
    seed += dot(seed, seed.yzx + 33.33);
    vec3 jitter = fract((seed.xxy + seed.yzz) * seed.zyx);
    vec2 delta = fract(q) - (0.30 + 0.40 * jitter.xy);
    float radius = length(delta);
    float age = fract(time * (0.65 + 0.4 * jitter.y) + jitter.z);
    float offset = radius - age * 0.29;
    float width = 0.022 + min(0.026, footprint);
    float wave = exp(-abs(offset) / width) - 0.66 * exp(-abs(offset + 0.045) / width);
    return delta / max(radius, 0.012) * wave * smoothstep(0.0, 0.12, age)
        * (1.0 - smoothstep(0.55, 1.0, age)) * (1.0 - smoothstep(0.025, 0.09, footprint));
}

vec3 vespera_ground(vec3 stone, vec3 p, vec3 eye, vec3 slope, vec4 deposit, float detail, float t, float motion, out vec3 glow) {
    float time = t * motion;
    float footprint = length(fwidth(p.xz));
    float lateral = p.x - 16.0 * sin(-p.z * 0.0035);
    float coarse = texture(deposits_map, p.xz * vec2(0.011, 0.006) + vec2(0.27, 0.63)).a;
    vec4 grit = texture(deposits_map, p.xz * 0.17);
    // The street crown drains towards the shoulders. Shallow hollows fill
    // in irregular hollows in the patched asphalt.
    float hollow = 0.49 * coarse + 0.32 * deposit.a + 0.15 * grit.a
        + 0.07 * smoothstep(2.0, 13.0, abs(lateral));
    float pool = smoothstep(0.45, 0.58, hollow) * smoothstep(0.78, 0.97, slope.y);
    float damp = smoothstep(0.30, 0.52, hollow);
    vec3 asphalt = stone * vec3(0.79, 0.87, 0.98);
    asphalt *= 1.0 - 0.36 * damp;
    vec2 run = texture(deposits_map, p.xz * vec2(0.22, 0.055) + vec2(0.0, time * 0.029)).rg - 0.5;
    vec2 rings = vespera_drop(p.xz * 0.63, time, footprint * 0.63);
    rings += vespera_drop(p.zx * 0.92 + vec2(0.27, 0.51), time * 1.19, footprint * 0.92).yx * 0.58;
    vec3 normal = normalize(slope + vec3(run.x * 0.12 + rings.x * 0.065, 0.0, run.y * 0.075 + rings.y * 0.065) * detail);
    vec3 ray = reflect(-eye, normal);
    float fresnel = pow(1.0 - clamp(dot(eye, normal), 0.0, 1.0), 2.5);
    vec3 water = asphalt * 0.44 + mix(vec3(0.012, 0.020, 0.032), vec3(0.072, 0.092, 0.14), fresnel);
    // Mirror the two illuminated edges of the elevated transit guideways.
    // Intersect the reflected view ray with their real height and rail curve.
    vec3 lights = vec3(0.0);
    for (int tier = 0; tier < 2; tier++) {
        float level = float(tier);
        vec2 hit = p.xz + ray.xz * ((32.0 + 4.0 * level - p.y) / max(ray.y, 0.070));
        float x = hit.x - 16.0 * sin(-hit.y * 0.0035);
        float edge = x - sign(x) * (23.0 + level * 4.0);
        float cyan = abs(edge + 1.8);
        float pink = abs(edge - 1.8);
        lights += vec3(0.072, 0.48, 0.59) / (1.0 + cyan * cyan * 0.92)
            + vec3(0.47, 0.12, 0.38) / (1.0 + pink * pink * 0.97);
    }
    // The first row of towers breaks the sky into windows and dark alleys.
    float side = ray.x >= 0.0 ? 1.0 : -1.0;
    float facade_distance = (52.0 - side * lateral) / max(abs(ray.x), 0.025);
    vec2 facade = p.zy + ray.zy * clamp(facade_distance, 0.0, 350.0);
    // Rough water stretches the colored windows into irregular vertical dashes.
    // The texture's mip chain integrates subpixel lights at the far end of the street.
    float windows = smoothstep(0.40, 0.77, texture(deposits_map, facade * vec2(0.039, 0.008)).a);
    float block = 0.5 + 0.5 * sin(floor(facade.x * 0.031) * 19.71);
    float facade_mask = smoothstep(3.0, 11.0, facade.y) * (1.0 - smoothstep(45.0 + 25.0 * block, 90.0, facade.y))
        * (1.0 - smoothstep(170.0, 350.0, facade_distance));
    lights += mix(vec3(0.073, 0.17, 0.21), vec3(0.20, 0.062, 0.17), block)
        * windows * facade_mask * detail;
    glow = lights * pool * (0.38 + 0.62 * fresnel);
    water += vec3(0.055, 0.073, 0.092) * max(0.0, dot(rings, vec2(-0.62, 0.78))) * detail;
    return mix(asphalt, water, pool * 0.93);
}
