extends Area2D

const PIXEL := 4.0
const RING_DOT_COUNT := 18
const RING_RADIUS := 24.0
const OUTER_RING_RADIUS := 34.0
const MAGNET_RADIUS := 70.0
const COLLECT_RADIUS := 18.0
const MAGNET_SPEED := 420.0

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
		position.y = _base_position.y + sin(_time * 2.4) * 4.0
	queue_redraw()


func _draw() -> void:
	_draw_distorted_rings()
	_draw_black_hole_core()


func _draw_distorted_rings() -> void:
	var pulse: float = (sin(_time * 5.0) + 1.0) * 0.5
	for index in RING_DOT_COUNT:
		var angle: float = (float(index) / float(RING_DOT_COUNT)) * TAU + _time * 1.3
		var wobble: float = sin(_time * 4.0 + float(index) * 1.7) * 4.0
		var radius: float = RING_RADIUS + wobble
		var center: Vector2 = Vector2.RIGHT.rotated(angle) * Vector2(radius * 1.45, radius * 0.55)
		_draw_pixel(center, PIXEL, Color(1, 1, 1, 0.78 + pulse * 0.18))

	for index in 12:
		var angle: float = (float(index) / 12.0) * TAU - _time * 0.75
		var center: Vector2 = Vector2.RIGHT.rotated(angle) * Vector2(OUTER_RING_RADIUS * 1.25, OUTER_RING_RADIUS * 0.75)
		_draw_pixel(center, PIXEL * 0.75, Color(0.45, 0.7, 1.0, 0.34))


func _draw_black_hole_core() -> void:
	# White rim makes the black center readable against the black arena.
	var rim_cells: Array[Vector2i] = [
		Vector2i(-2, -2), Vector2i(-1, -2), Vector2i(0, -2), Vector2i(1, -2), Vector2i(2, -2),
		Vector2i(-3, -1), Vector2i(-2, -1), Vector2i(2, -1), Vector2i(3, -1),
		Vector2i(-3, 0), Vector2i(3, 0),
		Vector2i(-3, 1), Vector2i(-2, 1), Vector2i(2, 1), Vector2i(3, 1),
		Vector2i(-2, 2), Vector2i(-1, 2), Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2)
	]
	var core_cells: Array[Vector2i] = [
		Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
		Vector2i(-2, 0), Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
		Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)
	]

	for cell in rim_cells:
		_draw_pixel(Vector2(cell) * PIXEL, PIXEL, Color(1, 1, 1, 0.95))
	for cell in core_cells:
		_draw_pixel(Vector2(cell) * PIXEL, PIXEL, Color(0, 0, 0, 1))


func _draw_pixel(center: Vector2, pixel_size: float, color: Color) -> void:
	draw_rect(Rect2(center - Vector2.ONE * pixel_size * 0.5, Vector2.ONE * pixel_size), color)


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
	if body.has_method("toggle_gravity"):
		body.call("toggle_gravity")
		queue_free()


func _on_body_entered(body: Node) -> void:
	_collect(body)
