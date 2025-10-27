extends TextureRect
class_name Blur

var mat: ShaderMaterial = null
var blurred_shadow: Texture2D = null

func _ready() -> void:
	mat = material as ShaderMaterial
	
func _process(_delta: float) -> void:
	blurred_shadow = mat.get_shader_parameter("blurred_shadow")
	# print(blurred_shadow)
