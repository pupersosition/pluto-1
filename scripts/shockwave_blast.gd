extends Node2D

const MAX_RADIUS := 820.0
const DURATION := 0.62
const DOT_SPACING := 15.0
const BORDER_DOT_SIZE := 4.0
const RAY_DOT_SIZE := 3.0
const RADIAL_COUNT := 24

var _origin := Vector2.ZERO
var _time := 0.0
var _active := false


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
	var inverse_progress: float = 1.0 - progress
	var eased: float = 1.0 - inverse_progress * inverse_progress * inverse_progress
	var radius: float = lerpf(16.0, MAX_RADIUS, eased)
	var alpha: float = 1.0 - progress
	var core_color: Color = Color(1, 1, 1, 0.9 * alpha)
	var faint_color: Color = Color(1, 1, 1, 0.32 * alpha)

	_draw_dotted_border(radius, core_color)
	_draw_radial_dotted_lines(radius, faint_color)


func _draw_dotted_border(radius: float, color: Color) -> void:
	var circumference: float = TAU * radius
	var dot_count: int = maxi(18, int(circumference / DOT_SPACING))
	var spin: float = _time * 4.5

	for index in dot_count:
		var angle: float = (float(index) / float(dot_count)) * TAU + spin
		var center: Vector2 = _origin + Vector2.RIGHT.rotated(angle) * radius
		draw_rect(Rect2(center - Vector2.ONE * BORDER_DOT_SIZE * 0.5, Vector2.ONE * BORDER_DOT_SIZE), color)


func _draw_radial_dotted_lines(radius: float, color: Color) -> void:
	var offset: float = fmod(_time * 220.0, DOT_SPACING)

	for ray_index in RADIAL_COUNT:
		var angle: float = (float(ray_index) / float(RADIAL_COUNT)) * TAU
		var direction: Vector2 = Vector2.RIGHT.rotated(angle)
		var distance: float = 24.0 + offset

		while distance < radius:
			var distance_alpha: float = 1.0 - distance / radius
			var dot_color: Color = Color(color.r, color.g, color.b, color.a * distance_alpha)
			var center: Vector2 = _origin + direction * distance
			draw_rect(Rect2(center - Vector2.ONE * RAY_DOT_SIZE * 0.5, Vector2.ONE * RAY_DOT_SIZE), dot_color)
			distance += DOT_SPACING
