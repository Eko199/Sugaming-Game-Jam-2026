extends Node
class_name ResultFx

## Feedback for a finished potion: quality word, particle burst, glow, cauldron shake,
## plus the "+coins" popup where the customer pays.

const WORD_SIZE: int = 64
const WORD_RISE: float = 90.0
const SHAKE_STEPS: int = 6
const SHAKE_AMOUNT: float = 10.0
const COIN_COLOR: Color = Color(1.0, 0.82, 0.25)
const GLOW_SHADER: Shader = preload("res://shaders/cauldron_glow.gdshader")

var _shake_tween: Tween
var _cauldron_rest: Vector2 = Vector2.INF

func _ready() -> void:
	Event.potion_served.connect(_on_potion_served)
	Event.customer_paid.connect(_on_customer_paid)

func _cauldron() -> Cauldron:
	var scene: MainScene = Utility.scene
	return scene.get_node_or_null("Cauldron") as Cauldron if scene else null

func _on_potion_served(result: Dictionary) -> void:
	var cauldron: Cauldron = _cauldron()
	if not cauldron: return
	var mouth: Vector2 = cauldron.water_mask.get_global_rect().get_center()
	var color: Color = cauldron.water_color
	var quality: Cons.QUALITY = result.quality
	var word: String
	var word_color: Color
	if not result.success:
		quality = Cons.QUALITY.FAIL
		word = "Wrong potion!" if result.ingredient_count > 0 else "Failed!"
		word_color = Color(1.0, 0.4, 0.35)
	else:
		match quality:
			Cons.QUALITY.POOR:
				word = "Meh"
				word_color = Color(0.85, 0.8, 0.6)
			Cons.QUALITY.GOOD:
				word = "Nice!"
				word_color = Color(0.55, 1.0, 0.6)
			_:
				word = "Perfect!"
				word_color = Color(1.0, 0.85, 0.3)

	_popup_word(word, mouth + Vector2(0, -170), word_color, quality)
	_burst(mouth, color, quality)
	if quality >= Cons.QUALITY.GOOD:
		_glow(cauldron, color, quality)
	elif quality == Cons.QUALITY.FAIL:
		_shake(cauldron)

func _popup_word(text: String, pos: Vector2, color: Color, quality: Cons.QUALITY) -> void:
	var label: Label = Label.new()
	var settings: LabelSettings = LabelSettings.new()
	settings.font = Cons.FONT_DISPLAY
	settings.font_size = WORD_SIZE + (24 if quality == Cons.QUALITY.EXCELLENT else 0)
	settings.font_color = color
	settings.outline_size = 14
	settings.outline_color = Color(0.08, 0.03, 0.15)
	label.label_settings = settings
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = Cons.Z_HELD
	get_parent().add_child(label)
	label.reset_size()
	label.pivot_offset = label.size / 2.0
	label.position = pos - label.size / 2.0
	label.scale = Vector2.ZERO
	label.rotation = randf_range(-0.06, 0.06)
	var tween: Tween = label.create_tween()
	tween.tween_property(label, "scale", Vector2.ONE * 1.25, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector2.ONE, 0.1)
	tween.tween_interval(0.35)
	tween.set_parallel()
	tween.chain().tween_property(label, "position:y", label.position.y - WORD_RISE, 0.7) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(label, "modulate:a", 0.0, 0.5).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(label.queue_free)

func _burst(pos: Vector2, color: Color, quality: Cons.QUALITY) -> void:
	var amounts: PackedInt32Array = [16, 26, 40, 64]
	var drops: CPUParticles2D = _make_burst(amounts[quality], 0.9)
	drops.direction = Vector2.UP
	drops.spread = 70.0 if quality > Cons.QUALITY.FAIL else 100.0
	drops.initial_velocity_min = 180.0
	drops.initial_velocity_max = 420.0 if quality > Cons.QUALITY.FAIL else 260.0
	drops.gravity = Vector2(0, 600)
	drops.scale_amount_min = 3.0
	drops.scale_amount_max = 8.0
	var base: Color = color.lightened(0.3) if quality > Cons.QUALITY.FAIL else color.darkened(0.4)
	drops.color_ramp = _fade_ramp(base)
	get_parent().add_child(drops)
	drops.position = pos
	drops.emitting = true
	drops.finished.connect(drops.queue_free)

	if quality == Cons.QUALITY.EXCELLENT:
		var sparkles: CPUParticles2D = _make_burst(36, 1.2)
		sparkles.direction = Vector2.UP
		sparkles.spread = 180.0
		sparkles.initial_velocity_min = 80.0
		sparkles.initial_velocity_max = 320.0
		sparkles.gravity = Vector2(0, -60)
		sparkles.damping_min = 60.0
		sparkles.damping_max = 120.0
		sparkles.scale_amount_min = 2.0
		sparkles.scale_amount_max = 5.0
		sparkles.color_ramp = _fade_ramp(Color(1.0, 0.95, 0.6))
		get_parent().add_child(sparkles)
		sparkles.position = pos
		sparkles.emitting = true
		sparkles.finished.connect(sparkles.queue_free)

func _make_burst(amount: int, lifetime: float) -> CPUParticles2D:
	var p: CPUParticles2D = CPUParticles2D.new()
	p.one_shot = true
	p.emitting = false
	p.explosiveness = 1.0
	p.amount = amount
	p.lifetime = lifetime
	p.z_index = Cons.Z_HELD
	return p

func _fade_ramp(base: Color) -> Gradient:
	var ramp: Gradient = Gradient.new()
	ramp.colors = PackedColorArray([base, base, Color(base, 0.0)])
	ramp.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	return ramp

## Light rising out of the cauldron. It is clipped to the opening's shape and sits behind the
## cauldron's front, so only the liquid is lit and the outer walls stay untouched.
func _glow(cauldron: Cauldron, color: Color, quality: Cons.QUALITY) -> void:
	var mask: TextureRect = cauldron.water_mask
	var glow: TextureRect = TextureRect.new()
	glow.texture = mask.texture
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.stretch_mode = TextureRect.STRETCH_SCALE
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.z_index = Cons.Z_IN_CAULDRON
	cauldron.add_child(glow)
	glow.position = mask.position
	glow.size = mask.size
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = GLOW_SHADER
	var tint: Color = color.lightened(0.5) if quality == Cons.QUALITY.GOOD else Color(1.0, 0.92, 0.6).lerp(color, 0.25)
	material.set_shader_parameter("glow_color", tint)
	material.set_shader_parameter("intensity", 0.0)
	glow.material = material
	var peak: float = 0.9 if quality == Cons.QUALITY.EXCELLENT else 0.55
	var tween: Tween = glow.create_tween()
	tween.tween_property(material, "shader_parameter/intensity", peak, 0.12)
	tween.tween_property(material, "shader_parameter/intensity", 0.0, 0.8) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(glow.queue_free)

func _shake(cauldron: Cauldron) -> void:
	if _shake_tween: _shake_tween.kill()
	if _cauldron_rest == Vector2.INF: _cauldron_rest = cauldron.position
	cauldron.position = _cauldron_rest
	_shake_tween = create_tween()
	for i: int in SHAKE_STEPS:
		var strength: float = SHAKE_AMOUNT * (1.0 - float(i) / SHAKE_STEPS)
		var dir: float = 1.0 if i % 2 == 0 else -1.0
		_shake_tween.tween_property(cauldron, "position", _cauldron_rest + Vector2(strength * dir, 0), 0.04)
	_shake_tween.tween_property(cauldron, "position", _cauldron_rest, 0.04)

func _on_customer_paid(amount: int, quality: Cons.QUALITY, _ingredient_count: int) -> void:
	var scene: MainScene = Utility.scene
	if not scene: return
	var customer: Customer = scene.customer
	var gained: int = scene.payout(amount, quality)
	var pos: Vector2 = customer.global_position + Vector2(customer.size.x * 0.5, customer.size.y * 0.3)
	_popup_coins("+%d" % gained, pos, quality)
	var coins: CPUParticles2D = _make_burst(10 + 6 * quality, 0.8)
	coins.direction = Vector2.UP
	coins.spread = 60.0
	coins.initial_velocity_min = 160.0
	coins.initial_velocity_max = 340.0
	coins.gravity = Vector2(0, 900)
	coins.scale_amount_min = 4.0
	coins.scale_amount_max = 7.0
	coins.color = COIN_COLOR
	coins.color_ramp = _fade_ramp(COIN_COLOR)
	get_parent().add_child(coins)
	coins.position = pos
	coins.emitting = true
	coins.finished.connect(coins.queue_free)

func _popup_coins(text: String, pos: Vector2, quality: Cons.QUALITY) -> void:
	var label: Label = Label.new()
	var settings: LabelSettings = LabelSettings.new()
	settings.font = Cons.FONT_DISPLAY
	settings.font_size = 48 + 8 * quality
	settings.font_color = COIN_COLOR
	settings.outline_size = 10
	settings.outline_color = Color(0.25, 0.1, 0.0)
	label.label_settings = settings
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_parent().add_child(label)
	label.reset_size()
	label.pivot_offset = label.size / 2.0
	label.position = pos - label.size / 2.0
	label.scale = Vector2.ZERO
	var tween: Tween = label.create_tween()
	tween.tween_property(label, "scale", Vector2.ONE * 1.3, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector2.ONE, 0.08)
	tween.set_parallel()
	tween.chain().tween_property(label, "position:y", label.position.y - 110.0, 1.1) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.4).set_delay(0.7)
	tween.chain().tween_callback(label.queue_free)
