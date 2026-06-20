extends Area2D

const BOB_HEIGHT := 4.0
const BOB_SPEED := 2.6
const RAY_COUNT := 4
const RAY_START := 16.0
const RAY_END := 38.0
const RAY_DOT_SPACING := 7.0
const DOT_SIZE := 3.0
const PIXEL := 4.0
const MAGNET_RADIUS := 70.0
const COLLECT_RADIUS := 18.0
const MAGNET_SPEED := 420.0
const STAR_COLOR := Color(0.35, 0.9, 1.0, 1.0)

var _time := 0.0
var _base_position := Vector2.ZERO
var _magnet_target: Node2D


func _ready() -> void:
	_base_position = position
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta
	_update_magnet_pickup(delta)
	if _magnet_target == null:
		position.y = _base_position.y + sin(_time * BOB_SPEED) * BOB_HEIGHT
	queue_redraw()


func _draw() -> void:
	_draw_dotted_diamond_rays()
	_draw_hollow_pixel_star()


func _draw_dotted_diamond_rays() -> void:
	var ray_phase: float = fmod(_time * 16.0, RAY_DOT_SPACING)
	var pulse: float = (sin(_time * 6.0) + 1.0) * 0.5

	for ray_index in RAY_COUNT:
		var angle: float = PI * 0.25 + (float(ray_index) / float(RAY_COUNT)) * TAU - _time * 0.35
		var direction: Vector2 = Vector2.RIGHT.rotated(angle)
		var distance: float = RAY_START + ray_phase

		while distance <= RAY_END:
			var distance_alpha: float = 1.0 - ((distance - RAY_START) / (RAY_END - RAY_START))
			var alpha: float = clampf(0.18 + distance_alpha * 0.52 + pulse * 0.18, 0.0, 0.85)
			var center: Vector2 = direction * distance
			draw_rect(Rect2(center - Vector2.ONE * DOT_SIZE * 0.5, Vector2.ONE * DOT_SIZE), Color(STAR_COLOR.r, STAR_COLOR.g, STAR_COLOR.b, alpha))
			distance += RAY_DOT_SPACING


func _draw_hollow_pixel_star() -> void:
	var pulse: float = (sin(_time * 8.0) + 1.0) * 0.5
	var bright: Color = STAR_COLOR
	var soft: Color = Color(STAR_COLOR.r, STAR_COLOR.g, STAR_COLOR.b, 0.35 + pulse * 0.25)

	# Diamond-like outer glow, intentionally unlike the annihilation plus-star.
	_draw_pixel(0, -4, soft)
	_draw_pixel(1, -3, soft)
	_draw_pixel(2, -2, soft)
	_draw_pixel(3, -1, soft)
	_draw_pixel(4, 0, soft)
	_draw_pixel(3, 1, soft)
	_draw_pixel(2, 2, soft)
	_draw_pixel(1, 3, soft)
	_draw_pixel(0, 4, soft)
	_draw_pixel(-1, 3, soft)
	_draw_pixel(-2, 2, soft)
	_draw_pixel(-3, 1, soft)
	_draw_pixel(-4, 0, soft)
	_draw_pixel(-3, -1, soft)
	_draw_pixel(-2, -2, soft)
	_draw_pixel(-1, -3, soft)

	# Hollow angular core.
	_draw_pixel(0, -3, bright)
	_draw_pixel(1, -2, bright)
	_draw_pixel(2, -1, bright)
	_draw_pixel(3, 0, bright)
	_draw_pixel(2, 1, bright)
	_draw_pixel(1, 2, bright)
	_draw_pixel(0, 3, bright)
	_draw_pixel(-1, 2, bright)
	_draw_pixel(-2, 1, bright)
	_draw_pixel(-3, 0, bright)
	_draw_pixel(-2, -1, bright)
	_draw_pixel(-1, -2, bright)


func _draw_pixel(x: int, y: int, color: Color) -> void:
	draw_rect(Rect2(Vector2(x, y) * PIXEL - Vector2.ONE * PIXEL * 0.5, Vector2.ONE * PIXEL), color)


func apply_warp_suction(warp_position: Vector2, pull_amount: float, delta: float) -> void:
	var pull_direction := global_position.direction_to(warp_position)
	var pulled_global_position := global_position + pull_direction * pull_amount * delta
	var parent_node: Node = get_parent()
	if parent_node is Node2D:
		var parent_2d := parent_node as Node2D
		_base_position = parent_2d.to_local(pulled_global_position)
	else:
		_base_position = pulled_global_position
	position = _base_position


func _update_magnet_pickup(delta: float) -> void:
	if _magnet_target == null or not is_instance_valid(_magnet_target):
		_magnet_target = _find_magnet_target()
	if _magnet_target == null:
		return

	var distance := global_position.distance_to(_magnet_target.global_position)
	if distance > MAGNET_RADIUS:
		_magnet_target = null
		return
	if distance <= COLLECT_RADIUS:
		_collect(_magnet_target)
		return

	var pulled_global_position := global_position.move_toward(_magnet_target.global_position, MAGNET_SPEED * delta)
	var parent_node: Node = get_parent()
	if parent_node is Node2D:
		var parent_2d := parent_node as Node2D
		_base_position = parent_2d.to_local(pulled_global_position)
	else:
		_base_position = pulled_global_position
	position = _base_position


func _find_magnet_target() -> Node2D:
	var player_node := get_tree().get_first_node_in_group("player")
	if player_node is Node2D:
		var player_2d := player_node as Node2D
		if global_position.distance_to(player_2d.global_position) <= MAGNET_RADIUS:
			return player_2d
	return null


func _collect(body: Node) -> void:
	if body.has_method("grant_mass_release_perk"):
		body.call("grant_mass_release_perk")
		queue_free()


func _on_body_entered(body: Node) -> void:
	_collect(body)
