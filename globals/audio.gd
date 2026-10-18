extends Node

const DIR: String = "res://audio/"

const GAIN: Dictionary[String, float] = {
	"almanac_close": -10.0,
	"almanac_open": 8.4,
	"almanac_tab": -1.8,
	"ambience_shop_loop": 11.7,
	"bgm": -30.4,
	"cauldron_bubble_loop": -10.8,
	"cauldron_fire_loop": -4.0,
	"coins": -4.3,
	"frog_ribbit": -8.1,
	"customer_leave_angry": -4.6,
	"dial_click": 2.8,
	"dragon_fire": -27.2,
	"dragon_roar": -25.2,
	"dragon_wings": -24.5,
	"game_over": 0.8,
	"ingredient_drop": -2.5,
	"ingredient_drop_fail": -3.3,
	"ingredient_pick": 2.4,
	"ingredient_right": 8.0,
	"ingredient_wrong": -0.3,
	"potion_bad": -11.6,
	"potion_excellent": -3.9,
	"potion_fail": -10.6,
	"potion_good": -2.0,
	"potion_poor": 0.4,
	"spoon_pick": 22.0,
	"stir_loop": 7.3,
	"time_bonus": -4.0,
}

## Global offset applied on top of GAIN; lower it to make everything quieter.
const MASTER_DB: float = -8.0

const POTION_SOUNDS: PackedStringArray = ["potion_fail", "potion_poor", "potion_good", "potion_excellent"]
const DRAGON_SOUNDS: PackedStringArray = ["dragon_roar", "dragon_fire", "dragon_wings"]
const DRAGON_INTERVAL: Vector2 = Vector2(25.0, 60.0)
const FIRE_HEAT_RANGE_DB: Vector2 = Vector2(-12.0, 3.0)
const FADE_TIME: float = 0.6
const STIR_HOLD: float = 0.15
const SILENT_DB: float = -60.0
const CLEAR_HZ: float = 20500.0
const MUFFLED_HZ: float = 700.0

var bgm: AudioStreamPlayer
var ambience: AudioStreamPlayer
var bubble: AudioStreamPlayer
var fire: AudioStreamPlayer
var stir: AudioStreamPlayer
var dragon_timer: Timer
var heat_db: float = 0.0
var stir_hold: float = 0.0
var muffle_filter: AudioEffectLowPassFilter = AudioEffectLowPassFilter.new()
var muffle_tween: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	muffle_filter.cutoff_hz = CLEAR_HZ
	AudioServer.add_bus_effect(AudioServer.get_bus_index("Master"), muffle_filter)
	bgm = _make_loop("bgm")
	ambience = _make_loop("ambience_shop_loop")
	bubble = _make_loop("cauldron_bubble_loop")
	fire = _make_loop("cauldron_fire_loop")
	stir = _make_loop("stir_loop")
	bgm.play()
	ambience.play()

	dragon_timer = Timer.new()
	dragon_timer.one_shot = true
	dragon_timer.process_mode = Node.PROCESS_MODE_PAUSABLE
	dragon_timer.timeout.connect(_on_dragon_timer)
	add_child(dragon_timer)

	Event.ingredient_added.connect(_on_ingredient_added)
	Event.potion_served.connect(_on_potion_served)
	Event.customer_arrived.connect(_on_customer_arrived)
	Event.customer_left.connect(_on_customer_left)
	Event.customer_paid.connect(_on_customer_paid)
	Event.time_added.connect(_on_time_added)
	Event.game_over.connect(_on_game_over)

func _process(delta: float) -> void:
	stir_hold -= delta
	var stirring: bool = stir_hold > 0.0
	if stirring and not stir.playing:
		stir.play(randf() * stir.stream.get_length())
	elif not stirring and stir.playing:
		stir.stop()

## Plays a one-shot sound by name, with optional random pitch variation.
func play(sound: String, pitch_spread: float = 0.0, delay: float = 0.0) -> void:
	if delay > 0.0: await get_tree().create_timer(delay).timeout
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.stream = load(DIR + sound + ".mp3")
	player.volume_db = _db(sound)
	player.pitch_scale = 1.0 + randf_range(-pitch_spread, pitch_spread)
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()

## Gradually muffles everything with a low-pass filter on the master bus.
func muffle(duration: float = 2.0) -> void:
	if muffle_tween: muffle_tween.kill()
	muffle_tween = create_tween()
	muffle_tween.tween_property(muffle_filter, "cutoff_hz", MUFFLED_HZ, duration)

## Fades the master low-pass filter back open.
func unmuffle(duration: float = 2.0) -> void:
	if muffle_tween: muffle_tween.kill()
	muffle_tween = create_tween()
	muffle_tween.tween_property(muffle_filter, "cutoff_hz", CLEAR_HZ, duration)

## Called by the cauldron when a round starts; (re)starts its loops and the dragon timer.
func start_cauldron() -> void:
	_fade(bubble, _db("cauldron_bubble_loop"))
	_fade(fire, _db("cauldron_fire_loop") + heat_db)
	_schedule_dragon()

## Fire loudness follows the heat dial (0..1).
func set_heat(heat: float) -> void:
	heat_db = lerpf(FIRE_HEAT_RANGE_DB.x, FIRE_HEAT_RANGE_DB.y, heat)
	if fire.playing: fire.volume_db = _db("cauldron_fire_loop") + heat_db

## Keeps the stirring loop alive while the spoon is moving inside the cauldron.
func keep_stirring() -> void:
	stir_hold = STIR_HOLD

func _db(sound: String) -> float:
	return GAIN[sound] + MASTER_DB

func _make_loop(sound: String) -> AudioStreamPlayer:
	var stream: AudioStreamMP3 = load(DIR + sound + ".mp3").duplicate()
	stream.loop = true
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = _db(sound)
	add_child(player)
	return player

func _fade(player: AudioStreamPlayer, to_db: float) -> void:
	if player.has_meta("fade"): (player.get_meta("fade") as Tween).kill()
	if to_db <= SILENT_DB and not player.playing: return
	if not player.playing:
		player.volume_db = SILENT_DB
		player.play()
	var tween: Tween = player.create_tween()
	tween.tween_property(player, "volume_db", to_db, FADE_TIME)
	if to_db <= SILENT_DB: tween.tween_callback(player.stop)
	player.set_meta("fade", tween)

func _schedule_dragon() -> void:
	dragon_timer.start(randf_range(DRAGON_INTERVAL.x, DRAGON_INTERVAL.y))

func _on_dragon_timer() -> void:
	play(DRAGON_SOUNDS[randi() % DRAGON_SOUNDS.size()], 0.08)
	_schedule_dragon()

func _on_ingredient_added(ing: Ingredient.TYPE) -> void:
	play("ingredient_drop", 0.05)
	var scene: MainScene = Utility.scene
	if not scene: return
	var hitbox: CauldronHitbox = get_tree().get_first_node_in_group("cauldron") as CauldronHitbox
	var count: int = hitbox.cauldron.current_items.count(ing) if hitbox else 1
	var right: bool = scene.customer.visible and scene.customer.wants(ing, count)
	play("ingredient_right" if right else "ingredient_wrong", 0.0, 0.15)

func _on_potion_served(result: Dictionary) -> void:
	var customer: Customer = Utility.scene.customer if Utility.scene else null
	if not result.success:
		play("potion_fail")
	elif customer and customer.visible and result.recipe_id != customer.wanted:
		play("potion_bad")
	else:
		play(POTION_SOUNDS[result.quality])

func _on_customer_arrived(_customer: Customer) -> void:
	play("frog_ribbit")

func _on_customer_left(_customer: Customer, served: bool) -> void:
	if not served: play("customer_leave_angry", 0.0, 0.5)

func _on_customer_paid(_amount: int, _quality: Cons.QUALITY, _ingredient_count: int) -> void:
	play("coins", 0.05, 0.4)

func _on_time_added(_seconds: float) -> void:
	play("time_bonus")

func _on_game_over() -> void:
	dragon_timer.stop()
	stir_hold = 0.0
	_fade(bubble, SILENT_DB)
	_fade(fire, SILENT_DB)
	play("game_over")
