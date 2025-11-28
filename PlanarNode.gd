extends TextureRect

var mat: ShaderMaterial = null
var time := 0.0
var last_spawn_time := 0.0
var lilypads: Array[Lilypad] = []

func _ready() -> void:
	mat = material as ShaderMaterial
	var locs := get_wavespawner_locs()
	mat.set_shader_parameter("wavespawner_locs", locs) 
	mat.set_shader_parameter("strengths", get_strengths())
	mat.set_shader_parameter("N_WAVESPAWNERS", len(locs))

func get_strengths() -> Array[float]:
	return [
		5.0,
		5.0,
	]

func get_wavespawner_locs() -> Array[Vector2]:
	return [
		Vector2(0.5, 0.25),
		Vector2(0.5, 0.75),
	]

func _process(delta: float) -> void:
	time += delta

	# Every 0.5 seconds, spawn a lilypad. However, cap out the lilypads with a queue of size 5.
	var LILYPAD_DELAY := 0.05
	var MAX_LILYPADS := 200

	var locs := get_wavespawner_locs()

	if time - last_spawn_time > LILYPAD_DELAY:
		last_spawn_time = time

		var rand_vel := Vector2.from_angle(randf_range(0, 2 * PI)) * 0.3
		var rand_offset = Vector2.from_angle(randf_range(0, 2 * PI)) * 0.05
		# Spawn lilypads from somewhere?
		# We imagine there is a bridge though for conical node.
		var lilypad := Lilypad.new()
		lilypad.pos = Vector2(0.5, 0.5) + rand_offset
		lilypad.vel = rand_vel
		lilypads.append(lilypad)

	# Remove lilypads that are offscreen.
	lilypads = lilypads.filter(func(l: Lilypad): return (l.pos - Vector2(0.5, 0.5)).length() < 0.5)

	if len(lilypads) > MAX_LILYPADS:
		# Remove the FASTEST lilypads.
		lilypads.sort_custom(func(l: Lilypad): return l.vel.length())
		lilypads.remove_at(lilypads.size() - 1)
	
	# Be affected by wavespawner "forces"
	var strengths := get_strengths()
	for lilypad in lilypads:
		var total_force := Vector2.ZERO
		for i in len(locs):
			var wave_loc := locs[i]
			var strength := strengths[i]
			var delt := lilypad.pos - wave_loc
			var force := strength * delt.normalized() * pow(0.8, 12.0 * delt.length()) * 0.003
			total_force += force
		
		# If total_force is low, apply drag. (lazy solution)
		lilypad.vel += total_force
		lilypad.vel *= 0.2


	for lilypad in lilypads:
		lilypad.pos += lilypad.vel

	var lilypad_locs = lilypads.map(func(l: Lilypad): return l.pos)
	mat.set_shader_parameter("lilypad_locs", lilypad_locs)
	mat.set_shader_parameter("N_LILYPADS", len(lilypad_locs))
