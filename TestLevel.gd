extends TextureRect
class_name TestLevel

var mat: ShaderMaterial = null
var time := 0.0
var last_spawn_time := 0.0
var lilypads: Array[Lilypad] = []
var frogs: Array[Frog] = []

var handrawn_offset: Vector2
var handrawn_dim: Vector2i

@onready var blur_canvas = $"../BlurCanvas" as Blur

var frog_texture_path: String = "res://Assets/frog_skin_texture.jpg"

var handrawn_water: Array[Array] = [
	[
		"res://Assets/Handrawn Water/Handrawn_water2_0.png",
		"res://Assets/Handrawn Water/Handrawn_water_highlight_0.png"
	],
	[
		"res://Assets/Handrawn Water/Handrawn_water2_0.png",
		"res://Assets/Handrawn Water/Handrawn_water_highlight_1.png"
	],
	[
		"res://Assets/Handrawn Water/Handrawn_water2_0.png",
		"res://Assets/Handrawn Water/Handrawn_water_highlight_2.png"
	],
]
var handrawn_water_shadows: Array[String] = [
	"res://Assets/Handrawn Water/Blurred_handrawn_water0.png",
	"res://Assets/Handrawn Water/Blurred_handrawn_water1.png",
	"res://Assets/Handrawn Water/Blurred_handrawn_water2.png",
]
var handrawn_water_textures: Array[Array] = []
var handrawn_water_highlight: CompressedTexture2D = null
var handrawn_water_shadow_textures: Array[CompressedTexture2D] = []

# Conical and Planar nodes work the same fundamental way.
# Therefore, categorize them as "distance_nodes". Spherical nodes are "barrier nodes"
var distance_node: NewConicalNode = null

var time_last_rand_water := -9999.0

var time_last_ripple := 0.0

# Bigger = scaled effect.
var GRID_SIZES := [4, 8, 16, 20, 24]

class RandWater:
	var grid_size: float = 0.0
	var vals: Array[float] = []
	var last_vals: Array[float] = []

var rand_waters: Array[RandWater] = []

@onready var frog_spawner: FrogSpawner = $FrogSpawner
@onready var ref_frog: Frog = $ReferenceFrog
@onready var ref_lilypad: Lilypad = $ReferenceLilypad

func _ready() -> void:
	mat = material as ShaderMaterial
	distance_node = NewConicalNode.new()
	frog_spawner.init(0, distance_node.get_wavespawner_locs(), frogs, self)

	var locs := distance_node.get_wavespawner_locs()
	mat.set_shader_parameter("wavespawner_locs", locs) 
	mat.set_shader_parameter("wavespawner_strengths", distance_node.get_strengths())
	mat.set_shader_parameter("N_WAVESPAWNERS", len(locs))
	
	for GRID_SIZE in GRID_SIZES:
		var rand_water := RandWater.new()
		rand_water.grid_size = GRID_SIZE
		for i in range(GRID_SIZE * GRID_SIZE):
			rand_water.vals.append(0.5)
			rand_water.last_vals.append(0.5)
		rand_waters.append(rand_water)

	for water_paths in handrawn_water:
		var img_texs: Array[CompressedTexture2D] = []
		for water_path in water_paths:
			# var img := Image.load_from_file(water_path)
			var img_tex := load(water_path)
			# var img_tex := ImageTexture.create_from_image(img)
			img_texs.append(img_tex)
		handrawn_water_textures.append(img_texs)
		
	for water_path in handrawn_water_shadows:
		# var img := Image.load_from_file(water_path)
		# var img_tex := ImageTexture.create_from_image(img)
		var img_tex := load(water_path)
		handrawn_water_shadow_textures.append(img_tex)
		
	var frog_img_tex := load(frog_texture_path)
	mat.set_shader_parameter("frog_skin_texture", frog_img_tex)

func select_frogs(cursor: Vector2) -> void:
	var dist := INF
	var closest_frog: Frog = null

	for frog in frogs:
		var circle_shape := frog.collision_shape.shape as CircleShape2D
		var circle_radius := circle_shape.radius * frog.global_scale.x
		var circle_pos := frog.collision_shape.global_position
		var to := circle_pos - cursor
		# print(circle_pos, " ", cursor)
		if to.length() < circle_radius:
			dist = min(dist, to.length())
			closest_frog = frog

	if closest_frog != null:
		# print("selected frog with coordinates ", closest_frog.position)
		closest_frog.selected = true

func _process(delta: float) -> void:
	time += delta

	# Debug testing ripples
	time_last_ripple += delta
	if Input.is_action_just_pressed("debug_u"):
		time_last_ripple = 0.0
	mat.set_shader_parameter("ripple_time", time_last_ripple)

	# Selecting frogs.
	if Input.is_action_just_pressed("select_frog"):
		select_frogs(get_global_mouse_position())

	var LILYPAD_GROUP_DELAY := 3.4
	var NUM_CARRIED_LILYPADS := 5
	var MAX_LILYPADS := 200

	var center := Vector2(0.5, 0.5)

	if time - last_spawn_time > LILYPAD_GROUP_DELAY:
		# Don't add lilypads if there are max number.
		if len(lilypads) < MAX_LILYPADS:
			last_spawn_time = time
			for i in range(NUM_CARRIED_LILYPADS):
				var rand_vel := Vector2.from_angle(randf_range(0, 2 * PI)) * 0.001
				var rand_offset := Vector2.from_angle(randf_range(0, 2 * PI)) * 0.08
				
				var lilypad := ref_lilypad.duplicate() as Lilypad
				lilypad.pos = center + rand_offset
				lilypad.vel = rand_vel
				lilypad.new_visible = true
				add_child(lilypad)
				lilypads.append(lilypad)

	# lilypads = lilypads.filter(func(l: Lilypad): return (l.pos - center).length() < 0.5)

	var dead_lilypads: Array[Lilypad] = []
	for lilypad in lilypads:
		if (lilypad.pos - center).length() > 0.5:
			dead_lilypads.append(lilypad)

	# Be affected by node forces
	for lilypad in lilypads:
		lilypad.vel += distance_node.affect_lilypad(lilypad, lilypads)
		lilypad.update(frogs)
	
	# Remove lilypads that are offscreen
	var longest_len := 0
	for lilypad in lilypads:
		var l := (lilypad.pos - center).length()
		longest_len = max(longest_len, l)

	var lilypad_locs = lilypads.map(func(l: Lilypad): return l.pos)
	mat.set_shader_parameter("lilypad_locs", lilypad_locs)
	mat.set_shader_parameter("N_LILYPADS", len(lilypad_locs))

	# Add random element to water
	var TRANS_TIME := 8.0

	if time - time_last_rand_water > TRANS_TIME:
		# DEBUGGING
		time_last_rand_water = time
		for rand_water in rand_waters:
			for i in len(rand_water.vals):
				rand_water.last_vals[i] = rand_water.vals[i]
			for i in len(rand_water.vals):
				# rand_water.vals[i] = semi_rand(time + i * 0.02341)
				rand_water.vals[i] = randf_range(0, 1)

	var mixed_water: Array[float] = []
	for rand_water in rand_waters:
		for i in len(rand_water.vals):
			var raw_interp := (time - time_last_rand_water) / TRANS_TIME
			var interp := 8.0 * pow(raw_interp / 2, 2)
			if raw_interp > 0.5:
				interp = -8.0 * pow((raw_interp - 1) / 2, 2) + 1

			mixed_water.append(rand_water.last_vals[i] + (rand_water.vals[i] - rand_water.last_vals[i]) * interp)
	
	mat.set_shader_parameter("rand_vals", mixed_water)

	mat.set_shader_parameter("GRID_SIZE_N", len(GRID_SIZES))
	mat.set_shader_parameter("GRID_SIZES", GRID_SIZES)
	
	# Lemniscate
	var angle := time * 0.6 + PI / 2
	var angle_norm := fmod(angle - PI / 2, 2 * PI) / (2 * PI)
	
	var f := func(x: float):
		var c := 0.33
		return -0.25 / (c * c - pow((0.25 - c), 2)) * pow((x - c), 2)
	var quad_array := [
		f.call(angle_norm) - f.call(0),
		-f.call(-angle_norm + 0.5) + f.call(0.25) + 0.25,
		f.call(angle_norm - 0.5) - f.call(0) + 0.5,
		-f.call(-(angle_norm - 0.5) + 0.5) + f.call(0.25) + 0.75
	]
	angle_norm = quad_array[int(angle_norm / 0.25)]
	
	angle = angle_norm * (2 * PI) + PI / 2
	var y := cos(angle) / (1 + pow(sin(angle), 2))
	var x := y * sin(angle)
	var texture_offset := Vector2(0.6 * x, 0.8 * y)
	mat.set_shader_parameter("texture_offset", texture_offset)
	
	# Ellipse
	handrawn_offset = Vector2(1.1 * x, 0.6 * y)
	mat.set_shader_parameter("handrawn_offset", handrawn_offset)
	
	# Frame by frame ani
	var ani_time = fmod(time, 8.0) / 8.0
	var lower_time_to_ani_index: Array[Vector2] = [
		Vector2(0.7, 0),
		Vector2(0.5, 1),
		Vector2(0.4, 2),
		Vector2(0.3, 1),
		Vector2(0.0, 0),
	]
	var ani_index := 0
	for lower in lower_time_to_ani_index:
		if ani_time > lower.x:
			ani_index = int(lower.y)
			break

	var handrawn_water_texs := handrawn_water_textures[ani_index]
	mat.set_shader_parameter("handrawn_water", handrawn_water_texs[0])
	mat.set_shader_parameter("handrawn_highlight", handrawn_water_texs[1])
	handrawn_water_highlight = handrawn_water_texs[1]
	
	handrawn_dim = Vector2i(handrawn_water_texs[0].get_width(), handrawn_water_texs[0].get_height())
	mat.set_shader_parameter("handrawn_dim", handrawn_dim)

	mat.set_shader_parameter("blurred_shadow", handrawn_water_shadow_textures[ani_index])

	for lilypad in dead_lilypads:
		lilypads.erase(lilypad)
		lilypad.queue_free()

func vec4_from(first: float, vec3: Vector3) -> Vector4:
	var v := Vector4()
	v.x = first
	v.y = vec3.x
	v.z = vec3.y
	v.w = vec3.z
	return v
	
func hex_to_vec3(hex: int) -> Vector3:
	var b := float(hex & 0xFF) / 0xFF
	var g := float((hex >> 8) & 0xFF) / 0xFF
	var r := float((hex >> 16) & 0xFF) / 0xFF
	return Vector3(r, g, b)

func fract(v: float) -> float:
	return v - floor(v)

func hash(p: float) -> float:
	p = fract(p * 0.011)
	p *= p + 7.5
	p *= p + p
	return fract(p)

# linear interpolation
func mix(a: float, b: float, t: float) -> float:
	return a + (b - a) * t

func semi_rand(x: float) -> float:
	# x *= 4000.0
	x *= 2000.0
	var i: float = floor(x)
	var f := fract(x)
	var u := f * f * (3 - 2 * f)
	return fmod(mix(hash(i), hash(i + 1), u), 1.0)
