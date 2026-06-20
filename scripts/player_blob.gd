extends CharacterBody2D

const BASE_ACCELERATION := 1100.0
const BASE_DRAG := 5.0
const BASE_GRAVITY := 260.0
const GROWTH_PER_MASS := 0.055
const DEFEAT_MASS_THRESHOLD := 9.0
const RECOVERY_ACCEL_THRESHOLD := 360.0
const FLOOR_GRACE_TIME := 1.0
const BLOB_RADIUS := 16.0
const BLOB_POINT_COUNT := 16
const MASS_RELEASE_AMOUNT := 1.6
const DEATH_MODE_DURATION := 6.0

var mass: float = 1.0
var floor_contact_time: float = 0.0
var input_enabled: bool = true
var annihilation_perk_ready: bool = false
var mass_release_perk_ready: bool = false
var death_perk_ready: bool = false
var death_mode_time_remaining: float = 0.0
var gravity_direction: float = 1.0

var _start_position := Vector2.ZERO
var _wobble_time := 0.0
var _wobble_impulse := 0.0
var _last_velocity := Vector2.ZERO
var _vacuum_pull_source := Vector2.ZERO
var _vacuum_pull_strength := 0.0
var _is_consumed_by_warp := false

@onready var blob_visual: Polygon2D = $BlobVisual


func _ready() -> void:
	_start_position = global_position
	_update_visual_scale()
	_update_blob_visual(0.0, Vector2.ZERO)


func _physics_process(delta: float) -> void:
	_wobble_time += delta
	_vacuum_pull_strength = move_toward(_vacuum_pull_strength, 0.0, delta * 2.6)
	if death_mode_time_remaining > 0.0:
		death_mode_time_remaining = maxf(0.0, death_mode_time_remaining - delta)

	if not input_enabled:
		velocity = velocity.move_toward(Vector2.ZERO, BASE_DRAG * 100.0 * delta)
		move_and_slide()
		_update_blob_visual(delta, Vector2.ZERO)
		return

	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var control_factor := 1.0 / sqrt(1.0 + (mass - 1.0) * 0.45)
	var gravity_factor := 1.0 + (mass - 1.0) * 0.035

	velocity += input_vector * BASE_ACCELERATION * control_factor * delta
	velocity.y += BASE_GRAVITY * gravity_factor * gravity_direction * delta

	var drag_strength := BASE_DRAG if input_vector.is_zero_approx() else BASE_DRAG * 0.35
	velocity = velocity.lerp(Vector2.ZERO, minf(drag_strength * delta, 1.0))

	move_and_slide()

	var is_on_gravity_surface: bool = is_on_floor() if gravity_direction > 0.0 else is_on_ceiling()
	if is_on_gravity_surface:
		floor_contact_time += delta
		_wobble_impulse = maxf(_wobble_impulse, minf(absf(velocity.y) / 850.0, 0.45))
	else:
		floor_contact_time = 0.0

	var acceleration_delta := (velocity - _last_velocity).length()
	_wobble_impulse = maxf(_wobble_impulse, minf(acceleration_delta / 900.0, 0.28))
	_last_velocity = velocity
	_update_blob_visual(delta, input_vector)


func absorb_dot(amount: float = 1.0) -> void:
	if not is_death_mode_active():
		mass += amount
	_wobble_impulse = minf(_wobble_impulse + 0.38, 1.15)
	_update_visual_scale()


func grant_annihilation_perk() -> void:
	annihilation_perk_ready = true
	_wobble_impulse = minf(_wobble_impulse + 0.5, 1.15)


func has_annihilation_perk() -> bool:
	return annihilation_perk_ready


func consume_annihilation_perk() -> bool:
	if not annihilation_perk_ready:
		return false
	annihilation_perk_ready = false
	return true


func grant_mass_release_perk() -> void:
	mass_release_perk_ready = true
	_wobble_impulse = minf(_wobble_impulse + 0.35, 1.15)


func has_mass_release_perk() -> bool:
	return mass_release_perk_ready


func consume_mass_release_perk() -> bool:
	if not mass_release_perk_ready:
		return false
	mass_release_perk_ready = false
	return true


func grant_death_perk() -> void:
	death_perk_ready = true
	_wobble_impulse = minf(_wobble_impulse + 0.45, 1.15)


func has_death_perk() -> bool:
	return death_perk_ready


func consume_death_perk() -> bool:
	if not death_perk_ready:
		return false
	death_perk_ready = false
	return true


func activate_death_mode() -> void:
	death_mode_time_remaining = DEATH_MODE_DURATION
	_wobble_impulse = minf(_wobble_impulse + 0.65, 1.15)


func is_death_mode_active() -> bool:
	return death_mode_time_remaining > 0.0


func set_death_mode_visual_active(active: bool) -> void:
	blob_visual.color = Color(0, 0, 0, 1) if active else Color(1, 1, 1, 1)


func release_mass() -> void:
	mass = maxf(1.0, mass - MASS_RELEASE_AMOUNT)
	_wobble_impulse = minf(_wobble_impulse + 0.45, 1.15)
	_update_visual_scale()


func drop_mass_from_death_mode_dot() -> void:
	mass = maxf(1.0, mass - MASS_RELEASE_AMOUNT)
	_wobble_impulse = minf(_wobble_impulse + 0.45, 1.15)
	_update_visual_scale()


func toggle_gravity() -> void:
	gravity_direction *= -1.0
	_wobble_impulse = minf(_wobble_impulse + 0.55, 1.15)
	velocity.y = -velocity.y * 0.55


func is_gravity_reversed() -> bool:
	return gravity_direction < 0.0


func reset_blob(position_value: Vector2) -> void:
	mass = 1.0
	floor_contact_time = 0.0
	input_enabled = true
	_is_consumed_by_warp = false
	_vacuum_pull_strength = 0.0
	annihilation_perk_ready = false
	mass_release_perk_ready = false
	death_perk_ready = false
	death_mode_time_remaining = 0.0
	gravity_direction = 1.0
	velocity = Vector2.ZERO
	_last_velocity = Vector2.ZERO
	_wobble_impulse = 0.0
	global_position = position_value
	blob_visual.visible = true
	_update_visual_scale()
	set_death_mode_visual_active(false)
	_update_blob_visual(0.0, Vector2.ZERO)


func set_input_enabled(enabled: bool) -> void:
	input_enabled = enabled


func apply_external_force(force: Vector2, delta: float) -> void:
	velocity += force * delta
	_wobble_impulse = maxf(_wobble_impulse, minf(force.length() / 2200.0, 0.32))


func set_vacuum_pull(source_position: Vector2, strength: float) -> void:
	_vacuum_pull_source = source_position
	_vacuum_pull_strength = maxf(_vacuum_pull_strength, clampf(strength, 0.0, 1.0))
	_wobble_impulse = maxf(_wobble_impulse, lerpf(0.18, 0.78, _vacuum_pull_strength))


func consume_by_warp() -> void:
	_is_consumed_by_warp = true
	input_enabled = false
	velocity = Vector2.ZERO
	blob_visual.visible = false


func collapse_for_game_over() -> void:
	input_enabled = false
	velocity = Vector2.ZERO
	blob_visual.visible = false


func is_defeated() -> bool:
	var is_on_gravity_surface: bool = is_on_floor() if gravity_direction > 0.0 else is_on_ceiling()
	if not is_on_gravity_surface or floor_contact_time < FLOOR_GRACE_TIME:
		return false

	var recovery_acceleration := BASE_ACCELERATION / sqrt(1.0 + (mass - 1.0) * 0.45) - BASE_GRAVITY * (1.0 + (mass - 1.0) * 0.035)
	return mass >= DEFEAT_MASS_THRESHOLD and recovery_acceleration < RECOVERY_ACCEL_THRESHOLD


func _update_visual_scale() -> void:
	scale = Vector2.ONE * (1.0 + (mass - 1.0) * GROWTH_PER_MASS)


func _update_blob_visual(delta: float, input_vector: Vector2) -> void:
	if _is_consumed_by_warp:
		blob_visual.visible = false
		return

	_wobble_impulse = move_toward(_wobble_impulse, 0.06 if velocity.length() > 20.0 else 0.0, delta * 1.8)

	var movement_direction := velocity.normalized() if velocity.length() > 1.0 else input_vector.normalized()
	var movement_angle := movement_direction.angle() if not movement_direction.is_zero_approx() else 0.0
	var vacuum_direction := to_local(_vacuum_pull_source).normalized()
	var vacuum_angle := vacuum_direction.angle() if not vacuum_direction.is_zero_approx() else movement_angle
	var stretch_angle := lerp_angle(movement_angle, vacuum_angle, _vacuum_pull_strength)
	var speed_stretch := clampf(velocity.length() / 850.0, 0.0, 0.22)
	var vacuum_stretch := _vacuum_pull_strength * 0.85
	var shrink := lerpf(1.0, 0.54, _vacuum_pull_strength)
	var wobble_amount := 0.06 + _wobble_impulse * 0.22 + _vacuum_pull_strength * 0.18
	var points := PackedVector2Array()

	for index in BLOB_POINT_COUNT:
		var angle := (float(index) / float(BLOB_POINT_COUNT)) * PI * 2.0
		var axis_stretch := cos(2.0 * (angle - stretch_angle)) * (speed_stretch + vacuum_stretch)
		var directional_pull := maxf(cos(angle - vacuum_angle), 0.0) * _vacuum_pull_strength * 0.7
		var ripple := sin(_wobble_time * 8.0 + float(index) * 1.35) * wobble_amount
		var secondary_ripple := sin(_wobble_time * 5.0 - float(index) * 0.9) * wobble_amount * 0.45
		var radius := BLOB_RADIUS * shrink * (1.0 + axis_stretch + directional_pull + ripple + secondary_ripple)
		points.append(Vector2(cos(angle), sin(angle)) * maxf(radius, BLOB_RADIUS * 0.18))

	blob_visual.polygon = points
	var visual_color := blob_visual.color
	visual_color.a = lerpf(1.0, 0.28, _vacuum_pull_strength)
	blob_visual.color = visual_color
