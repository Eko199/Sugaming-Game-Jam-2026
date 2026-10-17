extends TextureRect
class_name Customer

@export var wanted: Cons.RECIPE
@export var patience: float

@onready var timer: Timer = $Timer
@onready var request_label: Label = $RequestLabel
@onready var progress_bar: ProgressBar = $ProgressBar

func _ready() -> void:
	Event.potion_served.connect(_on_potion_served)
	hide()

func arrive(recipe: Cons.RECIPE, patience_time: float) -> void:
	wanted = recipe
	patience = patience_time
	request_label.text = Utility.get_keyname(wanted, Cons.RECIPE)
	timer.start(patience)
	show()
	Event.customer_arrived.emit(self)

func leave(served: bool) -> void:
	timer.stop()
	Event.customer_left.emit(self, served)
	hide()

func _process(_delta: float) -> void:
	progress_bar.max_value = patience
	progress_bar.value = timer.time_left

func _on_potion_served(result: Dictionary) -> void:
	if not visible: return
	var served: bool = result.success and result.recipe_id == wanted
	if served: Event.customer_paid.emit(result.money, result.quality)
	leave(served)

func _on_timer_timeout() -> void:
	leave(false)
	Event.cauldron_emptied.emit()
