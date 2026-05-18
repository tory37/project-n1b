# common/

Shared utility classes used across the project. No game logic lives here — only stateless helpers that transform inputs to outputs.

---

## HexUtils

`hex_utils.gd` — Static utility for axial hex grid math.

### Coordinate System

This project uses **axial coordinates** `(q, r)` to address hex cells. This is the standard choice for hex grid math — it keeps all operations (distance, neighbors, pathfinding) clean and branchless. The alternative (offset coordinates) requires special-casing even and odd rows everywhere.

Axial is a projection of **cube coordinates** `(q, r, s)`, where the constraint `q + r + s = 0` always holds. Since `s` is always derivable as `-q - r`, we only store two values.

The grid uses **pointy-top** hex orientation. The hexes point up and down, and columns of hexes are vertically aligned.

> Reference: [Hexagonal Grids — Red Blob Games](https://www.redblobgames.com/grids/hexagons/) — the authoritative source for all coordinate math used here.

---

### API

#### `axial_to_pixel_pointy_top(q, r, size) -> Vector2`

Converts an axial hex coordinate to a pixel position in world space.

`size` is the circumradius of the hex (center to corner). This scales the entire grid.

Uses the pointy-top forward matrix:

```
x = size * (√3·q  +  √3/2·r)
y = size * (         3/2 ·r)
```

#### `pixel_to_axial_pointy_top(x, y, size) -> Vector2i`

Inverse of `axial_to_pixel_pointy_top`. Finds which hex cell contains a given pixel position.

Applies the inverse matrix, then calls `axial_round` to snap the result to a valid hex center.

#### `axial_round(q, r) -> Vector2i`  *(used internally)*

Rounds a floating-point axial position to the nearest hex cell.

Naive rounding of `q` and `r` independently can produce an invalid cube position where `q + r + s ≠ 0`. The correct approach: round all three cube axes, find the one with the largest rounding error, and recompute it from the other two.

#### `get_neighbors(q, r) -> Array[Vector2i]`

Returns the six adjacent hex cells in axial coordinates, in clockwise order starting from the right.

#### `get_distance(q1, r1, q2, r2) -> int`

Returns the number of hex steps between two cells (no diagonal shortcut — every step moves one hex).

Uses the cube distance formula `(|Δq| + |Δr| + |Δs|) / 2`, with `s` reconstructed inline.

---

### Usage

All methods are `static` — call them directly on the class, no instantiation needed:

```gdscript
var pixel_pos: Vector2 = HexUtils.axial_to_pixel_pointy_top(2, -1, 32.0)
var hex_coord: Vector2i = HexUtils.pixel_to_axial_pointy_top(mouse_pos.x, mouse_pos.y, 32.0)
var neighbors: Array[Vector2i] = HexUtils.get_neighbors(0, 0)
var dist: int = HexUtils.get_distance(0, 0, 3, -1)
```
