class_name HexUtils
extends Node

## Static utility for axial hex grid math (pointy-top orientation).
## See common/README.md for coordinate system overview and usage examples.

## Clockwise neighbor offsets in axial (q, r) space, starting from the right.
const DIRECTIONS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1),
	Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1)
]

## Converts an axial hex coordinate to a pixel position. [param size] is the circumradius (center to corner).
static func axial_to_pixel(q: int, r: int, size: float) -> Vector2:
	var x: float = size * (sqrt(3.0) * q + sqrt(3.0) / 2.0 * r)
	var y: float = size * (1.5 * r)
	return Vector2(x, y)

## Converts a pixel position back to the nearest axial hex coordinate.
static func pixel_to_axial(x: float, y: float, size: float) -> Vector2i:
	var q: float = (sqrt(3.0) / 3.0 * x - 1.0 / 3.0 * y) / size
	var r: float = (2.0 / 3.0 * y) / size
	return axial_round(q, r)

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
