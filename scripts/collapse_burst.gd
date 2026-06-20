extends Node2D

const PARTICLE_COUNT := 42
const BURST_DURATION := 0.72
const SQUASH_DURATION := 0.12
const PIXEL_SIZE := 5.0
const FLOOR_DRIFT := 120.0

var _is_playing := false
var _age := 0.0
var _gravity_direction := 1.0
var _blob_scale := Vector2.ONE
var _particles: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	visible = false
	set_process(false)


func play_burst(origin: Vector2, gravity_direction: float, blob_scale: Vector2) -> void:
	global_position = origin
	_gravity_direction = gravity_direction
	_blob_scale = blob_scale
	_age = 0.0
	_is_playing = true
	visible = true
	_particles.clear()
	_build_particles(blob_scale)
	set_process(true)
	queue_redraw()


func stop() -> void:
	_is_playing = false
	visible = false
	_particles.clear()
	set_process(false)
	queue_redraw()


func _process(delta: float) -> void:
	if not _is_playing:
		return
	_age += delta
	if _age >= BURST_DURATION:
		stop()
		return
	queue_redraw()


func _draw() -> void:
	if not _is_playing:
		return
	if _age < SQUASH_DURATION:
		_draw_squash(clampf(_age / SQUASH_DURATION, 0.0, 1.0))
		return

	var particle_duration := maxf(BURST_DURATION - SQUASH_DURATION, 0.01)
	var particle_age := _age - SQUASH_DURATION
	var progress := clampf(particle_age / particle_duration, 0.0, 1.0)
	var fade := 1.0 - progress
	for particle in _particles:
		var velocity: Vector2 = particle["velocity"] as Vector2
		var start: Vector2 = particle["start"] as Vector2
		var size := float(particle["size"])
		var drift := Vector2(0.0, _gravity_direction * FLOOR_DRIFT * progress * progress)
		var position := start + velocity * particle_age + drift
		var pixel_size := maxf(1.0, size * fade)
		var alpha := clampf(fade * float(particle["alpha"]), 0.0, 1.0)
		draw_rect(Rect2(position - Vector2.ONE * pixel_size * 0.5, Vector2.ONE * pixel_size), Color(1, 1, 1, alpha))


func _draw_squash(progress: float) -> void:
	var scale_factor := maxf(_blob_scale.x, _blob_scale.y)
	var width := lerpf(34.0, 58.0, progress) * scale_factor
	var height := lerpf(24.0, 8.0, progress) * scale_factor
	var surface_offset := Vector2(0.0, _gravity_direction * 14.0 * scale_factor)
	var alpha := lerpf(0.9, 1.0, progress)
	var pixel := PIXEL_SIZE * scale_factor
	for row in 3:
		var row_width := width - float(abs(row - 1)) * pixel * 2.0
		var row_y := (float(row) - 1.0) * height * 0.32
		var center := surface_offset + Vector2(0.0, row_y)
		draw_rect(Rect2(center - Vector2(row_width, pixel) * 0.5, Vector2(row_width, pixel)), Color(1, 1, 1, alpha))


func _build_particles(blob_scale: Vector2) -> void:
	var scale_factor := maxf(blob_scale.x, blob_scale.y)
	var radius := 22.0 * scale_factor
	for index in PARTICLE_COUNT:
		var angle := (float(index) / float(PARTICLE_COUNT)) * TAU + _rng.randf_range(-0.22, 0.22)
		var direction := Vector2.RIGHT.rotated(angle)
		var start := direction * _rng.randf_range(0.0, radius * 0.38)
		var speed := _rng.randf_range(95.0, 260.0) * lerpf(0.85, 1.28, scale_factor - 1.0)
		_particles.append({
			"start": start,
			"velocity": direction * speed,
			"size": _rng.randf_range(3.0, PIXEL_SIZE + scale_factor * 2.0),
			"alpha": _rng.randf_range(0.58, 1.0),
		})
