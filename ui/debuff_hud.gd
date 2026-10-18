extends Control
class_name DebuffHud

## Row of debuff badges under the clock. A new debuff flies out of the cauldron into
## its slot, lands with a pop + pulse and shows its name. Timed debuffs drain a ring
## and blink near the end; instant ones (shuffle) show briefly, then fade.

const BADGE_SIZE: float = 84.0
const BADGE_GAP: float = 14.0
const ROW_ORIGIN: Vector2 = Vector2(36.0, 300.0)
const ARRIVE_DELAY: float = 0.45 ## Let "Wrong potion!" read first.
const FLY_TIME: float = 0.65
const FLY_ARC: float = 260.0
const SETTLE_TIME: float = 0.35
const INSTANT_SHOW_TIME: float = 3.0
const NAME_COLOR: Color = Color(1.0, 0.45, 0.4)

var _badges: Array[DebuffBadge] = []

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_PAUSABLE ## Drain with the (pausable) debuff timer.
	Event.debuff_started.connect(_on_debuff_started)
	Event.debuff_ended.connect(_on_debuff_ended)

func _on_debuff_started(type: Cons.DEBUFF, duration: float) -> void:
	var badge: DebuffBadge = DebuffBadge.new()
	badge.setup(type, duration, BADGE_SIZE)
	badge.visible = false
	add_child(badge)
	_badges.append(badge)
	_layout(badge)

	await get_tree().create_timer(ARRIVE_DELAY).timeout
	if not is_instance_valid(badge): return
	var target: Vector2 = _slot(_badges.find(badge))
	var start: Vector2 = _cauldron_mouth() - badge.size * 0.5
	if start.is_finite() == false: start = target
	var control: Vector2 = (start + target) * 0.5 + Vector2(0.0, -FLY_ARC)
	badge.position = start
	badge.scale = Vector2.ONE * 0.4
	badge.visible = true

	var fly: Tween = badge.create_tween().set_parallel()
	fly.tween_method(func(t: float) -> void:
		badge.position = start.lerp(control, t).lerp(control.lerp(target, t), t),
		0.0, 1.0, FLY_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	fly.tween_property(badge, "scale", Vector2.ONE * 1.6, FLY_TIME) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	fly.chain().tween_property(badge, "scale", Vector2.ONE, SETTLE_TIME) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await fly.finished
	if not is_instance_valid(badge): return

	badge.land()
	Utility.floating_text(self, Cons.DEBUFF_NAMES[type],
		badge.position + Vector2(0.0, BADGE_SIZE + 6.0), NAME_COLOR, 34, 30.0, 2.2)
	if duration <= 0.0:
		await get_tree().create_timer(INSTANT_SHOW_TIME).timeout
		_remove(badge)

func _on_debuff_ended(type: Cons.DEBUFF) -> void:
	for badge: DebuffBadge in _badges:
		if badge.type == type:
			_remove(badge)
			return

func _remove(badge: DebuffBadge) -> void:
	if not is_instance_valid(badge) or not badge in _badges: return
	_badges.erase(badge)
	var tween: Tween = badge.create_tween().set_parallel()
	tween.tween_property(badge, "scale", Vector2.ZERO, 0.3) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(badge, "modulate:a", 0.0, 0.3)
	tween.chain().tween_callback(badge.queue_free)
	_layout()

## Slide remaining badges into their slots (skipping one that's still in flight).
func _layout(skip: DebuffBadge = null) -> void:
	for i: int in _badges.size():
		var badge: DebuffBadge = _badges[i]
		if badge == skip or not badge.landed: continue
		badge.create_tween().tween_property(badge, "position", _slot(i), 0.25) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _slot(index: int) -> Vector2:
	return ROW_ORIGIN + Vector2((BADGE_SIZE + BADGE_GAP) * index, 0.0)

func _cauldron_mouth() -> Vector2:
	var scene: MainScene = Utility.scene
	var cauldron: Cauldron = scene.get_node_or_null("Cauldron") as Cauldron if scene else null
	if not cauldron: return Vector2.INF
	return cauldron.water_mask.get_global_rect().get_center()


class DebuffBadge extends Control:
	const BG_COLOR: Color = Color(0.98, 0.93, 0.82)
	const OUTLINE_COLOR: Color = Color(0.12, 0.08, 0.06)
	const RING_COLOR: Color = Color(0.85, 0.25, 0.25)
	const RING_WIDTH: float = 7.0
	const ICON_INSET: float = 14.0
	const WARN_TIME: float = 3.0

	var type: Cons.DEBUFF
	var duration: float = 0.0
	var time_left: float = 0.0
	var landed: bool = false
	var pulse: float = -1.0 ## 0..1 while the landing ring expands; <0 when idle.

	func setup(debuff: Cons.DEBUFF, seconds: float, badge_size: float) -> void:
		type = debuff
		duration = seconds
		time_left = seconds
		size = Vector2.ONE * badge_size
		pivot_offset = size * 0.5
		mouse_filter = Control.MOUSE_FILTER_PASS
		tooltip_text = Cons.DEBUFF_NAMES[debuff].trim_suffix("!")
		var icon: TextureRect = TextureRect.new()
		icon.texture = load(Cons.DEBUFF_TEXTURES[debuff])
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.position = Vector2.ONE * ICON_INSET
		icon.size = size - Vector2.ONE * ICON_INSET * 2.0
		add_child(icon)

	func land() -> void:
		landed = true
		var tween: Tween = create_tween()
		tween.tween_method(func(v: float) -> void:
			pulse = v
			queue_redraw(), 0.0, 1.0, 0.6).set_ease(Tween.EASE_OUT)
		tween.tween_callback(func() -> void:
			pulse = -1.0
			queue_redraw())

	func _process(delta: float) -> void:
		if duration <= 0.0 or not landed: return
		time_left = maxf(time_left - delta, 0.0)
		modulate.a = 1.0 if time_left > WARN_TIME else 0.55 + 0.45 * absf(cos(time_left * PI * 2.0))
		queue_redraw()

	func _draw() -> void:
		var center: Vector2 = size * 0.5
		var radius: float = size.x * 0.5
		draw_circle(center, radius, BG_COLOR)
		if duration > 0.0:
			var frac: float = time_left / duration
			draw_arc(center, radius - RING_WIDTH * 0.5, -PI / 2.0, -PI / 2.0 + TAU * frac, 64,
				RING_COLOR, RING_WIDTH, true)
		draw_arc(center, radius, 0.0, TAU, 64, OUTLINE_COLOR, 3.0, true)
		if pulse >= 0.0:
			var c: Color = RING_COLOR
			c.a = 1.0 - pulse
			draw_arc(center, radius * (1.0 + pulse * 0.9), 0.0, TAU, 64, c, 5.0 * (1.0 - pulse) + 1.0, true)
