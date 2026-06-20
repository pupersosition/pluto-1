# Collapse Animation Design

## Goal
When the player loses by collapsing under their own mass, the blob should not remain static on the floor or ceiling. It should play a short, readable collapse animation before the restart prompt appears.

## Behavior
- The animation applies only to mass-collapse defeat from `PlayerBlob.is_defeated()`.
- Warp consumption keeps its existing suck-in disappearance behavior.
- On collapse, gameplay stops immediately: enemy spawning, powerup spawning, and active warps stop as they do today.
- The player blob briefly squashes against the gravity surface, then disappears into a burst of white pixel particles.
- The restart prompt appears after a short delay so the player can see the burst.

## Visual Direction
Use a procedural pixel burst to match the project’s existing pixel-art effect style. Particles should originate at the blob’s position, fly outward with slight gravity-like drift, shrink/fade, and then stop drawing.

## Architecture
Add a focused collapse effect under the existing `BlastLayer` visual-effects layer. `main.gd` will distinguish collapse game over from warp game over and trigger the effect only for collapse. `player_blob.gd` will expose a small method for hiding/freezing the blob when the collapse effect starts.

## Testing
Add lightweight source-level regression tests because no Godot binary is available in this environment. Tests should verify that collapse defeat routes through a dedicated collapse game-over path, that warp defeat does not trigger the collapse effect, and that the effect/player APIs exist.
