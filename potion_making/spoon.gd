extends TextureRect
class_name Spoon

@onready var outline: TextureRect = $Outline

const drag_preview = preload("res://potion_making/drag_preview.gd")

var saved_texture: Texture2D
var is_dragging: bool = false
var has_ingredients: bool = false

func _ready() -> void:
	saved_texture = texture
	outline.texture = texture
	Event.ingredient_added.connect(_on_ingredient_added)
	Event.potion_served.connect(_on_cauldron_cleared)
	Event.cauldron_emptied.connect(_on_cauldron_cleared)
	_update_cursor()

func _on_ingredient_added(_ing = null) -> void:
	has_ingredients = true
	_update_cursor()

func _on_cauldron_cleared(_result = null) -> void:
	has_ingredients = false
	_update_cursor()

func _update_cursor() -> void:
	mouse_default_cursor_shape = CURSOR_POINTING_HAND if has_ingredients else CURSOR_FORBIDDEN

func _get_drag_data(_at_position: Vector2) -> Variant:
	if not has_ingredients: return null
	var item: TextureRect = duplicate()
	var item_holder: Control = drag_preview.new()
	item_holder.add_child(item)
	item.position = -0.5 * size
	item.rotation = PI
	set_drag_preview(item_holder)
	texture = null
	is_dragging = true
	outline.hide()
	return self

func _return_to_shelf(_result = null) -> void:
	if is_dragging: return
	texture = saved_texture

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and is_dragging:
		is_dragging = false
		if not is_drag_successful():
			_return_to_shelf()

func _on_mouse_entered() -> void:
	if is_dragging or not has_ingredients: return
	outline.show()

func _on_mouse_exited() -> void:
	outline.hide()
