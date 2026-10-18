extends ColorRect

const MENU_SCENE: String = "res://ui/main_menu.tscn"
const OVERLAY_ALPHA: float = 0.8
const COUNT_UP_TIME: Vector2 = Vector2(0.5, 1.4)

@onready var title: Label = %Title
@onready var card: PanelContainer = %Card
@onready var score_label: Label = %ScoreLabel
@onready var best_label: Label = %BestLabel
@onready var served_label: Label = %ServedLabel
@onready var perfect_label: Label = %PerfectLabel
@onready var failed_label: Label = %FailedLabel
@onready var buttons: HBoxContainer = %Buttons
@onready var play_again: Button = %PlayAgain
@onready var main_menu_button: Button = %MainMenuButton
@onready var new_high_score: PanelContainer = %NewHighScore
@onready var fade: ColorRect = %Fade

var _leaving: bool = false

func _ready() -> void:
	hide()
	Event.game_over.connect(_on_game_over)
	play_again.pressed.connect(_leave.bind(""))
	main_menu_button.pressed.connect(_leave.bind(MENU_SCENE))
	for button: Button in [play_again, main_menu_button]:
		_setup_button(button)
	Utility.load_high_score()

func _on_game_over() -> void:
	var scene: MainScene = Utility.scene
	var money: int = scene.money if scene else 0
	var served: int = scene.potions_served if scene else 0
	var perfect: int = scene.perfect_potions if scene else 0
	var fails: int = scene.fails if scene else 0

	var previous_best: int = Utility.high_score
	var is_new_best: bool = Utility.check_and_save_high_score(money)

	score_label.text = "0"
	served_label.text = str(served)
	perfect_label.text = str(perfect)
	failed_label.text = str(fails)
	if not is_new_best:
		best_label.text = "Best: %s" % Utility.format_number(Utility.high_score)
	elif previous_best > 0:
		best_label.text = "Previous best: %s" % Utility.format_number(previous_best)
	else:
		best_label.text = "Your first score is on the board!"

	new_high_score.hide()
	show()
	_play_reveal(money, is_new_best)

func _play_reveal(money: int, is_new_best: bool) -> void:
	color.a = 0.0
	for node: Control in [title, card, buttons]:
		node.modulate.a = 0.0

	await get_tree().process_frame # let containers lay out so pivots are right
	for node: Control in [title, card, play_again, main_menu_button]:
		_center_pivot(node)

	var tween: Tween = create_tween()
	tween.tween_property(self, "color:a", OVERLAY_ALPHA, 0.4)

	title.scale = Vector2(0.6, 0.6)
	tween.tween_property(title, "modulate:a", 1.0, 0.2)
	tween.parallel().tween_property(title, "scale", Vector2.ONE, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	card.scale = Vector2(0.9, 0.9)
	tween.parallel().tween_property(card, "modulate:a", 1.0, 0.3).set_delay(0.2)
	tween.parallel().tween_property(card, "scale", Vector2.ONE, 0.4).set_delay(0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Count the score up.
	var count_time: float = clampf(money / 400.0, COUNT_UP_TIME.x, COUNT_UP_TIME.y) if money > 0 else 0.01
	tween.tween_method(_set_score, 0, money, count_time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	if money > 0:
		tween.tween_callback(Audio.play.bind("coins", 0.05))

	if is_new_best:
		tween.tween_callback(_show_new_high_score)
		tween.tween_interval(0.35)

	tween.tween_property(buttons, "modulate:a", 1.0, 0.3)
	tween.tween_callback(play_again.grab_focus)
	tween.tween_callback(_start_idle_loops)

func _set_score(value: int) -> void:
	score_label.text = Utility.format_number(value)

func _show_new_high_score() -> void:
	new_high_score.show()
	new_high_score.reset_size()
	new_high_score.pivot_offset = new_high_score.size / 2.0
	var card_rect: Rect2 = card.get_global_rect()
	new_high_score.global_position = Vector2(
		card_rect.end.x - new_high_score.size.x * 0.6,
		card_rect.position.y - new_high_score.size.y * 0.55
	)
	new_high_score.scale = Vector2(2.2, 2.2)
	new_high_score.modulate.a = 0.0
	Audio.play("potion_excellent")
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(new_high_score, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(new_high_score, "modulate:a", 1.0, 0.15)
	tween.chain().tween_callback(_pulse_new_high_score)

func _pulse_new_high_score() -> void:
	var pulse: Tween = create_tween().set_loops()
	pulse.tween_property(new_high_score, "scale", Vector2(1.1, 1.1), 0.5).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(new_high_score, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_SINE)

func _start_idle_loops() -> void:
	var sway: Tween = create_tween().set_loops()
	sway.tween_property(title, "rotation", deg_to_rad(-1.5), 1.6).set_trans(Tween.TRANS_SINE)
	sway.tween_property(title, "rotation", deg_to_rad(1.5), 1.6).set_trans(Tween.TRANS_SINE)

func _setup_button(button: Button) -> void:
	button.resized.connect(_center_pivot.bind(button))
	button.mouse_entered.connect(_on_button_hover.bind(button, true))
	button.mouse_exited.connect(_on_button_hover.bind(button, false))
	button.focus_entered.connect(_on_button_hover.bind(button, true))
	button.focus_exited.connect(_on_button_hover.bind(button, false))

func _on_button_hover(button: Button, hovered: bool) -> void:
	if _leaving: return
	_center_pivot(button)
	var tween: Tween = button.create_tween()
	tween.tween_property(button, "scale", Vector2(1.08, 1.08) if hovered else Vector2.ONE, 0.15) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if hovered and button.is_hovered():
		Audio.play("dial_click", 0.1)

func _center_pivot(control: Control) -> void:
	control.pivot_offset = control.size / 2.0

func _leave(target: String) -> void:
	if _leaving: return
	_leaving = true
	play_again.disabled = true
	main_menu_button.disabled = true
	Audio.play("ingredient_drop")
	Audio.unmuffle(0.4)
	Utility.speech_impairment_active = false

	var tween: Tween = create_tween()
	tween.tween_property(fade, "color:a", 1.0, 0.35)
	tween.tween_callback(func() -> void:
		get_tree().paused = false
		if target.is_empty():
			get_tree().reload_current_scene()
		else:
			get_tree().change_scene_to_file(target)
	)
