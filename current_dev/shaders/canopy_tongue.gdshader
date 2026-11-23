shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec3 mouth;
uniform vec3 gate;
uniform vec3 tip;
uniform vec3 eye;
uniform float opened;
uniform float pulse;
uniform float sway;
uniform float aperture;
instance uniform float claw_index = -1.0;
varying vec3 fold_normal;
varying float lengthwise;

vec3 cubic(vec3 a, vec3 b, vec3 c, vec3 d, float t) {
	float u = 1.0-t;
	return u*u*u*a + 3.0*u*u*t*b + 3.0*u*t*t*c + t*t*t*d;
}

vec3 wrist_axis() {
	// Roll the four hooks into view as the pilot dodges the grasp.
	return normalize(vec3(0.37*sin(pulse*2.1),0.24*cos(pulse*2.6),1.0));
}

vec3 centerline(float s) {
	vec3 through = normalize(gate-mouth+vec3(0.0001));
	if (s < 0.36) {
		float t = s/0.36;
		vec3 surface = cubic(mouth, mix(mouth,gate,0.36)+vec3(0,0.035,0.04),
			gate-through*length(gate-mouth)*0.26, gate, t);
		return surface + vec3(0.023,0.071,0.0)*sin(PI*t)*sin(PI*t)*sin(5.0*t-pulse*4.4)*opened*sway;
	}
	float t = (s-0.36)/0.64;
	float d0 = max(0.001,eye.z-gate.z);
	float d1 = max(0.001,eye.z-tip.z);
	vec2 start = (gate-eye).xy/d0;
	vec2 finish = (tip-eye).xy/d1;
	vec2 dir = normalize(finish-start+vec2(0.00001,0.0));
	vec2 side = vec2(-dir.y,dir.x);
	// Bend across the pilot's sight line so that foreshortening cannot turn
	// the soft wave into a sharp elbow when the wrist approaches the lens.
	float wave = sin(t*8.4-pulse*4.8)*sin(PI*t)*sin(PI*t);
	float amplitude = min(length(finish-start)*0.30,0.15)*opened*sway;
	vec2 sight = mix(start,finish,t)+side*amplitude*wave;
	float depth = mix(d0,d1,t*(0.9+0.1*t));
	return eye+vec3(sight*depth,-depth);
}

vec3 hook(float s) {
	vec3 forward = wrist_axis();
	vec3 right = normalize(cross(vec3(0,1,0),forward));
	vec3 up = cross(forward,right);
	float angle = claw_index*PI*0.5+0.68+0.34*sin(pulse*2.0);
	vec3 spoke = cos(angle)*right+sin(angle)*up;
	// Each ivory hook opens knuckle first and bends its pointed end back
	// toward the other three. The four bases remain embedded in the oral bulb.
	vec3 base = tip+spoke*0.032-forward*0.043;
	vec3 knuckle = tip+spoke*(0.089+0.095*aperture)+forward*0.013;
	vec3 elbow = tip+spoke*(0.105+0.18*aperture)+forward*(0.125+0.008*claw_index);
	vec3 point = tip+spoke*(0.012+0.15*aperture)+forward*(0.201-0.105*aperture);
	return cubic(base,knuckle,elbow,point,s);
}

vec3 path_at(float s) {
	return claw_index < 0.0 ? centerline(s) : hook(s);
}

void vertex() {
	float s = clamp(0.5-0.5*VERTEX.y,0.0,1.0);
	lengthwise = s;
	vec3 center = path_at(s);
	vec3 tangent = normalize(path_at(min(1.0,s+0.002))-path_at(max(0.0,s-0.002))+vec3(0,0,0.00001));
	vec3 across = normalize(cross(tangent,vec3(0.04,1.0,0.03)));
	vec3 up = cross(tangent,across);
	float angle = UV.x*TAU;
	vec3 normal = cos(angle)*across+sin(angle)*up;
	float radius;
	if (claw_index < 0.0) {
		radius = mix(0.090,0.039,s)*(1.0+0.035*sin(s*62.0-pulse*4.0));
		radius += 0.028*smoothstep(0.84,0.96,s);
		radius *= 1.0-smoothstep(0.968,1.0,s);
		if (s > 0.36) { radius *= opened; }
	} else {
		radius = mix(0.037,0.001,pow(s,1.30))*opened;
		center = mix(tip,center,opened);
	}
	VERTEX = center+normal*radius;
	fold_normal = MODELVIEW_NORMAL_MATRIX*normal;
}

void fragment() {
	vec3 n = normalize(fold_normal);
	float cord = pow(abs(cos(UV.x*TAU*3.0 + 1.1*sin(lengthwise*13.0-pulse*1.7))),6.0);
	vec3 flesh = mix(vec3(0.24,0.021,0.041),vec3(0.48,0.094,0.13),0.34+cord*0.45);
	float papilla = length((fract(vec2(UV.x*2.0,lengthwise*16.0)+0.5)-0.5)*vec2(2.8,1.0));
	flesh *= 0.76+0.24*smoothstep(0.05,0.17,papilla);
	if (claw_index >= 0.0) {
		flesh = mix(vec3(0.33,0.075,0.075),vec3(0.87,0.65,0.43),smoothstep(0.06,0.47,lengthwise));
		flesh = mix(flesh,vec3(0.94,0.83,0.63),smoothstep(0.49,0.94,lengthwise));
	}
	vec3 key = normalize(vec3(-0.46,0.68,0.65));
	float gloss = pow(max(dot(n,normalize(key+VIEW)),0.0),25.0);
	vec3 col = flesh*(0.43+0.65*max(dot(n,key),0.0))+vec3(0.95,0.82,0.78)*gloss;
	ALBEDO = OUTPUT_IS_SRGB ? pow(col,vec3(1.0/2.2)) : col;
}
