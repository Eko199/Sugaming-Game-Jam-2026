extends CanvasLayer
class_name ColorBlindFilter

const SHADER: Shader = preload("res://shaders/color_blindness.gdshader")

var material_: ShaderMaterial = ShaderMaterial.new()
var tween: Tween

func _ready() -> void:
	layer = 100
	material_.shader = SHADER
	material_.set_shader_parameter("intensity", 0.0)
	var rect: ColorRect = ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.material = material_
	add_child(rect)

func fade_to(target: float, duration: float) -> void:
	if tween: tween.kill()
	tween = create_tween()
	tween.tween_property(material_, "shader_parameter/intensity", target, duration)

func fade_in(duration: float = 2.0) -> void:
	fade_to(1.0, duration)

func fade_out(duration: float = 2.0) -> void:
	fade_to(0.0, duration)
