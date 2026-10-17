extends Control
class_name Cauldron

@onready var water_mask: TextureRect = $WaterMask
@onready var water: TextureRect = %Water
@onready var front: TextureRect = $Front
@onready var dial: TextureRect = $Dial

var current_items: Array[Ingredient.TYPE] = []
var current_temp: float = 50.0
var current_stirring: Cons.STIR_PATTERN = Cons.STIR_PATTERN.NONE

func _ready() -> void:
	Event.potion_served.connect(_potion_served)
	Event.cauldron_emptied.connect(_potion_served)
	Event.stirred.connect(_stirred)
	water_mask.z_index = Cons.Z_WATER
	front.z_index = Cons.Z_CAULDRON_FRONT
	dial.z_index = Cons.Z_CAULDRON_FRONT
	water.self_modulate = Cons.WATER_COLOR
	_potion_served()
	update_dial()

func can_accept() -> bool:
	return current_items.size() < Cons.MAX_INGREDIENTS

func add_ingredient(ing: Ingredient.TYPE) -> void:
	if not can_accept(): return
	current_items.append(ing)
	_update_water_color()
	Event.ingredient_added.emit(ing)

func _potion_served(_pot = null) -> void:
	current_items.clear()
	_update_water_color()
	current_stirring = Cons.STIR_PATTERN.NONE

func _stirred(pattern: Cons.STIR_PATTERN) -> void:
	current_stirring = pattern
	brew()

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
	if event.is_action('temp_up'):
		current_temp = clamp(current_temp + Cons.TEMP_DIAL_CHANGE, 0, 100)
		update_dial()

func update_dial() -> void:
	dial.rotation = PI * (current_temp / 100) - PI / 2

func _on_dial_left_button_up() -> void:
	current_temp = clamp(current_temp - Cons.TEMP_DIAL_CHANGE, 0, 100)
	update_dial()

func _on_dial_right_button_up() -> void:
	current_temp = clamp(current_temp + Cons.TEMP_DIAL_CHANGE, 0, 100)
	update_dial()
