---
epic: 3d-world-foundation
ticket: hex-tile
created: 2026-05-17
priority: high
---

# 3D World Foundation: Create HexTile Scene & Script

**Step 3 of 7** — Create the individual hex tile scene and logic in `world/hex_tile/`.

## Files to Create

- `world/hex_tile/hex_tile.gd` — script with signals and hover logic
- `world/hex_tile/hex_tile.tscn` — scene (StaticBody3D root)

## Scene Structure

```
StaticBody3D (hex_tile.gd)
  └─ MeshInstance3D       ← CylinderMesh, radial_segments=6, height=0.2
  └─ CollisionShape3D     ← CylinderShape3D matching mesh
```

## Script: hex_tile.gd

**Exports:**
- `@export var axial_coord: Vector2i`

**Signals:**
- `signal tile_clicked(axial: Vector2i)`
- `signal tile_hovered(axial: Vector2i)`
- `signal tile_unhovered(axial: Vector2i)`

**Methods:**
- `func set_highlighted(on: bool) -> void` — swap between default and hover material
- `func _input_event(camera: Node, event: InputEvent, position: Vector3, normal: Vector3, shape_idx: int) -> void` — emit `tile_clicked` on mouse click
- `func _mouse_enter() -> void` — emit `tile_hovered`, call `set_highlighted(true)`
- `func _mouse_exit() -> void` — emit `tile_unhovered`, call `set_highlighted(false)`

**Materials:**
- Create two `StandardMaterial3D` materials (default grey, hovered highlight)
- Swap in `set_highlighted`

## Scene Setup

1. Create StaticBody3D node, attach hex_tile.gd
2. Add MeshInstance3D:
   - CylinderMesh (radial_segments=6, height=0.2)
   - Apply default material
3. Add CollisionShape3D:
   - CylinderShape3D to match mesh
4. Configure collision layer/mask for mouse input detection

## Acceptance Criteria

- [ ] hex_tile.gd created with all exports/signals/methods
- [ ] hex_tile.tscn created with correct scene structure
- [ ] Two materials created (default, hovered)
- [ ] Mouse input events trigger signals correctly
- [ ] Hover highlighting works (tested manually in scene preview)
