extends Node2D

const DOT_SCENE := preload("res://scenes/dot.tscn")
const SMART_ENEMY_SCENE := preload("res://scenes/smart_enemy.tscn")
const ANNIHILATION_STAR_SCENE := preload("res://scenes/annihilation_star.tscn")
const MASS_RELEASE_STAR_SCENE := preload("res://scenes/mass_release_star.tscn")
const GRAVITY_REVERSER_SCENE := preload("res://scenes/gravity_reverser.tscn")
const DEATH_SKULL_SCENE := preload("res://scenes/death_skull.tscn")
const ARENA_SIZE := Vector2(1152.0, 648.0)
const SPAWN_MARGIN := 32.0
const POWERUP_SPAWN_MARGIN := 70.0
const PLAYER_START := Vector2(576.0, 300.0)
const INITIAL_SPAWN_WAIT := 1.25
const MIN_SPAWN_WAIT := 0.28
const SPAWN_RAMP_SECONDS := 75.0
const POWERUP_SPAWN_WAIT := 12.0
const MAX_POWERUPS_ON_SCREEN := 3
const SMART_ENEMY_START_TIME := 10.0
const SMART_ENEMY_MAX_CHANCE := 0.22
const MASS_RELEASE_POWERUP_CHANCE := 0.34
const DEATH_SKULL_POWERUP_CHANCE := 0.18
const ANNIHILATION_POWERUP_CHANCE := 0.30
const GRAVITY_REVERSER_POWERUP_CHANCE := 0.18
const GRAVITY_REVERSER_HEAVY_CHANCE := 0.72
const GRAVITY_HELP_MASS_START := 4.2
const GRAVITY_HELP_MASS_FULL := 8.0
const GRAVITY_HELP_NEAR_RADIUS := 190.0
const RECORD_SAVE_PATH := "user://record.cfg"

@onready var background: ColorRect = $Background
@onready var arena_frame: Line2D = $ArenaFrame
@onready var player: Node2D = $PlayerBlob
@onready var spawn_timer: Timer = $SpawnTimer
@onready var powerup_timer: Timer = $PowerupTimer
@onready var dots_root: Node2D = $Dots
@onready var powerups_root: Node2D = $Powerups
@onready var shockwave_blast: Node2D = $BlastLayer/ShockwaveBlast
@onready var mass_release_burst: Node2D = $BlastLayer/MassReleaseBurst
@onready var gravity_flip_effect: Node2D = $BlastLayer/GravityFlipEffect
@onready var hud: Node = $HUD

var elapsed_time := 0.0
var record_time := 0.0
var is_playing := false
var has_started := false
var _last_gravity_reversed := false
var _last_death_mode_active := false
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()
	_load_record_time()
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	powerup_timer.timeout.connect(_on_powerup_timer_timeout)
	hud.connect("start_game_requested", _on_start_game_requested)
	_show_start_screen()


func _process(delta: float) -> void:
	if not has_started:
		return

	if is_playing:
		elapsed_time += delta
		hud.call("set_time_text", "TIME %.1f" % elapsed_time)
		if elapsed_time > record_time:
			record_time = elapsed_time
			hud.call("set_record_text", "BEST %.1f" % record_time)
		_update_perk_hud()

		if Input.is_action_just_pressed("activate_perk"):
			_try_activate_perk()

		_check_gravity_flip_effect()
		_check_death_mode_visuals()

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
	if powerups_root.get_child_count() >= MAX_POWERUPS_ON_SCREEN:
		return

	var player_mass: float = _get_player_mass()
	var gravity_help: float = clampf(
		(player_mass - GRAVITY_HELP_MASS_START) / (GRAVITY_HELP_MASS_FULL - GRAVITY_HELP_MASS_START),
		0.0,
		1.0
	)
	var gravity_chance: float = lerpf(GRAVITY_REVERSER_POWERUP_CHANCE, GRAVITY_REVERSER_HEAVY_CHANCE, gravity_help)

	var star: Node2D
	var is_gravity_reverser := false
	var total_weight: float = gravity_chance + MASS_RELEASE_POWERUP_CHANCE + DEATH_SKULL_POWERUP_CHANCE + ANNIHILATION_POWERUP_CHANCE
	var roll: float = rng.randf() * total_weight
	if roll < gravity_chance:
		star = GRAVITY_REVERSER_SCENE.instantiate() as Node2D
		is_gravity_reverser = true
	elif roll < gravity_chance + MASS_RELEASE_POWERUP_CHANCE:
		star = MASS_RELEASE_STAR_SCENE.instantiate() as Node2D
	elif roll < gravity_chance + MASS_RELEASE_POWERUP_CHANCE + DEATH_SKULL_POWERUP_CHANCE:
		star = DEATH_SKULL_SCENE.instantiate() as Node2D
	else:
		star = ANNIHILATION_STAR_SCENE.instantiate() as Node2D

	star.global_position = _random_powerup_position(is_gravity_reverser, gravity_help)
	powerups_root.add_child(star)


func _get_player_mass() -> float:
	return float(player.get("mass"))


func _random_powerup_position(is_gravity_reverser: bool, gravity_help: float) -> Vector2:
	if is_gravity_reverser and gravity_help > 0.0:
		var near_radius: float = lerpf(ARENA_SIZE.x * 0.42, GRAVITY_HELP_NEAR_RADIUS, gravity_help)
		var offset: Vector2 = Vector2.RIGHT.rotated(rng.randf_range(0.0, TAU)) * rng.randf_range(65.0, near_radius)
		var near_position: Vector2 = player.global_position + offset
		return Vector2(
			clampf(near_position.x, POWERUP_SPAWN_MARGIN, ARENA_SIZE.x - POWERUP_SPAWN_MARGIN),
			clampf(near_position.y, POWERUP_SPAWN_MARGIN, ARENA_SIZE.y - POWERUP_SPAWN_MARGIN)
		)

	return Vector2(
		rng.randf_range(POWERUP_SPAWN_MARGIN, ARENA_SIZE.x - POWERUP_SPAWN_MARGIN),
		rng.randf_range(POWERUP_SPAWN_MARGIN, ARENA_SIZE.y - POWERUP_SPAWN_MARGIN)
	)


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


func _show_start_screen() -> void:
	has_started = false
	is_playing = false
	spawn_timer.stop()
	powerup_timer.stop()
	hud.call("set_time_text", "TIME 0.0")
	hud.call("set_record_text", "BEST %.1f" % record_time)
	hud.call("set_annihilation_ready", false)
	hud.call("set_mass_release_ready", false)
	hud.call("set_death_mode_ready", false)
	hud.call("show_restart_prompt", false)
	hud.call("show_start_screen", true)
	if shockwave_blast.has_method("stop"):
		shockwave_blast.call("stop")
	if mass_release_burst.has_method("stop"):
		mass_release_burst.call("stop")
	if gravity_flip_effect.has_method("stop"):
		gravity_flip_effect.call("stop")
	_last_gravity_reversed = false
	_last_death_mode_active = false
	_apply_death_mode_visuals(false)
	for dot in dots_root.get_children():
		dot.queue_free()
	for powerup in powerups_root.get_children():
		powerup.queue_free()
	if player.has_method("reset_blob"):
		player.call("reset_blob", PLAYER_START)
	else:
		player.global_position = PLAYER_START
	if player.has_method("set_input_enabled"):
		player.call("set_input_enabled", false)


func _on_start_game_requested() -> void:
	has_started = true
	hud.call("show_start_screen", false)
	_restart_run()


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
	if gravity_flip_effect.has_method("stop"):
		gravity_flip_effect.call("stop")
	_last_death_mode_active = false
	_apply_death_mode_visuals(false)
	if player.has_method("set_input_enabled"):
		player.call("set_input_enabled", false)
	hud.call("show_restart_prompt", true)


func _try_activate_perk() -> void:
	if _try_activate_annihilation():
		return
	if _try_activate_mass_release():
		return
	_try_activate_death_mode()


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


func _try_activate_death_mode() -> bool:
	if not player.has_method("consume_death_perk"):
		return false
	if not bool(player.call("consume_death_perk")):
		return false

	if player.has_method("activate_death_mode"):
		player.call("activate_death_mode")
	_update_perk_hud()
	_check_death_mode_visuals()
	return true


func _play_annihilation_blast() -> void:
	if shockwave_blast.has_method("play"):
		shockwave_blast.call("play", player.global_position)


func _play_mass_release_burst() -> void:
	if mass_release_burst.has_method("play"):
		mass_release_burst.call("play", player.global_position)


func _check_gravity_flip_effect() -> void:
	if not player.has_method("is_gravity_reversed"):
		return

	var is_reversed: bool = bool(player.call("is_gravity_reversed"))
	if is_reversed == _last_gravity_reversed:
		return

	_last_gravity_reversed = is_reversed
	if gravity_flip_effect.has_method("play"):
		gravity_flip_effect.call("play", player.global_position)


func _check_death_mode_visuals() -> void:
	if not player.has_method("is_death_mode_active"):
		return

	var is_active: bool = bool(player.call("is_death_mode_active"))
	if is_active == _last_death_mode_active:
		return

	_last_death_mode_active = is_active
	_apply_death_mode_visuals(is_active)


func _apply_death_mode_visuals(active: bool) -> void:
	background.color = Color(1, 1, 1, 1) if active else Color(0, 0, 0, 1)
	arena_frame.default_color = Color(0, 0, 0, 1) if active else Color(1, 1, 1, 1)
	if player.has_method("set_death_mode_visual_active"):
		player.call("set_death_mode_visual_active", active)
	if hud.has_method("set_inverted_colors"):
		hud.call("set_inverted_colors", active)


func _update_perk_hud() -> void:
	if player.has_method("has_annihilation_perk"):
		hud.call("set_annihilation_ready", bool(player.call("has_annihilation_perk")))
	if player.has_method("has_mass_release_perk"):
		hud.call("set_mass_release_ready", bool(player.call("has_mass_release_perk")))
	if player.has_method("has_death_perk"):
		hud.call("set_death_mode_ready", bool(player.call("has_death_perk")))


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
	hud.call("show_start_screen", false)
	hud.call("show_restart_prompt", false)
	hud.call("set_annihilation_ready", false)
	hud.call("set_mass_release_ready", false)
	hud.call("set_death_mode_ready", false)
	if shockwave_blast.has_method("stop"):
		shockwave_blast.call("stop")
	if mass_release_burst.has_method("stop"):
		mass_release_burst.call("stop")
	if gravity_flip_effect.has_method("stop"):
		gravity_flip_effect.call("stop")
	_last_gravity_reversed = false
	_last_death_mode_active = false
	_apply_death_mode_visuals(false)

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
