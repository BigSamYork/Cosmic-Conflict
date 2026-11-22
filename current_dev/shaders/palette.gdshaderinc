vec3 palette_to_output(vec3 color) {
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	return color;
#else
	// Authored palette values are sRGB; Vulkan lighting operates in linear space.
	return mix(pow((color + vec3(0.055)) / 1.055, vec3(2.4)), color / 12.92, lessThanEqual(color, vec3(0.04045)));
#endif
}
