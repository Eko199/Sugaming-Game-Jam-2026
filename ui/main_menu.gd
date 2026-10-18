extends Control

const GAME_SCENE: String = "res://main.tscn"
const DRIFTER_COUNT: int = 9
const DRIFTER_SIZE: Vector2 = Vector2(70.0, 130.0)
const DRIFTER_ALPHA: float = 0.45
const DRIFT_TIME: Vector2 = Vector2(11.0, 19.0)
const PARALLAX: float = 6.0

@onready var drift_layer: Control = $DriftLayer
@onready var content: VBoxContainer = %Content
@onready var title: Label = %Title
@onready var high_score_panel: PanelContainer = %HighScorePanel
@onready var high_score_icon: TextureRect = %HighScoreIcon
@onready var high_score_value: Label = %HighScoreValue
@onready var high_score_hint: Label = %HighScoreHint
@onready var play_button: Button = %PlayButton
@onready var quit_button: Button = %QuitButton
@onready var fade: ColorRect = $Fade

var _leaving: bool = false

func _ready() -> void:
	get_tree().paused = false
	Utility.load_high_score()
	_show_high_score(Utility.high_score)
	quit_button.visible = not OS.has_feature("web")
	play_button.pressed.connect(_on_play_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	for button: Button in [play_button, quit_button]:
		_setup_button(button)

	for i: int in DRIFTER_COUNT:
		_spawn_drifter(true)

	_play_intro()
	play_button.grab_focus.call_deferred()

func _show_high_score(score: int) -> void:
	if score > 0:
		high_score_value.text = _format_number(score)
		high_score_hint.hide()
	else:
		high_score_value.text = "---"
		high_score_hint.show()

func _format_number(value: int) -> String:
	var digits: String = str(absi(value))
	var out: String = ""
	while digits.length() > 3:
		out = "," + digits.right(3) + out
		digits = digits.left(-3)
	return ("-" if value < 0 else "") + digits + out

func _play_intro() -> void:
	fade.color.a = 1.0
	for node: Control in [title, high_score_panel, play_button, quit_button]:
		node.modulate.a = 0.0

	await get_tree().process_frame
	_center_pivot(title)
	_center_pivot(high_score_panel)
	_center_pivot(high_score_icon)

	var tween: Tween = create_tween()
	tween.tween_property(fade, "color:a", 0.0, 0.5)

	title.scale = Vector2(0.6, 0.6)
	tween.tween_property(title, "modulate:a", 1.0, 0.25)
	tween.parallel().tween_property(title, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var delay: float = 0.0
	for node: Control in [high_score_panel, play_button, quit_button]:
		tween.parallel().tween_property(node, "modulate:a", 1.0, 0.35).set_delay(0.25 + delay)
		delay += 0.12

	tween.tween_callback(_start_idle_loops)

func _start_idle_loops() -> void:
	var sway: Tween = create_tween().set_loops()
	sway.tween_property(title, "rotation", deg_to_rad(-1.5), 1.6).set_trans(Tween.TRANS_SINE)
	sway.tween_property(title, "rotation", deg_to_rad(1.5), 1.6).set_trans(Tween.TRANS_SINE)

	var spin: Tween = create_tween().set_loops()
	spin.tween_property(high_score_icon, "rotation", TAU, 8.0).from(0.0)
	if Utility.high_score > 0:
		var glow: Tween = create_tween().set_loops()
		glow.tween_property(high_score_value, "modulate", Color(1.25, 1.2, 1.0), 0.9).set_trans(Tween.TRANS_SINE)
		glow.tween_property(high_score_value, "modulate", Color.WHITE, 0.9).set_trans(Tween.TRANS_SINE)

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

func _spawn_drifter(initial: bool = false) -> void:
	var drifter: TextureRect = TextureRect.new()
	drifter.texture = load(Cons.INGRIDIENT_TEXTURE[randi() % Cons.INGRIDIENT_TEXTURE.size()])
	drifter.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	drifter.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	drifter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var side: float = randf_range(DRIFTER_SIZE.x, DRIFTER_SIZE.y)
	drifter.size = Vector2(side, side)
	drifter.pivot_offset = drifter.size / 2.0
	drifter.rotation = randf() * TAU
	drifter.modulate.a = 0.0
	drift_layer.add_child(drifter)

	var view: Vector2 = size
	var start_x: float = randf_range(0.0, view.x - side)
	var start_y: float = randf_range(0.0, view.y) if initial else view.y + side
	drifter.position = Vector2(start_x, start_y)

	var travel: float = start_y + side * 2.0
	var duration: float = randf_range(DRIFT_TIME.x, DRIFT_TIME.y) * travel / (view.y + side * 2.0)
	var end_pos: Vector2 = Vector2(start_x + randf_range(-120.0, 120.0), -side * 1.5)

	var tween: Tween = drifter.create_tween().set_parallel()
	tween.tween_property(drifter, "position", end_pos, duration).set_trans(Tween.TRANS_SINE)
	tween.tween_property(drifter, "rotation", drifter.rotation + randf_range(-PI, PI), duration)
	tween.tween_property(drifter, "modulate:a", DRIFTER_ALPHA, 1.2)
	tween.tween_property(drifter, "modulate:a", 0.0, 1.2).set_delay(maxf(duration - 1.2, 0.0))
	tween.chain().tween_callback(func() -> void:
		drifter.queue_free()
		if not _leaving:
			_spawn_drifter()
	)

func _on_play_pressed() -> void:
	if _leaving: return
	_leaving = true
	Audio.play("ingredient_drop")
	play_button.disabled = true
	quit_button.disabled = true
	var tween: Tween = create_tween()
	tween.tween_property(play_button, "scale", Vector2(0.92, 0.92), 0.08)
	tween.tween_property(play_button, "scale", Vector2(1.12, 1.12), 0.12)
	tween.tween_property(fade, "color:a", 1.0, 0.4)
	tween.tween_callback(get_tree().change_scene_to_file.bind(GAME_SCENE))

func _on_quit_pressed() -> void:
	if _leaving: return
	_leaving = true
	var tween: Tween = create_tween()
	tween.tween_property(fade, "color:a", 1.0, 0.3)
	tween.tween_callback(get_tree().quit)
