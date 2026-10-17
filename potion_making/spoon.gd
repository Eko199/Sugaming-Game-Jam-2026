extends TextureRect

const drag_preview = preload("res://potion_making/drag_preview.gd")

var saved_texture: Texture2D
var is_dragging: bool = false

func _ready() -> void:
	saved_texture = texture

func _get_drag_data(_at_position: Vector2) -> Variant:
	var item: TextureRect = duplicate()
	var item_holder: Control = drag_preview.new()
	item_holder.add_child(item)
	item.position = -0.5 * size
	set_drag_preview(item_holder)
	texture = null
	is_dragging = true
	return self

func _return_to_shelf(_result = null) -> void:
	if is_dragging: return
	texture = saved_texture

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and is_dragging:
		is_dragging = false
		if not is_drag_successful():
			_return_to_shelf()
