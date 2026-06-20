extends Control

const PIXEL := 4.0

var _time := 0.0


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	_draw_corner_stars()
	_draw_blob(Vector2(size.x * 0.5, 76.0), 1.0 + sin(_time * 2.5) * 0.035)
	_draw_dots()


func _draw_blob(center: Vector2, wobble: float) -> void:
	var white := Color(1, 1, 1, 1)
	var soft := Color(1, 1, 1, 0.28)
	var cells: Array[Vector2i] = [
		Vector2i(-2, -3), Vector2i(-1, -3), Vector2i(0, -3), Vector2i(1, -3),
		Vector2i(-3, -2), Vector2i(-2, -2), Vector2i(-1, -2), Vector2i(0, -2), Vector2i(1, -2), Vector2i(2, -2),
		Vector2i(-3, -1), Vector2i(-2, -1), Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(2, -1), Vector2i(3, -1),
		Vector2i(-4, 0), Vector2i(-3, 0), Vector2i(-2, 0), Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0),
		Vector2i(-3, 1), Vector2i(-2, 1), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1),
		Vector2i(-2, 2), Vector2i(-1, 2), Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2),
		Vector2i(-1, 3), Vector2i(0, 3), Vector2i(1, 3)
	]

	for cell in cells:
		_draw_pixel(center + Vector2(cell) * PIXEL * 1.25 * wobble, PIXEL * 1.25, soft)
	for cell in cells:
		_draw_pixel(center + Vector2(cell) * PIXEL * wobble, PIXEL, white)


func _draw_corner_stars() -> void:
	_draw_star(Vector2(330, 84), Color(1, 1, 1, 0.85), 0.75)
	_draw_star(Vector2(820, 92), Color(0.35, 0.9, 1, 0.85), 0.75)
	_draw_star(Vector2(228, 454), Color(1, 1, 1, 0.55), 0.55)
	_draw_star(Vector2(925, 442), Color(0.35, 0.9, 1, 0.55), 0.55)


func _draw_star(center: Vector2, color: Color, scale_value: float) -> void:
	var pulse: float = (sin(_time * 5.0 + center.x * 0.01) + 1.0) * 0.5
	var p: float = PIXEL * scale_value
	var star_cells: Array[Vector2i] = [Vector2i(0, -3), Vector2i(0, -2), Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(-3, 0), Vector2i(-2, 0), Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 2), Vector2i(0, 3)]
	for cell in star_cells:
		_draw_pixel(center + Vector2(cell) * p, p, Color(color.r, color.g, color.b, color.a + pulse * 0.15))

	for ray in 8:
		var direction := Vector2.RIGHT.rotated(float(ray) / 8.0 * TAU + _time * 0.35)
		for dot in 3:
			var distance: float = 20.0 * scale_value + float(dot) * 10.0 * scale_value + fmod(_time * 10.0, 10.0)
			_draw_pixel(center + direction * distance, maxf(2.0, p * 0.65), Color(color.r, color.g, color.b, color.a * 0.42))


func _draw_dots() -> void:
	for index in 18:
		var x: float = 130.0 + float(index) * 52.0
		var y: float = 545.0 + sin(_time * 2.0 + float(index) * 0.7) * 10.0
		var alpha: float = 0.18 + float(index % 3) * 0.08
		_draw_pixel(Vector2(x, y), 3.0, Color(1, 1, 1, alpha))


func _draw_pixel(center: Vector2, pixel_size: float, color: Color) -> void:
	draw_rect(Rect2(center - Vector2.ONE * pixel_size * 0.5, Vector2.ONE * pixel_size), color)
