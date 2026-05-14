extends GutTest

const SIZE := 32.0


# --- axial_to_pixel ---

func test_axial_to_pixel_origin_is_zero() -> void:
	var result := HexUtils.axial_to_pixel(0, 0, SIZE)
	assert_eq(result, Vector2.ZERO)

func test_axial_to_pixel_q_axis_moves_right() -> void:
	var result := HexUtils.axial_to_pixel(1, 0, SIZE)
	assert_almost_eq(result.x, SIZE * sqrt(3.0), 0.001)
	assert_almost_eq(result.y, 0.0, 0.001)

func test_axial_to_pixel_r_axis_moves_down_and_right() -> void:
	var result := HexUtils.axial_to_pixel(0, 1, SIZE)
	assert_almost_eq(result.x, SIZE * sqrt(3.0) / 2.0, 0.001)
	assert_almost_eq(result.y, SIZE * 1.5, 0.001)

func test_axial_to_pixel_scales_with_size() -> void:
	var small := HexUtils.axial_to_pixel(1, 0, 16.0)
	var large := HexUtils.axial_to_pixel(1, 0, 32.0)
	assert_almost_eq(large.x, small.x * 2.0, 0.001)


# --- pixel_to_axial ---

func test_pixel_to_axial_origin_is_zero() -> void:
	var result := HexUtils.pixel_to_axial(0.0, 0.0, SIZE)
	assert_eq(result, Vector2i.ZERO)

func test_pixel_to_axial_round_trips_with_axial_to_pixel() -> void:
	var coords := [Vector2i(2, -1), Vector2i(-3, 2), Vector2i(0, 4), Vector2i(1, 1)]
	for axial in coords:
		var pixel := HexUtils.axial_to_pixel(axial.x, axial.y, SIZE)
		var back := HexUtils.pixel_to_axial(pixel.x, pixel.y, SIZE)
		assert_eq(back, axial, "Round trip failed for %s" % str(axial))

func test_pixel_to_axial_snaps_nearby_pixel_to_nearest_hex() -> void:
	# A pixel just slightly off-center of hex (1,0) should still resolve to (1,0).
	var center := HexUtils.axial_to_pixel(1, 0, SIZE)
	var result := HexUtils.pixel_to_axial(center.x + 2.0, center.y + 2.0, SIZE)
	assert_eq(result, Vector2i(1, 0))


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
	for cell in expected:
		assert_true(neighbors.has(cell), "Missing neighbor %s" % str(cell))

func test_get_neighbors_are_all_distance_one_from_origin() -> void:
	for neighbor in HexUtils.get_neighbors(0, 0):
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
