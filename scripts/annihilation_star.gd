extends Area2D

const BOB_HEIGHT := 5.0
const BOB_SPEED := 3.2
const RAY_COUNT := 8
const RAY_START := 18.0
const RAY_END := 44.0
const RAY_DOT_SPACING := 8.0
const DOT_SIZE := 3.0
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
	_draw_dotted_rays()
	_draw_pixel_star()


func _draw_dotted_rays() -> void:
	var ray_phase: float = fmod(_time * 18.0, RAY_DOT_SPACING)
	var pulse: float = (sin(_time * 7.0) + 1.0) * 0.5

	for ray_index in RAY_COUNT:
		var angle: float = (float(ray_index) / float(RAY_COUNT)) * TAU + _time * 0.25
		var direction: Vector2 = Vector2.RIGHT.rotated(angle)
		var distance: float = RAY_START + ray_phase

		while distance <= RAY_END:
			var distance_alpha: float = 1.0 - ((distance - RAY_START) / (RAY_END - RAY_START))
			var alpha: float = clampf(0.18 + distance_alpha * 0.58 + pulse * 0.2, 0.0, 0.9)
			var center: Vector2 = direction * distance
			draw_rect(Rect2(center - Vector2.ONE * DOT_SIZE * 0.5, Vector2.ONE * DOT_SIZE), Color(1, 1, 1, alpha))
			distance += RAY_DOT_SPACING


func _draw_pixel_star() -> void:
	var pulse: float = (sin(_time * 9.0) + 1.0) * 0.5
	var bright: Color = Color(1, 1, 1, 1)
	var soft: Color = Color(1, 1, 1, 0.45 + pulse * 0.25)

	# Soft white pixel halo.
	_draw_pixel(0, -4, soft)
	_draw_pixel(0, 4, soft)
	_draw_pixel(-4, 0, soft)
	_draw_pixel(4, 0, soft)
	_draw_pixel(0, -3, soft)
	_draw_pixel(0, 3, soft)
	_draw_pixel(-3, 0, soft)
	_draw_pixel(3, 0, soft)

	# Crisp pixel-art star core.
	_draw_pixel(0, -3, bright)
	_draw_pixel(0, -2, bright)
	_draw_pixel(-1, -1, bright)
	_draw_pixel(0, -1, bright)
	_draw_pixel(1, -1, bright)
	_draw_pixel(-3, 0, bright)
	_draw_pixel(-2, 0, bright)
	_draw_pixel(-1, 0, bright)
	_draw_pixel(0, 0, bright)
	_draw_pixel(1, 0, bright)
	_draw_pixel(2, 0, bright)
	_draw_pixel(3, 0, bright)
	_draw_pixel(-1, 1, bright)
	_draw_pixel(0, 1, bright)
	_draw_pixel(1, 1, bright)
	_draw_pixel(0, 2, bright)
	_draw_pixel(0, 3, bright)


func _draw_pixel(x: int, y: int, color: Color) -> void:
	draw_rect(Rect2(Vector2(x, y) * PIXEL - Vector2.ONE * PIXEL * 0.5, Vector2.ONE * PIXEL), color)


func _on_body_entered(body: Node) -> void:
	if body.has_method("grant_annihilation_perk"):
		body.call("grant_annihilation_perk")
		queue_free()
