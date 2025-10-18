shader_type canvas_item;

// Act as a queue of 1000, deleting old lilypads.
const int MAX = 1000;
uniform int N_WAVESPAWNERS;
uniform int N_LILYPADS;
uniform vec2[MAX] lilypad_locs;
uniform vec2[MAX] wavespawner_locs;
uniform float[MAX] strengths;

void vertex() {
	// Called for every vertex the material is visible on.
	
}

void fragment() {
	// Called for every pixel the material is visible on.
	// Key point is to see if this works even with point wavespawners.
	
	vec2 xy = UV.xy;
	
	// Can we get a rough X shape based on the magnitude of "forces"?
	vec2 total_force = vec2(0);
	for (int i = 0; i < N_WAVESPAWNERS; i++) {
		vec2 loc = wavespawner_locs[i];
		vec2 delta = xy - loc;
		vec2 force = strengths[i] * normalize(delta) * pow(0.4, 12.0 * length(delta));
		total_force += force;
	}
	// MAX total_force is like 4.0
	COLOR = vec4(vec3(min(1.0, length(total_force) * 0.20)), 1);
	
	// Render wavespawner locations.
	for (int i = 0; i < N_WAVESPAWNERS; i++) {
		vec2 loc = wavespawner_locs[i];
		if (length(xy - loc) < 0.05) {
			COLOR = COLOR * 0.5 + vec4(0, 0, 1, 1) * 0.5;
			break;
		}
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
