extends TextureRect

var mat: ShaderMaterial = null
var time := 0.0
var last_spawn_time := 0.0
var lilypads: Array[Lilypad] = []

func _ready() -> void:
	mat = material as ShaderMaterial
	mat.set_shader_parameter("N_FENCES", 1)

func get_fence_radii() -> Array[float]:
	return [
		0.3
	]

func _process(delta: float) -> void:
	time += delta
	var LILYPAD_DELAY := 0.1
	var MAX_LILYPADS := 200

	if time - last_spawn_time > LILYPAD_DELAY:
		last_spawn_time = time

		var rand_vel = Vector2.from_angle(randf_range(0, 2 *  PI)) * 0.3
		var rand_offset = Vector2.from_angle(randf_range(0, 2 * PI)) * 0.05
		lilypads.append(Lilypad.new(Vector2(0.5, 0.5) + rand_offset, rand_vel))

	lilypads = lilypads.filter(func(l: Lilypad): return (l.pos - Vector2(0.5, 0.5)).length() < 0.5)

	if len(lilypads) > MAX_LILYPADS:
		lilypads.sort_custom(func(l: Lilypad): return l.vel.length())
		lilypads.remove_at(lilypads.size() - 1)

	var radii := get_fence_radii()
	for lilypad in lilypads:
		var delt := lilypad.pos - Vector2(0.5, 0.5)
		var strength := 0.3 
		# Desire to make the sameish as others
		var total_force := strength * delt.normalized() * pow(0.8, 12.0 * delt.length()) * 0.003
		for radius in radii:
			var dist := absf(delt.length() - radius)
			if dist < 0.1:
				total_force *= dist / 0.001
		
		lilypad.vel += total_force
		lilypad.vel *= 0.4
	
	for lilypad in lilypads:
		lilypad.pos += lilypad.vel

	var lilypad_locs = lilypads.map(func(l: Lilypad): return l.pos)
	mat.set_shader_parameter("fence_radii", radii)
	mat.set_shader_parameter("lilypad_locs", lilypad_locs)
	mat.set_shader_parameter("N_LILYPADS", len(lilypad_locs))
