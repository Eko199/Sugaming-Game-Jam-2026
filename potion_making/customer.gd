extends TextureRect
class_name Customer

@export var wanted: Cons.RECIPE
@export var patience: float

@onready var timer: Timer = $Timer
@onready var request_label: Label = $RequestLabel
@onready var progress_bar: ProgressBar = $ProgressBar

const WALK_TIME: float = 0.7
const SPEECH_SHOW: float = 0.2

var rest_x: float
var rest_y: float
var active: bool = false
var walk_tween: Tween
var react_tween: Tween

func _ready() -> void:
	Event.potion_served.connect(_on_potion_served)
	rest_x = position.x
	rest_y = position.y
	hide()

func _offscreen_x() -> float:
	return get_viewport_rect().size.x - 600.0

func _walk_to(x: float, speech_to: float, delay: float = WALK_TIME) -> Tween:
	if walk_tween: walk_tween.kill()
	walk_tween = create_tween().set_trans(Tween.TRANS_SINE)
	walk_tween.tween_property(self, "position:x", x, WALK_TIME)
	walk_tween.parallel().tween_property(
		request_label, "modulate:a", speech_to, SPEECH_SHOW
	).from(abs(speech_to - 1.0)).set_delay(delay)
	return walk_tween

func arrive(recipe: Cons.RECIPE, patience_time: float) -> void:
	wanted = recipe
	patience = patience_time
	request_label.text = Utility.get_keyname(wanted, Cons.RECIPE)
	if Utility.speech_impairment_active:
		request_label.text = Utility.shuffle(request_label.text)
	progress_bar.max_value = patience
	progress_bar.value = patience
	active = true
	_reset_pose()
	position.x = _offscreen_x()
	show()
	Event.customer_arrived.emit(self)
	_walk_to(rest_x, 1.0).set_ease(Tween.EASE_OUT).finished.connect(func() -> void:
		if active: timer.start(patience))

func wants(ing: Ingredient.TYPE, count: int) -> bool:
	for ings: Array in Recipe.RECIPE:
		if Recipe.RECIPE[ings][Recipe.REC_ID] == wanted:
			return ings.count(ing) >= count
	return false

func _reset_pose() -> void:
	if react_tween: react_tween.kill()
	modulate = Color.WHITE
	rotation = 0.0
	scale = Vector2.ONE
	position.y = rest_y

func _react(served: bool, quality: Cons.QUALITY) -> Tween:
	pivot_offset = Vector2(size.x / 2.0, size.y)
	react_tween = create_tween()
	if not served or quality == Cons.QUALITY.FAIL:
		react_tween.tween_property(self, "modulate", Color(1.0, 0.45, 0.45), 0.1)
		for i: int in 4:
			var tilt: float = 0.08 * (1 if i % 2 == 0 else -1)
			react_tween.tween_property(self, "rotation", tilt, 0.06)
		react_tween.tween_property(self, "rotation", 0.0, 0.06)
	elif quality == Cons.QUALITY.POOR:
		react_tween.tween_property(self, "modulate", Color(1.0, 0.95, 0.6), 0.1)
		react_tween.tween_property(self, "scale", Vector2(1.04, 0.93), 0.12)
		react_tween.tween_property(self, "scale", Vector2.ONE, 0.12)
	else:
		var hops: int = 2 if quality == Cons.QUALITY.EXCELLENT else 1
		var tint: Color = Color(1.0, 0.9, 0.4) if hops == 2 else Color(0.7, 1.0, 0.7)
		react_tween.tween_property(self, "modulate", tint, 0.1)
		for i: int in hops:
			react_tween.tween_property(self, "position:y", rest_y - 24.0, 0.1) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			react_tween.tween_property(self, "position:y", rest_y, 0.1) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	react_tween.tween_interval(0.1)
	return react_tween

func leave(served: bool, quality: Cons.QUALITY = Cons.QUALITY.FAIL) -> void:
	active = false
	timer.stop()
	Event.customer_left.emit(self, served)
	await _react(served, quality).finished
	if active: return
	_reset_pose()
	_walk_to(_offscreen_x(), 0, 0.0).set_ease(Tween.EASE_IN).finished.connect(func() -> void:
		if not active: hide())

func _process(_delta: float) -> void:
	if active and not timer.is_stopped():
		progress_bar.value = timer.time_left

func _on_potion_served(result: Dictionary) -> void:
	if not active: return
	var served: bool = result.success and result.recipe_id == wanted
	if served: Event.customer_paid.emit(result.money, result.quality, result.ingredient_count)
	leave(served, result.quality if served else Cons.QUALITY.FAIL)

func _on_timer_timeout() -> void:
	leave(false)
	Event.cauldron_emptied.emit()
