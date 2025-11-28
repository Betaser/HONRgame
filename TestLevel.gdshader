shader_type canvas_item;

const int MAX = 1000;

uniform vec2 texture_offset;
uniform vec2 handrawn_offset;

uniform float ripple_time;

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

uniform sampler2D frog_skin_texture;

uniform sampler2D handrawn_highlight;

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

float snap(float f, float amt) {
	return floor(f / amt) * amt;
}

vec2 snap_vec(vec2 v, float amt) {
	return vec2(snap(v.x, amt), snap(v.y, amt));
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
		vec4(0.33, hex_to_vec3(0x96AE9C)),
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

/*
float LEN = 0.8;
float time_effect = TIME * 0.1;
time_effect = time_effect - floor(time_effect / 0.7);
float handrawn_len = length(xy - center) - time_effect;
xy = center + normalize(xy - center) * handrawn_len;

// I want to make this small
const float PD = 0.02;
float N_PD = floor(LEN / PD);

float pds[50];
for (int i = 1; i < int(N_PD) + 1; i++) {
	float norm = float(i) / floor(N_PD);
	float pd = 1.0 - pow((1.0 - norm), 2);
	pds[i - 1] = pd;
}

for (int i = 0; i < int(N_PD); i++) {
	pds[i] /= pds[int(N_PD) - 1];
}

// so... how are we translating it from xs to x?
// Do this
float norm_x = x / LEN;
float shifted_x = norm_x;
float time_effect = TIME * time_factor;
time_effect = time_effect - floor(time_effect / 0.2) * 0.2;
shifted_x -= time_effect;

if (shifted_x < 0.0) {
	shifted_x += 1.0;
}

int pdi = 0;
float lower = 0.0;
float upper = pds[0];
while (upper < norm_x) {
	pdi += 1;
	lower = upper;
	upper = pds[pdi];
}

if (pdi % 2 == 1) {
	y = 1.0 / (upper - lower) * pow(shifted_x - lower, 2) + lower;
} else {
	y = -1.0 / (upper - lower) * pow(shifted_x - upper, 2) + upper;
}
y *= LEN;
*/
vec2 ripple(vec2 xy, vec2 center, float amt, float time_factor) {
	// Obviously we have to loop xy, but otherwise this looks good!

	float x = length(xy - center);
	float y;


	bool in_spreading_dist = x < ripple_time * 0.05;
	float x_in_cos = in_spreading_dist ? x : 0.0;
	float ripple_t = in_spreading_dist ? ripple_time : 0.0;

	float cos_offset = 0.008 / max(x, 0.1) * amt * pow(x, 0.5) * cos(4.4 * pow(x_in_cos * 7.0, 1.5) + ripple_t * -time_factor);;
	y = x + cos_offset;
	// Bad idea: we isolate one ripple at a time by adding a strong decay effect for things "far" from ripple_time
	// Better idea: we cut off the ripple at first, and it expands to the max distance over time

	return center + normalize(xy - center) * y;
	// return xy;
}

vec4 ripple_highlight(vec2 xy, vec2 center, float time, float time_factor) {
	float x = length(xy - center);

	bool in_spreading_dist = x < time * 0.05;

	if (!in_spreading_dist) {
		return vec4(0);
	}
	float x_in_cos = in_spreading_dist ? x : 0.0;
	float ripple_t = in_spreading_dist ? time * -time_factor : 0.0;

	// float in_cos_ripple_t = floor(ripple_t / (x * 0.3)) * (x * 0.3);

	float norm_highlight_amt = cos(4.4 * pow(x_in_cos * 7.0, 1.5) + ripple_t) * 0.5 + 0.5;

	// multiply by this bumpy texture
	vec2 out_v = (xy - center) * 0.6;
	float len_out_v = length(out_v);

	float ang = atan(out_v.y, out_v.x);
	ang += ripple_t * 0.05;

	float amts[2];
	float angs[2] = { ang, ang * 0.4 };
	for (int i = 0; i < 2; i++) {
		vec2 rotated_xy = vec2(cos(angs[i]), sin(angs[i])) * len_out_v + center;
		vec4 frog_color = texture(frog_skin_texture, rotated_xy);

		float amt = norm_highlight_amt;
		amt = amt * (frog_color.r + frog_color.g + frog_color.b) / 3.0;
		amts[i] = amt;
	}

	const float cutoff = 0.30;
	const float lower = 0.3;

	float amt = (amts[0] + amts[1]) / 2.0;
	if (amt < cutoff || norm_highlight_amt < 0.98) {
		// CENTER OF PUDDLE INTENSITY;
		amt = 0.15;
	} else {
		// set amt that is non zero between lower and 1.0
		amt = (amt / (1.0 - cutoff)) * (1.0 - lower) + lower;
	}
	// decays over time
	amt = max(0.0, amt - x * 2.0);

	return vec4(0.05, 0.15, 0.05, amt);
}

// Everything except the ripples
vec4 background_color(vec2 xy, inout vec4 gaussian_color, inout vec4 tot_highlight) {
	vec2 ripple_shadow_xy = vec2(0);
	vec2 ripple_handrawn_xy = vec2(0);

	tot_highlight = vec4(0);

	int n_spawners = N_WAVESPAWNERS;

	for (int i = 0; i < n_spawners; i++) {
		vec2 center = wavespawner_locs[i];
		ripple_shadow_xy += ripple(xy, center, 0.9, 3.5);
		ripple_handrawn_xy += ripple(xy, center, 2.9, 3.2);
	}
	ripple_shadow_xy *= 1.0 / float(n_spawners);
	ripple_handrawn_xy *= 1.0 / float(n_spawners);

	// vec2 handrawn_highlight_pixel = snap_vec(ripple_handrawn + handrawn_offset * 0.03, 0.01);
	vec2 handrawn_highlight_pixel = ripple_handrawn_xy + handrawn_offset * 0.03;
	vec4 handrawn_highlight_color = texture(handrawn_highlight, handrawn_highlight_pixel);
	handrawn_highlight_color.rgb += 0.5;
	handrawn_highlight_color.a *= 0.1;

	/*
	for (int i = 0; i < n_spawners; i++) {
		vec2 center = wavespawner_locs[i];

		// Use this for making frogs leap into the water.
		float pd = ripple_time + (float(i) / float(n_spawners)) * (2.0 * 3.1415) / 3.2 * 0.3;
		// Now apply the highlight ripple
		vec4 highlight = ripple_highlight(xy, center, pd, 3.2);

		// Doesn't really combine with anything.
		vec3 combined_highlight = handrawn_highlight_color.rgb / (1.0 - highlight.rgb) + vec3(0.2, 0.2, 0.2);
		combined_highlight += 0.2;
		if (highlight.a > tot_highlight.a) {
			tot_highlight.a = highlight.a;
			tot_highlight.rgb = combined_highlight;
		}
	}
	*/

	vec2 shadow_xy = ripple_shadow_xy + texture_offset * 0.1;
	vec4 shadow_color = texture(blurred_shadow, shadow_xy);

	vec4 CLR = vec4(0);

	gaussian_color = perlin_blur(CLR, ripple_handrawn_xy, 6, 0.009, 1.0);

	// shadow_color kinda mutes everything when its gray like it is rn.
	shadow_color = vec4(vec3(4.4 - shadow_color.r - shadow_color.g - shadow_color.b) / 3.0, shadow_color.a);
	CLR = shadow_color * gaussian_color;
	CLR = gaussian_color * 0.3;
	CLR.b *= 0.6;
	CLR.a = 1.0;

	// clearly not how to do pixel!
	vec2 handrawn_color_pixel = floor((ripple_handrawn_xy + handrawn_offset * 0.03) / 0.01) * 0.01;
	handrawn_color_pixel = ripple_handrawn_xy + handrawn_offset * 0.03;
	vec4 handrawn_color = texture(handrawn_water, handrawn_color_pixel);
	// Made it too light
	CLR = 0.2 * handrawn_color + 0.8 * CLR;
	CLR.rgb *= 0.8;
	CLR.g *= 1.1;
	CLR.r *= 1.3;

	return vec4((CLR * (1.0 - handrawn_highlight_color.a) + handrawn_highlight_color * handrawn_highlight_color.a).rgb, CLR.a);
}

void fragment() {
	vec2 xy = UV.xy;
	vec4 gaussian_color;
	vec4 tot_highlight;
	vec4 blah, blah1;
	vec2 center_spawners = vec2(0);

	// lines and a ripple effect
	vec4 sample_color;
	{
		vec2 sample_xy = vec2(0);
		for (int i = 0; i < N_WAVESPAWNERS; i++) {
			vec2 center = wavespawner_locs[i];
			sample_xy += ripple(xy, center, 2.9, 3.2);
		}
		float t = snap(ripple_time, 1.4);
		sample_xy *= 1.0 / float(N_WAVESPAWNERS);
		float xy_snap_sum = snap((sample_xy.x - 0.5) + (sample_xy.y - 0.5) *
			0.15 * (sin(t * 0.8) + 2.3), 0.01);
		float xy_variation = rand_norm(xy_snap_sum);
		float dist = 0.005 + 0.06 * xy_variation;
		float ang = 2.0 * 3.1415 * xy_variation;
		ang = snap(ang, 1.62);
		vec2 offset = vec2(
			sin(float(ang * 2.0 * 3.1415)),
			cos(float(ang * 2.0 * 3.1415))) * dist;

		sample_color = background_color(xy + offset, gaussian_color, blah);

		// COLOR = sample_color;
	}

	// Muddle with a gradient, more muddled inwards
	vec4 muddle_color;
	{
		int n_spawners = N_WAVESPAWNERS;
		for (int i = 0; i < n_spawners; i++) {
			vec2 center = wavespawner_locs[i];
			center_spawners += center;
		}
		center_spawners *= 1.0 / float(n_spawners);

		// come on you don't need to do this, why doesnt it work?
		center_spawners.x = center_spawners.y = 0.5;

		float dist_offset = sin(float(ripple_time * 0.3)) * 0.3;
		// greenish
		vec4 color1 = vec4(49.0, 59.0, 37.0, 0.0) / 255.0;
		// brownish
		vec4 color2 = vec4(57.0, 57.0, 51.0, 255.0) / 255.0;
		float interp = 0.9 - 0.2 * pow(clamp(length(xy - center_spawners) * 2.4 + dist_offset, 0.0, 1.0), 2.2);
		vec4 full_muddle = mix(color2, color1, interp);
		float amt = interp;
		// COLOR = vec4((muddle_color * amt + sample_color * (1.0 - amt)).rgb, COLOR.a);
		float alpha = COLOR.a;
		muddle_color = mix(sample_color, full_muddle, amt);

		// I'm lazy, tint it kinda darker green
		// muddle_color = mix(muddle_color, vec4(0.05, 0.1, 0.0, muddle_color.a), 0.7);

		muddle_color.a = sample_color.a;
	}

	COLOR = muddle_color;

	// Wave highlights
	int n_spawners = N_WAVESPAWNERS;
	for (int i = 0; i < n_spawners; i++) {
		vec2 center = wavespawner_locs[i];

		// Use this for making frogs leap into the water.
		float pd = ripple_time + (float(i) / float(n_spawners)) * (2.0 * 3.1415) / 3.2 * 0.3;
		// Now apply the highlight ripple
		vec4 highlight = ripple_highlight(xy, center, pd, 3.2);

		// Doesn't really combine with anything.
		vec3 combined_highlight = mix(COLOR.rgb, vec3(1), 0.85);

		if (highlight.a > tot_highlight.a) {
			tot_highlight.a = highlight.a;
			tot_highlight.rgb = combined_highlight;
		}
	}

	// Key out stuff that is not gaussian colored.
	if (abs(gaussian_color.r - 0.3) < 0.4 && abs(gaussian_color.b - 0.5) < 0.3) {
		tot_highlight.a *= 0.8;
		COLOR = mix(muddle_color * 0.8, tot_highlight, tot_highlight.a * 0.8);
	} else {
		tot_highlight.a *= 0.65;
		// Random "tears" of highlightable area
		vec4 avg_tot_highlight = vec4(1) * (tot_highlight.r + tot_highlight.g + tot_highlight.b) / 3.0;
		COLOR = mix(muddle_color * 0.8, avg_tot_highlight, tot_highlight.a * 0.8);
	}

	COLOR.a = sample_color.a;

	// COLOR = vec4(muddle_color.rgb * (1.0 - tot_highlight.a) + tot_highlight.rgb * tot_highlight.a, muddle_color.a);

	// COLOR = muddle_color;

	// whole thing is too blue, have to shift it brown, oh well do later
	// COLOR = intensity_map(xy);

	// COLOR = vec4(avg_intensity, avg_intensity, avg_intensity, 1);
	// DEBUG, make it fairly translucent
	// COLOR.a *= 0.9;
}