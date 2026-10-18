extends ColorRect

@onready var score_label: Label = %ScoreLabel
@onready var play_again: Button = %PlayAgain
@onready var highscore_control: Control = $Box/HighscoreControl

var high_score: int = 0

func _ready() -> void:
	hide()
	Event.game_over.connect(_on_game_over)
	play_again.pressed.connect(_on_play_again_pressed)
	load_high_score()

func _on_game_over() -> void:
	var scene: MainScene = Utility.scene
	var money: int = scene.money if scene else 0
	
	if check_and_save_high_score(money):
		highscore_control.visible = true

	score_label.text = "Score: %d" % money
	show()

func _on_play_again_pressed() -> void:
	highscore_control.visible = false
	get_tree().paused = false
	get_tree().reload_current_scene()

func check_and_save_high_score(current_score: int) -> bool:
	if current_score <= high_score:
		return false
		
	high_score = current_score
	var config := ConfigFile.new()
	
	config.load(Cons.SAVE_PATH) 
	config.set_value("stats", "high_score", high_score)
	config.save(Cons.SAVE_PATH)
	return true

func load_high_score() -> void:
	var config := ConfigFile.new()
	if config.load(Cons.SAVE_PATH) == OK:
		high_score = config.get_value("stats", "high_score", 0)
