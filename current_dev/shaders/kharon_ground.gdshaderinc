// Long wind tails run towards +X. Short, forked ripples cross the wind.
vec3 kharon_ground(vec3 stone, vec3 p, vec3 eye, vec3 slope, vec4 deposit, float detail, float t, float motion) {
    vec2 along = vec2(0.915, -0.404);
    vec2 across = vec2(-along.y, along.x);
    vec2 bed = vec2(dot(p.xz, along), dot(p.xz, across));
    vec2 bend = vec2(sin(bed.y * 0.047 + bed.x * 0.018), sin(bed.x * 0.031 - bed.y * 0.063));
    float drift = texture(deposits_map, bed * vec2(0.004, 0.006) + bend * 0.061).a;
    float lee = smoothstep(-0.22, 0.25, -dot(slope.xz, along));
    float loose = smoothstep(0.14, 0.76, drift * 0.69 + deposit.a * 0.18 + lee * 0.19);

    // Broad apricot crests and iron-rich hollows stay anchored as sand skims overhead.
    vec3 ochre = mix(vec3(0.80, 0.70, 0.65), vec3(1.20, 1.09, 1.00), loose);
    stone *= ochre * mix(0.91, 1.09, lee);
    float forks = sin(bed.y * 0.31 + 4.2 * deposit.a + bend.x);
    float phase = bed.x * 3.3 + 2.8 * bend.x + 1.6 * forks + 1.1 * sin(bed.x * 0.21 + bed.y * 0.13);
    float resolved = 1.0 - smoothstep(0.55, 2.9, fwidth(phase));
    float crest = cos(phase) + 0.34 * cos(2.0 * phase + 0.61);
    float ripple_field = smoothstep(0.37, 0.72, drift + 0.14 * forks);
    stone *= 1.0 + crest * 0.13 * ripple_field * loose * resolved;

    // Sample airborne sand a little above the bed so its narrow streamers separate
    // from the ripple relief at a shallow viewing angle. The veil gathers and thins
    // as individual streamers overtake the slower moving gust.
    float lift = (0.22 + 0.66 * drift) / max(0.16, dot(slope, eye));
    vec2 air = bed + lift * vec2(dot(eye.xz, along), dot(eye.xz, across));
    vec2 lane = air + vec2(-t * 4.0, 1.3 * sin(air.x * 0.044 - t * 0.16 + bend.x));
    float gust = texture(deposits_map, lane * vec2(0.008, 0.023)).a;
    float wisps = texture(deposits_map, vec2(lane.x - t * 2.7, lane.y) * vec2(0.019, 0.112)).a;
    float veil = smoothstep(0.46, 0.84, gust) * smoothstep(0.36, 0.9, wisps);
    float scud = veil * motion * (0.22 + 0.78 * loose) * mix(0.17, 0.37, detail);
    return mix(stone, stone * 0.78 + vec3(0.45, 0.31, 0.17), scud);
}
