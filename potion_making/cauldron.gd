extends Control

@onready var ingredient_textures: Array[TextureRect] = [
	$Ingredient1, $Ingredient2, $Ingredient3
]
var current_items: Array[Ingredient.TYPE] = []

func _ready() -> void:
	Event.potion_served.connect(_potion_served)
	_potion_served()

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Node and data.is_in_group("ingredient")

func _drop_data(at_position: Vector2, data: Variant) -> void:
	print(Utility.get_keyname(data.type, Ingredient.TYPE))
	Event.ingredient_added.emit(data.type)
	added_item(data.type, at_position - 0.5 * data.size)

func added_item(ing: Ingredient.TYPE, pos: Vector2) -> void:
	if current_items.size() >= Constant.MAX_INGREDIENTS: return
	current_items.append(ing)
	var idx: int = current_items.size() - 1
	ingredient_textures[idx].texture = load(Constant.INGRIDIENT_TEXTURE[ing])
	ingredient_textures[idx].position = pos
	ingredient_textures[idx].show()
	
func _potion_served(_pot = null) -> void:
	for t: TextureRect in ingredient_textures:
		t.hide()
