extends Node2D

const DOT_SCENE := preload("res://scenes/dot.tscn")
const SMART_ENEMY_SCENE := preload("res://scenes/smart_enemy.tscn")
const ANNIHILATION_STAR_SCENE := preload("res://scenes/annihilation_star.tscn")
const MASS_RELEASE_STAR_SCENE := preload("res://scenes/mass_release_star.tscn")
const ARENA_SIZE := Vector2(1152.0, 648.0)
const SPAWN_MARGIN := 32.0
const POWERUP_SPAWN_MARGIN := 70.0
const PLAYER_START := Vector2(576.0, 300.0)
const INITIAL_SPAWN_WAIT := 1.25
const MIN_SPAWN_WAIT := 0.28
const SPAWN_RAMP_SECONDS := 75.0
const POWERUP_SPAWN_WAIT := 12.0
const SMART_ENEMY_START_TIME := 10.0
const SMART_ENEMY_MAX_CHANCE := 0.22
const MASS_RELEASE_POWERUP_CHANCE := 0.38
const RECORD_SAVE_PATH := "user://record.cfg"

@onready var player: Node2D = $PlayerBlob
@onready var spawn_timer: Timer = $SpawnTimer
@onready var powerup_timer: Timer = $PowerupTimer
@onready var dots_root: Node2D = $Dots
@onready var powerups_root: Node2D = $Powerups
@onready var shockwave_blast: Node2D = $BlastLayer/ShockwaveBlast
@onready var mass_release_burst: Node2D = $BlastLayer/MassReleaseBurst
@onready var hud: Node = $HUD

var elapsed_time := 0.0
var record_time := 0.0
var is_playing := true
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()
	_load_record_time()
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	powerup_timer.timeout.connect(_on_powerup_timer_timeout)
	_restart_run()


func _process(delta: float) -> void:
	if is_playing:
		elapsed_time += delta
		hud.call("set_time_text", "TIME %.1f" % elapsed_time)
		if elapsed_time > record_time:
			record_time = elapsed_time
			hud.call("set_record_text", "BEST %.1f" % record_time)
		_update_perk_hud()

		if Input.is_action_just_pressed("activate_perk"):
			_try_activate_perk()

		if player.has_method("is_defeated") and bool(player.call("is_defeated")):
			_game_over()
	elif Input.is_action_just_pressed("restart"):
		_restart_run()


func _on_spawn_timer_timeout() -> void:
	if not is_playing:
		return

	_spawn_dot()
	_update_spawn_wait()
	spawn_timer.start()


func _on_powerup_timer_timeout() -> void:
	if not is_playing:
		return

	_spawn_powerup()
	powerup_timer.start()


func _spawn_dot() -> void:
	var smart_chance: float = 0.0
	if elapsed_time >= SMART_ENEMY_START_TIME:
		smart_chance = minf((elapsed_time - SMART_ENEMY_START_TIME) / 90.0, 1.0) * SMART_ENEMY_MAX_CHANCE

	if rng.randf() < smart_chance:
		_spawn_smart_enemy()
		return

	var dot := DOT_SCENE.instantiate() as Node2D
	dot.set("target", player)
	dot.global_position = _random_edge_position()
	dot.set("speed", rng.randf_range(85.0, 125.0) + minf(elapsed_time * 0.45, 28.0))
	dots_root.add_child(dot)


func _spawn_smart_enemy() -> void:
	var enemy := SMART_ENEMY_SCENE.instantiate() as Node2D
	enemy.set("target", player)
	enemy.global_position = _random_edge_position()
	enemy.set("speed", rng.randf_range(145.0, 180.0) + minf(elapsed_time * 0.35, 35.0))
	dots_root.add_child(enemy)


func _spawn_powerup() -> void:
	if powerups_root.get_child_count() > 0:
		return

	var star: Node2D
	if rng.randf() < MASS_RELEASE_POWERUP_CHANCE:
		star = MASS_RELEASE_STAR_SCENE.instantiate() as Node2D
	else:
		star = ANNIHILATION_STAR_SCENE.instantiate() as Node2D

	star.global_position = Vector2(
		rng.randf_range(POWERUP_SPAWN_MARGIN, ARENA_SIZE.x - POWERUP_SPAWN_MARGIN),
		rng.randf_range(POWERUP_SPAWN_MARGIN, ARENA_SIZE.y - POWERUP_SPAWN_MARGIN)
	)
	powerups_root.add_child(star)


func _random_edge_position() -> Vector2:
	match rng.randi_range(0, 3):
		0:
			return Vector2(rng.randf_range(0.0, ARENA_SIZE.x), -SPAWN_MARGIN)
		1:
			return Vector2(ARENA_SIZE.x + SPAWN_MARGIN, rng.randf_range(0.0, ARENA_SIZE.y))
		2:
			return Vector2(rng.randf_range(0.0, ARENA_SIZE.x), ARENA_SIZE.y + SPAWN_MARGIN)
		_:
			return Vector2(-SPAWN_MARGIN, rng.randf_range(0.0, ARENA_SIZE.y))


func _update_spawn_wait() -> void:
	var ramp := clampf(elapsed_time / SPAWN_RAMP_SECONDS, 0.0, 1.0)
	spawn_timer.wait_time = lerpf(INITIAL_SPAWN_WAIT, MIN_SPAWN_WAIT, ramp)


func _game_over() -> void:
	is_playing = false
	_save_record_time()
	spawn_timer.stop()
	powerup_timer.stop()
	for dot in dots_root.get_children():
		dot.queue_free()
	for powerup in powerups_root.get_children():
		powerup.queue_free()
	if shockwave_blast.has_method("stop"):
		shockwave_blast.call("stop")
	if mass_release_burst.has_method("stop"):
		mass_release_burst.call("stop")
	if player.has_method("set_input_enabled"):
		player.call("set_input_enabled", false)
	hud.call("show_restart_prompt", true)


func _try_activate_perk() -> void:
	if _try_activate_annihilation():
		return
	_try_activate_mass_release()


func _try_activate_annihilation() -> bool:
	if not player.has_method("consume_annihilation_perk"):
		return false
	if not bool(player.call("consume_annihilation_perk")):
		return false

	for dot in dots_root.get_children():
		dot.queue_free()
	_play_annihilation_blast()
	_update_perk_hud()
	return true


func _try_activate_mass_release() -> bool:
	if not player.has_method("consume_mass_release_perk"):
		return false
	if not bool(player.call("consume_mass_release_perk")):
		return false

	if player.has_method("release_mass"):
		player.call("release_mass")
	_play_mass_release_burst()
	_update_perk_hud()
	return true


func _play_annihilation_blast() -> void:
	if shockwave_blast.has_method("play"):
		shockwave_blast.call("play", player.global_position)


func _play_mass_release_burst() -> void:
	if mass_release_burst.has_method("play"):
		mass_release_burst.call("play", player.global_position)


func _update_perk_hud() -> void:
	if player.has_method("has_annihilation_perk"):
		hud.call("set_annihilation_ready", bool(player.call("has_annihilation_perk")))
	if player.has_method("has_mass_release_perk"):
		hud.call("set_mass_release_ready", bool(player.call("has_mass_release_perk")))


func _load_record_time() -> void:
	var config := ConfigFile.new()
	var error: Error = config.load(RECORD_SAVE_PATH)
	if error == OK:
		record_time = float(config.get_value("record", "time", 0.0))


func _save_record_time() -> void:
	var config := ConfigFile.new()
	config.set_value("record", "time", record_time)
	config.save(RECORD_SAVE_PATH)


func _restart_run() -> void:
	is_playing = true
	elapsed_time = 0.0
	hud.call("set_time_text", "TIME 0.0")
	hud.call("set_record_text", "BEST %.1f" % record_time)
	hud.call("show_restart_prompt", false)
	hud.call("set_annihilation_ready", false)
	hud.call("set_mass_release_ready", false)
	if shockwave_blast.has_method("stop"):
		shockwave_blast.call("stop")
	if mass_release_burst.has_method("stop"):
		mass_release_burst.call("stop")

	for dot in dots_root.get_children():
		dot.queue_free()
	for powerup in powerups_root.get_children():
		powerup.queue_free()

	if player.has_method("reset_blob"):
		player.call("reset_blob", PLAYER_START)
	else:
		player.global_position = PLAYER_START

	_update_spawn_wait()
	spawn_timer.start()
	powerup_timer.wait_time = POWERUP_SPAWN_WAIT
	powerup_timer.start()
