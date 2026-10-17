extends ColorRect

@onready var score_label: Label = %ScoreLabel
@onready var play_again: Button = %PlayAgain

func _ready() -> void:
	hide()
	Event.game_over.connect(_on_game_over)
	play_again.pressed.connect(_on_play_again_pressed)

func _on_game_over() -> void:
	var scene: MainScene = Utility.scene
	score_label.text = "Score: %d" % (scene.money if scene else 0)
	show()

func _on_play_again_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
