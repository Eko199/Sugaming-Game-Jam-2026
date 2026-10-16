extends CanvasLayer

@onready var timer: Timer = $Timer
@onready var label: Label = $Label

func _ready() -> void:
	timer.timeout.connect(_on_timer_timeout)

func _on_timer_timeout() -> void:
	#end game
	pass
	
func _process(_delta: float) -> void:
	label.text = "%d:%02d" % [timer.time_left / 60, floori(timer.time_left) % 60]
