class_name NewConicalNode extends Node

func get_strengths() -> Array[float]:
	return [
		5.0,
		2.0,
		3.0,
		5.0,
		2.0,
		3.0
	]

func get_wavespawner_locs() -> Array[Vector2]:
	return [
		Vector2(0.5, 0.1),
		Vector2(0.5, 0.25),

		Vector2(0.65, 0.5),

		Vector2(0.5, 0.9),
		Vector2(0.5, 0.75),

		Vector2(0.35, 0.5)
	]

func affect_lilypad(lilypad: Lilypad) -> Vector2:
	var strengths := get_strengths()
	var locs := get_wavespawner_locs()
	var total_force := Vector2.ZERO

	# The more one-sided a force is, the more it affects total_force
	var forces: Array[Vector2] = []
	var force_mag := 0.0
	for i in len(locs):
		var wave_loc := locs[i]
		var strength := strengths[i]
		var delt := lilypad.pos - wave_loc
		var force := strength * delt.normalized() * pow(0.8, 12.0 * delt.length()) * 0.0001
		forces.append(force)
		force_mag += force.length()
	
	forces.sort_custom(func(a: Vector2, b: Vector2): return a.length() < b.length())
	var forces_unit_sum := Vector2.ZERO
	for i in len(forces):
		var force := forces[i]
		forces_unit_sum += force * pow(0.6, i)
	total_force = forces_unit_sum.normalized() * force_mag
	
	var drag_delta := -0.5 * lilypad.vel
	return drag_delta + total_force