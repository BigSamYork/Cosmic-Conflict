shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform float density = 0.0;
uniform float spread = 1.0;

float segment(vec2 p, vec2 a, vec2 b) {
	vec2 ab = b-a;
	return length(p-a-ab*clamp(dot(p-a,ab)/dot(ab,ab),0.0,1.0));
}

void fragment() {
	vec2 p = UV*2.0-1.0;
	float silhouette = length(p/vec2(0.29,0.24))-1.0;
	float edge = 1.0-smoothstep(-0.56,0.6,silhouette);
	edge = max(edge,1.0-smoothstep(0.11,0.22,segment(p,vec2(-0.13,-0.09),vec2(-0.93,-0.57))));
	for(int i=0;i<5;i++) {
		float a = float(i)*1.135-0.75;
		vec2 root = vec2(cos(a),sin(a))*0.16;
		vec2 joint = vec2(cos(a),sin(a))*vec2(0.53,0.45)*spread;
		vec2 tip = joint+vec2(cos(a+0.64),sin(a+0.64))*0.19*spread;
		edge = max(edge,1.0-smoothstep(0.016,0.12,segment(p,root,joint)));
		edge = max(edge,1.0-smoothstep(0.005,0.075,segment(p,joint,tip)));
	}
	ALBEDO = vec3(0.004,0.007,0.006);
	ALPHA = edge * density;
}
