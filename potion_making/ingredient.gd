extends TextureRect

var saved_texture: Texture2D
@onready var area: Area2D = get_parent() as Area2D

func _ready() -> void:
	saved_texture = texture

func _get_drag_data(_at_position: Vector2) -> Variant:
	var item: TextureRect = duplicate()
	var item_holder := Control.new()
	item_holder.add_child(item)

	item.position = -0.5 * size
	set_drag_preview(item_holder)
	texture = null
	return self
	
func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		if not is_drag_successful():
			texture = saved_texture
