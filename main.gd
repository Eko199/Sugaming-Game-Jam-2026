extends Node2D
class_name MainScene

@onready var round_timer: Timer = $UI/Timer
@onready var customer: Customer = $Customer

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var customers_spawned: int = 0

func _ready() -> void:
	rng.randomize()
	Event.customer_left.connect(_on_customer_left)
	_spawn_customer()

## 0.0 at the start of the round, 1.0 at the end
func round_progress() -> float:
	return 1.0 - round_timer.time_left / round_timer.wait_time

func _spawn_customer() -> void:
	var progress: float = round_progress()
	# The first customer is the tutorial and always wants the first recipe
	var recipe: Cons.RECIPE = 0 as Cons.RECIPE if customers_spawned == 0 else _pick_recipe(progress)
	var patience: float = lerpf(Cons.PATIENCE_MAX, Cons.PATIENCE_MIN, progress)
	customers_spawned += 1
	customer.arrive(recipe, patience)

## Recipes with a higher index are harder. Early on the easy ones are most likely,
## and the likely difficulty moves up as the round goes on.
func _pick_recipe(progress: float) -> Cons.RECIPE:
	var target: float = progress * (Cons.RECIPE.size() - 1)
	var weights: PackedFloat32Array = []
	for i: int in Cons.RECIPE.size():
		weights.append(1.0 / pow(1.0 + absf(i - target), Cons.RECIPE_DIFFICULTY_FALLOFF))
	return rng.rand_weighted(weights) as Cons.RECIPE

func _on_customer_left(_customer: Customer, _served: bool) -> void:
	await get_tree().create_timer(Cons.CUSTOMER_GAP).timeout
	if round_timer.is_stopped(): return
	_spawn_customer()
