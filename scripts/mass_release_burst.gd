extends Node2D

const DURATION := 0.55
const PARTICLE_COUNT := 34
const MIN_SPEED := 70.0
const MAX_SPEED := 210.0
const DOT_SIZE := 4.0

var _origin := Vector2.ZERO
var _time := 0.0
var _active := false
var _directions: Array[Vector2] = []
var _speeds: Array[float] = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	visible = false
	set_process(false)


func play(origin: Vector2) -> void:
	_origin = origin
	_time = 0.0
	_active = true
	_directions.clear()
	_speeds.clear()

	for index in PARTICLE_COUNT:
		var angle: float = (float(index) / float(PARTICLE_COUNT)) * TAU + _rng.randf_range(-0.18, 0.18)
		_directions.append(Vector2.RIGHT.rotated(angle))
		_speeds.append(_rng.randf_range(MIN_SPEED, MAX_SPEED))

	visible = true
	set_process(true)
	queue_redraw()


func stop() -> void:
	_active = false
	visible = false
	set_process(false)
	queue_redraw()


func _process(delta: float) -> void:
	if not _active:
		return

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
	var color: Color = Color(1, 1, 1, 0.75 * alpha)

	for index in _directions.size():
		var distance: float = _speeds[index] * _time
		var center: Vector2 = _origin + _directions[index] * distance
		draw_rect(Rect2(center - Vector2.ONE * DOT_SIZE * 0.5, Vector2.ONE * DOT_SIZE), color)
