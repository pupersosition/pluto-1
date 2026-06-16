## Growing Blob Game Design

### Overview

This project is a small 2D pixel-style Godot 4.6.3 game with a black background and white-only visuals. The player controls a blob of mass using keyboard arrows or a controller. White dots spawn from the screen edges and move toward the blob. Each dot that reaches the blob is absorbed, increasing the blob's mass and visual size while making it harder to move. The run ends when the blob becomes so heavy that it settles onto the bottom of the screen and can no longer lift itself away.

The main success criterion is a short, readable arcade loop with clear controls, visible growth, and an ending that feels physical rather than arbitrary.

### Goals

- Deliver a playable single-screen arcade prototype.
- Support both keyboard and controller movement.
- Keep visuals minimal: black background, white blob, white dots, simple HUD.
- Make growth and increasing heaviness easy to feel.
- Score runs by survival time.

### Non-Goals

- No multiple levels or progression systems.
- No complex enemy behaviors beyond seeking the blob.
- No narrative, menus, unlocks, or meta progression.
- No decorative color palette beyond black and white.

### Core Loop

1. Start a run with a small, mobile blob near the middle of the play area.
2. Dots spawn from just outside the screen edges and travel toward the blob.
3. The player steers to survive as long as possible while avoiding rapid mass gain.
4. Absorbed dots increase mass, size, and movement difficulty.
5. Spawn pressure increases over time.
6. The run ends when the blob can no longer lift itself off the floor.
7. The player can instantly restart and try to beat their previous survival time.

### Design Approach

The chosen implementation style is physics-lite arcade movement.

#### Chosen Approach: Physics-Lite Arcade

- Use deterministic player movement driven by acceleration, drag, and a gravity-like downward force.
- Use a single `mass` value to drive both visual scale and movement penalties.
- Use simple, direct dot seeking behavior.
- Use a floor defeat rule based on contact and failure to recover.

This approach is preferred because it provides a physical feel while remaining straightforward to tune in Godot.

#### Alternatives Considered

1. Full rigid body physics
   - Pros: more emergent motion.
   - Cons: harder to tune, easier to make frustrating, less deterministic.
2. Pure scripted threshold system
   - Pros: simplest to build.
   - Cons: weaker physical fantasy, less satisfying motion.

### Scene Architecture

#### Main Scene

Responsibilities:
- Own global game state: playing, game over, restart.
- Track survival time.
- Spawn dots on a timer.
- Increase spawn intensity over time.
- Update the HUD.

Suggested contents:
- Root `Node2D`
- Gameplay container
- Spawn timer
- HUD canvas layer

#### PlayerBlob Scene

Responsibilities:
- Read keyboard and controller input.
- Apply movement using acceleration, drag, and downward pull.
- Track current `mass`.
- Grow visually after absorption.
- Detect defeat conditions near the floor.

Suggested node type:
- `CharacterBody2D` for predictable movement and easy tuning.

#### Dot Scene

Responsibilities:
- Spawn off-screen along the edges.
- Move toward the current blob position.
- Notify the blob when absorbed.
- Remove itself after collision or if otherwise invalid.

Suggested node type:
- `Area2D` for lightweight hit detection.

#### HUD

Responsibilities:
- Show survival time.
- Show a restart prompt after game over.
- Remain visually minimal and readable.

### Movement Model

The blob should feel light early and heavy later.

#### Input

- Keyboard arrows drive 2D movement.
- Controller left stick maps to the same directional input.

#### Motion

- Input applies acceleration toward the desired direction.
- Drag reduces velocity over time so the blob feels smooth rather than slippery.
- A constant downward pull acts like gravity.
- Increasing mass reduces acceleration effectiveness.
- Increasing mass also strengthens the practical effect of downward pull, making upward recovery harder.

This should create three phases:
- Early game: responsive and forgiving.
- Mid game: tense but manageable.
- Late game: heavy, strained, and increasingly inevitable.

### Growth System

Each absorbed dot increments a single `mass` variable.

`mass` affects:
- Visual scale of the blob.
- Acceleration multiplier.
- Effective heaviness / difficulty escaping downward drift.
- Defeat pressure near the floor.

Growth should be noticeable every few hits, but not so aggressive that the run collapses immediately.

### Dot Spawning And Threat Model

- Dots spawn just beyond one of the screen edges.
- Their initial direction is aimed toward the blob.
- Spawn cadence starts moderate and ramps up over time.
- The result should feel increasingly crowded without requiring complex AI.

This keeps the screen readable while steadily raising tension.

### Game Over Rule

The approved defeat condition is physical rather than threshold-only.

The run ends when:
- The blob is at the bottom of the screen or in clear floor contact.
- The blob no longer has enough upward recovery to meaningfully separate from the floor.

This should be implemented with a bottom-contact check plus an upward recovery threshold, not only with a raw size limit.

### Visual Direction

- Black background.
- White assets only.
- Pixel-style shapes with nearest-neighbor rendering.
- No decorative colors.
- Clean silhouettes for both blob and dots.

The visual tone should feel stark, readable, and intentionally minimal.

### Audio

Audio is optional for the first playable version. If included later, it should remain minimal: a soft absorb sound, a death thud, and possibly a subtle ambient loop.

### Controls

- Keyboard arrows: movement.
- Controller left stick or d-pad: movement.
- Restart key/button after game over.

Input naming should be set up in Godot's input map for both device types.

### Testing Strategy

Manual verification should cover:

- The blob moves correctly with keyboard arrows.
- The blob moves correctly with a controller.
- Dots spawn from screen edges only.
- Dots are absorbed on contact.
- Absorption increases both size and heaviness.
- Spawn pressure increases over time.
- Survival time increments correctly during active play.
- Game over happens only when the blob truly cannot lift from the floor.
- Restart resets mass, position, timer, and active dots.

### Risks And Tuning Notes

- If mass reduces movement too quickly, the game will feel unfair.
- If mass reduces movement too slowly, the core fantasy will be weak.
- If spawn rate ramps too hard, the game becomes chaotic instead of tense.
- If the floor defeat threshold is too strict, the game may end while recovery still feels possible.

The most important tuning work is balancing mass growth, acceleration loss, downward pull, and spawn ramp.

### Recommended Initial Tuning Direction

- Start the blob small and clearly maneuverable.
- Make the first 10-20 seconds readable and survivable.
- Let visual growth become obvious by the mid game.
- Let the late game feel desperate but not random.
- Target fast restarts so repeated runs feel frictionless.
