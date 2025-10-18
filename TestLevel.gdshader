shader_type canvas_item;

const int MAX = 300;
uniform int N_WAVESPAWNERS;
uniform int N_LILYPADS;
uniform vec2[MAX] lilypad_locs;
uniform vec2[MAX] wavespawner_locs;
uniform float[MAX] wavespawner_strengths;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec2 xy = UV.xy;

	// Remember, this is only for RENDERING.
	vec2 total_force = vec2(0);
	for (int i = 0; i < N_WAVESPAWNERS; i++) {
		vec2 loc = wavespawner_locs[i];
		vec2 delt = xy - loc;
		// distance_node
		{
			vec2 force = wavespawner_strengths[i] * normalize(delt) * pow(0.4, 12.0 * length(delt));
			total_force += force;
		}
	}

	// MAX total_force is probably max(strength) (5) * 6 or 3.0
	COLOR = vec4(vec3(min(1.0, length(total_force) / 3.0)), 1);

	// Render wavespawer locations.
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

	// DEBUG, make it fairly translucent
	COLOR.a *= 0.2;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
