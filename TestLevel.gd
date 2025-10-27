extends TextureRect
class_name TestLevel

var mat: ShaderMaterial = null
var time := 0.0
var last_spawn_time := 0.0
var lilypads: Array[Lilypad] = []
var frogs: Array[Frog] = []

var handrawn_water_tex: Texture2D = null
var handrawn_offset: Vector2
var handrawn_dim: Vector2i

@onready var blur_canvas = $"../BlurCanvas" as Blur

var handrawn_water: Array[String] = [
	"res://Assets/Handrawn Water/Handrawn_water0.png",
	"res://Assets/Handrawn Water/Handrawn_water1.png",
	"res://Assets/Handrawn Water/Handrawn_water2.png",
]
var handrawn_water_shadows: Array[String] = [
	"res://Assets/Handrawn Water/Blurred_handrawn_water0.png",
	"res://Assets/Handrawn Water/Blurred_handrawn_water1.png",
	"res://Assets/Handrawn Water/Blurred_handrawn_water2.png",
]
var handrawn_water_textures: Array[Texture2D] = []
var handrawn_water_shadow_textures: Array[Texture2D] = []

# Conical and Planar nodes work the same fundamental way.
# Therefore, categorize them as "distance_nodes". Spherical nodes are "barrier nodes"
var distance_node: NewConicalNode = null

var time_last_rand_water := -9999.0

# Bigger = scaled effect.
var GRID_SIZES := [4, 8, 16, 20, 24]
class RandWater:
	var grid_size: float = 0.0
	var vals: Array[float] = []
	var last_vals: Array[float] = []
var rand_waters: Array[RandWater] = []

func _ready() -> void:
	mat = material as ShaderMaterial
	distance_node = NewConicalNode.new()

	var locs := distance_node.get_wavespawner_locs()
	mat.set_shader_parameter("wavespawner_locs", locs) 
	mat.set_shader_parameter("wavespawner_strengths", distance_node.get_strengths())
	mat.set_shader_parameter("N_WAVESPAWNERS", len(locs))

	frogs.append(find_children("TestFrog")[0])
	
	for GRID_SIZE in GRID_SIZES:
		var rand_water := RandWater.new()
		rand_water.grid_size = GRID_SIZE
		for i in range(GRID_SIZE * GRID_SIZE):
			rand_water.vals.append(0.5)
			rand_water.last_vals.append(0.5)
		rand_waters.append(rand_water)

	for water_path in handrawn_water:
		var img := Image.load_from_file(water_path)
		var img_tex := ImageTexture.create_from_image(img)
		handrawn_water_textures.append(img_tex)
		
	for water_path in handrawn_water_shadows:
		var img := Image.load_from_file(water_path)
		var img_tex := ImageTexture.create_from_image(img)
		handrawn_water_shadow_textures.append(img_tex)

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

	# Add random element to water
	var TRANS_TIME := 2.0

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
	var ani_time = fmod(time, 4.0) / 4.0
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

	handrawn_water_tex = handrawn_water_textures[ani_index]
	mat.set_shader_parameter("handrawn_water", handrawn_water_tex)
	handrawn_dim = Vector2i(handrawn_water_tex.get_width(), handrawn_water_tex.get_height())
	mat.set_shader_parameter("handrawn_dim", handrawn_dim)

	mat.set_shader_parameter("blurred_shadow", handrawn_water_shadow_textures[ani_index])

	"""
	var intensity_bounds_to_color: Array[Vector4] = [
		vec4_from(0.4, hex_to_vec3(0xBED2E0)),
		vec4_from(0.32, hex_to_vec3(0x96AE9C)),
		vec4_from(0.30, hex_to_vec3(0x5E826A)),
		vec4_from(0.27, hex_to_vec3(0x252145)),
		vec4_from(0.0, hex_to_vec3(0x1C2A31)),
	]
	var avg_intensity := 0.0
	while avg_intensity < 1.0:
		for i in intensity_bounds_to_color.size():
			var lower := intensity_bounds_to_color[i]
			var upper := intensity_bounds_to_color[max(0, i - 1)]
			if i == 0:
				upper.x = 1.0
			if avg_intensity > lower.x:
				var c1 := lower
				c1.w = 1
				var c2 := upper
				c2.w = 1
				var interp := (avg_intensity - lower.x) / (upper.x - lower.x)
				var CLR := c1 + (c2 - c1) * interp
				print("interp ", interp)
				print("top ", avg_intensity - lower.x, " btm ", upper.x - lower.x)
				print("avg ", avg_intensity, " upperx ", upper.x, " lowerx ", lower.x)
				print("")
				break

		avg_intensity += 0.05
	"""

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
