extends Control
class_name IngredientDragPreview

var cauldron: Control

func _ready() -> void:
	_find_cauldron()

func _find_cauldron() -> void:
	cauldron = get_tree().get_first_node_in_group("cauldron")

func _process(_delta: float) -> void:
	if not is_instance_valid(cauldron):
		_find_cauldron()
		if not is_instance_valid(cauldron): return
	var in_cauldron: bool = cauldron.is_over_cauldron_opening(get_global_mouse_position())
	z_index = cauldron.z_index + (Cons.Z_IN_CAULDRON if in_cauldron else Cons.Z_HELD)
