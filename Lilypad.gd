class_name Lilypad

extends AnimatedSprite2D

var pos: Vector2
var vel: Vector2

var new_visible := false

@onready var static_body: StaticBody2D = $StaticBody2D

func _ready() -> void:
	animation = "idle"
	play(animation)
	# lilypad has no shader, but below is needed for animations to be unique
	material = material.duplicate()

func update(frogs: Array[Frog]) -> void:
	var movable := true
	for frog in frogs:
		var f_shape := frog.collision_shape.shape as CircleShape2D
		var f_radius := f_shape.radius * frog.global_scale.x
		var f_pos := frog.collision_shape.global_position

		var collision_shape = static_body.get_child(0) as CollisionShape2D
		var shape := collision_shape.shape as CircleShape2D
		var radius := shape.radius * global_scale.x
		var p: Vector2 = collision_shape.global_position
		
		if (p - f_pos).length() < f_radius + radius:
			movable = false	
			break

	if movable:
		pos += vel
	visible = new_visible
	position = pos * get_parent().size

"""
func _process(_delta: float) -> void:
	visible = new_visible
	position = pos * get_parent().size
"""
