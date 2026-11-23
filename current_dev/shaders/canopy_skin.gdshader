shader_type spatial;
render_mode unshaded, cull_disabled;

instance uniform float grip_age = 0.0;
instance uniform float pressure = 0.0;
instance uniform float wide_grip = 0.0;
instance uniform vec3 left_lobe = vec3(0.0);
instance uniform vec3 right_lobe = vec3(0.0);
varying vec3 skin_position;

float hash(vec3 p) {
	p = fract(p * vec3(0.1031, 0.1030, 0.0973));
	p += dot(p, p.yxz + 33.33);
	return fract((p.x + p.y) * p.z);
}

float tissue(vec3 p) {
	vec3 cell = floor(p);
	vec3 f = fract(p);
	f *= f * (3.0 - 2.0 * f);
	vec4 base = vec4(hash(cell), hash(cell + vec3(0, 1, 0)), hash(cell + vec3(0, 0, 1)), hash(cell + vec3(0, 1, 1)));
	cell.x += 1.0;
	vec4 next = vec4(hash(cell), hash(cell + vec3(0, 1, 0)), hash(cell + vec3(0, 0, 1)), hash(cell + vec3(0, 1, 1)));
	vec4 x = mix(base, next, f.x);
	return mix(mix(x.x, x.y, f.y), mix(x.z, x.w, f.y), f.z);
}

void vertex() {
	skin_position = VERTEX;
	// The two pendulous copper pods are below the mouth. The other copper
	// faces here belong to the toes, outside this band of the ventral mesh.
	if (abs(UV.x-0.32) < 0.01 && abs(VERTEX.x) < 0.55 && VERTEX.y < -0.46) {
		// The pods overlap slightly at the seam. Their outward normals
		// distinguish which pod an inner vertex belongs to.
		float side = sign(VERTEX.x-0.23*NORMAL.x);
		vec3 motion = side < 0.0 ? left_lobe : right_lobe;
		float d = clamp((-0.46-VERTEX.y)/0.61,0.0,1.0);
		float weight = d*d*(3.0-2.0*d);
		float slope = -6.0*d*(1.0-d)/0.61;
		vec3 offset = VERTEX-vec3(side*0.255,-0.46,0.17);
		float narrow = -0.5*motion.y;
		vec3 delta = vec3(motion.x+narrow*offset.x, motion.y*offset.y, motion.z+narrow*offset.z);
		VERTEX += weight*delta;
		// Inverse-transpose of the deformation gradient keeps reflections
		// attached to the changing curvature as the tissue compresses.
		NORMAL.xz /= 1.0+weight*narrow;
		NORMAL.y = (NORMAL.y-slope*dot(NORMAL.xz,delta.xz))/(1.0+weight*motion.y+slope*delta.y);
		NORMAL = normalize(NORMAL);
	}
	float flex = sin(grip_age * 3.8 + VERTEX.y * 3.0);
	VERTEX.z += 0.022 * flex * exp(-3.0 * dot(VERTEX.xy, VERTEX.xy));
	float foot = smoothstep(1.04,1.41,abs(VERTEX.x));
	// Brace the legs toward the pane. Flatten the suction pads against its
	// inner silhouette while letting the abdomen breathe between fixed feet.
	VERTEX.z += pressure * foot * 0.37;
	VERTEX.z = mix(VERTEX.z, min(VERTEX.z,0.49), pressure);
	VERTEX.xy *= 1.0 + 0.015*flex*(1.0-foot);
	// Spread the feet across the pane and tuck the striped tail up alongside
	// the abdomen as the creature flattens against the central windshield.
	float brace = smoothstep(0.52,1.37,abs(skin_position.x));
	float tail = (1.0-step(0.003,abs(UV.x-0.16)))*smoothstep(0.54,0.76,-skin_position.y);
	float angle = wide_grip*tail*0.9;
	mat2 bend = mat2(vec2(cos(angle),sin(angle)),vec2(-sin(angle),cos(angle)));
	vec2 hinge = vec2(0.0,-0.76);
	VERTEX.xy = hinge + bend*(VERTEX.xy-hinge) + wide_grip*brace*vec2(0.345,0.36);
	NORMAL.xy = bend*NORMAL.xy;
}

void fragment() {
	vec3 p = skin_position;
	float mottling = tissue(p * 8.0) + 0.45 * tissue(p * 22.0);
	float capillary = tissue(p * vec3(16, 8, 10) + 1.6 * mottling);
	float vein = 1.0 - smoothstep(0.012, 0.064, abs(capillary - 0.49));
	float grain = tissue(p * 76.0);
	float pores = smoothstep(0.72, 0.85, grain);
	vec3 skin = COLOR.rgb * (0.48 + 0.64 * mottling);
	skin *= mix(vec3(1), vec3(0.63, 0.28, 0.38), vein * (0.2 + 0.56 * mottling));
	skin *= 1.0 - 0.30 * pores;

	// The Blender mesh tags the recessed oral disc with its own finish.
	float disc = 1.0 - smoothstep(0.01, 0.03, abs(UV.x - 0.44));
	vec2 uv = (p.xy - vec2(0, 0.05)) / vec2(0.29, 0.51);
	float radius = length(uv) + 0.028 * sin(atan(uv.y, uv.x) * 8.0 + grip_age * 2.0);
	float ridge = 0.5 + 0.5 * sin(40.0 * radius - grip_age * 2.4 + mottling);
	vec3 throat = mix(vec3(0.009, 0.001, 0.004), vec3(0.31, 0.038, 0.062), smoothstep(0.22, 0.84, radius) * (0.4 + 0.6 * ridge));
	skin = mix(skin, throat, disc);
	vec3 n = normalize(NORMAL);
	vec3 key = normalize(vec3(-0.48, 0.69, 0.61));
	// A travelling film pools along the tissue grain and reflects the long
	// cockpit lights as narrow, curved streaks across each rounded segment.
	float film = tissue(p * vec3(34,5,16) + vec3(0,grip_age*0.26,0));
	float rivulet = 1.0-smoothstep(0.025,0.105,abs(film-0.54));
	vec3 polish = normalize(n + 0.038*vec3(film-0.5,grain-0.5,0.0));
	vec3 reflection = reflect(-normalize(VIEW),polish);
	float strip = exp(-55.0*abs(reflection.y-0.51+reflection.x*0.22))*smoothstep(-0.4,0.28,reflection.z);
	float edge = pow(1.0-clamp(dot(polish,normalize(VIEW)),0.0,1.0),3.6);
	float wet = pow(max(0.0, dot(polish, normalize(key + VIEW))), 31.0) * (0.63 + 0.55 * film);
	vec3 color = skin * (0.22 + 0.76 * max(0.0, dot(n, key))) * (0.97-0.16*rivulet);
	color += vec3(0.97,0.83,0.78)*wet + vec3(0.69,0.87,1.0)*(strip*(0.34+0.61*rivulet)+edge*0.19);
	ALBEDO = OUTPUT_IS_SRGB ? pow(color, vec3(1.0 / 2.2)) : color;
}
