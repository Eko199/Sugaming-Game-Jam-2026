extends CanvasLayer

@onready var timer: Timer = $Timer
@onready var clock: TextureProgressBar = $Clock
@onready var hand: TextureRect = $Clock/Hand
@onready var money_label: Label = $MoneyLabel

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	timer.process_mode = Node.PROCESS_MODE_PAUSABLE
	clock.max_value = Cons.ROUND_TIME
	Event.money_changed.connect(_on_money_changed)
	Event.time_added.connect(_on_time_added)
	_on_money_changed(0)

func _on_money_changed(amount: int) -> void:
	money_label.text = "%d coins" % amount

func _process(_delta: float) -> void:
	var progress: float = Cons.ROUND_TIME - timer.time_left
	clock.value = progress
	hand.rotation = TAU * progress / Cons.ROUND_TIME

func _format_time(seconds: float) -> String:
	var s: int = ceili(seconds)
	return "%d:%02d" % [floori(s / 60.0), s % 60]

func _on_time_added(_seconds: float) -> void:
	Utility.floating_text(self, "+", clock.position + Vector2(clock.size.x + 20, 0), Color(0.4, 1, 0.4))
