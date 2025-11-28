shader_type canvas_item;

uniform float norm_cooldown_t;
uniform sampler2D tex;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
	if (norm_cooldown_t > 0.0) {
		vec4 c1 = vec4(vec3(0), 0.3);
		vec4 c2 = vec4(0.2, 0.2, 0.05, 0.7);

		float t = 0.5 * cos(norm_cooldown_t * 2.0 * PI * 2.5) + 0.5;

		vec4 mask = c1 + (c2 - c1) * t;
		// COLOR = (1.0 - mask.a) * COLOR + mask.a * mask;

		float alpha = t * 0.6 + 0.4;

		vec4 tex_color = texture(tex, UV.xy);
		COLOR = vec4(((1.0 - mask.a) * tex_color + mask.a * mask).rgb, tex_color.a * alpha);
	}
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
