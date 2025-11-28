shader_type canvas_item;

uniform ivec2 handrawn_dim;
uniform sampler2D handrawn_water;
uniform vec2 handrawn_offset;

void vertex() {
	// Called for every vertex the material is visible on.
}

vec4 handrawn_pixel(vec2 xy) {
	return texture(handrawn_water, xy);
}

// out of date
vec4 handrawn_shadow(vec2 xy) {
	vec2 mid = vec2(0.5, 0.5);
	vec2 shadow_delt = xy - mid;
	vec2 shadow_xy = mid + shadow_delt * 1.1 + handrawn_offset * 0.3;
	vec4 pixel = handrawn_pixel(shadow_xy);
	// Work on making it properly darker later
	pixel = vec4(vec3(3.0 - (pixel.r + pixel.g + pixel.b)) / 3.0, 1);
	return pixel;
}

void fragment() {
	COLOR = handrawn_shadow(UV.xy);
	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
