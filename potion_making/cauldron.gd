extends Control

@onready var ingredient_textures: Array[TextureRect] = [
	$Ingredient1, $Ingredient2, $Ingredient3
]
var current_items: Array[Ingredient.TYPE] = []
var current_temp: float = 50.0
var current_stirring: Cons.STIR_PATTERN

func _ready() -> void:
	Event.potion_served.connect(_potion_served)
	Event.cauldron_emptied.connect(_potion_served)
	_potion_served()

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Node and data.is_in_group("ingredient") \
		and current_items.size() < Cons.MAX_INGREDIENTS

func _drop_data(at_position: Vector2, data: Variant) -> void:
	added_item(data.type, at_position - 0.5 * data.size)
	Event.ingredient_added.emit(data.type)

func added_item(ing: Ingredient.TYPE, pos: Vector2) -> void:
	if current_items.size() >= Cons.MAX_INGREDIENTS: return
	current_items.append(ing)
	var idx: int = current_items.size() - 1
	ingredient_textures[idx].texture = load(Cons.INGRIDIENT_TEXTURE[ing])
	ingredient_textures[idx].position = pos
	ingredient_textures[idx].show()
	
func _potion_served(_pot = null) -> void:
	current_items.clear()
	for t: TextureRect in ingredient_textures:
		t.hide()

func brew() -> void:
	var result: Dictionary = Recipe.evaluate(current_items.duplicate(), roundi(current_temp), current_stirring)
	print(result)
	# Clears the cauldron and returns the ingredients to the shelf
	Event.potion_served.emit(result)

# TODO: Temporary just for testing
#region temporary

func _temperature_value_changed(value: float) -> void:
	current_temp = value

func _on_stir_left_button_up() -> void:
	if current_items.is_empty(): return
	current_stirring = Cons.STIR_PATTERN.LEFT
	brew()

func _on_stir_zig_zag_button_up() -> void:
	if current_items.is_empty(): return
	current_stirring = Cons.STIR_PATTERN.ZIG_ZAG
	brew()

func _on_stir_right_button_up() -> void:
	if current_items.is_empty(): return
	current_stirring = Cons.STIR_PATTERN.RIGHT
	brew()

#endregion
