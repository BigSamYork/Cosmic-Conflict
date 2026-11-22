shader_type canvas_item;
render_mode unshaded;

uniform vec4 enamel : source_color;
uniform vec4 stripe : source_color;
// Width, spacing and count of the recognition bands on each canopy rail.
uniform vec3 bands;

void fragment() {
	vec4 metal = texture(TEXTURE, UV);
	vec2 p = UV * vec2(1376.0, 768.0);
	float side = min(p.x, 1376.0 - p.x);
	bool combiner = side > 490.0 && p.y > 66.0 && p.y < 199.0;
	bool canopy = p.y < 425.0 || (side < 200.0 && p.y < 592.0);
	bool sill = p.y >= 592.0 && side < 240.0;
	if ((canopy && !combiner) || sill) {
		float light = dot(metal.rgb, vec3(0.27, 0.59, 0.14));
		float along = p.y + side * (sill ? 0.55 : 0.27);
		float band = mod(along, 156.0);
		float marking = (1.0 - smoothstep(bands.x - 1.0, bands.x, mod(band, bands.y))) *
			(1.0 - step(bands.y * bands.z, band));
		vec3 paint = mix(enamel.rgb, stripe.rgb, marking);
		float relief = 0.10 + min(light * 1.65, 1.0);
		float cyan_light = smoothstep(0.06, 0.23, metal.b - metal.r);
		float coverage = sill ? 1.0 - smoothstep(152.0, 240.0, side) : 1.0;
		metal.rgb = mix(metal.rgb, metal.rgb * 0.64 + paint * relief, 0.85 * coverage * (1.0 - cyan_light));
	}
	COLOR = metal;
}
