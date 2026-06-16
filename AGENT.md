# AGENT.md

Guidelines for coding agents working in this Godot project.

## Project
- Godot 4 project.
- Main scene: `res://scenes/main.tscn`.
- Gameplay scripts live in `scripts/`.
- Scene files live in `scenes/`.

## Coding style
- Use typed GDScript where practical.
- Avoid `:=` when the right-hand side can be inferred as `Variant`; warnings are treated as errors.
- Prefer small, focused scripts and scenes.
- Keep visuals procedural/pixel-art friendly unless assets are explicitly added.

## Validation
- If Godot is available, run a project parse/check before committing.
- If Godot is not available, mention that validation could not be run.

## Gameplay notes
- Player blob: `scripts/player_blob.gd`.
- Main spawning/game loop: `scripts/main.gd`.
- Regular dots: `scripts/dot.gd`.
- Smart red enemies: `scripts/smart_enemy.gd`.
- Powerups use collectible star scenes and are activated with Space.
