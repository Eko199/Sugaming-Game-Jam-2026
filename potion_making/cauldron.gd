extends Control

@onready var water_mask: TextureRect = $Control/WaterMask
@onready var water: TextureRect = %Water
@onready var front: TextureRect = $Control/Cauldron
@onready var dial: TextureRect = $Control/Dial

var current_items: Array[Ingredient.TYPE] = []
var current_temp: float = 50.0
var current_stirring: Cons.STIR_PATTERN

func _ready() -> void:
	Event.potion_served.connect(_potion_served)
	Event.cauldron_emptied.connect(_potion_served)
	water_mask.z_index = Cons.Z_WATER
	front.z_index = Cons.Z_CAULDRON_FRONT
	dial.z_index = Cons.Z_CAULDRON_FRONT
	water.self_modulate = Cons.WATER_COLOR
	_potion_served()
	update_dial()

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Node and data.is_in_group("ingredient") \
		and current_items.size() < Cons.MAX_INGREDIENTS

func _drop_data(at_position: Vector2, data: Variant) -> void:
	_sink(data.saved_texture, data.size, at_position)
	added_item(data.type)
	Event.ingredient_added.emit(data.type)

func added_item(ing: Ingredient.TYPE) -> void:
	if current_items.size() >= Cons.MAX_INGREDIENTS: return
	current_items.append(ing)
	_update_water_color()

func get_water_sort_y() -> float:
	if not is_instance_valid(water):
		return global_position.y
	var water_center_ratio: float = 274.0 / 612.0
	return water.global_position.y + water.size.y * water_center_ratio

func _sink(tex: Texture2D, item_size: Vector2, at_position: Vector2) -> void:
	var item: TextureRect = TextureRect.new()
	item.texture = tex
	item.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.size = item_size
	item.pivot_offset = item_size * 0.5
	item.position = at_position - item_size * 0.5
	item.rotation = randf_range(-0.1, 0.1) * PI
	item.z_index = Cons.Z_IN_CAULDRON
	add_child(item)
	var tween: Tween = item.create_tween().set_parallel()
	tween.tween_property(item, "position:y", item.position.y + Cons.SINK_DEPTH, Cons.SINK_TIME) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(item, "scale", Vector2.ONE * 0.6, Cons.SINK_TIME)
	tween.tween_property(item, "modulate:a", 0.0, Cons.SINK_TIME).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(item.queue_free)

func get_water_ellipse() -> Dictionary:
	if not is_instance_valid(water):
		return {}
	return {
		"center": water.global_position + Vector2(water.size.x * (440.0 / 896.0), water.size.y * (274.0 / 612.0)),
		"radius": Vector2(water.size.x * (314.0 / 896.0), water.size.y * (119.0 / 612.0)),
	}

func is_over_cauldron_opening(pos: Vector2, margin: float = 1.1) -> bool:
	var ellipse: Dictionary = get_water_ellipse()
	if ellipse.is_empty():
		return false
	var center: Vector2 = ellipse["center"]
	var radius: Vector2 = ellipse["radius"] * margin
	if radius.x <= 0.0 or radius.y <= 0.0:
		return false
	var dx: float = (pos.x - center.x) / radius.x
	var dy: float = (pos.y - center.y) / radius.y
	return (dx * dx + dy * dy) <= 1.0

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
