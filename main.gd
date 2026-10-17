extends Node2D
class_name MainScene

@onready var round_timer: Timer = $UI/Timer
@onready var customer: Customer = $Customer
@onready var spoon: TextureRect = $Spoon
@onready var almanac: MarginContainer = $UI/ColorRect/AlmanacControl
@onready var back_background: TextureRect = $BackBackground

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var customers_spawned: int = 0
var money: int = 0
var potions_served: int = 0
var is_spoon_held: bool = false
var is_over: bool = false
var elapsed: float = 0.0

func _ready() -> void:
	rng.randomize()
	Event.customer_left.connect(_on_customer_left)
	Event.customer_paid.connect(_on_customer_paid)
	round_timer.timeout.connect(_end_game)
	round_timer.start(Cons.ROUND_TIME)
	_spawn_customer()

func _process(delta: float) -> void:
	elapsed += delta
	var radius: Vector2 = back_background.size / 2
	var mouse_pos: Vector2 = (get_local_mouse_position() - radius) / radius
	var dir: Vector2 = (get_local_mouse_position() - radius).normalized()
	var length: float = mouse_pos.length()
	back_background.position = length * dir * 4

func add_time(seconds: float) -> void:
	if is_over: return
	round_timer.start(round_timer.time_left + seconds)
	Event.time_added.emit(seconds)

func _end_game() -> void:
	if is_over: return
	is_over = true
	almanac.close()
	get_tree().paused = true
	Event.game_over.emit()

func round_progress() -> float:
	return clampf(elapsed / Cons.ROUND_TIME, 0.0, 1.0)

func _spawn_customer() -> void:
	var progress: float = round_progress()
	var recipe: Cons.RECIPE = 0 as Cons.RECIPE if customers_spawned == 0 else _pick_recipe(progress)
	var patience: float = lerpf(Cons.PATIENCE_MAX, Cons.PATIENCE_MIN, progress)
	customers_spawned += 1
	customer.arrive(recipe, patience)

func _pick_recipe(progress: float) -> Cons.RECIPE:
	var target: float = progress * (Cons.RECIPE.size() - 1)
	var weights: PackedFloat32Array = []
	for i: int in Cons.RECIPE.size():
		var weight: float = 1.0 / pow(1.0 + absf(i - target), Cons.RECIPE_DIFFICULTY_FALLOFF)
		if i <= target: weight = maxf(weight, Cons.EASY_RECIPE_MIN_WEIGHT)
		weights.append(weight)
	return rng.rand_weighted(weights) as Cons.RECIPE

func _on_customer_left(_customer: Customer, _served: bool) -> void:
	await get_tree().create_timer(Cons.CUSTOMER_GAP).timeout
	if is_over or round_timer.is_stopped(): return
	_spawn_customer()
	
func _on_customer_paid(amount: int, quality: Cons.QUALITY) -> void:
	money += roundi(amount * Cons.QUALITY_MULT[quality])
	potions_served += 1
	Event.money_changed.emit(money)
	if quality == Cons.QUALITY.EXCELLENT: add_time(Cons.PERFECT_TIME_BONUS)

func _on_spoon_button_up() -> void:
	spoon.hide()
	is_spoon_held = true
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and almanac.get_parent().visible == true:
		almanac.close()
	elif event.is_action_pressed("open_book") and almanac.get_parent().visible == false:
		almanac.open()
