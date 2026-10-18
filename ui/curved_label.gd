@tool
extends Control
class_name CurvedLabel

## Draws text along a curved centerline, one glyph at a time, so it follows
## a wavy banner (like the ingredient name tags). The curve is given in
## normalized coordinates (0..1) of this control's rect, so the label can be
## resized freely. The font size is picked automatically so the text fits.

@export var text: String = "":
	set(value):
		text = value
		queue_redraw()
@export var font: Font:
	set(value):
		font = value
		queue_redraw()
@export var font_color: Color = Color.BLACK:
	set(value):
		font_color = value
		queue_redraw()
@export var max_font_size: int = 48:
	set(value):
		max_font_size = value
		queue_redraw()
@export var min_font_size: int = 8:
	set(value):
		min_font_size = value
		queue_redraw()
## Usable horizontal span of the banner (normalized start, end).
@export var text_span: Vector2 = Vector2(0.1, 0.86):
	set(value):
		text_span = value
		queue_redraw()
## How tall a line of text may be, as a fraction of this control's height.
@export_range(0.05, 1.0) var band_height: float = 0.55:
	set(value):
		band_height = value
		queue_redraw()
## Nudges the text up (negative) or down (positive), in fractions of the height.
@export var vertical_offset: float = 0.0:
	set(value):
		vertical_offset = value
		queue_redraw()
## Centerline of the banner, normalized. Measured from textures/name_tag.png.
@export var centerline: PackedVector2Array = PackedVector2Array([
	Vector2(0.0, 0.56), Vector2(0.07, 0.54), Vector2(0.13, 0.51), Vector2(0.19, 0.52),
	Vector2(0.26, 0.56), Vector2(0.32, 0.60), Vector2(0.39, 0.64), Vector2(0.45, 0.68),
	Vector2(0.52, 0.70), Vector2(0.58, 0.70), Vector2(0.65, 0.69), Vector2(0.71, 0.67),
	Vector2(0.78, 0.63), Vector2(0.84, 0.56), Vector2(0.89, 0.48), Vector2(1.0, 0.30),
]):
	set(value):
		centerline = value
		queue_redraw()

func _ready() -> void:
	resized.connect(queue_redraw)

func _get_font() -> Font:
	return font if font else get_theme_default_font()

## Smooth (Catmull-Rom) height of the centerline at normalized x.
func _curve_y(nx: float) -> float:
	var pts: PackedVector2Array = centerline
	if pts.size() < 2: return 0.5
	if nx <= pts[0].x: return pts[0].y
	if nx >= pts[pts.size() - 1].x: return pts[pts.size() - 1].y
	var i: int = 0
	while i < pts.size() - 2 and nx > pts[i + 1].x:
		i += 1
	var p0: Vector2 = pts[maxi(i - 1, 0)]
	var p1: Vector2 = pts[i]
	var p2: Vector2 = pts[i + 1]
	var p3: Vector2 = pts[mini(i + 2, pts.size() - 1)]
	var t: float = (nx - p1.x) / maxf(p2.x - p1.x, 0.0001)
	var t2: float = t * t
	var t3: float = t2 * t
	return 0.5 * ((2.0 * p1.y) + (-p0.y + p2.y) * t \
		+ (2.0 * p0.y - 5.0 * p1.y + 4.0 * p2.y - p3.y) * t2 \
		+ (-p0.y + 3.0 * p1.y - 3.0 * p2.y + p3.y) * t3)

## Centerline point in pixels at pixel x.
func _point_at(x: float) -> Vector2:
	return Vector2(x, (_curve_y(x / size.x) + vertical_offset) * size.y)

func _angle_at(x: float) -> float:
	var a: Vector2 = _point_at(x - 2.0)
	var b: Vector2 = _point_at(x + 2.0)
	return (b - a).angle()

## Walks the curve from start_x and returns [centers, angles, end_x] for every glyph.
func _layout(f: Font, font_size: int, start_x: float) -> Array:
	var centers: PackedVector2Array = []
	var angles: PackedFloat32Array = []
	var x: float = start_x
	for i in text.length():
		var w: float = f.get_char_size(text.unicode_at(i), font_size).x
		var a: float = _angle_at(x + w * 0.5)
		var mid_x: float = x + w * 0.5 * cos(a)
		a = _angle_at(mid_x)
		centers.append(_point_at(mid_x))
		angles.append(a)
		x += w * cos(a)
	return [centers, angles, x]

func _fit_font_size(f: Font, span: float) -> int:
	var font_size: int = max_font_size
	while font_size > min_font_size:
		var length: float = _layout(f, font_size, 0.0)[2]
		if length <= span and f.get_height(font_size) <= band_height * size.y:
			break
		font_size -= 1
	return font_size

func _draw() -> void:
	var f: Font = _get_font()
	if text.is_empty() or f == null or size.x <= 0.0 or size.y <= 0.0: return
	var span_start: float = text_span.x * size.x
	var span: float = (text_span.y - text_span.x) * size.x
	var font_size: int = _fit_font_size(f, span)
	# Center the text along the span.
	var length: float = _layout(f, font_size, span_start)[2] - span_start
	var layout: Array = _layout(f, font_size, span_start + (span - length) * 0.5)
	var centers: PackedVector2Array = layout[0]
	var angles: PackedFloat32Array = layout[1]
	var ascent: float = f.get_ascent(font_size)
	var descent: float = f.get_descent(font_size)
	var baseline: float = (ascent - descent) * 0.5 # puts the line's middle on the curve
	for i in text.length():
		var ch: int = text.unicode_at(i)
		var w: float = f.get_char_size(ch, font_size).x
		draw_set_transform(centers[i], angles[i])
		f.draw_char(get_canvas_item(), Vector2(-w * 0.5, baseline), ch, font_size, font_color)
	draw_set_transform_matrix(Transform2D.IDENTITY)
