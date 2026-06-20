# Skull Death Mode Perk Design

## Goal

Add a new collectible skull perk that the player can store and activate with Space. When active, the player enters a short "death mode" where dots flee from the blob and can be eaten without increasing player mass. The arena colors invert during the effect: the background becomes white and normally white gameplay elements become black.

## Player-facing behavior

- A pixel-art skull collectible appears as one of the powerup types.
- Collecting the skull stores the perk on the player; it does not activate immediately.
- HUD shows a ready indicator such as `DEATH MODE READY - SPACE`.
- Pressing Space activates perks in existing order first, then skull:
  1. Annihilation
  2. Mass Release
  3. Skull Death Mode
- Death Mode lasts 6 seconds.
- During Death Mode:
  - Regular dots and smart enemies flee from the player instead of chasing/homing.
  - Touching dots or smart enemies removes them without increasing player mass.
  - New dots/enemies spawned during the effect also flee.
  - The arena background turns white.
  - The player blob and normally white dots/effects render black.
  - Red smart enemies should also become dark/black enough to read against the white background.
- When the timer ends, colors and enemy behavior return to normal.
- Starting/restarting/game-over should clear readiness and active Death Mode state.

## Architecture

Use the project’s existing duck-typed method pattern.

### Player state: `scripts/player_blob.gd`

Add stored and active state to the player:

- `death_perk_ready: bool`
- `death_mode_time_remaining: float`
- `DEATH_MODE_DURATION := 6.0`

Add methods:

- `grant_death_perk()`
- `has_death_perk()`
- `consume_death_perk()`
- `activate_death_mode()`
- `is_death_mode_active()`
- optionally `get_death_mode_time_remaining()` for HUD/debugging

The player decrements the timer in `_physics_process()` or another existing per-frame path. `reset_blob()` clears both ready and active state.

`absorb_dot(amount)` should not increase mass when Death Mode is active, but should still trigger a wobble/feedback impulse.

### Main orchestration: `scripts/main.gd`

Add preload for the skull scene and include it in `_spawn_powerup()` probability selection.

Add a new activation branch after existing perks:

- `_try_activate_death_mode()` consumes the stored perk and calls `player.activate_death_mode()`.

Add color inversion tracking in `_process()`:

- Read `player.is_death_mode_active()`.
- When it changes, update arena/HUD/effect colors.

Main should clear visual inversion on start screen, restart, and game over.

### Dots/enemies: `scripts/dot.gd`, `scripts/smart_enemy.gd`

When target is valid and `target.is_death_mode_active()` returns true:

- Desired direction becomes `target.global_position.direction_to(global_position)` (away from player).
- Regular dots should flee even if they are not currently in homing mode.
- Smart enemies should flee using their existing turn-rate steering.

Collision remains simple: dots call `body.absorb_dot(absorb_amount)` and free themselves. The player’s `absorb_dot()` decides whether mass increases.

### HUD: `scripts/hud.gd`, `scenes/hud.tscn`

Add a Death Mode ready label and setter:

- `set_death_mode_ready(is_ready: bool)`

The label should match the current style and read something like `DEATH MODE READY - SPACE`.

For inverted colors, either add a HUD method to apply inverted color state or update relevant label colors from main. Prefer a small HUD method to keep node paths inside `hud.gd`.

### Skull collectible: new scene and script

Add:

- `scenes/death_skull.tscn`
- `scripts/death_skull.gd`

The script should follow existing collectible patterns:

- `extends Area2D`
- bobbing animation in `_process()`
- procedural `_draw()` pixel-art skull
- on body enter, call `grant_death_perk()` and `queue_free()`

The scene should contain an `Area2D` root with a collision shape and the script attached.

## Probability and balance

Keep the existing one-powerup-at-a-time rule. Add skull as another possible spawn. Initial balance:

- Death skull chance: 0.18
- Gravity chance remains mass-biased as currently implemented.
- Mass release chance remains 0.34.
- Annihilation receives the remaining chance.

If the gravity chance grows high for heavy players, total probabilities should be clamped/selected in a way that still leaves room for other powerups.

## Visual inversion approach

Use explicit color updates rather than screen shaders:

- `Background.color`: black/white
- `ArenaFrame.default_color`: white/black
- `PlayerBlob.BlobVisual.color`: white/black
- Dot visual color: white/black while target is in Death Mode
- Smart enemy visual color: red normally, black/dark during Death Mode
- HUD label colors should invert for readability.

This avoids adding shader complexity and matches the procedural/pixel-art style.

## Validation

- If Godot is available, run a project parse/check.
- If not available, inspect affected `.gd` and `.tscn` files for path/resource consistency.
- Manual playtest checklist:
  - Skull spawns and can be collected.
  - HUD shows Death Mode ready.
  - Space activates existing perks before skull.
  - Death Mode lasts about 6 seconds.
  - Dots flee during Death Mode, including newly spawned dots.
  - Eating dots during Death Mode does not increase mass.
  - Colors invert during Death Mode and restore afterward.
  - Restart/game over clears the effect.
