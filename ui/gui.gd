extends CanvasLayer

@onready var timer: Timer = $Timer
@onready var label: Label = $Label
@onready var money_label: Label = $MoneyLabel

func _ready() -> void:
	timer.timeout.connect(_on_timer_timeout)
	Event.money_changed.connect(_on_money_changed)
	_on_money_changed(0)

func _on_money_changed(amount: int) -> void:
	money_label.text = "%d coins" % amount

func _on_timer_timeout() -> void:
	#end game
	Event.game_over.emit()
	
func _process(_delta: float) -> void:
	label.text = "%d:%02d" % [timer.time_left / 60, floori(timer.time_left) % 60]
