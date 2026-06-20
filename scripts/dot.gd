extends Area2D

const DESPAWN_MARGIN := 28.0
const MAX_LIFETIME := 11.0
const ARENA_RECT := Rect2(Vector2.ZERO, Vector2(1152.0, 648.0))
const TURN_RATE := 3.2
const TARGET_ACQUIRE_DISTANCE := 380.0
const TARGET_ESCAPE_DISTANCE := 520.0
const DEATH_MODE_FLEE_SPEED_MULTIPLIER := 0.45
const DEATH_MODE_MASS_DROP_FEEDBACK_SCRIPT := preload("res://scripts/death_mode_mass_drop_feedback.gd")

var target: Node2D
var speed: float = 125.0
var absorb_amount: float = 0.35
var initial_direction := Vector2.ZERO
var homing_delay: float = 0.0

var _lifetime := 0.0
var _has_entered_arena := false
var _direction := Vector2.ZERO
var _external_velocity := Vector2.ZERO
var _homing_enabled := false

@onready var visual: Polygon2D = $DotVisual


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if not initial_direction.is_zero_approx():
		_direction = initial_direction.normalized()
	elif target != null and is_instance_valid(target):
		# Dots begin aimed at the blob, but only actively steer once they get close.
		_direction = global_position.direction_to(target.global_position)
	else:
		_direction = Vector2.RIGHT.rotated(randf() * TAU)


func _physics_process(delta: float) -> void:
	_lifetime += delta
	if _lifetime > MAX_LIFETIME:
		queue_free()
		return

	if target != null and is_instance_valid(target):
		var distance_to_target := global_position.distance_to(target.global_position)
		var can_home := _lifetime >= homing_delay
		var is_death_mode_active: bool = _is_target_death_mode_active()

		if is_death_mode_active:
			_homing_enabled = false
			var flee_direction: Vector2 = target.global_position.direction_to(global_position)
			var flee_turn_amount: float = clampf(TURN_RATE * 1.8 * delta, 0.0, 1.0)
			_direction = _direction.lerp(flee_direction, flee_turn_amount).normalized()
		elif can_home and not _homing_enabled and distance_to_target <= TARGET_ACQUIRE_DISTANCE:
			_homing_enabled = true
		elif (not can_home and _homing_enabled) or (_homing_enabled and distance_to_target >= TARGET_ESCAPE_DISTANCE):
			_homing_enabled = false

		if _homing_enabled:
			var desired_direction := global_position.direction_to(target.global_position)
			var turn_amount := clampf(TURN_RATE * delta, 0.0, 1.0)
			_direction = _direction.lerp(desired_direction, turn_amount).normalized()
	elif _direction.is_zero_approx():
		queue_free()
		return

	var movement_speed: float = speed * DEATH_MODE_FLEE_SPEED_MULTIPLIER if _is_target_death_mode_active() else speed
	global_position += (_direction * movement_speed + _external_velocity) * delta
	_external_velocity = _external_velocity.move_toward(Vector2.ZERO, movement_speed * 2.8 * delta)

	if ARENA_RECT.has_point(global_position):
		_has_entered_arena = true
	elif _has_entered_arena and not ARENA_RECT.grow(DESPAWN_MARGIN).has_point(global_position):
		queue_free()


func _process(_delta: float) -> void:
	visual.color = Color(0, 0, 0, 1) if _is_target_death_mode_active() else Color(1, 1, 1, 1)


func apply_external_force(force: Vector2, delta: float) -> void:
	_external_velocity += force * delta


func _is_target_death_mode_active() -> bool:
	return target != null and is_instance_valid(target) and target.has_method("is_death_mode_active") and bool(target.call("is_death_mode_active"))


func _spawn_death_mode_mass_drop_feedback(origin: Vector2) -> void:
	var feedback := DEATH_MODE_MASS_DROP_FEEDBACK_SCRIPT.new() as Node2D
	var scene_root := get_tree().current_scene
	if scene_root != null:
		scene_root.add_child(feedback)
	else:
		get_parent().add_child(feedback)
	feedback.call("play", origin)


func _on_body_entered(body: Node) -> void:
	if body.has_method("absorb_dot"):
		var eaten_position := global_position
		if body.has_method("is_death_mode_active") and bool(body.call("is_death_mode_active")) and body.has_method("drop_mass_from_death_mode_dot"):
			body.call("drop_mass_from_death_mode_dot")
			_spawn_death_mode_mass_drop_feedback(eaten_position)
		else:
			body.call("absorb_dot", absorb_amount)
		queue_free()
