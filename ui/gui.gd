extends CanvasLayer

@onready var timer: Timer = $Timer
@onready var clock: TextureProgressBar = $Clock
@onready var hand: TextureRect = $Clock/Hand
@onready var money_label: Label = $Money/HBox/Label

var shown_money: int = 0
var money_tween: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	timer.process_mode = Node.PROCESS_MODE_PAUSABLE
	clock.max_value = Cons.ROUND_TIME
	Event.money_changed.connect(_on_money_changed)
	Event.time_added.connect(_on_time_added)
	add_child(ResultFx.new())
	var debuff_hud: DebuffHud = DebuffHud.new()
	add_child(debuff_hud)
	move_child(debuff_hud, money_label.get_index() + 1) ## Below the almanac / end screen overlays.
	_on_money_changed(0)

func _on_money_changed(amount: int) -> void:
	if amount == shown_money:
		money_label.text = str(amount)
		return
	if money_tween: money_tween.kill()
	money_label.pivot_offset = money_label.size / 2.0
	money_tween = create_tween()
	money_tween.tween_property(money_label, "scale", Vector2.ONE * 1.35, 0.1) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	money_tween.parallel().tween_method(_show_money, shown_money, amount, 0.45)
	money_tween.tween_property(money_label, "scale", Vector2.ONE, 0.2)

func _show_money(value: float) -> void:
	shown_money = roundi(value)
	money_label.text = str(shown_money)

func _process(_delta: float) -> void:
	var progress: float = Cons.ROUND_TIME - timer.time_left
	clock.value = progress
	hand.rotation = TAU * progress / Cons.ROUND_TIME

func _format_time(seconds: float) -> String:
	var s: int = ceili(seconds)
	return "%d:%02d" % [floori(s / 60.0), s % 60]

func _on_time_added(_seconds: float) -> void:
	Utility.floating_text(self, "+", clock.position + Vector2(clock.size.x + 20, 0), Color(0.4, 1, 0.4))
