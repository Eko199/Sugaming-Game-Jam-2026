extends Node2D
class_name MainScene

@onready var round_timer: Timer = $UI/Timer
@onready var customer: Customer = $Customer
@onready var spoon: TextureRect = $Spoon

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var customers_spawned: int = 0
var money: int = 0
var potions_served: int = 0
var is_spoon_held: bool = false

func _ready() -> void:
	rng.randomize()
	Event.customer_left.connect(_on_customer_left)
	Event.customer_paid.connect(_on_customer_paid)
	_spawn_customer()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed('spoon_drop') and is_spoon_held:
		spoon.show()
		is_spoon_held = false

func round_progress() -> float:
	return 1.0 - round_timer.time_left / round_timer.wait_time

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
	if round_timer.is_stopped(): return
	_spawn_customer()
	
func _on_customer_paid(amount: int, quality: Cons.QUALITY) -> void:
	money += roundi(amount * Cons.QUALITY_MULT[quality])
	Event.money_changed.emit(money)

func _on_spoon_button_up() -> void:
	spoon.hide()
	is_spoon_held = true
