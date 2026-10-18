extends TextureRect
class_name Spoon

@onready var outline: TextureRect = $Outline
@onready var upgrade: Button = $"../Spoon Upgrade"
@onready var upgrade_outline: TextureRect = $"../Spoon Upgrade/Outline"
@onready var price_tag: TextureRect = $"../Spoon Upgrade/Price"

const drag_preview = preload("res://potion_making/drag_preview.gd")

var is_dragging: bool = false
var has_ingredients: bool = false
var level: int = 1

func _ready() -> void:
	outline.texture = texture
	Event.ingredient_added.connect(_on_ingredient_added)
	Event.potion_served.connect(_on_cauldron_cleared)
	Event.cauldron_emptied.connect(_on_cauldron_cleared)
	Event.money_changed.connect(_update_spoon_upgrade)
	
	#Unfade upgrade button while disabled
	upgrade.add_theme_stylebox_override("disabled", upgrade.get_theme_stylebox("normal"))
	upgrade.add_theme_color_override("icon_disabled_color", upgrade.get_theme_color("icon_normal_color"))
	upgrade.add_theme_color_override("font_disabled_color", upgrade.get_theme_color("font_color"))
	
	_update_spoon_upgrade()
	_update_spoon_sprite()
	_update_cursor()

func _on_ingredient_added(_ing = null) -> void:
	has_ingredients = true
	_update_cursor()

func _on_cauldron_cleared(_result = null) -> void:
	has_ingredients = false
	_update_cursor()
	if is_dragging:
		get_viewport().gui_cancel_drag()
	else:
		_return_to_shelf()

func _update_cursor() -> void:
	mouse_default_cursor_shape = CURSOR_POINTING_HAND if has_ingredients else CURSOR_FORBIDDEN
	
func _update_spoon_upgrade(_money = null) -> void:
	if level > len(Cons.SPOON_UPGRADES_PRICE):
		return
	var price: int = Cons.SPOON_UPGRADES_PRICE[level - 1]
	upgrade.disabled = Utility.scene.money < price
	upgrade.mouse_default_cursor_shape = CURSOR_POINTING_HAND if not upgrade.disabled else CURSOR_FORBIDDEN

func _update_spoon_sprite() -> void:
	texture = load(Cons.SPOONS_TEXTURE[level - 1])
	
	if level < len(Cons.SPOONS_TEXTURE):
		price_tag.texture = load(Cons.PRICE_TAGS[level - 1])
		upgrade.icon = load(Cons.SPOONS_TEXTURE[level])
		upgrade_outline.texture = upgrade.icon

func _get_drag_data(_at_position: Vector2) -> Variant:
	if not has_ingredients: return null
	var item: TextureRect = duplicate()
	item.set_script(null)
	var item_holder: Control = drag_preview.new()
	item_holder.add_child(item)
	item.position = -0.5 * size
	item.rotation = PI
	set_drag_preview(item_holder)
	texture = null
	is_dragging = true
	outline.hide()
	Audio.play("spoon_pick", 0.05)
	return self

func _return_to_shelf(_result = null) -> void:
	if is_dragging: return
	texture = load(Cons.SPOONS_TEXTURE[level - 1])

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and is_dragging:
		is_dragging = false
		_return_to_shelf()

func _on_mouse_entered() -> void:
	if is_dragging or not has_ingredients: return
	outline.show()

func _on_mouse_exited() -> void:
	outline.hide()

func _on_spoon_upgrade_pressed() -> void:
	var price: int = Cons.SPOON_UPGRADES_PRICE[level - 1]
	if Utility.scene.money < price:
		return
	
	level += 1
	Utility.scene.money -= price
	Event.money_changed.emit(Utility.scene.money)

	if level > len(Cons.SPOON_UPGRADES_PRICE):
		upgrade.visible = false

	_update_spoon_sprite()
	if Utility.scene.money < price:
		upgrade_outline.hide()


func _on_spoon_upgrade_mouse_entered() -> void:
	if upgrade.disabled: return
	upgrade_outline.show()

func _on_spoon_upgrade_mouse_exited() -> void:
	upgrade_outline.hide()
