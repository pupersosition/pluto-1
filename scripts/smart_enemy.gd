extends Area2D

const DOT_SCENE := preload("res://scenes/dot.tscn")
const DESPAWN_MARGIN := 40.0
const MAX_LIFETIME := 16.0
const ARENA_RECT := Rect2(Vector2.ZERO, Vector2(1152.0, 648.0))
const TURN_RATE := 7.2
const CLOUD_MIN_WAIT := 3.0
const CLOUD_MAX_WAIT := 6.5
const CLOUD_MIN_COUNT := 5
const CLOUD_MAX_COUNT := 9
const DEATH_MODE_FLEE_SPEED_MULTIPLIER := 0.55

var target: Node2D
var speed: float = 165.0
var absorb_amount: float = 0.75

var _lifetime := 0.0
var _has_entered_arena := false
var _direction := Vector2.ZERO
var _external_velocity := Vector2.ZERO
var _cloud_wait := 4.0
var _cloud_timer := 0.0
var _rng := RandomNumberGenerator.new()

@onready var visual: Polygon2D = $DotVisual


func _ready() -> void:
	_rng.randomize()
	body_entered.connect(_on_body_entered)
	_cloud_wait = _rng.randf_range(CLOUD_MIN_WAIT, CLOUD_MAX_WAIT)

	if target != null and is_instance_valid(target):
		_direction = global_position.direction_to(target.global_position)
	else:
		_direction = Vector2.RIGHT.rotated(randf() * TAU)


func _physics_process(delta: float) -> void:
	_lifetime += delta
	if _lifetime > MAX_LIFETIME:
		queue_free()
		return

	_cloud_timer += delta
	if _cloud_timer >= _cloud_wait:
		_cloud_timer = 0.0
		_cloud_wait = _rng.randf_range(CLOUD_MIN_WAIT, CLOUD_MAX_WAIT)
		_spawn_white_cloud()

	if target != null and is_instance_valid(target):
		var desired_direction: Vector2 = target.global_position.direction_to(global_position) if _is_target_death_mode_active() else global_position.direction_to(target.global_position)
		var turn_amount: float = clampf(TURN_RATE * delta, 0.0, 1.0)
		_direction = _direction.lerp(desired_direction, turn_amount).normalized()
	elif _direction.is_zero_approx():
		queue_free()
		return

	var movement_speed: float = speed * DEATH_MODE_FLEE_SPEED_MULTIPLIER if _is_target_death_mode_active() else speed
	global_position += (_direction * movement_speed + _external_velocity) * delta
	_external_velocity = _external_velocity.move_toward(Vector2.ZERO, movement_speed * 2.8 * delta)
	rotation = _direction.angle()

	if ARENA_RECT.has_point(global_position):
		_has_entered_arena = true
	elif _has_entered_arena and not ARENA_RECT.grow(DESPAWN_MARGIN).has_point(global_position):
		queue_free()


func _process(delta: float) -> void:
	var pulse: float = (sin(_lifetime * 9.0) + 1.0) * 0.5
	visual.scale = Vector2.ONE * (1.0 + pulse * 0.1)
	visual.color = Color(0, 0, 0, 1) if _is_target_death_mode_active() else Color(1, 0.08, 0.08, 1)


func apply_external_force(force: Vector2, delta: float) -> void:
	_external_velocity += force * delta


func _is_target_death_mode_active() -> bool:
	return target != null and is_instance_valid(target) and target.has_method("is_death_mode_active") and bool(target.call("is_death_mode_active"))


func _spawn_white_cloud() -> void:
	if target == null or not is_instance_valid(target) or get_parent() == null:
		return

	var count: int = _rng.randi_range(CLOUD_MIN_COUNT, CLOUD_MAX_COUNT)
	for index in count:
		var dot := DOT_SCENE.instantiate() as Node2D
		var angle: float = (float(index) / float(count)) * TAU + _rng.randf_range(-0.35, 0.35)
		var shot_direction: Vector2 = Vector2.RIGHT.rotated(angle)
		var distance: float = _rng.randf_range(14.0, 24.0)
		dot.global_position = global_position + shot_direction * distance
		dot.scale = Vector2.ONE * _rng.randf_range(0.55, 0.75)
		dot.set("target", target)
		dot.set("initial_direction", shot_direction)
		dot.set("homing_delay", _rng.randf_range(0.65, 1.05))
		dot.set("speed", _rng.randf_range(185.0, 245.0))
		dot.set("absorb_amount", 0.18)
		get_parent().add_child(dot)


func _on_body_entered(body: Node) -> void:
	if body.has_method("absorb_dot"):
		body.call("absorb_dot", absorb_amount)
		queue_free()
