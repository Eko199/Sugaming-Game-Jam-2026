extends Node2D
class_name MainScene

@onready var round_timer: Timer = $UI/Timer
@onready var customer: Customer = $Customer
@onready var spoon: TextureRect = $Spoon
@onready var almanac: MarginContainer = $UI/ColorRect/AlmanacControl
@onready var back_background: TextureRect = $BackBackground
@onready var shelf: Node2D = $Shelf
@onready var color_blind: ColorBlindFilter = $ColorBlind

const TIMED_DEBUFFS: Array[Cons.DEBUFF] = [Cons.DEBUFF.SENSORY_DEPRIVATION, Cons.DEBUFF.SOUND_IMPAIRMENT]

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var customers_spawned: int = 0
var money: int = 0
var potions_served: int = 0
var perfect_potions: int = 0
var fails: int = 0
var current_debuffs: Array[Cons.DEBUFF] = []
var is_spoon_held: bool = false
var is_over: bool = false
var elapsed: float = 0.0
var recent_potions: Array[Cons.RECIPE] = []

func _ready() -> void:
	rng.randomize()
	Event.customer_left.connect(_on_customer_left)
	Event.customer_paid.connect(_on_customer_paid)
	round_timer.timeout.connect(_end_game)
	round_timer.start(Cons.ROUND_TIME)
	_show_tutorial()
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
	round_timer.start(clampf(round_timer.time_left + seconds, 0.0, Cons.ROUND_TIME))
	Event.time_added.emit(seconds)

func _end_game() -> void:
	if is_over: return
	is_over = true
	almanac.close()
	color_blind.fade_out(1.0)
	get_tree().paused = true
	Event.game_over.emit()

func round_progress() -> float:
	return clampf(elapsed / Cons.ROUND_TIME, 0.0, 1.0)

func _spawn_customer() -> void:
	var progress: float = round_progress()
	var recipe: Cons.RECIPE = 0 as Cons.RECIPE if customers_spawned == 0 else _pick_recipe(progress)
	var patience: float = Cons.PATIENCE_MAX - ease(progress, -5) * (Cons.PATIENCE_MAX - Cons.PATIENCE_MIN) # in seconds
	customers_spawned += 1
	customer.arrive(recipe, patience)

func _pick_recipe(progress: float) -> Cons.RECIPE:
	var target: float = lerpf(0.5, float(Cons.RECIPE.size() - 1), progress)
	var weights: PackedFloat32Array = []
	
	for i: int in Cons.RECIPE.size():
		var weight: float = 1.0 / pow(1.0 + absf(i - target), Cons.RECIPE_DIFFICULTY_FALLOFF)
		if i <= target:
			weight = maxf(weight, Cons.EASY_RECIPE_MIN_WEIGHT)
		
		if recent_potions.size() > 0 and i == recent_potions[-1]:
			weight *= Cons.REQUEST_REPEAT_PENALTY_RECENT
		elif recent_potions.size() > 1 and i == recent_potions[-2]:
			weight *= Cons.REQUEST_REPEAT_PENALTY_OLDER
			
		weights.append(weight)
	
	var picked := rng.rand_weighted(weights) as Cons.RECIPE
	
	recent_potions.append(picked)
	if recent_potions.size() > 2:
		recent_potions.pop_front()
		
	return picked

func _get_debuff() -> void:
	if fails % Cons.DEBUFF_FAILS != 0: return
	var debuffs: Array = Cons.DEBUFF.values().filter(
		func(a): return not a in current_debuffs
	)
	if debuffs.is_empty(): return
	var debuff: Cons.DEBUFF = debuffs.pick_random()
	current_debuffs.append(debuff)
	_apply_debuff(debuff)
	Event.debuff_started.emit(debuff, Cons.DEBUFF_TIME if debuff in TIMED_DEBUFFS else 0)
	if debuff in TIMED_DEBUFFS:
		await get_tree().create_timer(Cons.DEBUFF_TIME).timeout
		_remove_debuff(debuff)

func _apply_debuff(wt: Cons.DEBUFF) -> void:
	match wt:
		Cons.DEBUFF.SENSORY_DEPRIVATION:
			color_blind.fade_in()
			Audio.muffle()
		Cons.DEBUFF.SOUND_IMPAIRMENT:
			Utility.speech_impairment_active = true
		Cons.DEBUFF.ITEM_SHUFFLE:
			_shuffle_items()

func _remove_debuff(wt: Cons.DEBUFF) -> void:
	current_debuffs.erase(wt)
	match wt:
		Cons.DEBUFF.SENSORY_DEPRIVATION:
			color_blind.fade_out()
			Audio.unmuffle()
		Cons.DEBUFF.SOUND_IMPAIRMENT:
			Utility.speech_impairment_active = false
	Event.debuff_ended.emit(wt)

func _shuffle_items() -> void:
	var items: Array = shelf.get_children().map(func(ing): return ing.type)
	items.shuffle()
	for i in shelf.get_child_count():
		shelf.get_child(i).type = items[i]

## Every unhappy exit is a fail: a wrong/failed potion or running out of patience.
func _on_customer_left(_customer: Customer, served: bool) -> void:
	if not served and not is_over:
		fails += 1
		_get_debuff()
	await get_tree().create_timer(Cons.CUSTOMER_GAP).timeout
	if is_over or round_timer.is_stopped(): return
	_spawn_customer()
	
func _on_customer_paid(amount: int, quality: Cons.QUALITY, ingredient_count: int) -> void:
	money += roundi(amount * Cons.QUALITY_MULT[quality] * Cons.SPOON_LEVEL_MULT[spoon.level - 1])
	potions_served += 1
	Event.money_changed.emit(money)
	if quality == Cons.QUALITY.EXCELLENT: 
		perfect_potions += 1
		add_time(Cons.PERFECT_TIME_BONUS_BASE + Cons.PERFECT_TIME_BONUS_PER_INGREDIENT * ingredient_count)

func _on_spoon_button_up() -> void:
	spoon.hide()
	is_spoon_held = true
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and almanac.get_parent().visible == true:
		almanac.close()
	elif event.is_action_pressed("open_book") and almanac.get_parent().visible == false:
		almanac.open()

func _show_tutorial() -> void:
	get_tree().paused = true
	almanac.open()
	almanac._on_tutorial_btn_pressed()
