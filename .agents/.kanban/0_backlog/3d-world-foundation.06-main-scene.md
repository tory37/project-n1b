---
epic: 3d-world-foundation
ticket: main-scene
created: 2026-05-17
priority: high
---

# 3D World Foundation: Create Main Scene & Script

**Step 6 of 7** — Create the root 3D scene with camera and lights in `world/main/`.

## Files to Create

- `world/main/main.gd` — minimal setup script
- `world/main/main.tscn` — root scene (Node3D)

## Scene Structure

```
Node3D (main.gd)
  ├─ Camera3D
  ├─ DirectionalLight3D
  ├─ HexBoard (instance of hex_board.tscn)
  └─ Table (instance of table.tscn)
```

## Camera Setup

**Camera3D:**
- Position: `Vector3(0, 9, 7)`
- Rotation (degrees): `Vector3(-52, 0, 0)`
- This provides an angled isometric-ish view:
  - Player sees fronts of future pieces/entities
  - Good visibility of board surface
  - Not top-down, not side-view — perspective mix

## Light Setup

**DirectionalLight3D:**
- Rotation: angle shadows to be readable (recommend similar to camera angle)
- Energy: reasonable default
- Direction: so shadows fall away from camera, not towards it

## Script: main.gd

Minimal — just ensure scene loads:

```gdscript
extends Node3D

func _ready() -> void:
    print("Main scene loaded - 3D world ready")
```

Optional: Add debug output for loaded components.

## Scene Assembly

1. Create Node3D root, attach main.gd
2. Add Camera3D child, configure position/rotation
3. Add DirectionalLight3D child, orient for readable shadows
4. Instance `hex_board.tscn` as child
   - Ensure `hex_tile_scene` export is assigned
5. Instance `table.tscn` as child

## Acceptance Criteria

- [ ] main.gd created with minimal _ready() logic
- [ ] main.tscn created with correct structure
- [ ] Camera positioned at (0, 9, 7) with rotation (-52, 0, 0)
- [ ] DirectionalLight3D added and shadows readable
- [ ] HexBoard and Table instances present and visible
- [ ] Scene runs without errors
- [ ] Visual preview shows board at reasonable perspective
