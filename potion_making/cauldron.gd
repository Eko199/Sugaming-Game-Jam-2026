extends Control

@onready var water: TextureRect = $Water
@onready var dial: TextureRect = $Dial

var current_items: Array[Ingredient.TYPE] = []
var current_temp: float = 50.0
var current_stirring: Cons.STIR_PATTERN

func _ready() -> void:
	Event.potion_served.connect(_potion_served)
	Event.cauldron_emptied.connect(_potion_served)
	water.self_modulate = Cons.WATER_COLOR
	_potion_served()
	update_dial()

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Node and data.is_in_group("ingredient") \
		and current_items.size() < Cons.MAX_INGREDIENTS

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	added_item(data.type)
	Event.ingredient_added.emit(data.type)

func added_item(ing: Ingredient.TYPE) -> void:
	if current_items.size() >= Cons.MAX_INGREDIENTS: return
	current_items.append(ing)
	_update_water_color()

func get_water_sort_y() -> float:
	if not is_instance_valid(water):
		return global_position.y
	# Water oval center in water.png is at local Y ~274 out of 612
	var water_center_ratio: float = 274.0 / 612.0
	return water.global_position.y + water.size.y * water_center_ratio

func get_water_z_index() -> int:
	return water.z_index if is_instance_valid(water) else 1

func _potion_served(_pot = null) -> void:
	current_items.clear()
	_update_water_color()

func _update_water_color() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(water, "self_modulate", Utility.mix_colors(current_items), Cons.WATER_TINT_TIME)

func brew() -> void:
	var result: Dictionary = Recipe.evaluate(current_items.duplicate(), roundi(current_temp), current_stirring)
	Event.potion_served.emit(result)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action('temp_down'):
		current_temp = clamp(current_temp - Cons.TEMP_DIAL_CHANGE, 0, 100)
		update_dial()
	elif event.is_action('temp_up'):
		current_temp = clamp(current_temp + Cons.TEMP_DIAL_CHANGE, 0, 100)
		update_dial()

func update_dial() -> void:
	dial.rotation = PI * (current_temp / 100) - PI / 2

# TODO: Temporary just for testing
#region temporary

func _on_stir_left_button_up() -> void:
	if current_items.is_empty(): return
	current_stirring = Cons.STIR_PATTERN.CLOCKWISE
	brew()

func _on_stir_right_button_up() -> void:
	if current_items.is_empty(): return
	current_stirring = Cons.STIR_PATTERN.COUNTERCLOCKWISE
	brew()

#endregion

func _on_dial_left_button_up() -> void:
	current_temp = clamp(current_temp - Cons.TEMP_DIAL_CHANGE, 0, 100)
	update_dial()

func _on_dial_right_button_up() -> void:
	current_temp = clamp(current_temp + Cons.TEMP_DIAL_CHANGE, 0, 100)
	update_dial()
