# AGENT.md

Guidelines and project map for coding agents working in this Godot project.

## Project overview

- Godot 4 project, configured in `project.godot`.
- Main scene: `res://scenes/main.tscn`.
- Game name in config: `Proto-1` / exported as `PLUTO-1` in current web build files.
- The game is a 2D arena survival prototype:
  - The player controls a white blob affected by gravity.
  - White dots and red smart enemies fly in from arena edges.
  - Touching dots increases player mass.
  - If the blob becomes too massive and stays pinned to the gravity surface, the run ends.
  - Collectible powerups provide one-shot perks.

## Top-level layout

- `project.godot` — Godot project settings, viewport size, input actions, main scene.
- `AGENT.md` — this file; coding-agent orientation and conventions.
- `scenes/` — Godot scene files (`.tscn`). Most scene node trees are here.
- `scripts/` — gameplay, UI, and procedural visual scripts (`.gd`).
- `docs/plans/` — design/implementation notes from prior feature work.
- `build/` — exported web build output. Usually generated; avoid editing by hand unless explicitly asked.
- `export_presets.cfg` — Godot export configuration.
- `.godot/` — Godot editor/cache data. Do not edit manually unless explicitly needed.

## Main scenes

- `scenes/main.tscn`
  - Root gameplay scene and default run scene.
  - Important children:
    - `Background` / `ArenaFrame` — black arena and white frame.
    - `Ceiling`, `Floor`, `LeftWall`, `RightWall` — static collision boundaries.
    - `Dots` — runtime parent for spawned dots and smart enemies.
    - `Powerups` — runtime parent for spawned collectible powerups.
    - `PlayerBlob` — instance of `scenes/player_blob.tscn`.
    - `SpawnTimer` — one-shot timer for enemy/dot spawning.
    - `PowerupTimer` — one-shot timer for powerup spawning.
    - `HUD` — instance of `scenes/hud.tscn`.
    - `BlastLayer` — `CanvasLayer` containing procedural perk/effect visuals.
- `scenes/player_blob.tscn`
  - `CharacterBody2D` controlled by `scripts/player_blob.gd`.
  - Contains `BlobVisual` polygon and circular collision shape.
- `scenes/hud.tscn`
  - HUD labels, start screen, start button, restart prompt.
  - Uses `scripts/hud.gd` and `scripts/start_screen_art.gd`.
- `scenes/dot.tscn`
  - Regular white collectible/hazard dot using `scripts/dot.gd`.
- `scenes/smart_enemy.tscn`
  - Red homing enemy using `scripts/smart_enemy.gd`.
- Powerup scenes:
  - `scenes/annihilation_star.tscn` — grants annihilation perk.
  - `scenes/mass_release_star.tscn` — grants mass-release perk.
  - `scenes/gravity_reverser.tscn` — immediately toggles gravity.
  - `scenes/death_skull.tscn` — grants the stored Death Mode perk.

## Main logic locations

### Game loop and spawning: `scripts/main.gd`

This is the central orchestration script. Look here first for gameplay flow.

Responsibilities:
- Loads/preloads scenes for dots, smart enemies, and powerups.
- Defines arena constants, spawn timing, difficulty ramp, powerup probabilities, and record save path.
- Owns run state:
  - `elapsed_time`
  - `record_time`
  - `is_playing`
  - `has_started`
- Connects timers and HUD signals in `_ready()`.
- Shows the start screen on launch via `_show_start_screen()`.
- Updates time, record, perk HUD state, perk activation, gravity flip effects, and defeat checks in `_process()`.
- Spawns enemies through `_on_spawn_timer_timeout()`, `_spawn_dot()`, and `_spawn_smart_enemy()`.
- Spawns powerups through `_on_powerup_timer_timeout()` and `_spawn_powerup()`.
- Calculates powerup placement in `_random_powerup_position()`.
- Handles run lifecycle:
  - `_on_start_game_requested()`
  - `_restart_run()`
  - `_game_over()`
  - `_show_start_screen()`
- Handles perks:
  - `_try_activate_perk()`
  - `_try_activate_annihilation()`
  - `_try_activate_mass_release()`
  - `_try_activate_death_mode()`
  - `_update_perk_hud()`
- Handles visual effects:
  - `_play_annihilation_blast()`
  - `_play_mass_release_burst()`
  - `_check_gravity_flip_effect()`
- Saves/loads best time through `ConfigFile` at `user://record.cfg`.

### Player movement, mass, and defeat: `scripts/player_blob.gd`

Look here for physics feel, gravity behavior, blob growth, perk inventory, and loss conditions.

Responsibilities:
- `CharacterBody2D` movement in `_physics_process()`.
- Reads input via `Input.get_vector("move_left", "move_right", "move_up", "move_down")`.
- Applies acceleration, drag, mass-based control reduction, and mass-scaled gravity.
- Tracks floor/ceiling contact time depending on current gravity direction.
- Grows with `absorb_dot(amount)`.
- Maintains perk readiness:
  - `annihilation_perk_ready`
  - `mass_release_perk_ready`
  - `death_perk_ready`
- Provides grant/has/consume methods for perks.
- `release_mass()` lowers mass after mass-release activation.
- `activate_death_mode()` starts a timed mode where dots flee and absorbed dots add no mass.
- `is_death_mode_active()` reports whether Death Mode is currently active.
- `toggle_gravity()` flips gravity direction and bounces vertical velocity.
- `is_gravity_reversed()` reports whether gravity currently points upward.
- `reset_blob(position_value)` resets mass, velocity, perks, gravity, and position for a new run.
- `set_input_enabled(enabled)` freezes/unfreezes player control for menus/game over.
- `is_defeated()` implements collapse logic based on mass, gravity-surface contact, and recovery acceleration.
- Procedural blob wobble/shape is generated in `_update_blob_visual()`.

### HUD and start/restart UI: `scripts/hud.gd`

Responsibilities:
- Emits `start_game_requested` when the start button is pressed.
- Updates visible labels through small setter methods:
  - `set_time_text()`
  - `set_record_text()`
  - `set_annihilation_ready()`
  - `set_mass_release_ready()`
  - `show_start_screen()`
  - `show_restart_prompt()`
- Start-screen procedural art is in `scripts/start_screen_art.gd`.

### Enemies and dots

- `scripts/dot.gd`
  - Regular white dot.
  - Starts aimed toward the player or an explicit `initial_direction`.
  - Can home toward the player after `homing_delay` and within acquire/escape distances.
  - Flees from the player at reduced speed while Death Mode is active.
  - Despawns after max lifetime or after leaving the arena after entry.
  - On body contact, calls `absorb_dot(absorb_amount)` on the player and frees itself.
- `scripts/smart_enemy.gd`
  - Red homing enemy.
  - Steers aggressively toward the player, or away from the player at reduced speed while Death Mode is active.
  - Periodically spawns a radial cloud of small white `dot.tscn` instances.
  - On body contact, calls `absorb_dot(absorb_amount)` and frees itself.

### Powerups

- `scripts/annihilation_star.gd`
  - Procedural white star collectible.
  - On player contact, calls `grant_annihilation_perk()` and frees itself.
  - Actual activation/clearing happens in `scripts/main.gd` when Space is pressed.
- `scripts/mass_release_star.gd`
  - Procedural cyan diamond/star collectible.
  - On player contact, calls `grant_mass_release_perk()` and frees itself.
  - Actual activation/mass reduction happens in `scripts/main.gd` and `scripts/player_blob.gd` when Space is pressed.
- `scripts/gravity_reverser.gd`
  - Procedural black-hole collectible.
  - On player contact, calls `toggle_gravity()` immediately and frees itself.
  - Gravity flip visual feedback is detected and played by `scripts/main.gd`.
- `scripts/death_skull.gd`
  - Procedural pixel-art skull collectible.
  - On player contact, calls `grant_death_perk()` and frees itself.
  - Actual activation happens in `scripts/main.gd` when Space is pressed after existing stored perks.
  - During Death Mode, `scripts/main.gd` inverts arena/HUD colors and dots/enemies flee via player state checks.

### Procedural visual effects

- `scripts/shockwave_blast.gd`
  - Annihilation activation effect.
  - Dotted expanding ring and radial dotted lines.
- `scripts/mass_release_burst.gd`
  - Mass-release activation effect.
  - Short particle burst from the player.
- `scripts/gravity_flip_effect.gd`
  - Gravity flip distortion effect.
  - Horizontal dotted slices and rings.
- `scripts/start_screen_art.gd`
  - Procedural pixel-art art on the start screen.

## Input actions

Defined in `project.godot`:

- `move_left` — left arrow, D-pad/joypad left, analog left.
- `move_right` — right arrow, D-pad/joypad right, analog right.
- `move_up` — up arrow, D-pad/joypad up, analog up.
- `move_down` — down arrow, D-pad/joypad down, analog down.
- `restart` — `R`, joypad face button, joypad shoulder/start-style button depending on mapping.
- `activate_perk` — Space.

## Run lifecycle summary

1. Godot opens `scenes/main.tscn`.
2. `scripts/main.gd::_ready()` randomizes RNG, loads record time, connects timers/HUD, and calls `_show_start_screen()`.
3. Player presses the HUD start button.
4. HUD emits `start_game_requested`.
5. `main.gd::_on_start_game_requested()` hides the start screen and calls `_restart_run()`.
6. `_restart_run()` resets state, clears existing dots/powerups, resets player, starts timers.
7. While `is_playing`:
   - `_process()` advances time and checks perk activation/defeat.
   - `SpawnTimer` spawns dots or smart enemies.
   - `PowerupTimer` spawns one powerup if none exists.
8. If the player collapses, `_game_over()` stops timers, clears spawned objects, disables input, saves record, and shows restart prompt.
9. Pressing `R` after game over calls `_restart_run()`.

## Coding style and conventions

- Use typed GDScript where practical.
- Avoid `:=` when the right-hand side can be inferred as `Variant`; warnings are treated as errors in this project.
- Prefer explicit local types when interacting with `Node.get()`, `call()`, scene instances, or loosely typed Godot APIs.
- Prefer small, focused scripts and scenes.
- Keep visuals procedural/pixel-art friendly unless assets are explicitly added.
- This project frequently uses duck-typed methods (`has_method()`, `call()`) between `main.gd`, HUD, player, and powerups. Preserve method names when refactoring.
- Runtime-spawned objects are usually added under `Dots` or `Powerups` in `scenes/main.tscn`; up to 3 powerups may be present at once.
- Scene/script paths use Godot `res://` paths inside `.tscn` and preload calls.

## Validation

- If Godot is available, run a project parse/check before claiming a change is complete.
- If Godot is not available, mention that validation could not be run.
- Useful checks when available may include opening the project in Godot or running the installed Godot binary in headless/check mode.
- There is currently no separate automated test suite in the repository.

## Things to be careful about

- Do not hand-edit generated build output in `build/` unless specifically requested.
- Do not manually edit `.godot/` cache/editor files unless specifically requested.
- Check `git status` before editing; this repo may contain user changes and untracked generated files.
- Be careful when changing `.tscn` files by hand; keep resource IDs and node paths consistent.
- HUD methods are called dynamically from `main.gd`; renaming them requires updating string calls.
- Powerup grant/consume methods are called dynamically between collectibles, player, and main.
- Gravity uses `gravity_direction` in `player_blob.gd`; floor vs ceiling logic depends on this value.
- Arena size constants are duplicated in multiple scripts (`main.gd`, `dot.gd`, `smart_enemy.gd`) and should stay consistent with the 1152x648 viewport and `main.tscn` arena boundaries.
