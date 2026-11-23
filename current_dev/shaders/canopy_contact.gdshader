shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;

void fragment() {
	vec2 p = (UV-0.5)*2.0;
	float angle = atan(p.y,p.x);
	float r = length(p) + 0.05*sin(3.0*angle) + 0.027*cos(7.0*angle);
	float pool = 1.0-smoothstep(0.77,0.93,r);
	float rim = exp(-40.0*abs(r-0.82));
	float glint = rim * max(dot(normalize(p+0.001),vec2(-0.65,-0.76)),0.0);
	float contact = (1.0-smoothstep(0.38,0.73,r))*0.28;
	ALBEDO = mix(vec3(0.07,0.044,0.038),vec3(0.71,0.85,0.86),rim*0.53+glint*0.47);
	ALPHA = pool*0.17 + contact + rim*0.23 + glint*0.43;
}
