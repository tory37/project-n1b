---
epic: 3d-world-foundation
ticket: hex-utils-impl
created: 2026-05-17
priority: high
---

# 3D World Foundation: Update HexUtils Implementation

**Step 2 of 7** — Implement 3D world position math in `common/hex_utils.gd`.

## Scope

Remove 2D pixel functions:
- `Q_BASIS_POINTY_TOP`, `R_BASIS_POINTY_TOP`
- `Q_INV_BASIS_POINTY_TOP`, `R_INV_BASIS_POINTY_TOP`
- `axial_to_pixel_pointy_top`
- `pixel_to_axial_pointy_top`

Add 3D world position functions:

**Enum:**
```gdscript
enum HexOrientation { POINTY_TOP, FLAT_TOP }
```

**Named variants:**
- `axial_to_world_pointy_top(q: int, r: int, size: float) -> Vector3`
- `world_to_axial_pointy_top(point: Vector3, size: float) -> Vector2i`
- `axial_to_world_flat_top(q: int, r: int, size: float) -> Vector3`
- `world_to_axial_flat_top(point: Vector3, size: float) -> Vector2i`

**Generic dispatchers:**
- `axial_to_world(q: int, r: int, size: float, orientation: HexOrientation) -> Vector3`
- `world_to_axial(point: Vector3, size: float, orientation: HexOrientation) -> Vector2i`

## Math Reference

**Pointy-top:**
- `axial_to_world`: x = size * (sqrt(3) * q + sqrt(3)/2 * r), y = 0, z = size * (3/2 * r)`
- `world_to_axial`: q_float = (sqrt(3)/3 * x - 1/3 * z) / size, r_float = (2/3 * z) / size`

**Flat-top:**
- `axial_to_world`: x = size * (3/2 * q), y = 0, z = size * (sqrt(3)/2 * q + sqrt(3) * r)`
- `world_to_axial`: q_float = (2/3 * x) / size, r_float = (-1/3 * x + sqrt(3)/3 * z) / size`

## Acceptance Criteria

- [ ] HexOrientation enum added
- [ ] All named 3D functions implemented
- [ ] All dispatcher functions implemented
- [ ] All 2D pixel functions removed
- [ ] Tests pass (verify step 1 tests run successfully)
