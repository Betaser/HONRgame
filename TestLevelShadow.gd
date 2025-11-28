extends TextureRect

@onready var test_level: TestLevel = $"../TestLevel"
var mat: ShaderMaterial = null

func _ready() -> void:
	mat = material as ShaderMaterial
		
func _process(_delta: float) -> void:
	mat.set_shader_parameter("handrawn_dim", test_level.handrawn_dim)
	mat.set_shader_parameter("handrawn_offset", test_level.handrawn_offset)
	mat.set_shader_parameter("handrawn_water", test_level.handrawn_water_highlight)
