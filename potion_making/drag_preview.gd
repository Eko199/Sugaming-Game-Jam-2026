extends Control
class_name IngredientDragPreview

var cauldron: Control
var water: TextureRect

func _ready() -> void:
	_find_cauldron()

func _find_cauldron() -> void:
	cauldron = get_tree().get_first_node_in_group("cauldron")
	if cauldron and cauldron.has_node("Water"):
		water = cauldron.get_node("Water")

func _process(_delta: float) -> void:
	if not is_instance_valid(cauldron):
		_find_cauldron()

	var current_y: float = get_global_mouse_position().y
	var water_y: float = 744.0
	var water_z: int = 1

	if is_instance_valid(cauldron) and cauldron.has_method("get_water_sort_y"):
		water_y = cauldron.get_water_sort_y()
		if cauldron.has_method("get_water_z_index"):
			water_z = cauldron.get_water_z_index()
	elif is_instance_valid(water):
		water_y = water.global_position.y + water.size.y * (274.0 / 612.0)
		water_z = water.z_index

	# Y-sort with the water:
	# If lower on screen (greater Y / from underneath / in front of water center): render over water
	# If higher on screen (smaller Y / from above / behind water center): render under water
	if current_y > water_y:
		z_index = water_z + 1
	else:
		z_index = max(0, water_z - 1)
