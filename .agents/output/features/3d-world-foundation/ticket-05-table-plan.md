# Ticket 5: Create Table Scene — Implementation Plan

## Overview

Create a simple flat ground plane scene (`world/table/table.tscn`) that serves as a visual and physical reference beneath the hex board. This is a scene-only file with no script logic.

## Phase 1: Create Table Scene (Single Phase)

Since this is a simple scene file with no logic, it's a single implementation phase.

### Scope

- Create `world/table/table.tscn` with Node3D root (purely decorative)
- Add MeshInstance3D with PlaneMesh (24×24)
- Apply StandardMaterial3D with dark green/brown albedo
- No collision or physics — purely visual ground reference

### Implementation Steps

1. Create directory `world/table/`
2. Create scene file `table.tscn` with proper structure:
   - StaticBody3D root node
   - MeshInstance3D child with PlaneMesh submesh
   - CollisionShape3D child with BoxShape3D
3. Configure PlaneMesh: size=Vector2(24, 24)
4. Create and assign StandardMaterial3D with dark color (e.g., Color(0.2, 0.5, 0.2) for green)
5. Configure BoxShape3D: size=Vector3(24, 0.1, 24), position=Vector3(0, -0.1, 0)

### Tests & Verification

Since this is a scene file with no logic, verification is visual:
- Scene opens without errors
- Plane appears as a flat surface at correct size
- Can see it in the editor viewport

### Design Rationale

- **StaticBody3D:** Provides physics presence without movement (board will rest on it)
- **PlaneMesh:** Simple 2D plane geometry, perfect for a flat ground surface
- **BoxShape3D for collision:** More efficient than matching plane geometry exactly; thin height (0.1) provides clear reference plane
- **Position offset (y=-0.1):** Ensures board sits flush on top of collision volume, not clipping into it
- **Size 24×24:** Matches HexBoard's default radius (3) with comfortable margin for any sized board
- **Color coding:** Dark green suggests natural ground, placeholder art appropriate for MVP
