class_name HexUtils
extends Node
## Static utility for axial hex grid math.
## See common/README.md for coordinate system overview and usage examples.

## Clockwise neighbor offsets in axial (q, r) space, starting from the right.
const DIRECTIONS: Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(1, -1),
	Vector2i(0, -1),
	Vector2i(-1, 0),
	Vector2i(-1, 1),
	Vector2i(0, 1),
]

const APOTHEM_MODIFIER: float = sqrt(3.0) / 2.0

static func get_apothem_from_size(size: float) -> float:
	return size * APOTHEM_MODIFIER


## https://www.redblobgames.com/grids/hexagons/#conversions-offset
## Pointy Top - oddr
static func axial_to_oddr(q: int, r: int) -> Vector2i:
	var parity: int = r & 1
	var col: int = q + (r - parity) / 2
	var row: int = r
	return Vector2i(col, row)


static func oddr_to_axial(col: int, row: int) -> Vector2i:
	var parity: int = row & 1
	var q: int = col - (row - parity) / 2
	var r: int = row
	return Vector2i(q, r)


## Point Typ - evenr
static func axial_to_evenr(q: int, r: int) -> Vector2i:
	var parity: int = r & 1
	var col: int = q + (r + parity) / 2
	var row: int = r
	return Vector2i(col, row)


static func evenr_to_axial(col: int, row: int) -> Vector2i:
	var parity: int = row & 1
	var q: int = col - (row + parity) / 2
	var r: int = row
	return Vector2i(q, r)


## Flat Top - evenq
static func axial_to_evenq(q: int, r: int) -> Vector2i:
	var parity: int = q & 1
	var col: int = q
	var row: int = r + (q + parity) / 2
	return Vector2i(col, row)


static func evenq_to_axial(col: int, row: int) -> Vector2i:
	var parity: int = col & 1
	var q: int = col
	var r: int = row - (col + parity) / 2
	return Vector2i(q, r)


## Flat Top - oddq
static func axial_to_oddq(q: int, r: int) -> Vector2i:
	var parity: int = q & 1
	var col: int = q
	var row: int = r + (q - parity) / 2
	return Vector2i(col, row)


static func oddq_to_axial(col: int, row: int) -> Vector2i:
	var parity: int = col & 1
	var q: int = col
	var r: int = row - (col - parity) / 2
	return Vector2i(q, r)


## Converts a pointy-top axial hex coordinate to a 3D world position (XZ plane).
## https://www.redblobgames.com/grids/hexagons/#hex-to-pixel
static func axial_to_world_pointy_top(q: int, r: int, size: float) -> Vector3:
	var x: float = size * (sqrt(3.0) * q + sqrt(3.0) / 2.0 * r)
	var z: float = size * (3.0 / 2.0 * r)
	return Vector3(x, 0.0, z)


## Converts a flat-top axial hex coordinate to a 3D world position (XZ plane).
static func axial_to_world_flat_top(q: int, r: int, size: float) -> Vector3:
	var x: float = size * (3.0 / 2.0 * q)
	var z: float = size * (sqrt(3.0) / 2.0 * q + sqrt(3.0) * r)
	return Vector3(x, 0.0, z)


## Dispatches to the named variant based on orientation.
static func axial_to_world(
		q: int,
		r: int,
		size: float,
		orientation: HexOrientation.Type,
		offset: Vector3 = Vector3.ZERO,
) -> Vector3:
	if orientation == HexOrientation.FLAT_TOP:
		return axial_to_world_flat_top(q, r, size) + offset
	return axial_to_world_pointy_top(q, r, size) + offset


## Converts a 3D world position back to the nearest pointy-top axial hex coordinate.
## https://www.redblobgames.com/grids/hexagons/#pixel-to-hex
static func world_to_axial_pointy_top(point: Vector3, size: float) -> Vector2i:
	var q: float = (sqrt(3.0) / 3.0 * point.x - 1.0 / 3.0 * point.z) / size
	var r: float = (2.0 / 3.0 * point.z) / size
	return axial_round(q, r)


## Converts a 3D world position back to the nearest flat-top axial hex coordinate.
static func world_to_axial_flat_top(point: Vector3, size: float) -> Vector2i:
	var q: float = (2.0 / 3.0 * point.x) / size
	var r: float = (-1.0 / 3.0 * point.x + sqrt(3.0) / 3.0 * point.z) / size
	return axial_round(q, r)


## Dispatches to the named variant based on orientation.
static func world_to_axial(
		point: Vector3,
		size: float,
		orientation: HexOrientation.Type,
) -> Vector2i:
	if orientation == HexOrientation.FLAT_TOP:
		return world_to_axial_flat_top(point, size)
	return world_to_axial_pointy_top(point, size)


## Rounds a float axial position to the nearest valid hex cell.
## Operates in cube space to preserve the q+r+s=0 constraint.
static func axial_round(q: float, r: float) -> Vector2i:
	var s: float = -q - r
	var rq: float = roundf(q)
	var rr: float = roundf(r)
	var rs: float = roundf(s)

	var q_diff: float = absf(rq - q)
	var r_diff: float = absf(rr - r)
	var s_diff: float = absf(rs - s)

	if q_diff > r_diff and q_diff > s_diff:
		rq = -rr - rs
	elif r_diff > s_diff:
		rr = -rq - rs

	return Vector2i(int(rq), int(rr))


## Returns all six neighboring hex cells in axial coordinates.
static func get_neighbors(q: int, r: int) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	for d in DIRECTIONS:
		neighbors.append(Vector2i(q + d.x, r + d.y))
	return neighbors


## Returns the number of hex steps between two cells.
static func get_distance(q1: int, r1: int, q2: int, r2: int) -> int:
	return int((abs(q1 - q2) + abs(q1 + r1 - q2 - r2) + abs(r1 - r2)) / 2)
