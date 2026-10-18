extends Control
class_name CauldronHitbox

@onready var cauldron: Cauldron = owner

var accumulated: float = 0.0
var last_angle: float = NAN

func _process(_delta: float) -> void:
	var viewport: Viewport = get_viewport()
	if not (viewport.gui_is_dragging() and viewport.gui_get_drag_data() is Spoon):
		return
	var radius: Vector2 = size * 0.5
	if radius.x <= 0 or radius.y <= 0:
		_reset_stir()
		return
	
	var mouse_pos: Vector2 = (get_local_mouse_position() - radius) / radius
	var dist: float = mouse_pos.length()
	if dist < Cons.STIR_DEAD_ZONE or dist > Cons.STIR_OUTER_LIMIT:
		last_angle = NAN
		return
	var angle: float = mouse_pos.angle()
	if not is_nan(last_angle):
		var step: float = angle_difference(last_angle, angle)
		if absf(step) <= Cons.STIR_MAX_STEP:
			accumulated += step
			if absf(step) > 0.01: Audio.keep_stirring()
	last_angle = angle
	if absf(accumulated) < TAU * Cons.STIR_AMOUNTS[cauldron.current_items.size() - 1]: return
	
	var stir_dir: Cons.STIR_PATTERN = \
		Cons.STIR_PATTERN.CLOCKWISE if accumulated > 0 else Cons.STIR_PATTERN.COUNTERCLOCKWISE
	accumulated = 0
	#print(Utility.get_keyname(stir_dir, Cons.STIR_PATTERN))
	Event.stirred.emit(stir_dir)

func _reset_stir() -> void:
	accumulated = 0
	last_angle = NAN

func _has_point(point: Vector2) -> bool:
	var radius: Vector2 = size * 0.5
	if radius.x <= 0.0 or radius.y <= 0.0: return false
	return ((point - radius) / radius).length_squared() <= 1.0

func is_over(global_pos: Vector2) -> bool:
	return _has_point(get_global_transform().affine_inverse() * global_pos)

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Ingredient and cauldron.can_accept()

func _drop_data(at_position: Vector2, data: Variant) -> void:
	var drop_pos: Vector2 = get_global_transform() * at_position
	_sink(data.saved_texture, data.size, drop_pos)
	cauldron.splash(drop_pos)
	cauldron.add_ingredient(data.type)

func _sink(tex: Texture2D, item_size: Vector2, global_pos: Vector2) -> void:
	var item: TextureRect = TextureRect.new()
	item.texture = tex
	item.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.size = item_size
	item.pivot_offset = item_size * 0.5
	item.rotation = randf_range(-0.1, 0.1) * PI
	item.z_index = Cons.Z_IN_CAULDRON
	cauldron.add_child(item)
	item.global_position = global_pos - item_size * 0.5
	var tween: Tween = item.create_tween().set_parallel()
	tween.tween_property(item, "position:y", item.position.y + Cons.SINK_DEPTH, Cons.SINK_TIME) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(item, "scale", Vector2.ONE * 0.6, Cons.SINK_TIME)
	tween.tween_property(item, "modulate:a", 0.0, Cons.SINK_TIME).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(item.queue_free)
