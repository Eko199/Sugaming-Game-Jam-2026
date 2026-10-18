extends ColorRect

@onready var score_label: Label = %ScoreLabel
@onready var play_again: Button = %PlayAgain
@onready var highscore_control: Control = $Box/HighscoreControl
@onready var served_label: Label = %ServedLabel
@onready var perfect_label: Label = %PerfectLabel
@onready var failed_label: Label = %FailedLabel

func _ready() -> void:
	hide()
	Event.game_over.connect(_on_game_over)
	play_again.pressed.connect(_on_play_again_pressed)
	Utility.load_high_score()

func _on_game_over() -> void:
	var scene: MainScene = Utility.scene
	var money: int = scene.money if scene else 0
	var served: int = scene.potions_served if scene else 0
	var perfect: int = scene.perfect_potions if scene else 0
	var fails: int = scene.fails if scene else 0
	
	if Utility.check_and_save_high_score(money):
		highscore_control.visible = true

	score_label.text = "Score: %d" % money
	served_label.text = "Customers served: %d" % served
	perfect_label.text = "Perfect potions: %d" % perfect
	failed_label.text = "Failed potions: %d" % fails
	show()

func _on_play_again_pressed() -> void:
	highscore_control.visible = false
	get_tree().paused = false
	get_tree().reload_current_scene()
