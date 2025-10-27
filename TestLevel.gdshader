shader_type canvas_item;

const int MAX = 10000;

uniform vec2 texture_offset;
uniform vec2 handrawn_offset;

uniform int[MAX] GRID_SIZES;
uniform int GRID_SIZE_N;
uniform float[MAX] rand_vals;
uniform int N_WAVESPAWNERS;
uniform int N_LILYPADS;
uniform vec2[MAX] lilypad_locs;
uniform vec2[MAX] wavespawner_locs;
uniform float[MAX] wavespawner_strengths;

// Figure out frame to use in TestLevel
uniform ivec2 handrawn_dim;

uniform sampler2D handrawn_water;

uniform sampler2D blurred_shadow;

void vertex() {
	// Called for every vertex the material is visible on.
}

vec4 intensity_map(vec2 xy) {
	vec4 CLR = vec4(0);
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
	CLR = vec4(vec3(min(1.0, length(total_force) / 3.0)), 1);

	// Render wavespawer locations.
	for (int i = 0; i < N_WAVESPAWNERS; i++) {
		vec2 loc = wavespawner_locs[i];
		if (length(xy - loc) < 0.05) {
			CLR = CLR * 0.5 + vec4(0, 0, 1, 1) * 0.5;
			break;
		}
	}

	// Render lilypads w/ transparency
	for (int i = 0; i < N_LILYPADS; i++) {
		vec2 loc = lilypad_locs[i];
		if (length(xy - loc) < 0.02) {
			CLR = CLR * 0.5 + vec4(0, 1, 0, 1) * 0.5;
			break;
		}
	}

	return CLR;
}

// When sin, we get outwards propagating waves
float sin_rand_norm(float x) {
	return sin(x * 999.9) * 0.5 + 0.5;
}
float hash(float p) {
	p = fract(p * 0.011);
	p *= p + 7.5;
	p *= p + p;
	return fract(p);
}
float rand_norm(float x) {
	x *= 4000.0;
	float i = floor(x);
	float f = fract(x);
	float u = f * f * (3.0 - 2.0 * f);
	return mod(mix(hash(i), hash(i + 1.0), u), 1.0);
}

float madeup_mult(vec2 uv, int GRID_SIZE, float CELL_SIZE, int depth_offset) {
	int rand_index_x = int(uv.x / CELL_SIZE);
	int rand_index_y = int(uv.y / CELL_SIZE);

	vec2 small_corner = floor(uv / CELL_SIZE) * CELL_SIZE;

	vec2 xy = (uv - small_corner) / CELL_SIZE;

	int MOD = GRID_SIZE * GRID_SIZE;
	float small_x = rand_vals[(rand_index_x * GRID_SIZE + rand_index_y) % MOD + depth_offset];
	float big_x = rand_vals[((rand_index_x + 1) * GRID_SIZE + rand_index_y) % MOD + depth_offset];
	float small_y = rand_vals[(rand_index_y * GRID_SIZE + rand_index_x + 100) % MOD + depth_offset];
	float big_y = rand_vals[((rand_index_y + 1) * GRID_SIZE + rand_index_x + 100) % MOD + depth_offset];

	float intensity = (small_x + (big_x - small_x) * xy.x) * (small_y + (big_y - small_y) * xy.y);
	return intensity;
}

vec3 hex_to_vec3(int hex) {
	float b = float(hex & 0xFF) / float(0xFF);
	float g = float((hex >> 8) & 0xFF) / float(0xFF);
	float r = float((hex >> 16) & 0xFF) / float(0xFF);
	return vec3(r, g, b);
}

vec4 my_perlin(vec2 xy) {
	vec4 CLR = vec4(0);
	// N passes of the grids
	int depth_offset = 0;
	float avg_intensity = 0.0;
	for (int n = 0; n < GRID_SIZE_N; n++) {
		int GRID_SIZE = GRID_SIZES[n];
		float CELL_SIZE = 1.0 / float(GRID_SIZE);
		float OFFSET = CELL_SIZE / 4.0;

		int rand_index_x = int(xy.x / CELL_SIZE);
		int rand_index_y = int(xy.y / CELL_SIZE);

		// float rand = rand_norm(float(rand_index_x * GRID_SIZE + rand_index_y) + floor(TIME / 0.8) * 0.05);
		float intensities[4] = {
			madeup_mult(xy + vec2(-OFFSET, -OFFSET), GRID_SIZE, CELL_SIZE, depth_offset),
			madeup_mult(xy + vec2(+OFFSET, -OFFSET), GRID_SIZE, CELL_SIZE, depth_offset),
			madeup_mult(xy + vec2(+OFFSET, +OFFSET), GRID_SIZE, CELL_SIZE, depth_offset),
			madeup_mult(xy + vec2(-OFFSET, +OFFSET), GRID_SIZE, CELL_SIZE, depth_offset)
		};
		depth_offset = GRID_SIZE * GRID_SIZE;
		float intensity = (intensities[0] + intensities[1] + intensities[2] + intensities[3]) / 4.0 + 0.08;
		avg_intensity += intensity;
	}
	avg_intensity *= 1.0 / float(GRID_SIZE_N);
	// Because we did intensity + a constant
	avg_intensity = min(1.0, avg_intensity);

	/*
	1C2A31
	252145
	5E826A
	96AE9C
	BED2E0
	*/

	vec4 intensity_bounds_to_color[5] = {
		vec4(0.40, hex_to_vec3(0xBED2E0)),
		vec4(0.23, hex_to_vec3(0x96AE9C)),
		vec4(0.19, hex_to_vec3(0x5E826A)),
		vec4(0.10, hex_to_vec3(0x252145)),
		vec4(0.0, hex_to_vec3(0x1C2A31))
	};

	// Interpolate colors maybe?
	// Print debug an equivalent
	for (int i = 0; i < intensity_bounds_to_color.length(); i++) {
		vec4 lower = intensity_bounds_to_color[i];
		vec4 upper = intensity_bounds_to_color[max(0, i - 1)];
		if (i == 0) {
			upper.x = 1.0;
		}
		if (avg_intensity > lower.x) {
			vec4 c1 = vec4(lower.yzw, 1);
			vec4 c2 = vec4(upper.yzw, 1);
			CLR = c1 + (c2 - c1) * (avg_intensity - lower.x) / (upper.x - lower.x); // ???
			break;
		}
	}

	return CLR;
}

// Maybe this should be more randomized?
vec4 perlin_blur(vec4 color, vec2 xy, int samples, float dist, float strength) {
	vec4 sample_color = vec4(0);
	for (int i = 0; i < samples; i++) {
		float t = float(i) / float(samples);
		vec2 offset = vec2(
			sin(float(t * 2.0 * 3.1415)),
			cos(float(t * 2.0 * 3.1415))) * dist;

		// Let's map positions into spheres maybe?
		sample_color += my_perlin(offset + xy);
	}

	sample_color *= 1.0 / float(samples);

	return color * (1.0 - strength) + sample_color * strength;
}

vec4 handrawn_pixel(vec2 texel_xy) {
	ivec2 icoords = ivec2(int(texel_xy.x * float(handrawn_dim.x)), int(texel_xy.y * float(handrawn_dim.y)));
	if (icoords.x < 0) {
		icoords.x += int(handrawn_dim.x);
	}
	icoords.x %= int(handrawn_dim.x);
	if (icoords.y < 0) {
		icoords.y += int(handrawn_dim.x);
	}
	icoords.y %= int(handrawn_dim.y);
	return texelFetch(handrawn_water, icoords, 1);
}

void fragment() {
	vec2 xy = UV.xy + texture_offset * 0.3;

	vec4 shadow_color = texture(blurred_shadow, xy);

	vec4 gaussian_color = perlin_blur(COLOR, xy, 6, 0.009, 1.0);
	
	// shadow_color kinda mutes everything when its gray like it is rn.
	shadow_color = vec4(vec3(4.0 - shadow_color.r - shadow_color.g - shadow_color.b) / 3.0, shadow_color.a);
	COLOR = shadow_color * gaussian_color * gaussian_color;
	
	vec4 handrawn_color = texture(handrawn_water, UV.xy + handrawn_offset * 0.3);

	if (length(handrawn_color.rgb - vec3(37, 150, 190) / 255.0) > 0.4) {
		COLOR = handrawn_color;
	} else {
		COLOR = 0.5 * handrawn_color + 0.5 * COLOR;
	}

	// COLOR = intensity_map(xy);
	
	// COLOR = vec4(avg_intensity, avg_intensity, avg_intensity, 1);
	// DEBUG, make it fairly translucent
	// COLOR.a *= 0.9;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
