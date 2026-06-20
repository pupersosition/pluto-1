extends Area2D

const BOB_HEIGHT := 4.0
const BOB_SPEED := 2.8
const PIXEL := 4.0

var _time := 0.0
var _base_position := Vector2.ZERO


func _ready() -> void:
	_base_position = position
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta
	position.y = _base_position.y + sin(_time * BOB_SPEED) * BOB_HEIGHT
	queue_redraw()


func _draw() -> void:
	_draw_aura()
	_draw_skull()


func _draw_aura() -> void:
	var pulse: float = (sin(_time * 7.0) + 1.0) * 0.5
	for ray in 10:
		var direction: Vector2 = Vector2.RIGHT.rotated((float(ray) / 10.0) * TAU - _time * 0.5)
		for dot in 3:
			var distance: float = 22.0 + float(dot) * 9.0 + fmod(_time * 12.0, 9.0)
			_draw_pixel(direction * distance, maxf(2.0, PIXEL * 0.65), Color(1, 1, 1, 0.24 + pulse * 0.18))


func _draw_skull() -> void:
	var white := Color(1, 1, 1, 1)
	var soft := Color(1, 1, 1, 0.38)
	var cells: Array[Vector2i] = [
		Vector2i(-2, -3), Vector2i(-1, -3), Vector2i(0, -3), Vector2i(1, -3), Vector2i(2, -3),
		Vector2i(-3, -2), Vector2i(-2, -2), Vector2i(-1, -2), Vector2i(0, -2), Vector2i(1, -2), Vector2i(2, -2), Vector2i(3, -2),
		Vector2i(-3, -1), Vector2i(-2, -1), Vector2i(0, -1), Vector2i(2, -1), Vector2i(3, -1),
		Vector2i(-3, 0), Vector2i(-2, 0), Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0),
		Vector2i(-2, 1), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1),
		Vector2i(-2, 2), Vector2i(0, 2), Vector2i(2, 2),
		Vector2i(-2, 3), Vector2i(-1, 3), Vector2i(1, 3), Vector2i(2, 3)
	]
	var holes: Array[Vector2i] = [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(0, 1)]

	for cell in cells:
		_draw_pixel(Vector2(cell) * PIXEL * 1.2, PIXEL * 1.2, soft)
	for cell in cells:
		_draw_pixel(Vector2(cell) * PIXEL, PIXEL, white)
	for cell in holes:
		_draw_pixel(Vector2(cell) * PIXEL, PIXEL, Color(0, 0, 0, 1))


func _draw_pixel(center: Vector2, pixel_size: float, color: Color) -> void:
	draw_rect(Rect2(center - Vector2.ONE * pixel_size * 0.5, Vector2.ONE * pixel_size), color)


func _on_body_entered(body: Node) -> void:
	if body.has_method("grant_death_perk"):
		body.call("grant_death_perk")
		queue_free()
