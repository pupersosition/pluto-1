extends Node2D

signal player_consumed
signal closed(warp: Node)

const PULL_RADIUS := 240.0
const CORE_RADIUS := 24.0
const PLAYER_PULL_STRENGTH := 420.0
const ENEMY_PULL_STRENGTH := 1500.0
const PULL_FALLOFF_POWER := 1.45
const PIXEL_COUNT := 26
const RING_COUNT := 4
const PIXEL_SIZE := 5.0

var warning_duration := 2.0
var active_duration := 8.0
var _age := 0.0
var _is_active := false
var _rng := RandomNumberGenerator.new()
var _pixels: Array[ColorRect] = []
var _rings: Array[Line2D] = []


func _ready() -> void:
	_rng.randomize()
	_build_visuals()


func configure(warning_seconds: float, active_seconds: float) -> void:
	warning_duration = warning_seconds
	active_duration = active_seconds


func _process(delta: float) -> void:
	_age += delta
	if not _is_active and _age >= warning_duration:
		_is_active = true
		_age = 0.0
	elif _is_active and _age >= active_duration:
		closed.emit(self)
		queue_free()
		return

	_update_visuals()
	if _is_active:
		_apply_suction(delta)


func _build_visuals() -> void:
	for ring_index in RING_COUNT:
		var ring := Line2D.new()
		ring.closed = true
		ring.width = 3.0
		ring.default_color = Color(0.58, 0.22, 1.0, 0.78)
		add_child(ring)
		_rings.append(ring)

	for index in PIXEL_COUNT:
		var pixel := ColorRect.new()
		pixel.size = Vector2.ONE * PIXEL_SIZE
		pixel.pivot_offset = pixel.size * 0.5
		pixel.color = Color(0.82, 0.52, 1.0, 0.9)
		add_child(pixel)
		_pixels.append(pixel)


func _update_visuals() -> void:
	var phase_scale: float = 1.0 if _is_active else clampf(_age / maxf(warning_duration, 0.01), 0.15, 1.0)
	var spin: float = Time.get_ticks_msec() / 1000.0
	var pulse: float = 0.88 + sin(spin * 8.0) * 0.08

	for ring_index in _rings.size():
		var ring := _rings[ring_index]
		var point_count := 18
		var radius: float = (34.0 + ring_index * 28.0) * phase_scale * pulse
		var points := PackedVector2Array()
		for point_index in point_count:
			var angle: float = (float(point_index) / float(point_count)) * TAU + spin * (1.2 + ring_index * 0.25)
			var squash: float = 0.46 + ring_index * 0.08
			points.append(Vector2(cos(angle) * radius, sin(angle) * radius * squash))
		ring.points = points
		ring.default_color = Color(0.42, 0.08, 0.72, 0.55) if not _is_active else Color(0.72, 0.28, 1.0, 0.78)

	for index in _pixels.size():
		var pixel := _pixels[index]
		var t: float = fmod(float(index) / float(_pixels.size()) + spin * (0.08 if not _is_active else 0.22), 1.0)
		var angle: float = t * TAU * 2.0 + float(index) * 0.47
		var radius: float = lerpf(110.0, 16.0, t) * phase_scale
		var funnel_y: float = sin(angle + spin * 3.0) * radius * 0.36
		pixel.position = Vector2(cos(angle) * radius, funnel_y) - pixel.size * 0.5
		pixel.color = Color(0.22, 0.02, 0.34, 0.9) if not _is_active else Color(0.78, 0.42, 1.0, 0.95)
		pixel.scale = Vector2.ONE * lerpf(0.8, 1.5, 1.0 - t)


func _apply_suction(delta: float) -> void:
	var parent := get_parent()
	if parent == null:
		return
	var main := parent.get_parent()
	if main == null:
		return

	_apply_to_player(main, delta)
	_apply_to_enemies(main, delta)


func _apply_to_player(main: Node, delta: float) -> void:
	var player := main.get_node_or_null("PlayerBlob")
	if player == null or not is_instance_valid(player):
		return
	var distance := global_position.distance_to(player.global_position)
	if distance > PULL_RADIUS:
		return
	if distance <= CORE_RADIUS:
		player_consumed.emit()
		return
	_apply_pull(player, PLAYER_PULL_STRENGTH, distance, delta)


func _apply_to_enemies(main: Node, delta: float) -> void:
	var dots_root := main.get_node_or_null("Dots")
	if dots_root == null:
		return
	for enemy in dots_root.get_children():
		if not is_instance_valid(enemy) or not enemy is Node2D:
			continue
		var enemy_node := enemy as Node2D
		var distance := global_position.distance_to(enemy_node.global_position)
		if distance > PULL_RADIUS:
			continue
		if distance <= CORE_RADIUS:
			enemy_node.queue_free()
			continue
		_apply_pull(enemy_node, ENEMY_PULL_STRENGTH, distance, delta)


func _apply_pull(node: Node2D, strength: float, distance: float, delta: float) -> void:
	if not node.has_method("apply_external_force"):
		return
	var distance_factor := 1.0 - clampf(distance / PULL_RADIUS, 0.0, 1.0)
	var pull_amount := strength * pow(distance_factor, PULL_FALLOFF_POWER)
	var pull_direction := node.global_position.direction_to(global_position)
	node.call("apply_external_force", pull_direction * pull_amount, delta)
