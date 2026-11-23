shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;
uniform float seed = 5.0;
instance uniform float opening = 1.0;
instance uniform float shard_time = 0.7;

float noise1(float x) { return fract(sin(x*31.173+seed)*4375.19); }
float segment(vec2 p, vec2 a, vec2 b) {
	vec2 v = b-a;
	return length(p-a-v*clamp(dot(p-a,v)/max(dot(v,v),0.0000001),0.0,1.0));
}

void fragment() {
	vec2 p = (UV-0.5)*2.0;
	float ang = atan(p.y,p.x);
	float tooth = (ang+PI)*17.0/TAU;
	float a0 = 0.21 + 0.12*noise1(mod(floor(tooth),17.0)+17.0);
	float a1 = 0.21 + 0.12*noise1(mod(floor(tooth)+1.0,17.0)+17.0);
	float outer = mix(a0,a1,fract(tooth));
	float radial = length(p);
	float edge = radial - outer;
	float aa = max(fwidth(radial),0.002);
	float split = 1.0;
	float facets = 0.0;
	for (int i=0; i<11; i++) {
		float k = float(i);
		float theta = (k+0.68*noise1(k))*TAU/11.0;
		vec2 dir = vec2(cos(theta),sin(theta));
		vec2 perp = vec2(-dir.y,dir.x);
		vec2 a = dir*0.22;
		vec2 b = dir*(0.35+0.15*noise1(k+32.0))+perp*(noise1(k+19.0)-0.5)*0.11;
		vec2 c = dir*(0.60+0.34*noise1(k+9.0))+perp*(noise1(k+49.0)-0.5)*0.25;
		float ray = min(segment(p,a,b),segment(p,b,c));
		ray = min(ray,segment(p,b,b+(c-b)*0.44+perp*(noise1(k+65.0)-0.5)*0.26));
		split = min(split,ray);
		facets = max(facets, (1.0-smoothstep(0.0,0.064,ray))*noise1(k+4.0));
	}
	float visible = 1.0-smoothstep(opening-0.04,opening,radial);
	float rim = 1.0-smoothstep(0.0008,0.006+aa,abs(edge));
	float lip = 1.0-smoothstep(0.003,0.039,abs(edge+0.012));
	float crack = (1.0-smoothstep(0.0008,0.0038+aa,split))*smoothstep(-aa,aa,edge);
	float chip = lip*(0.42+0.58*abs(sin(ang*19.0+sin(ang*7.0))));
	float opacity = (rim*0.61+chip*0.52+crack*0.71+0.16*facets*smoothstep(0.0,0.03,edge))*visible;
	float shards = 0.0;
	if (shard_time < 0.7) {
		for (int i=0; i<7; i++) {
			float k = float(i);
			float spin = k*2.4 + shard_time*(2.0+noise1(k+2.0)*9.0);
			vec2 dir = vec2(cos(k*2.4+seed),sin(k*2.4+seed));
			vec2 q = p - dir*(0.23+shard_time*(0.4+noise1(k))) - vec2(0.0,1.25*shard_time*shard_time);
			vec2 chip_uv = mat2(vec2(cos(spin),sin(spin)),vec2(-sin(spin),cos(spin))) * q;
			float shard = max(abs(chip_uv.x)*1.8+chip_uv.y*0.45-0.027,-chip_uv.y-0.034);
			shards = max(shards,(1.0-smoothstep(0.0,aa,shard))*(0.55+0.4*cos(spin))* (1.0-smoothstep(0.32,0.70,shard_time)));
		}
	}
	opacity = max(opacity, shards);
	if (opacity < 0.015) { discard; }
	ALBEDO = mix(vec3(0.065,0.12,0.18),vec3(0.78,0.92,1.0),clamp(crack+rim*0.7+chip*0.6+shards,0.0,1.0));
	ALPHA = clamp(opacity,0.0,0.96);
}
