extends TextureRect
class_name Ingredient

enum TYPE {
	FIRE_WORM, FROSTY_MINT, UNICORN_TEARS,
	EXPANDING_BEANS, STAR_FLOWER, GNOME_HAIR,
}

@export var type: TYPE

var saved_texture: Texture2D
var is_currently_used: bool = false

func _ready() -> void:
	texture = load(Cons.INGRIDIENT_TEXTURE[type])
	saved_texture = texture

func _get_drag_data(_at_position: Vector2) -> Variant:
	if is_currently_used: return null
	var item: TextureRect = duplicate()
	var item_holder: Control = Control.new()
	item_holder.add_child(item)

	item.position = -0.5 * size
	set_drag_preview(item_holder)
	texture = null
	is_currently_used = true
	return self
	
func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		if not is_drag_successful():
			texture = saved_texture
