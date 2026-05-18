---
epic: 3d-world-foundation
ticket: integration-verify
created: 2026-05-17
priority: high
---

# 3D World Foundation: Integration & Verification

**Step 8 of 8** — Final integration testing and verification. All prior tickets must be completed before this.

## Smoke Tests

Run these manual checks:

1. **Project launches cleanly**
   - F5 (or play button) starts main scene
   - No import errors, warnings, or script errors in Output

2. **Board renders correctly**
   - Hex tiles visible in viewport
   - Tiles arranged in ring pattern (radius 3 by default)
   - Both orientations work (toggle `HexBoard.orientation` in inspector)

3. **Table visible**
   - Flat plane beneath the board
   - Board sits above it at correct Y position

4. **Camera view**
   - Board visible at ~70° angled perspective
   - Can see tile faces and board surface
   - Shadows cast readably

5. **Hover interaction (manual)**
   - Click on a tile — verify no errors
   - Hover over tiles — visual highlight appears
   - Unhover — highlight disappears

6. **GUT Tests pass**
   - Run GUT test suite
   - All hex_utils tests pass (3D + inherited tests)
   - Verify test report shows green

## Follow-up Validation

- [ ] All prior 7 tickets committed and verified
- [ ] GUT tests pass completely
- [ ] Project launches and displays 3D board
- [ ] Tiles render with correct positions and spacing
- [ ] Camera provides good viewing angle
- [ ] No console errors or warnings
- [ ] Hover highlighting works on tiles
- [ ] Ready to move to next story (Card Hand UI + Drag)

## Notes

This is the final integration gate. If any checks fail, return to the relevant ticket to fix before marking complete.
