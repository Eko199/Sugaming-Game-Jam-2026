extends TextureRect
class_name Ingredient

enum TYPE {
	GNOME_HAIR, FIRE_WORM, FROSTY_MINT,
	UNICORN_TEARS, EXPANDING_BEANS, STAR_FLOWER,
}

@export var type: TYPE

var saved_texture: Texture2D
var is_currently_used: bool = false
var is_dragging: bool = false

func _ready() -> void:
	texture = load(Cons.INGRIDIENT_TEXTURE[type])
	saved_texture = texture
	Event.potion_served.connect(_return_to_shelf)
	Event.cauldron_emptied.connect(_return_to_shelf)

func _return_to_shelf(_result = null) -> void:
	# A held item resolves itself on drag end (dropped or returned), resetting it now would duplicate it
	if is_dragging: return
	texture = saved_texture
	is_currently_used = false

func _get_drag_data(_at_position: Vector2) -> Variant:
	if is_currently_used: return null
	var item: TextureRect = duplicate()
	var item_holder: Control = Control.new()
	item_holder.add_child(item)

	item.position = -0.5 * size
	set_drag_preview(item_holder)
	texture = null
	is_currently_used = true
	is_dragging = true
	return self

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and is_dragging:
		is_dragging = false
		if not is_drag_successful():
			_return_to_shelf()
