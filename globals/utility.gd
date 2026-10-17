extends Node

class DragPreview extends Control:
	var cauldron: Control
	var water: TextureRect

	func _ready() -> void:
		cauldron = get_tree().get_first_node_in_group("cauldron")
		if cauldron and cauldron.has_node("Water"):
			water = cauldron.get_node("Water")

	func _process(_delta: float) -> void:
		var current_y: float = get_global_mouse_position().y
		var water_y: float = 744.0
		var water_z: int = 1

		if is_instance_valid(cauldron) and cauldron.has_method("get_water_sort_y"):
			water_y = cauldron.get_water_sort_y()
			if cauldron.has_method("get_water_z_index"):
				water_z = cauldron.get_water_z_index()
		elif is_instance_valid(water):
			water_y = water.global_position.y + water.size.y * (274.0 / 612.0)
			water_z = water.z_index

		if current_y > water_y:
			z_index = water_z + 1
		else:
			z_index = max(0, water_z - 1)

## Returns the current main scene
var scene: MainScene:
	get: return get_tree().current_scene if is_inside_tree() else null

## Give an enum and key to get the name of the key
func get_keyname(key: int, enu: Dictionary) -> String:
	return (enu.find_key(key) as String).replace('_', ' ').capitalize()

## Mixes colors
func mix_colors(ings: Array[Ingredient.TYPE]) -> Color:
	if ings.is_empty(): return Cons.WATER_COLOR
	var sum: Color = Color(0, 0, 0)
	var avg_sat: float = 0.0
	var avg_val: float = 0.0
	for ing in ings:
		var col: Color = Cons.INGREDIENT_COLOR[ing]
		sum += col.srgb_to_linear()
		avg_sat += col.s
		avg_val += col.v
	var n: float = ings.size()
	var mixed: Color = (sum / n).linear_to_srgb()
	mixed.a = 1.0
	mixed = Color.from_hsv(mixed.h, lerpf(mixed.s, avg_sat / n, 0.6), lerpf(mixed.v, avg_val / n, 0.5))
	var strength: float = Cons.WATER_TINT_STRENGTH[mini(ings.size(), Cons.WATER_TINT_STRENGTH.size() - 1)]
	return Cons.WATER_COLOR.lerp(mixed, strength)

func floating_text(parent: Node, text: String, pos: Vector2, color: Color = Color.WHITE, font_size: int = 40, rise: float = 50.0, duration: float = 1.2) -> Label:
	var popup: Label = Label.new()
	var settings: LabelSettings = LabelSettings.new()
	settings.font_size = font_size
	settings.font_color = color
	settings.outline_size = 8
	settings.outline_color = Color.BLACK
	popup.label_settings = settings
	popup.text = text
	popup.position = pos
	popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(popup)
	var tween: Tween = popup.create_tween().set_parallel()
	tween.tween_property(popup, "position:y", pos.y - rise, duration)
	tween.tween_property(popup, "modulate:a", 0.0, duration).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(popup.queue_free)
	return popup
