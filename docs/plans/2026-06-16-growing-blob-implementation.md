# Growing Blob Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a small single-screen Godot 4.6.3 arcade game where the player controls a growing blob, absorbs incoming dots, gets heavier over time, and loses when the blob can no longer lift itself from the floor.

**Architecture:** Use a single `Main` gameplay scene to own spawning, timing, HUD updates, and restart flow. Use a `CharacterBody2D` player scene for deterministic movement and growth tuning, plus a lightweight `Area2D` dot scene for seeking behavior and absorption events.

**Tech Stack:** Godot 4.6.3, GDScript, built-in 2D nodes, Godot Input Map, manual gameplay verification with headless syntax checks where possible.

---

### Task 1: Project Setup And Input Map

**Files:**
- Modify: `project.godot`
- Create: `scenes/main.tscn`
- Create: `scripts/main.gd`

**Step 1: Write the failing test**

Define the expected setup before implementation:
- `project.godot` contains input actions for `move_left`, `move_right`, `move_up`, `move_down`, and `restart`.
- `project.godot` sets `res://scenes/main.tscn` as the main scene.
- `scenes/main.tscn` exists and attaches `res://scripts/main.gd`.

**Step 2: Run verification to confirm the setup does not exist yet**

Run: `godot --headless --path . --quit`
Expected: project opens, but there is no gameplay main scene and no custom input actions yet.

**Step 3: Write minimal implementation**

Update `project.godot` to:
- add the movement and restart input actions,
- bind keyboard arrows,
- bind controller d-pad and left stick equivalents,
- set `run/main_scene="res://scenes/main.tscn"`.

Create `scenes/main.tscn` with a simple root `Node2D` using `res://scripts/main.gd`.

Create `scripts/main.gd` with a minimal script skeleton:

```gdscript
extends Node2D
```

**Step 4: Run verification to confirm the project still opens**

Run: `godot --headless --path . --quit`
Expected: the project opens and exits without script parse errors.

**Step 5: Commit**

```bash
git add project.godot scenes/main.tscn scripts/main.gd
git commit -m "feat: initialize growing blob game scene"
```

### Task 2: Player Blob Scene Skeleton

**Files:**
- Create: `scenes/player_blob.tscn`
- Create: `scripts/player_blob.gd`
- Modify: `scenes/main.tscn`

**Step 1: Write the failing test**

Define the expected scene structure before implementation:
- `scenes/player_blob.tscn` exists.
- The root node is `CharacterBody2D`.
- It includes visible white blob art and a collision shape.
- `scenes/main.tscn` instantiates the blob scene.

**Step 2: Run verification to confirm the player scene does not exist yet**

Run: `godot --headless --path . --quit`
Expected: project opens, but no player blob is present in the main scene yet.

**Step 3: Write minimal implementation**

Create `scenes/player_blob.tscn` with:
- root `CharacterBody2D`,
- `Sprite2D` or `Polygon2D` for the white blob,
- `CollisionShape2D` sized to the starting blob.

Create `scripts/player_blob.gd`:

```gdscript
extends CharacterBody2D

var mass: float = 1.0
```

Instance the player scene inside `scenes/main.tscn`.

**Step 4: Run verification to confirm the player scene loads**

Run: `godot --headless --path . --quit`
Expected: the project opens and exits without missing-scene or script errors.

**Step 5: Commit**

```bash
git add scenes/player_blob.tscn scripts/player_blob.gd scenes/main.tscn
git commit -m "feat: add player blob scene skeleton"
```

### Task 3: Blob Movement With Acceleration And Drag

**Files:**
- Modify: `scripts/player_blob.gd`

**Step 1: Write the failing test**

Define the expected behavior before implementation:
- Holding directional input accelerates the blob in that direction.
- Releasing input lets drag reduce velocity.
- A constant downward pull affects the blob each frame.
- Heavier mass will later reduce effective control.

**Step 2: Run verification to confirm movement is not implemented yet**

Run: `godot --path .`
Expected: the blob appears, but it does not respond to movement input yet.

**Step 3: Write minimal implementation**

Implement `_physics_process(delta)` in `scripts/player_blob.gd` with:
- input vector read from the input map,
- acceleration toward input,
- drag applied over time,
- downward force,
- `move_and_slide()`.

Suggested starting shape:

```gdscript
const BASE_ACCELERATION := 900.0
const BASE_DRAG := 6.0
const BASE_GRAVITY := 500.0

func _physics_process(delta: float) -> void:
    var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    velocity += input_vector * BASE_ACCELERATION * delta
    velocity.y += BASE_GRAVITY * delta
    velocity = velocity.lerp(Vector2.ZERO, BASE_DRAG * delta)
    move_and_slide()
```

Tune the drag logic as needed so it does not erase gravity entirely.

**Step 4: Run verification to confirm movement works**

Run: `godot --path .`
Expected: arrow keys and controller input move the blob, and the blob drifts downward naturally.

**Step 5: Commit**

```bash
git add scripts/player_blob.gd
git commit -m "feat: add blob acceleration movement"
```

### Task 4: Floor Boundaries And Playfield Framing

**Files:**
- Modify: `scenes/main.tscn`
- Modify: `scripts/main.gd`

**Step 1: Write the failing test**

Define the expected behavior before implementation:
- The playfield has a visible bottom boundary behavior.
- The blob cannot fall forever.
- The camera/view frame reads as a single contained arena.

**Step 2: Run verification to confirm the arena is not bounded yet**

Run: `godot --path .`
Expected: the blob can drift outside the intended play area or lacks a meaningful floor.

**Step 3: Write minimal implementation**

Add arena framing in `scenes/main.tscn` using one of these simple patterns:
- static collision walls and floor, or
- clamp logic in `scripts/main.gd` / `scripts/player_blob.gd`.

Prefer static world boundaries for clearer floor contact behavior.

Ensure the background remains black and the arena reads clearly.

**Step 4: Run verification to confirm floor behavior works**

Run: `godot --path .`
Expected: the blob remains inside the arena and can settle onto a visible bottom area.

**Step 5: Commit**

```bash
git add scenes/main.tscn scripts/main.gd
git commit -m "feat: add arena boundaries"
```

### Task 5: Dot Scene Skeleton

**Files:**
- Create: `scenes/dot.tscn`
- Create: `scripts/dot.gd`

**Step 1: Write the failing test**

Define the expected scene structure before implementation:
- `scenes/dot.tscn` exists.
- The root is `Area2D`.
- It has a visible white shape and collision area.

**Step 2: Run verification to confirm the dot scene does not exist yet**

Run: `godot --headless --path . --quit`
Expected: the project opens, but there is no dot scene in the project yet.

**Step 3: Write minimal implementation**

Create `scenes/dot.tscn` with:
- root `Area2D`,
- visible white pixel-style art,
- `CollisionShape2D`.

Create `scripts/dot.gd`:

```gdscript
extends Area2D

var target: Node2D
var speed: float = 120.0
```

**Step 4: Run verification to confirm the dot scene parses**

Run: `godot --headless --path . --quit`
Expected: the project opens and exits without scene or script parse errors.

**Step 5: Commit**

```bash
git add scenes/dot.tscn scripts/dot.gd
git commit -m "feat: add incoming dot scene"
```

### Task 6: Dot Seeking Movement

**Files:**
- Modify: `scripts/dot.gd`

**Step 1: Write the failing test**

Define the expected behavior before implementation:
- Each dot travels toward the blob.
- If the blob moves, newly updated direction still generally tracks it.

**Step 2: Run verification to confirm dot movement is not implemented yet**

Run: `godot --path .`
Expected: if a dot is manually placed in the scene, it does not move yet.

**Step 3: Write minimal implementation**

Implement `_process(delta)` or `_physics_process(delta)` in `scripts/dot.gd`:

```gdscript
func _physics_process(delta: float) -> void:
    if target == null:
        return

    var direction := global_position.direction_to(target.global_position)
    global_position += direction * speed * delta
```

Use physics step if collision timing feels more reliable there.

**Step 4: Run verification to confirm dots seek the blob**

Run: `godot --path .`
Expected: placed dots move toward the blob on screen.

**Step 5: Commit**

```bash
git add scripts/dot.gd
git commit -m "feat: add dot seeking behavior"
```

### Task 7: Dot Spawner In Main Scene

**Files:**
- Modify: `scripts/main.gd`
- Modify: `scenes/main.tscn`

**Step 1: Write the failing test**

Define the expected behavior before implementation:
- Dots spawn from off-screen edges only.
- Spawn timer repeatedly creates new dots.
- Each spawned dot is assigned the blob as its target.

**Step 2: Run verification to confirm automatic spawning is not implemented yet**

Run: `godot --path .`
Expected: no dots appear automatically.

**Step 3: Write minimal implementation**

In `scripts/main.gd`:
- preload `res://scenes/dot.tscn`,
- store a reference to the player blob,
- choose a random screen edge,
- spawn dots just beyond the visible arena,
- assign the blob as `target`.

Add a `Timer` node in `scenes/main.tscn` if not already present.

**Step 4: Run verification to confirm edge spawning works**

Run: `godot --path .`
Expected: dots appear from all four edges over time and travel toward the blob.

**Step 5: Commit**

```bash
git add scripts/main.gd scenes/main.tscn
git commit -m "feat: spawn dots from screen edges"
```

### Task 8: Absorption And Mass Growth

**Files:**
- Modify: `scripts/player_blob.gd`
- Modify: `scripts/dot.gd`

**Step 1: Write the failing test**

Define the expected behavior before implementation:
- When a dot touches the blob, the dot disappears.
- The blob's `mass` increases.
- The blob's visible size increases.

**Step 2: Run verification to confirm collisions do not yet cause growth**

Run: `godot --path .`
Expected: dots may overlap the blob, but no mass or size change happens yet.

**Step 3: Write minimal implementation**

In `scripts/player_blob.gd`, add a method like:

```gdscript
func absorb_dot(amount: float = 1.0) -> void:
    mass += amount
    scale = Vector2.ONE * (1.0 + (mass - 1.0) * 0.05)
```

In `scripts/dot.gd`, connect overlap detection so the blob receives `absorb_dot()` and the dot queues itself for deletion.

**Step 4: Run verification to confirm growth works**

Run: `godot --path .`
Expected: each collision removes a dot and makes the blob visibly larger.

**Step 5: Commit**

```bash
git add scripts/player_blob.gd scripts/dot.gd
git commit -m "feat: add blob growth on absorption"
```

### Task 9: Mass-Based Movement Penalties

**Files:**
- Modify: `scripts/player_blob.gd`

**Step 1: Write the failing test**

Define the expected behavior before implementation:
- Higher mass reduces acceleration response.
- Higher mass makes downward pull harder to overcome.
- The blob remains controllable in the early and middle game.

**Step 2: Run verification to confirm mass does not yet affect movement enough**

Run: `godot --path .`
Expected: the blob grows visually, but handling does not change clearly yet.

**Step 3: Write minimal implementation**

Update movement formulas in `scripts/player_blob.gd` so `mass` affects:
- acceleration multiplier,
- effective gravity or lift resistance,
- possibly drag tuning if needed.

Prefer a smooth formula such as:

```gdscript
var control_factor := 1.0 / sqrt(mass)
var gravity_factor := 1.0 + mass * 0.08
```

Then apply those factors inside `_physics_process(delta)`.

**Step 4: Run verification to confirm heaviness is felt**

Run: `godot --path .`
Expected: after enough absorbed dots, the blob feels noticeably slower and heavier.

**Step 5: Commit**

```bash
git add scripts/player_blob.gd
git commit -m "feat: scale blob movement by mass"
```

### Task 10: Survival Timer And Minimal HUD

**Files:**
- Create: `scenes/hud.tscn`
- Create: `scripts/hud.gd`
- Modify: `scenes/main.tscn`
- Modify: `scripts/main.gd`

**Step 1: Write the failing test**

Define the expected behavior before implementation:
- The screen shows elapsed survival time during play.
- The HUD remains readable on a black background.
- The HUD can later show game-over restart text.

**Step 2: Run verification to confirm no HUD exists yet**

Run: `godot --path .`
Expected: there is no visible timer on screen.

**Step 3: Write minimal implementation**

Create a HUD scene using `CanvasLayer` and labels.

Implement a simple HUD script API such as:

```gdscript
extends CanvasLayer

func set_time_text(value: String) -> void:
    pass

func show_restart_prompt(visible_state: bool) -> void:
    pass
```

Update `scripts/main.gd` to track elapsed time and push formatted text to the HUD.

**Step 4: Run verification to confirm timer display works**

Run: `godot --path .`
Expected: a white timer is visible and increments while the run is active.

**Step 5: Commit**

```bash
git add scenes/hud.tscn scripts/hud.gd scenes/main.tscn scripts/main.gd
git commit -m "feat: add survival timer HUD"
```

### Task 11: Spawn Ramp Over Time

**Files:**
- Modify: `scripts/main.gd`

**Step 1: Write the failing test**

Define the expected behavior before implementation:
- Dots spawn faster as survival time increases.
- The ramp raises tension without becoming unreadable immediately.

**Step 2: Run verification to confirm spawn pressure stays flat**

Run: `godot --path .`
Expected: spawn frequency remains constant across the run.

**Step 3: Write minimal implementation**

In `scripts/main.gd`, update spawn timing using elapsed time, for example by:
- reducing timer wait time gradually to a safe minimum, or
- scheduling the next spawn interval procedurally.

Keep the ramp simple and easy to tune.

**Step 4: Run verification to confirm spawn pressure increases**

Run: `godot --path .`
Expected: later moments of the run feel busier than the opening seconds.

**Step 5: Commit**

```bash
git add scripts/main.gd
git commit -m "feat: ramp dot spawn pressure over time"
```

### Task 12: Floor Defeat Rule

**Files:**
- Modify: `scripts/player_blob.gd`
- Modify: `scripts/main.gd`

**Step 1: Write the failing test**

Define the expected behavior before implementation:
- The game does not end purely on size.
- The game ends when the blob is on the floor and cannot recover upward.
- The defeat check feels physical and readable.

**Step 2: Run verification to confirm game over is not implemented yet**

Run: `godot --path .`
Expected: the blob can grow and rest on the floor without ending the run.

**Step 3: Write minimal implementation**

In `scripts/player_blob.gd`, add a method that reports whether the blob is defeated based on:
- floor contact status,
- upward velocity or recovery capability,
- optional short grace check to avoid false positives.

In `scripts/main.gd`, stop the run when that defeat condition is met.

**Step 4: Run verification to confirm defeat behavior works**

Run: `godot --path .`
Expected: the run ends only when the blob has effectively collapsed onto the floor and cannot lift away.

**Step 5: Commit**

```bash
git add scripts/player_blob.gd scripts/main.gd
git commit -m "feat: add floor-based game over"
```

### Task 13: Game Over State And Restart Flow

**Files:**
- Modify: `scripts/main.gd`
- Modify: `scripts/hud.gd`

**Step 1: Write the failing test**

Define the expected behavior before implementation:
- Dot spawning stops on game over.
- The final blob remains visible.
- A restart prompt appears.
- Pressing restart starts a fresh run.

**Step 2: Run verification to confirm restart flow is incomplete**

Run: `godot --path .`
Expected: after game over, the game either continues running or cannot restart cleanly.

**Step 3: Write minimal implementation**

In `scripts/main.gd`:
- freeze the active run state,
- stop spawn timers,
- clear remaining dots on restart,
- reset timer, blob state, and HUD.

In `scripts/hud.gd`, show a restart hint only after defeat.

**Step 4: Run verification to confirm clean restart works**

Run: `godot --path .`
Expected: restart reliably resets mass, blob position, elapsed time, and active threats.

**Step 5: Commit**

```bash
git add scripts/main.gd scripts/hud.gd
git commit -m "feat: add restart flow after collapse"
```

### Task 14: Pixel Presentation Polish

**Files:**
- Modify: `project.godot`
- Modify: `scenes/player_blob.tscn`
- Modify: `scenes/dot.tscn`
- Modify: `scenes/hud.tscn`

**Step 1: Write the failing test**

Define the expected behavior before implementation:
- The game reads as a simple pixel-style black-and-white prototype.
- Blob and dot silhouettes are crisp.
- The HUD remains minimal and readable.

**Step 2: Run verification to confirm visuals still need final tuning**

Run: `godot --path .`
Expected: the prototype functions, but visual sharpness or readability may still need cleanup.

**Step 3: Write minimal implementation**

Apply final presentation tuning:
- ensure nearest-neighbor texture behavior where relevant,
- keep background black,
- keep gameplay art white,
- align blob and dot sizes to a clean pixel look,
- keep HUD small and unobtrusive.

**Step 4: Run verification to confirm the presentation matches the brief**

Run: `godot --path .`
Expected: the game feels visually coherent, minimal, and readable.

**Step 5: Commit**

```bash
git add project.godot scenes/player_blob.tscn scenes/dot.tscn scenes/hud.tscn
git commit -m "style: polish black and white pixel presentation"
```

### Task 15: Final Verification

**Files:**
- No code changes expected unless issues are found.

**Step 1: Write the failing test**

Define the final acceptance checklist:
- Keyboard and controller both move the blob.
- Dots spawn from edges and seek the blob.
- Absorption grows the blob.
- Higher mass makes movement harder.
- Survival time displays correctly.
- The run ends only when the blob cannot lift from the floor.
- Restart works cleanly.

**Step 2: Run verification to confirm any remaining defects**

Run: `godot --path .`
Expected: note any behavior that still fails the acceptance checklist.

**Step 3: Write minimal fixes**

Resolve only the specific remaining issues found in Step 2. Avoid adding extra features.

**Step 4: Run full verification again**

Run: `godot --path .`
Run: `godot --headless --path . --quit`
Expected: the game plays correctly and scripts parse cleanly in headless mode.

**Step 5: Commit**

```bash
git add .
git commit -m "fix: finalize growing blob gameplay loop"
```
