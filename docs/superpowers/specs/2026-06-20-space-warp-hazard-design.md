# Space Warp Hazard Design

## Overview

Add a timed space warp hazard to the arena. A warp opens at a random fixed location, warns the player before activating, then vacuums the player, enemies, and powerups toward its center. Enemies and powerups are pulled much more easily than the player. Anything that reaches the core is consumed: enemies and powerups disappear, and the player loses the run.

## Gameplay Behavior

- Only one warp may be forming or active at a time.
- `Main` schedules warp spawns with random delays.
- First-version pacing:
  - next warp delay: 18–35 seconds
  - warning duration: 2 seconds
  - active duration: 7–10 seconds
- Warp positions are random inside the arena with a margin from edges.
- Warning phase:
  - warp is visible as a forming pixel-art space tear/funnel
  - no suction is applied
- Active phase:
  - warp remains fixed in place
  - player, enemies, and powerups across the whole arena are pulled toward the center
  - attraction is weak far away and stronger near the core
  - attraction ramps up after activation, peaks mid-life, and drops near closing
  - player pull is aggressive but capped so escape remains possible
  - enemies and powerups use stronger pull multipliers because they have lower mass
  - enemies and powerups reaching the core are removed
  - player reaching the core triggers game over
- Warp closes automatically after its active duration.
- Warps are cleared on start screen, restart, and game over.

## Code Structure

Add a self-contained hazard scene:

- `scenes/space_warp.tscn`
- `scripts/space_warp.gd`

`space_warp.gd` owns:

- warning and active phase timing
- active duration
- pixel-art funnel/vortex visuals
- pull radius and core radius
- suction force calculation
- consuming enemies and powerups at the core
- emitting a signal when the player reaches the core
- emitting a signal when the warp closes

`main.gd` owns:

- loading the warp scene
- random warp scheduling
- random spawn position selection
- limiting to one warp at a time
- connecting warp signals
- ending the run when the warp consumes the player
- cleanup during restart/game-over/start-screen flows

Player/enemy scripts expose lightweight force methods:

- `player_blob.gd`: `apply_external_force(force: Vector2, delta: float)` adds to `velocity`.
- `dot.gd` and `smart_enemy.gd`: `apply_external_force(force: Vector2, delta: float)` accumulates external velocity or displacement before normal movement.

This keeps the warp self-contained while avoiding direct mutation of script internals from `main.gd`.

## Balance Constants

Constants should be grouped and clearly named so tuning is easy.

In `main.gd`:

- `WARP_SPAWN_WAIT_MIN := 18.0`
- `WARP_SPAWN_WAIT_MAX := 35.0`
- `WARP_WARNING_DURATION := 2.0`
- `WARP_ACTIVE_DURATION_MIN := 7.0`
- `WARP_ACTIVE_DURATION_MAX := 10.0`
- `WARP_SPAWN_MARGIN := 120.0`

In `space_warp.gd`:

- `PULL_RADIUS`
- `CORE_RADIUS`
- `PLAYER_PULL_STRENGTH`
- `ENEMY_PULL_STRENGTH`
- `PULL_FALLOFF_POWER`
- `MIN_DISTANCE_PULL_FACTOR`
- `LIFETIME_RAMP_IN_FRACTION`
- `LIFETIME_RAMP_OUT_FRACTION`
- `MAX_PLAYER_PULL`
- `POWERUP_PULL_STRENGTH`
- visual animation constants

The updated feel should be arena-wide and aggressive: the player always feels the warp, must actively fight it, the pull becomes dangerous near the center, and escape is still possible because player pull is capped and the warp weakens near the end of its life. While the player is being sucked in, the blob body stretches toward the warp, wobbles harder, and disappears when consumed by the core.

## Visual Design

The warp uses generated pixel-art-style visuals, with no imported art required for the first version.

Warning phase:

- flickering dark/purple space tear
- small square pixels orbiting slowly
- compact funnel shape that grows into visibility

Active phase:

- rotating funnel/ring segments
- square particles moving inward toward the core
- stronger pulse near the core
- visual reads as suction/vacuum motion

The visuals should work against the existing black arena background and remain visible during death-mode inverted colors where practical.

## Error Handling and Edge Cases

- If target nodes are freed while the warp is active, skip invalid references.
- If the player is already defeated or the game is not playing, warp effects should not matter because `Main` removes active warps during cleanup.
- If no enemies exist, the warp still affects the player and animates normally.
- If a warp closes naturally, `Main` clears its current-warp reference and schedules the next random spawn.

## Verification

Before implementation is considered complete:

- run Godot script/scene validation if available in the local environment
- verify all new scene script references load correctly
- verify `git status` is clean after commit
- manually inspect that restart, game over, and start screen cleanup paths remove active warps
