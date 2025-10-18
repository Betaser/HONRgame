shader_type canvas_item;

uniform float t = 0;

void vertex() {
	// Called for every vertex the material is visible on.
}

struct Circle {
	float radius;
	vec2 position;
};

vec2 closest_point_on_line(vec2 point, vec2 line_pt1, vec2 line_pt2) {
	vec2 a = point - line_pt1;
	vec2 b = line_pt2 - line_pt1;
	return line_pt1 + dot(a, b) / dot(b, b) * b;
}

void secant_intersection_pts(Circle c, vec2[2] pts, out vec2[2] intersections) {
	vec2 v = normalize(pts[1] - pts[0]);
	vec2 closest = closest_point_on_line(c.position, pts[0], pts[1]);
	float dist = length(closest - c.position);
	float leg_len = sqrt(pow(c.radius, 2.0) - pow(dist, 2.0));
	intersections[0] = closest + v * leg_len;
	intersections[1] = closest - v * leg_len;
}

// UNUSED
vec2 perp(vec2 v) {
	float vx = v.x;
	v.x = v.y;
	v.y = -vx;
	return v;
}

float dist_of_point_from_line(vec2 point, vec2 line_pt1, vec2 line_pt2) {
	vec2 to_point = line_pt1 - point;
	vec2 out_v = perp(line_pt2 - line_pt1);

	return abs(dot(to_point, out_v) / length(out_v));
}

// UNUSED
Circle circle_2_points_1_tangent(vec2 tangent_pt, vec2 other_pt, vec2 tangent) {
	tangent = normalize(tangent);
	tangent = perp(tangent);
	vec2 delta = other_pt - tangent_pt;
	vec2 perp_delta = perp(delta);
	float sin_cross = cross(vec3(perp_delta, 0), vec3(tangent, 0)).z;
	if (sin_cross < 0.0) {
		tangent = -tangent;
		sin_cross = cross(vec3(perp_delta, 0), vec3(tangent, 0)).z;
	}
	sin_cross *= 1.0 / length(perp_delta);
	float opp_len = length(delta) / 2.0;
	float hyp_len = opp_len / sin_cross;
	if (sin_cross < 0.0) {
		hyp_len *= -1.0;
	}
	vec2 center = tangent_pt + tangent * hyp_len;
	Circle circle;
	circle.radius = hyp_len;
	circle.position = center;
	return circle;
}

vec2 intersection_lines(vec2 side_a[2], vec2 side_b[2]) {
	vec2 d1 = side_a[1] - side_a[0];
	float ndy2 = side_b[0].y - side_b[1].y;
	float det = d1.x * ndy2 - (side_b[0].x - side_b[1].x) * d1.y;

	// det == 0 case is unhandled
	vec2 a_inv_row_1 = vec2(
		(side_b[0].y - side_b[1].y) / det,
		(side_b[1].x - side_b[0].x) / det
	);
	vec2 b = vec2(side_b[0] - side_a[0]);
	float t1 = a_inv_row_1[0] * b[0] + a_inv_row_1[1] * b[1];
	vec2 v = d1 * t1 + side_a[0];
	return v;
}

float angle(vec2 v) {
	float ang = atan(-v.y, v.x);
	if (ang < 0.0) {
		return ang + 2.0 * PI;
	}
	return ang;
}

// ratio is normalized
// sigmoidal?
float alter_ratio(float r) {
	return 1.0 - 1.0 / (1.0 + pow(r / (1.0 - r), 2.0));
}

void shrink_pts(inout vec2 pts[3], vec2 mid, float amt) {
	for (int i = 0; i < pts.length(); i++) {
		vec2 v = pts[i] - mid;
		pts[i] = v * amt + mid;
	}
}

float angle_between(vec2 a, vec2 b) {
	float cos_theta = dot(a, b) / length(a) / length(b);
	return acos(cos_theta);
}

vec2 bad_intersection_lines(vec2 side_a[2], vec2 side_b[2]) {
	float dx1 = side_a[1].x - side_a[0].x;
	float dy1 = side_a[1].y - side_a[0].y;
	float ndy2 = side_b[0].y - side_b[1].y;
	float det = dx1 * ndy2 - (side_b[0].x - side_b[1].x) * dy1;

	// det == 0 case is unhandled
	vec2 a_inv_row_1 = vec2(
		(side_b[0].y - side_b[1].y) / det,
		(side_b[1].x - side_b[0].x) / det
	);
	vec2 b = vec2(
		side_b[0].x - side_a[0].x,
		side_b[0].y - side_a[0].y
	);
	float t1 = a_inv_row_1[0] * b[0] + a_inv_row_1[1] * b[1];
	float x = dx1 * t1 + side_a[0].x;
	float y = dy1 * t1 + side_a[0].y;
	return vec2(x, y);
}

vec2 diff_of_non(vec2 pts[3], int index) {
	switch (index) {
		case 0:
			return pts[1] - pts[2];
		case 1:
			return pts[0] - pts[2];
	};
	return pts[0] - pts[1];
}

float multiple_of_unit_edge(vec2 tri_pts[3], vec2 mid, vec2 o) {
	vec2 a = tri_pts[0];
	vec2 b = tri_pts[1];
	vec2 c = tri_pts[2];
	//    a
	// b     c
	/*
	vec2 bisector1 = normalize(b - a) + normalize(c - a);
	vec2 bisector2 = normalize(b - c) + normalize(a - c);
	vec2 circle_center = intersection_lines(
		{ a, a + bisector1 },
		{ c, c + bisector2 });
	*/
	vec2 mid_ab = (a + b) / 2.0;
	vec2 mid_bc = (b + c) / 2.0;
	vec2 circle_center = intersection_lines(
		{ mid_ab, mid_ab + perp(a - b) },
		{ mid_bc, mid_bc + perp(b - c) });

	vec2 pt = o + mid;
	o = pt - circle_center;
	float small_ratio = 1.0 / 0.0;
	float edge_dist = length(o);

	float circumscribed_circle_radius = length(a - b) * length(b - c) * length(c - a)
		/ (2.0 * abs(cross(vec3(a - b, 0), vec3(c - b, 0)).z));
	float circle_dist = length(o) / circumscribed_circle_radius;

	for (int i = 0; i < tri_pts.length(); i++) {
		vec2 p1 = tri_pts[i];
		vec2 p2 = tri_pts[(i + 1) % tri_pts.length()];

		vec2 out1 = p1 - circle_center;
		vec2 out2 = p2 - circle_center;
		float out_to_vert_outs_sum = angle_between(out1, o) + angle_between(out2, o);
		float new_ratio = abs(1.0 - out_to_vert_outs_sum / angle_between(out1, out2));

		if (new_ratio < small_ratio) {
			small_ratio = new_ratio;
			vec2 max_inter = intersection_lines({ p1, p2 }, { circle_center, pt });
			float segment_dist = length(o) / length(max_inter - circle_center) * 1.0;

			// float inscribed_circle_radius = abs(cross(vec3(a - b, 0), vec3(c - b, 0)).z
			// * 0.5 / (0.5 * (length(a - b) + length(b - c) + length(c - a))));

			// float min_dist = length(o) / inscribed_circle_radius;

			float n1to2 = angle_between(out2, o) / angle_between(out1, out2);
			float n = 0.4 * (abs(n1to2 - 0.5) / 0.5) + 0.6;

			// We multiply distance d (see diagram) by n. Trouble is finding d.

			/*
			Circle circle;
			circle.position = circle_center;
			circle.radius = circumscribed_circle_radius;
			vec2[2] inters;
			secant_intersection_pts(
				circle,
				{ max_inter, max_inter + perp(p1 - p2) },
				inters);
			int inter_idx = dist_of_point_from_line(inters[0], p1, p2) <
				dist_of_point_from_line(inters[1], p1, p2)
				? 0 : 1;
			vec2 inter = inters[inter_idx];
			float d = dist_of_point_from_line(inter, p1, p2);
			vec2 pos = max_inter + d * 1.0 * normalize(inter_idx == 0 ? -perp(a - b) : perp(a - b));
			edge_dist = length(o) / length(pos - circle_center);
			*/


			vec2 circle_hit = normalize(o) * circumscribed_circle_radius + circle_center;
			float d = dist_of_point_from_line(circle_hit, p1, p2);
			vec2 pos = circle_hit + d * 1.0 * normalize(perp(a - b));
			edge_dist = length(o) / length(pos - circle_center);
			// edge_dist = segment_dist + (circle_dist - segment_dist) * n;

			// float CURVE_AMT = 0.4;
			// edge_dist = min_dist * CURVE_AMT + segment_dist * (1.0 - CURVE_AMT);
		}
	}
	return edge_dist;

	// This method requires scaling the unit edge.
	/*
	float SCALE1 = 9.0;
	float SCALE2 = 50.0;

	shrink_pts(tri_pts, mid, length(o) * SCALE1);
	float dist_combined = 0.0;
	for (int i = 0; i < tri_pts.length(); i++) {
		dist_combined += length(tri_pts[i] - (o + mid));
	}
	return dist_combined * SCALE2 / SCALE1;
	*/
}

float bad_multiple_of_unit_edge(vec2 tri_pts[3], vec2 mid, vec2 o) {
	float small = 999999.0;
	int loc = -1;
	float edge_dist = 999999.0;

	float small_ratio = 1.0 / 0.0;
	float debug_lens[3] = {0.3, 0.4, 0.5};
	for (int i = 0; i < tri_pts.length(); i++) {
		vec2 p1 = tri_pts[i];
		vec2 p2 = tri_pts[(i + 1) % tri_pts.length()];
		vec2 out1 = p1 - mid;
		vec2 out2 = p2 - mid;
		float tri_angle1 = angle(out1);
		float tri_angle2 = angle(out2);

		float l1 = length(out1);
		float l2 = length(out2);

		float out_to_vert_outs_sum = angle_between(out1, o) + angle_between(out2, o);
		float new_ratio = abs(1.0 - out_to_vert_outs_sum / angle_between(out1, out2));

		if (new_ratio < small_ratio) {
			small_ratio = new_ratio;
			loc = i;

			vec2 delta1 = diff_of_non(tri_pts, i);
			vec2 delta2 = diff_of_non(tri_pts, (i + 1) % tri_pts.length());

			vec2 mid_to_pt[2] = { mid, mid + o };
			vec2 inter1 = intersection_lines(mid_to_pt, { p1, p1 + delta1 });
			vec2 inter2 = intersection_lines(mid_to_pt, { p2, p2 + delta2 });

			float max_dist = min(length(inter1 - mid), length(inter2 - mid));
			vec2 x_inter = intersection_lines(mid_to_pt, { p1, p2 });
			float min_dist = length(x_inter - mid);

			float n1to2 = angle_between(out2, o) / angle_between(out1, out2);

			float n = 0.5 * (abs(n1to2 - 0.5) / 0.5) + 0.5;

			vec2 max_pt = intersection_lines({ p1, p1 + delta1 }, { p2, p2 + delta2 });
			vec2 towards = x_inter - max_pt;
			vec2 fin_pt = max_pt + towards * n;
			edge_dist = length(fin_pt - mid);
			// n1to2 = 0.1;
			edge_dist = min_dist + (max_dist - min_dist) * 0.1;
			/*
			// NO, NOT JUST OTHER SIDE
			vec2 other_side[2];
			switch (i) {
				case 0:
					other_side[0] = tri_pts[1];
					other_side[1] = tri_pts[2];
					break;
				case 1:
					other_side[0] = tri_pts[0];
					other_side[1] = tri_pts[2];
					break;
				case 2:
					other_side[0] = tri_pts[0];
					other_side[1] = tri_pts[1];
			};
			// vec2 out_v[2] = { mid, mid + o };
			// float d1 = intersection_lines(out_v, other_side);
			// float d2 = intersection_lines(out_v, )
			// edge_dist = debug_lens[i];
			*/
		}
	}

	// loc can be returned for debugging section purposes
	return length(o) / edge_dist;
}

float old_multiple_of_unit_edge(vec2 tri_pts[3], vec2 mid, vec2 o) {
	float pt_angle = angle(o);
	float small = 999999.0;
	int loc = -1;
	float max_dist = 999999.0;
	for (int i = 0; i < tri_pts.length(); i++) {
		float tri_angle1 = angle(tri_pts[i] - mid);
		float tri_angle2 = angle(tri_pts[(i + 1) % tri_pts.length()] - mid);

		float l1 = length(tri_pts[i] - mid);
		float l2 = length(tri_pts[(i + 1) % tri_pts.length()] - mid);

		// Then we have wrong angles; it goes through 0
		bool in_ang = false;
		if (abs(tri_angle1 - tri_angle2) > PI) {
			// Then we need to set max_dist differently!
			float small_angle = min(tri_angle1, tri_angle2);
			float diff = small_angle * 1.01;
			small_angle = small_angle - diff + 2.0 * PI;
			float big_angle = max(tri_angle1, tri_angle2) - diff;
			float new_pt_angle = pt_angle - diff;
			if (new_pt_angle < 0.0) {
				new_pt_angle += 2.0 * PI;
			}


			if (0.0 <= pt_angle && pt_angle <= min(tri_angle1, tri_angle2)) {
				in_ang = true;
			}
			if (max(tri_angle1, tri_angle2) <= pt_angle && pt_angle <= 2.0 * PI) {
				in_ang = true;
			}

			if (in_ang) {
				loc = i;

				// 3  x  9
				// res = a + (b-a)|(x-9)/(3-9)|
				float ratio = (new_pt_angle - small_angle) / (big_angle - small_angle);
					ratio = alter_ratio(ratio);
				if (tri_angle1 > tri_angle2) {
					max_dist = l2 + (l1 - l2) * ratio;
				} else {
					max_dist = l2 + (l1 - l2) * (1.0 - ratio);
				}
			}

		} else {
			if (min(tri_angle1, tri_angle2) <= pt_angle && pt_angle <= max(tri_angle1, tri_angle2)) {
				loc = i;

				float ratio = abs(pt_angle - tri_angle2) / abs(tri_angle1 - tri_angle2);
				ratio = alter_ratio(ratio);
				max_dist = l2 + (l1 - l2) * ratio;
			}
		}
	}

	// loc can be returned for debugging section purposes
	return length(o) / max_dist;
}

struct Triangle {
	vec2 pts[3];
};

Triangle mkTriangle(vec2 a, vec2 b, vec2 c) {
	Triangle triangle;
	triangle.pts[0] = a;
	triangle.pts[1] = b;
	triangle.pts[2] = c;
	return triangle;
}

void fragment() {
	vec2 xy = UV.xy;
	vec2 a = vec2(0.9, 0.6);
	vec2 b = vec2(0.5, 0.5);
	vec2 c = vec2(0.1, 0.6);

	vec2 tri_pts[3] = { a, b, c };

	// Mid can be calculated in potentially different ways, though it shouldn't affect things much
	/*
	vec2 mid = vec2(0);

	for (int i = 0; i < tri_pts.length(); i++) {
		mid += tri_pts[i];
	}
	mid *= (1.0 / float(tri_pts.length()));
	*/
	/*
	vec2 bisector1 = normalize(b - a) + normalize(c - a);
	vec2 bisector2 = normalize(b - c) + normalize(a - c);
	vec2 circle_center = intersection_lines(
		{ a, a + bisector1 },
		{ c, c + bisector2 });
	// vec2 mid = circle_center;
	*/

	vec2 mid_ab = (a + b) / 2.0;
	vec2 mid_bc = (b + c) / 2.0;
	vec2 mid = intersection_lines({ mid_ab, c }, { mid_bc, a });

	shrink_pts(tri_pts, mid, 0.2);
	vec2 o = xy - mid;

	float dist = -t + old_multiple_of_unit_edge(tri_pts, mid, o);
	if (dist < PI / 2.0) {
		float val = pow(0.8, length(o) * 8.0) * (sin(3.0 * dist) + 1.0) / 2.0;
		COLOR = vec4(0, 0, 0, 1) * val + vec4(1, 1, 1, 1) * (1.0 - val);
	}

	// Rendering the location of points
	for (int i = 0; i < tri_pts.length(); i++) {
		vec2 pt = tri_pts[i];
		if (length(xy - pt) < 0.05) {
			vec4 clr = vec4(0, 1, 1, 1);
			COLOR = COLOR * 0.8 + clr * 0.2;
		}
	}
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
