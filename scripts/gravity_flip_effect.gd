extends Node2D

const DURATION := 0.42
const LINE_COUNT := 18
const DOT_SIZE := 4.0

var _time := 0.0
var _active := false
var _origin := Vector2.ZERO


func _ready() -> void:
	visible = false
	set_process(false)


func play(origin: Vector2) -> void:
	_origin = origin
	_time = 0.0
	_active = true
	visible = true
	set_process(true)
	queue_redraw()


func stop() -> void:
	_active = false
	visible = false
	set_process(false)
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	if _time >= DURATION:
		stop()
		return
	queue_redraw()


func _draw() -> void:
	if not _active:
		return

	var progress: float = clampf(_time / DURATION, 0.0, 1.0)
	var alpha: float = 1.0 - progress
	var radius: float = lerpf(20.0, 520.0, progress)

	# A short-lived pixel distortion: horizontal slices offset around the blob.
	for line in LINE_COUNT:
		var y: float = _origin.y - 220.0 + float(line) * 26.0
		var wave: float = sin(float(line) * 1.8 + _time * 32.0)
		var half_width: float = radius * (0.35 + absf(wave) * 0.35)
		var x_offset: float = wave * 34.0 * alpha
		var color: Color = Color(1, 1, 1, 0.22 * alpha)
		_draw_dotted_line(Vector2(_origin.x - half_width + x_offset, y), Vector2(_origin.x + half_width + x_offset, y), color)

	# Inverting rings sell the gravity flip.
	for ring in 3:
		_draw_dotted_ring(radius * (0.45 + float(ring) * 0.24), Color(0.55, 0.8, 1.0, 0.34 * alpha))


func _draw_dotted_line(from: Vector2, to: Vector2, color: Color) -> void:
	var length: float = from.distance_to(to)
	var direction: Vector2 = from.direction_to(to)
	var distance: float = 0.0
	while distance <= length:
		var center: Vector2 = from + direction * distance
		draw_rect(Rect2(center - Vector2.ONE * DOT_SIZE * 0.5, Vector2.ONE * DOT_SIZE), color)
		distance += 14.0


func _draw_dotted_ring(radius: float, color: Color) -> void:
	var count: int = maxi(20, int(TAU * radius / 18.0))
	for index in count:
		var angle: float = (float(index) / float(count)) * TAU - _time * 8.0
		var center: Vector2 = _origin + Vector2.RIGHT.rotated(angle) * radius
		draw_rect(Rect2(center - Vector2.ONE * DOT_SIZE * 0.5, Vector2.ONE * DOT_SIZE), color)
