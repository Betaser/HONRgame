extends TextureRect

var mat: ShaderMaterial = null
var time := 0.0
var last_spawn_time := 0.0
var lilypads: Array[Lilypad] = []
var frogs: Array[Frog] = []

# Conical and Planar nodes work the same fundamental way.
# Therefore, categorize them as "distance_nodes". Spherical nodes are "barrier nodes"
var distance_node: NewConicalNode = null

func _ready() -> void:
	mat = material as ShaderMaterial
	distance_node = NewConicalNode.new()

	var locs := distance_node.get_wavespawner_locs()
	mat.set_shader_parameter("wavespawner_locs", locs) 
	mat.set_shader_parameter("wavespawner_strengths", distance_node.get_strengths())
	mat.set_shader_parameter("N_WAVESPAWNERS", len(locs))

	frogs.append(find_children("TestFrog")[0])

func select_frogs(cursor: Vector2) -> void:
	var dist := INF
	var closest_frog: Frog = null

	for frog in frogs:
		var circle_radius := (frog.collision_shape.shape as CircleShape2D).radius
		var circle_pos := frog.collision_shape.position + frog.position
		var to := circle_pos - cursor
		# print(circle_pos, " ", cursor)
		if to.length() < circle_radius:
			dist = min(dist, to.length())
			closest_frog = frog

	if closest_frog != null:
		closest_frog.selected = true

func _process(delta: float) -> void:
	time += delta

	# Selecting frogs.
	if Input.is_action_just_pressed("select_frog"):
		select_frogs(get_local_mouse_position())

	# collision_shape.shape.collide(

	var LILYPAD_DELAY := 0.1
	var MAX_LILYPADS := 200

	var center := Vector2(0.5, 0.5)

	if time - last_spawn_time > LILYPAD_DELAY:
		# Don't add lilypads if there are max number.
		if len(lilypads) < MAX_LILYPADS:
			last_spawn_time = time

			var rand_vel := Vector2.from_angle(randf_range(0, 2 * PI)) * 0.001
			var rand_offset := Vector2.from_angle(randf_range(0, 2 * PI)) * 0.03
			lilypads.append(Lilypad.new(center + rand_offset, rand_vel))

	# Remove lilypads that are offscreen
	lilypads = lilypads.filter(func(l: Lilypad): return (l.pos - center).length() < 0.5)

	# Be affected by node forces
	for lilypad in lilypads:
		lilypad.vel += distance_node.affect_lilypad(lilypad)

	for lilypad in lilypads:
		lilypad.pos += lilypad.vel
	
	var lilypad_locs = lilypads.map(func(l: Lilypad): return l.pos)
	mat.set_shader_parameter("lilypad_locs", lilypad_locs)
	mat.set_shader_parameter("N_LILYPADS", len(lilypad_locs))
