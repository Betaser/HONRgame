class_name Frog

extends AnimatedSprite2D

static var norm_cooldown_ts: Array[float] = []

@onready var collision_shape: CollisionShape2D = $StaticBody2D/CollisionShape2D
var parent: TextureRect
var mat: ShaderMaterial

# When you click in an area, make frog jump to the exact location (not final desired behavior, but partway there)

# Assume the bounds of parent are (0, 0) to (1, 1)
# This is in seconds
const JUMP_TIME_PER_UNIT := 2.5
const REPOSITION_TIME_PER_ROT := 1.0
const JUMP_COOLDOWN := 1.5

var start_leap := false
var wavespawner_loc: Vector2 = Vector2(INF, INF)

class JumpState:
	func name() -> String:
		return "JumpState"

class RepositionState extends JumpState:
	var target := Vector2.ZERO
	var start_rotation := 0.0
	var start_pos := Vector2.ZERO
	var t := 0.0
	func name() -> String:
		return "RepositionState"

class StartState extends JumpState:
	var pos := Vector2.ZERO
	func name() -> String:
		return "StartState"

class JumpingState extends JumpState:
	var start_pos := Vector2.ZERO
	var target := Vector2.ZERO
	var t := 0.0
	func name() -> String:
		return "JumpingState"

class EndState extends JumpState:
	var t := 0.0
	var start_rotation: float
	func _init(_t: float, rotation: float) -> void:
		t = _t
		start_rotation = rotation
	func name() -> String:
		return "EndState"

class SelectState extends JumpState:
	func name() -> String:
		return "SelectState"

var jump_state: JumpState = EndState.new(999, 0)
var selected := false

# Cooldown for the frog to be able to be interacted with will be in EndState.
# Then we'll make the frog have a simple cooldown animation in the shader.

func update_shader_tex() -> void:
	var tex := sprite_frames.get_frame_texture(animation, frame)
	mat.set_shader_parameter("tex", tex)

func been_jumping(new_jump_state: JumpState, delta: float) -> JumpState:
	animation = "leaping"
	new_jump_state.t += delta

	# Ends after enough time has passed
	var delt: Vector2 = new_jump_state.target - new_jump_state.start_pos
	var norm_delt_length := (delt / parent.size).length()
	var t_val: float = new_jump_state.t / JUMP_TIME_PER_UNIT / norm_delt_length
	# Now we can do a thing to frick with t_val

	# S shape
	var nicer_t_val := 8.0 * pow(t_val / 2, 2)
	if t_val > 0.5:
		nicer_t_val = -8.0 * pow((t_val - 1) / 2, 2) + 1

	position = delt * nicer_t_val + new_jump_state.start_pos

	if t_val > 1.0:
		position = new_jump_state.target
		new_jump_state = EndState.new(0, rotation)

	return new_jump_state

func _ready() -> void:
	animation = "idle"
	# Make it autoplay I think?
	
	parent = get_parent() as TextureRect

	material = material.duplicate()
	mat = material as ShaderMaterial

# First make jump be a basic linear movement
func _process(delta: float) -> void:
	if start_leap:
		var j := JumpingState.new()
		j.t = 0
		j.start_pos = position
		j.target = wavespawner_loc
		jump_state = j
		start_leap = false

		var to_target_corrected := Vector2.from_angle((j.target - j.start_pos).angle() + PI / 2)
		rotation = to_target_corrected.angle()

	# Set by frog_spawner
	if wavespawner_loc.is_finite():
		var n_jump_state := been_jumping(jump_state, delta)
		if jump_state.name() != n_jump_state.name():
			wavespawner_loc = Vector2(INF, INF)
			# print("ok stop the jump!!!")
		else:
			# The start leap should not be interrupted?
			return

	var new_jump_state := jump_state
	# What's the nicest way to wait a frame?
	if Input.is_action_just_pressed("confirm_jump_target"):
		if new_jump_state is SelectState:
			new_jump_state = StartState.new()
			new_jump_state.pos = position
			
	if selected:
		selected = false
		# print("select a frog.")
		if new_jump_state is EndState:
			if new_jump_state.t >= JUMP_COOLDOWN:
				new_jump_state = Frog.SelectState.new()

	# Reset jumping behavior
	if new_jump_state is StartState:
		# Go into Reposition state
		var r := RepositionState.new()
		r.t = 0
		var local_mouse_pos := parent.get_local_mouse_position()
		r.target = local_mouse_pos
		r.start_pos = new_jump_state.pos 
		r.start_rotation = rotation
		new_jump_state = r

	elif new_jump_state is RepositionState:
		new_jump_state.t += delta

		var to_target_corrected := Vector2.from_angle((new_jump_state.target - new_jump_state.start_pos).angle() + PI / 2)
		var ang_diff := calc_angle_diff(to_target_corrected, Vector2.from_angle(new_jump_state.start_rotation))

		if ang_diff > PI:
			ang_diff -= 2 * PI

		# Let's interpolate orientation
		var t_val: float = new_jump_state.t / REPOSITION_TIME_PER_ROT * 2 * PI / ang_diff

		var target_rotation: float = to_target_corrected.angle()

		rotation = lerp_angle(new_jump_state.start_rotation, target_rotation, t_val)

		if t_val > 1.0:
			var j := JumpingState.new()
			j.t = 0
			j.start_pos = new_jump_state.start_pos
			j.target = new_jump_state.target
			new_jump_state = j
		
	# We have been jumping.
	elif new_jump_state is JumpingState:
		new_jump_state = been_jumping(new_jump_state, delta)
	elif new_jump_state is EndState:
		animation = "idle"
		new_jump_state.t += delta
		mat.set_shader_parameter("norm_cooldown_t", min(1.0, new_jump_state.t / JUMP_COOLDOWN))

		if new_jump_state.t > JUMP_COOLDOWN:
			mat.set_shader_parameter("norm_cooldown_t", -1)
		
	jump_state = new_jump_state
	# print(jump_state.name())
	update_shader_tex()

func calc_angle_diff(a: Vector2, b: Vector2) -> float:
	return acos(a.dot(b) / a.length() / b.length())
