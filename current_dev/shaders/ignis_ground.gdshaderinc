vec3 ignis_ground(vec3 p, vec3 eye, vec3 slope, vec4 deposit, float detail, float t, float motion, out vec3 glow) {
    // Open faults taper into pitted basalt and send fingers down the canyon.
    vec2 rock = p.xz + p.y * vec2(0.31, -0.29);
    vec2 warp = vec2(sin(rock.y * 0.024 + rock.x * 0.016), cos(rock.x * 0.027 - rock.y * 0.012));
    vec3 fault = texture(deposits_map, rock / vec2(64.0, 74.0) + 0.089 * warp).rgb;
    float relief = (fault.g - 0.51) * 1.5;
    float light = 0.63 + 0.39 * max(dot(slope, vec3(-0.40, 0.82, 0.41)), 0.0);
    vec3 stone = mix(vec3(0.043, 0.032, 0.038), vec3(0.155, 0.090, 0.067),
        smoothstep(0.2, 0.79, 0.64 * fault.b + 0.36 * deposit.b)) * light;
    vec3 basalt = stone * vec3(0.70, 0.76, 0.88) * (0.8 + relief + 0.27 * fault.b);
    float ash_bed = 0.49 + 0.21 * sin(rock.x * 0.074 + 0.8 * warp.y)
        + 0.20 * sin(rock.y * 0.067 - rock.x * 0.027 + 1.3 * warp.x) + (deposit.b - 0.5) * 0.46;
    float ash = smoothstep(0.48, 0.82, ash_bed) * smoothstep(0.48, 1.0, slope.y);
    basalt = mix(basalt, stone * vec3(0.89, 1.03, 1.12) + vec3(0.019, 0.020, 0.022), ash * 0.71);
    vec3 chips = texture(deposits_map, vec2(rock.y, -rock.x) / 7.4 + 0.023 * warp).rgb;
    basalt *= 1.0 + (chips.b - 0.47) * 0.41 * detail;
    // Light catches the glassy upper lip, then falls away down the fracture wall.
    float rim = smoothstep(0.65, 0.95, fault.g) * (1.0 - ash);
    float grazing = pow(1.0 - clamp(dot(slope, eye), 0.0, 1.0), 2.0);
    basalt += vec3(0.031, 0.030, 0.039) * rim * (0.44 + grazing) * detail;
    float open_joint = fault.r * (1.0 - ash * 0.86);
    basalt *= 1.0 - 0.61 * open_joint;

    // Some networks have already cooled. Intensity travels through the
    // remaining apertures, intermittently exposing gold under the red crust.
    float heat_belt = 0.47 + 0.27 * sin(rock.x * 0.081 + rock.y * 0.043 + warp.x)
        + 0.21 * cos(rock.y * 0.051 - rock.x * 0.023 + 1.5 * warp.y);
    float live = smoothstep(0.38, 0.74, heat_belt + (deposit.b - 0.5) * 0.20);
    float pulse = 0.5 + 0.5 * sin(rock.x * 0.43 + rock.y * 0.17 + warp.y * 2.7 - t * motion * 0.99);
    float heat = live * (0.60 + 0.40 * pulse);
    float throat = smoothstep(0.30, 0.76, open_joint + (chips.b - 0.47) * 0.19 * detail);
    float incandescent = smoothstep(0.17, 0.72, throat * heat);
    glow = vec3(0.48, 0.033, 0.003) * open_joint * heat;
    glow += (vec3(1.10, 0.22, 0.012) * throat + vec3(0.92, 0.57, 0.095) * incandescent) * heat;
    return basalt;
}
