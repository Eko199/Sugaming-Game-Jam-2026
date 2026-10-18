extends TextureRect
class_name Ingredient

enum TYPE {
	GNOME_HAIR, FIRE_WORM, FROSTY_MINT,
	UNICORN_TEARS, EXPANDING_BEANS, STAR_FLOWER,
}

@export var type: TYPE:
	set(value): 
		type = value
		reload()
@onready var outline: TextureRect = $Outline
@onready var particles: GPUParticles2D = $GPUParticles2D
@onready var label: CurvedLabel = $TextureRect/Label

var saved_texture: Texture2D
var is_currently_used: bool = false
var is_dragging: bool = false
const drag_preview = preload("res://potion_making/drag_preview.gd")
const PARTICLE_MATERIALS: Array[ParticleProcessMaterial] = [
	preload("res://particles/gnome_hair.tres"),
	preload("res://particles/fire_worm.tres"),
	preload("res://particles/frosty_mint.tres"),
	preload("res://particles/unicorn_tears.tres"),
	preload("res://particles/expanding_beans.tres"),
	preload("res://particles/star_flower.tres"),
]

func _ready() -> void:
	reload()
	Event.potion_served.connect(_return_to_shelf)
	Event.cauldron_emptied.connect(_return_to_shelf)

func reload() -> void:
	texture = load(Cons.INGRIDIENT_TEXTURE[type])
	if outline != null: outline.texture = texture
	saved_texture = texture
	if label != null: label.text = Utility.get_keyname(type, TYPE) # CurvedLabel bends + fits it to the tag
	if particles != null:
		particles.process_material = PARTICLE_MATERIALS[type]
		particles.show()

func _return_to_shelf(_result = null) -> void:
	if is_dragging: return
	texture = saved_texture
	is_currently_used = false
	particles.show()

func _get_drag_data(_at_position: Vector2) -> Variant:
	if is_currently_used: return null
	var item: TextureRect = duplicate()
	var item_holder: Control = drag_preview.new()
	item_holder.add_child(item)
	var held_particles: GPUParticles2D = item.get_node("GPUParticles2D")
	held_particles.local_coords = true # travel with the mouse instead of trailing behind
	item.get_node("TextureRect").hide() # the name tag stays on the shelf

	item.position = -0.5 * size
	item.rotation = randf_range(-0.1, 0.1) * PI
	set_drag_preview(item_holder)
	texture = null
	particles.hide()
	is_currently_used = true
	is_dragging = true
	outline.hide()
	Audio.play("ingredient_pick", 0.05)
	return self

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and is_dragging:
		is_dragging = false
		if not is_drag_successful():
			_return_to_shelf()
			Audio.play("ingredient_drop_fail", 0.05)

func _on_mouse_entered() -> void:
	if is_dragging or is_currently_used: return
	outline.show()

func _on_mouse_exited() -> void:
	outline.hide()
