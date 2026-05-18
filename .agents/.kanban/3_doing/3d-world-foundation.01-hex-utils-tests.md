---
epic: 3d-world-foundation
ticket: hex-utils-tests
created: 2026-05-17
priority: high
---

# 3D World Foundation: Update HexUtils Tests

**Step 1 of 7** — Test-first approach. Update `tests/unit/test_hex_utils.gd` to remove 2D pixel tests and add 3D world position tests.

## Scope

Remove all existing 2D pixel-based tests:
- `test_axial_to_pixel_*` (4 tests)
- `test_pixel_to_axial_*` (3 tests)

Add new 3D world position tests for both orientations:
- **Pointy-top:** origin zero, q-axis, r-axis, round-trip
- **Flat-top:** origin zero, q-axis, r-axis, round-trip
- **Dispatchers:** verify generic functions match named variants

Keep unchanged: `test_axial_round_*`, `test_get_neighbors_*`, `test_get_distance_*` tests.

## Test List

New tests to add:
- `test_axial_to_world_pointy_top_origin_is_zero`
- `test_axial_to_world_pointy_top_q_axis`
- `test_axial_to_world_pointy_top_r_axis`
- `test_axial_to_world_pointy_top_round_trip`
- `test_axial_to_world_flat_top_origin_is_zero`
- `test_axial_to_world_flat_top_q_axis`
- `test_axial_to_world_flat_top_r_axis`
- `test_axial_to_world_flat_top_round_trip`
- `test_axial_to_world_dispatcher_pointy_top`
- `test_axial_to_world_dispatcher_flat_top`
- `test_world_to_axial_pointy_top_origin_is_zero`
- `test_world_to_axial_flat_top_origin_is_zero`
- `test_world_to_axial_round_trips`
- `test_world_to_axial_snaps_nearby_point_to_nearest_hex`

## Implementation Phases

- [x] Review existing test file and identify needed additions
- [x] Add `world_to_axial_pointy_top` origin and snapping tests
- [x] Add `world_to_axial_flat_top` origin and snapping tests
- [x] Add `world_to_axial` dispatcher tests
- [ ] Run full test suite and verify all tests pass

## Acceptance Criteria

- [x] All old 2D tests removed (none present to remove)
- [x] All new 3D tests added 
- [ ] All tests passing
- [ ] Unchanged tests still pass (axial_round, get_neighbors, get_distance)
