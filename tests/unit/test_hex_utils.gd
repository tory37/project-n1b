extends GutTest

const SIZE := 1.0


# --- axial_to_world_pointy_top ---

func test_axial_to_world_pointy_top_origin_is_zero() -> void:
	assert_eq(HexUtils.axial_to_world_pointy_top(0, 0, SIZE), Vector3.ZERO)

func test_axial_to_world_pointy_top_q_axis() -> void:
	var result: Vector3 = HexUtils.axial_to_world_pointy_top(1, 0, SIZE)
	assert_almost_eq(result.x, sqrt(3.0), 0.001)
	assert_eq(result.y, 0.0)
	assert_almost_eq(result.z, 0.0, 0.001)

func test_axial_to_world_pointy_top_r_axis() -> void:
	var result: Vector3 = HexUtils.axial_to_world_pointy_top(0, 1, SIZE)
	assert_almost_eq(result.x, sqrt(3.0) / 2.0, 0.001)
	assert_eq(result.y, 0.0)
	assert_almost_eq(result.z, 1.5, 0.001)

func test_axial_to_world_pointy_top_round_trip() -> void:
	for coord: Vector2i in [Vector2i(2, -1), Vector2i(-3, 2), Vector2i(0, 4), Vector2i(1, 1)]:
		var world: Vector3 = HexUtils.axial_to_world_pointy_top(coord.x, coord.y, SIZE)
		var back: Vector2i = HexUtils.world_to_axial_pointy_top(world, SIZE)
		assert_eq(back, coord, "Round trip failed for %s" % str(coord))


# --- axial_to_world_flat_top ---

func test_axial_to_world_flat_top_origin_is_zero() -> void:
	assert_eq(HexUtils.axial_to_world_flat_top(0, 0, SIZE), Vector3.ZERO)

func test_axial_to_world_flat_top_q_axis() -> void:
	var result: Vector3 = HexUtils.axial_to_world_flat_top(1, 0, SIZE)
	assert_almost_eq(result.x, 1.5, 0.001)
	assert_eq(result.y, 0.0)
	assert_almost_eq(result.z, sqrt(3.0) / 2.0, 0.001)

func test_axial_to_world_flat_top_r_axis() -> void:
	var result: Vector3 = HexUtils.axial_to_world_flat_top(0, 1, SIZE)
	assert_almost_eq(result.x, 0.0, 0.001)
	assert_eq(result.y, 0.0)
	assert_almost_eq(result.z, sqrt(3.0), 0.001)

func test_axial_to_world_flat_top_round_trip() -> void:
	for coord: Vector2i in [Vector2i(2, -1), Vector2i(-3, 2), Vector2i(0, 4), Vector2i(1, 1)]:
		var world: Vector3 = HexUtils.axial_to_world_flat_top(coord.x, coord.y, SIZE)
		var back: Vector2i = HexUtils.world_to_axial_flat_top(world, SIZE)
		assert_eq(back, coord, "Round trip failed for %s" % str(coord))


# --- dispatcher ---

func test_axial_to_world_dispatcher_pointy_top() -> void:
	var coord := Vector2i(2, -1)
	assert_eq(
		HexUtils.axial_to_world(coord.x, coord.y, SIZE, HexUtils.HexOrientation.POINTY_TOP),
		HexUtils.axial_to_world_pointy_top(coord.x, coord.y, SIZE)
	)

func test_axial_to_world_dispatcher_flat_top() -> void:
	var coord := Vector2i(2, -1)
	assert_eq(
		HexUtils.axial_to_world(coord.x, coord.y, SIZE, HexUtils.HexOrientation.FLAT_TOP),
		HexUtils.axial_to_world_flat_top(coord.x, coord.y, SIZE)
	)


# --- axial_round ---

func test_axial_round_integer_coords_unchanged() -> void:
	assert_eq(HexUtils.axial_round(2.0, -1.0), Vector2i(2, -1))
	assert_eq(HexUtils.axial_round(0.0, 0.0), Vector2i(0, 0))

func test_axial_round_snaps_to_correct_hex_when_q_has_largest_error() -> void:
	# q=0.4, r=0.3, s=-0.7 — naive rounds give (0,0,-1), which is invalid (sum=-1).
	# q_diff=0.4 is largest, so q is recomputed: rq = -0 - (-1) = 1. Result: (1, 0).
	var result := HexUtils.axial_round(0.4, 0.3)
	assert_eq(result, Vector2i(1, 0))

func test_axial_round_snaps_to_correct_hex_when_r_has_largest_error() -> void:
	var result := HexUtils.axial_round(0.1, 0.6)
	assert_eq(result, Vector2i(0, 1))


# --- get_neighbors ---

func test_get_neighbors_always_returns_six() -> void:
	assert_eq(HexUtils.get_neighbors(0, 0).size(), 6)
	assert_eq(HexUtils.get_neighbors(5, -3).size(), 6)

func test_get_neighbors_origin_contains_expected_cells() -> void:
	var neighbors := HexUtils.get_neighbors(0, 0)
	var expected := [
		Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1),
		Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1)
	]
	for cell: Vector2i in expected:
		assert_true(neighbors.has(cell), "Missing neighbor %s" % str(cell))

func test_get_neighbors_are_all_distance_one_from_origin() -> void:
	for neighbor: Vector2i in HexUtils.get_neighbors(0, 0):
		var dist := HexUtils.get_distance(0, 0, neighbor.x, neighbor.y)
		assert_eq(dist, 1, "Neighbor %s is not distance 1" % str(neighbor))


# --- get_distance ---

func test_get_distance_same_cell_is_zero() -> void:
	assert_eq(HexUtils.get_distance(0, 0, 0, 0), 0)
	assert_eq(HexUtils.get_distance(3, -2, 3, -2), 0)

func test_get_distance_adjacent_cells_is_one() -> void:
	assert_eq(HexUtils.get_distance(0, 0, 1, 0), 1)
	assert_eq(HexUtils.get_distance(0, 0, 0, 1), 1)
	assert_eq(HexUtils.get_distance(0, 0, -1, 1), 1)

func test_get_distance_known_values() -> void:
	assert_eq(HexUtils.get_distance(0, 0, 2, 0), 2)
	assert_eq(HexUtils.get_distance(0, 0, 3, -3), 3)
	assert_eq(HexUtils.get_distance(1, 1, -1, -1), 4)

func test_get_distance_is_symmetric() -> void:
	assert_eq(
		HexUtils.get_distance(2, -3, 0, 1),
		HexUtils.get_distance(0, 1, 2, -3)
	)
