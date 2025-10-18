shader_type canvas_item;

const int MAX = 1000;
uniform float t;
uniform int N_FENCES;
uniform int N_LILYPADS;
// Arguably there could be fence strength but eh
uniform float[MAX] fence_radii;
uniform vec2[MAX] lilypad_locs;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
	vec2 xy = UV.xy;
	vec2 loc = vec2(0.5);

	float strength = 3.0;
	vec2 delta = xy - loc;
	vec2 force = strength * normalize(delta) * pow(0.8, 12.0 * length(delta));

	for (int i = 0; i < N_FENCES; i++) {
		// Force is mult by proximity to fence_radii
		float dist = abs(length(delta) - fence_radii[i]);
		if (dist < 0.1) {
			force *= dist / 0.1;
		}
	}
	// MAX force is like 4.0?
	COLOR = vec4(vec3(min(1.0, length(force) * 0.20)), 1);

	// 1 wavespawner in center.
	if (length(xy - loc) < 0.05) {
		COLOR = COLOR * 0.5 + vec4(0, 0, 1, 1) * 0.5;
	}

	// Render lilypads w/ transparency
	for (int i = 0; i < N_LILYPADS; i++) {
		vec2 loc = lilypad_locs[i];
		if (length(xy - loc) < 0.02) {
			COLOR = COLOR * 0.5 + vec4(0, 1, 0, 1) * 0.5;
			break;
		}
	}
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
