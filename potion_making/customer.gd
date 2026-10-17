extends TextureRect
class_name Customer

@export var wanted: Cons.RECIPE
@export var patience: float

@onready var timer: Timer = $Timer
@onready var request_label: RichTextLabel = $RichTextLabel

func _ready() -> void:
	Event.potion_served.connect(_on_potion_served)
	hide()

## Called by the spawner in main.gd
func arrive(recipe: Cons.RECIPE, patience_time: float) -> void:
	wanted = recipe
	patience = patience_time
	request_label.text = Utility.get_keyname(wanted, Cons.RECIPE)
	timer.start(patience)
	show()
	Event.customer_arrived.emit(self)

func leave(served: bool) -> void:
	timer.stop()
	hide()
	Event.customer_left.emit(self, served)

func _on_potion_served(result: Dictionary) -> void:
	if not visible: return
	leave(result.success and result.recipe_id == wanted)

func _on_timer_timeout() -> void:
	leave(false)
	Event.cauldron_emptied.emit()
