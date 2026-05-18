---
epic: 3d-world-foundation
ticket: hex-board
created: 2026-05-17
priority: high
---

# 3D World Foundation: Create HexBoard Scene & Script

**Step 4 of 7** — Create the hex board generator in `world/hex_board/`.

## Files to Create

- `world/hex_board/hex_board.gd` — procedural tile generation
- `world/hex_board/hex_board.tscn` — scene (Node3D root)

## Scene Structure

```
Node3D (hex_board.gd)
  [tile instances spawned at runtime]
```

## Script: hex_board.gd

**Exports:**
- `@export var hex_size: float = 1.0`
- `@export var board_radius: int = 3`
- `@export var orientation: HexUtils.HexOrientation = HexUtils.HexOrientation.POINTY_TOP`
- `@export var hex_tile_scene: PackedScene` — reference to HexTile scene

**Internal State:**
- `var _tiles: Dictionary = {}` — maps `Vector2i` (axial) → `HexTile` node

**Methods:**
- `func generate() -> void` — called in `_ready()`, fills board with tiles
- `func get_tile(axial: Vector2i) -> HexTile` — returns HexTile node or null
- `func _spawn_tile(q: int, r: int) -> void` — helper to instantiate and position a tile

**Generation Algorithm:**

```gdscript
# Fill all cells within board_radius
for q in range(-board_radius, board_radius + 1):
    for r in range(max(-board_radius, -q - board_radius), min(board_radius, -q + board_radius) + 1):
        _spawn_tile(q, r)
```

**Tile Positioning:**
- Call `HexUtils.axial_to_world(q, r, hex_size, orientation)` to compute world position
- Place tile instance at that position
- Set tile's `axial_coord = Vector2i(q, r)`
- Store in `_tiles` dictionary

**Signal Forwarding (optional for MVP):**
- Optionally listen to tile signals and re-emit or log (for future game logic)

## Scene Setup

1. Create Node3D, attach hex_board.gd
2. Leave empty — tiles are spawned in `_ready()`
3. Assign HexTile scene to `@export hex_tile_scene`

## Acceptance Criteria

- [ ] hex_board.gd created with all exports/methods
- [ ] hex_board.tscn created (minimal Node3D)
- [ ] `generate()` fills board correctly for given radius
- [ ] Tiles positioned at correct 3D world coords
- [ ] `get_tile()` retrieves tiles by axial coord
- [ ] Verify visually: board appears as ring of hexes in Godot preview
