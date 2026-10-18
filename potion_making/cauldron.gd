extends Control
class_name Cauldron

@onready var water_mask: TextureRect = $WaterMask
@onready var water: TextureRect = %Water
@onready var front: TextureRect = $Front
@onready var dial: TextureRect = $Dial

var current_items: Array[Ingredient.TYPE] = []
var current_temp: float = 50.0
var current_stirring: Cons.STIR_PATTERN = Cons.STIR_PATTERN.NONE
var water_color: Color = Cons.WATER_COLOR
var refill_tween: Tween
var _ready_done: bool = false
var customer_present: bool = false
var ripples: PackedVector4Array = PackedVector4Array()
var next_ripple: int = 0
var trails: PackedVector4Array = PackedVector4Array()
var trail_ages: PackedFloat32Array = PackedFloat32Array()
var next_trail: int = 0
var bubbles: PackedVector4Array = PackedVector4Array()
var bubble_ages: PackedFloat32Array = PackedFloat32Array()
var bubble_lives: PackedFloat32Array = PackedFloat32Array()
var next_bubble: int = 0
var _last_stir_pos: Vector2 = Vector2.INF
var _bubble_timer: float = 0.0

const MAX_RIPPLES: int = 8
const RIPPLE_LIFETIME: float = 1.5
const MAX_TRAILS: int = 24
const TRAIL_LIFETIME: float = 1.4
const MAX_BUBBLES: int = 16
const BUBBLE_MIN_SIZE: float = 0.018
const BUBBLE_MAX_SIZE: float = 0.04
const BUBBLE_INTERVAL_COLD: float = 1.0
const BUBBLE_INTERVAL_HOT: float = 0.05
const STIR_TRAIL_STEP: float = 28.0

func _ready() -> void:
	Event.potion_served.connect(_potion_served)
	Event.cauldron_emptied.connect(_potion_served)
	Event.stirred.connect(_stirred)
	Event.customer_arrived.connect(func(_c: Customer) -> void: customer_present = true)
	Event.customer_left.connect(func(_c: Customer, _served: bool) -> void: customer_present = false)
	water_mask.z_index = Cons.Z_WATER
	front.z_index = Cons.Z_CAULDRON_FRONT
	dial.z_index = Cons.Z_CAULDRON_FRONT
	_setup_water()
	_potion_served()
	_ready_done = true
	update_dial()
	Audio.start_cauldron()

func _setup_water() -> void:
	water.self_modulate = Color.WHITE
	for i: int in MAX_RIPPLES:
		ripples.append(Vector4(0.5, 0.5, -1.0, 0.0))
	for i: int in MAX_TRAILS:
		trails.append(Vector4.ZERO)
		trail_ages.append(-1.0)
	for i: int in MAX_BUBBLES:
		bubbles.append(Vector4(0.5, 0.5, -1.0, 0.0))
		bubble_ages.append(-1.0)
		bubble_lives.append(1.0)
	_set_water_color(Cons.WATER_COLOR)
	water.resized.connect(_update_water_aspect)
	_update_water_aspect()

func _update_water_aspect() -> void:
	if water.size.y > 0.0:
		water.material.set_shader_parameter("aspect", water.size.x / water.size.y)

func _set_water_color(color: Color) -> void:
	water_color = color
	water.material.set_shader_parameter("water_color", color)

func _process(delta: float) -> void:
	_stir_trail()
	_update_bubbles(delta)
	for i: int in ripples.size():
		var r: Vector4 = ripples[i]
		if r.z < 0.0: continue
		r.z += delta
		if r.z > RIPPLE_LIFETIME: r.z = -1.0
		ripples[i] = r
	for i: int in trail_ages.size():
		if trail_ages[i] < 0.0: continue
		trail_ages[i] += delta
		if trail_ages[i] > TRAIL_LIFETIME: trail_ages[i] = -1.0
	water.material.set_shader_parameter("ripples", ripples)
	water.material.set_shader_parameter("bubbles", bubbles)
	water.material.set_shader_parameter("trails", trails)
	water.material.set_shader_parameter("trail_ages", trail_ages)

func _update_bubbles(delta: float) -> void:
	for i: int in MAX_BUBBLES:
		if bubble_ages[i] < 0.0: continue
		bubble_ages[i] += delta
		var v: Vector4 = bubbles[i]
		v.z = bubble_ages[i] / bubble_lives[i]
		if v.z >= 1.0:
			v.z = -1.0
			bubble_ages[i] = -1.0
		bubbles[i] = v
	if current_items.is_empty():
		_bubble_timer = 0.0
		return
	var heat: float = current_temp / 100.0
	var interval: float = lerpf(BUBBLE_INTERVAL_COLD, BUBBLE_INTERVAL_HOT, heat * heat) / (1.0 + 0.5 * (current_items.size() - 1))
	_bubble_timer += delta
	if _bubble_timer < interval: return
	_bubble_timer = randf_range(0.0, interval * 0.3)
	_spawn_bubble(heat)

func _spawn_bubble(heat: float) -> void:
	var angle: float = randf() * TAU
	var radius: float = sqrt(randf()) * 0.78
	var pos: Vector2 = Vector2(0.5, 0.5) + Vector2(cos(angle), sin(angle)) * radius * 0.5
	bubble_ages[next_bubble] = 0.0
	bubble_lives[next_bubble] = lerpf(1.3, 0.7, heat) * randf_range(0.85, 1.15)
	bubbles[next_bubble] = Vector4(pos.x, pos.y, 0.0, randf_range(BUBBLE_MIN_SIZE, BUBBLE_MAX_SIZE))
	next_bubble = (next_bubble + 1) % MAX_BUBBLES

## While the spoon is dragged through the water, leave streaks along its path.
func _stir_trail() -> void:
	var mouse: Vector2 = get_global_mouse_position()
	if not _is_spoon_held() or not ($Hitbox as CauldronHitbox).is_over(mouse):
		_last_stir_pos = Vector2.INF
		return
	if _last_stir_pos == Vector2.INF:
		_last_stir_pos = mouse
		return
	if mouse.distance_to(_last_stir_pos) < STIR_TRAIL_STEP: return
	var inverse: Transform2D = water.get_global_transform().affine_inverse()
	var from: Vector2 = inverse * _last_stir_pos / water.size
	var to: Vector2 = inverse * mouse / water.size
	trails[next_trail] = Vector4(from.x, from.y, to.x, to.y)
	trail_ages[next_trail] = 0.0
	next_trail = (next_trail + 1) % MAX_TRAILS
	_last_stir_pos = mouse

func _add_ripple(global_pos: Vector2, strength: float) -> void:
	var local: Vector2 = water.get_global_transform().affine_inverse() * global_pos
	var uv: Vector2 = local / water.size
	ripples[next_ripple] = Vector4(uv.x, uv.y, 0.0, strength)
	next_ripple = (next_ripple + 1) % MAX_RIPPLES

func can_accept() -> bool:
	return customer_present and current_items.size() < Cons.MAX_INGREDIENTS

func add_ingredient(ing: Ingredient.TYPE) -> void:
	if not can_accept(): return
	current_items.append(ing)
	_update_water_color()
	Event.ingredient_added.emit(ing)

## Ripple on the water plus a burst of droplets where an ingredient lands.
func splash(global_pos: Vector2) -> void:
	_add_ripple(global_pos, 1.0)
	_spawn_droplets(global_pos)

func _spawn_droplets(global_pos: Vector2) -> void:
	var drops: CPUParticles2D = CPUParticles2D.new()
	drops.one_shot = true
	drops.emitting = false
	drops.explosiveness = 1.0
	drops.amount = 22
	drops.lifetime = 0.75
	drops.direction = Vector2.UP
	drops.spread = 40.0
	drops.initial_velocity_min = 140.0
	drops.initial_velocity_max = 280.0
	drops.gravity = Vector2(0, 700)
	drops.scale_amount_min = 2.0
	drops.scale_amount_max = 5.0
	var fade: Gradient = Gradient.new()
	var base: Color = water_color.lightened(0.35)
	fade.colors = PackedColorArray([base, Color(base, 0.0)])
	fade.offsets = PackedFloat32Array([0.55, 1.0])
	drops.color_ramp = fade
	drops.z_index = Cons.Z_HELD
	add_child(drops)
	drops.global_position = global_pos
	drops.emitting = true
	drops.finished.connect(drops.queue_free)

func _potion_served(_pot = null) -> void:
	current_items.clear()
	current_stirring = Cons.STIR_PATTERN.NONE
	if is_node_ready() and _ready_done:
		_refill_water()

func _refill_water() -> void:
	if refill_tween: refill_tween.kill()
	water.position.y = 0.0
	refill_tween = create_tween()
	refill_tween.tween_property(water, "position:y", water.size.y, Cons.WATER_DRAIN_TIME) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	refill_tween.tween_callback(func() -> void: _set_water_color(Cons.WATER_COLOR))
	refill_tween.tween_property(water, "position:y", 0.0, Cons.WATER_REFILL_TIME) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

func _stirred(pattern: Cons.STIR_PATTERN) -> void:
	if not customer_present: return
	current_stirring = pattern
	brew()

func _update_water_color() -> void:
	var tween: Tween = create_tween()
	tween.tween_method(_set_water_color, water_color, Utility.mix_colors(current_items), Cons.WATER_TINT_TIME)

func brew() -> void:
	var result: Dictionary = Recipe.evaluate(current_items.duplicate(), roundi(current_temp), current_stirring)
	result.success = result.success and Utility.scene.customer.wanted == result.recipe_id
	Event.potion_served.emit(result)

func _is_spoon_held() -> bool:
	var viewport: Viewport = get_viewport()
	return viewport.gui_is_dragging() and viewport.gui_get_drag_data() is Spoon

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action('temp_down'):
		_change_temp(-Cons.TEMP_DIAL_CHANGE)
	if event.is_action('temp_up'):
		_change_temp(Cons.TEMP_DIAL_CHANGE)

func _change_temp(amount: int) -> void:
	var new_temp: float = clamp(current_temp + amount, 0, 100)
	if new_temp == current_temp: return
	current_temp = new_temp
	update_dial()
	Audio.play("dial_click", 0.05)

func update_dial() -> void:
	dial.rotation = PI * (current_temp / 100) - PI / 2
	water.material.set_shader_parameter("heat", current_temp / 100)
	Audio.set_heat(current_temp / 100)

func _on_dial_left_button_up() -> void:
	if _is_spoon_held(): return
	_change_temp(-Cons.TEMP_DIAL_CHANGE)

func _on_dial_right_button_up() -> void:
	if _is_spoon_held(): return
	_change_temp(Cons.TEMP_DIAL_CHANGE)
