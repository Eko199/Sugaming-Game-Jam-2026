extends Control
class_name IngredientDragPreview

var hitbox: CauldronHitbox

func _ready() -> void:
	_find_hitbox()

func _find_hitbox() -> void:
	hitbox = get_tree().get_first_node_in_group("cauldron") as CauldronHitbox

func _process(_delta: float) -> void:
	if not is_instance_valid(hitbox):
		_find_hitbox()
		if not is_instance_valid(hitbox): return
	var in_cauldron: bool = hitbox.is_over(get_global_mouse_position())
	z_index = hitbox.cauldron.z_index + (Cons.Z_IN_CAULDRON if in_cauldron else Cons.Z_HELD)
