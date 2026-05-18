---
epic: 3d-world-foundation
ticket: table
created: 2026-05-17
priority: high
---

# 3D World Foundation: Create Table Scene

**Step 5 of 7** — Create the flat table plane beneath the board in `world/table/`.

## Files to Create

- `world/table/table.tscn` — scene only (no script needed for MVP)

## Scene Structure

```
StaticBody3D
  └─ MeshInstance3D  ← PlaneMesh, size=24x24
  └─ CollisionShape3D ← BoxShape3D (thin, large)
```

## Mesh Setup

**MeshInstance3D:**
- Mesh: `PlaneMesh`
  - size: `Vector2(24, 24)`
- Material: `StandardMaterial3D`
  - Albedo color: dark green or brown (table surface)
  - Keep simple — placeholder art

## Collision Setup

**CollisionShape3D:**
- Shape: `BoxShape3D`
- Size: `Vector3(24, 0.1, 24)` (thin plane, large coverage)
- Position slightly below (y = -0.1) so board sits on top

## Physical Properties

- Static body (no movement)
- Allows board to rest on it visually
- Provides a ground reference for camera framing

## Decision Note

Table is implemented as **purely decorative** (Node3D root with MeshInstance3D only). No physics/collision shapes — it's just a visual ground reference. Can be enhanced with collision later if gameplay needs it.

## Acceptance Criteria

- [ ] table.tscn created with correct structure
- [ ] PlaneMesh sized appropriately (24x24)
- [ ] Material applied (simple dark color)
- [ ] Visually appears as ground plane in scene preview
