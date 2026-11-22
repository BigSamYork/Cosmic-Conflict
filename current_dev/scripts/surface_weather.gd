class_name SurfaceWeather
extends MultiMeshInstance3D

const SKY_FX := preload("res://shaders/surface_weather.gdshader")
# Tint, near-plane particle size, fall rate, lateral wind, streak length.
const CLIMATES := {
	"ignis": [Color("#f1934f"), 0.054, -1.4, 1.1, 1.05],
	"cryo": [Color("#d1f2fc"), 0.073, 2.6, 1.7, 1.25],
	"vespera": [Color("#7e97cc"), 0.039, 13.0, 1.2, 6.4],
	"xylo": [Color("#b9db72"), 0.087, -0.58, 0.62, 1.0],
	"thalassa": [Color("#92c9d9"), 0.061, 8.1, 4.1, 4.7],
	"kharon": [Color("#dfb983"), 0.049, 1.4, 5.3, 2.45]
}
var weather_material := ShaderMaterial.new()
var age := 0.0
var climate := ""
var active := false
var sky_material: ShaderMaterial
var sky_frame := -1

func _ready() -> void:
	var environment := get_world_3d().environment
	if environment != null and environment.sky != null and environment.sky.sky_material is ShaderMaterial:
		sky_material = environment.sky.sky_material
		sky_material.set_shader_parameter("cloud_atlas", preload("res://assets/ground/sector_sky.png"))
	var flake := QuadMesh.new()
	flake.size = Vector2.ONE
	var field := MultiMesh.new()
	field.transform_format = MultiMesh.TRANSFORM_3D
	field.use_custom_data = true
	field.mesh = flake
	field.instance_count = 116
	field.custom_aabb = AABB(Vector3(-47, -26, -74), Vector3(94, 52, 74))
	var random := RandomNumberGenerator.new()
	random.seed = 473991
	for i in field.instance_count:
		field.set_instance_transform(i, Transform3D.IDENTITY)
		field.set_instance_custom_data(i, Color(random.randf(), random.randf(), random.randf(), random.randf()))
	multimesh = field
	weather_material.shader = SKY_FX
	material_override = weather_material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visible = active
	if not climate.is_empty():
		_set_parameters()

func configure(sector: String, ground: bool, reduced: bool) -> void:
	active = ground and not reduced
	visible = active
	if sector != climate:
		climate = sector
		age = 0.0
		sky_frame = -1
		if is_node_ready():
			_set_parameters()

func _set_parameters() -> void:
	var values: Array = CLIMATES.get(climate, CLIMATES["ignis"])
	weather_material.set_shader_parameter("tint", values[0])
	weather_material.set_shader_parameter("conditions", Vector4(values[1], values[2], values[3], values[4]))
	weather_material.set_shader_parameter("flight_time", age)

func advance(delta: float) -> void:
	if not active or not is_inside_tree():
		return
	age += delta
	weather_material.set_shader_parameter("flight_time", age)
	# Cloud drift moves less than a texel per update. Avoid regenerating the
	# sky's radiance map at the particle simulation rate.
	var frame := floori(age * 4.0)
	if sky_material != null and frame != sky_frame:
		sky_frame = frame
		sky_material.set_shader_parameter("surface_time", age)
