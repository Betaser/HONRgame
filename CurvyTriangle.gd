extends TextureRect

func angle(v: Vector2) -> float:
	var ang = atan2(-v.y, v.x)
	if ang < 0:
		return ang + 2 * PI
	return ang

var mat: ShaderMaterial = null
var time := 0.0

func _ready() -> void:
	mat = material as ShaderMaterial
	
func _process(_delta: float) -> void:
	time += _delta
	mat.set_shader_parameter("t", time)
