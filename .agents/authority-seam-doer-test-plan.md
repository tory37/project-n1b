# Doer Test Plan: Authority Seam Refactor

## Entry Point

Launch the Godot 4 editor. Open the project. Run the GUT panel (Scene > Run GUT) before launching the game.

---

## Step 1 — GUT Unit Tests

1. Open the GUT panel and run all tests in `tests/unit/test_game_state.gd`.
2. **Expected (before implementation):** All tests in this file fail or error — `PLAYER_ONE`, `PLAYER_TWO`, `request_*` functions, and `reset()` do not exist yet.
3. Confirm `test_signal_bus.gd` still passes — no regressions.

---

## Step 2 — After Implementation: Unit Tests Pass

1. Re-run `tests/unit/test_game_state.gd` after the refactor.
2. **Expected:** All tests pass (green).
3. Re-confirm `test_signal_bus.gd` still passes.

---

## Step 3 — In-Game: AP Spend & Marker Movement

1. Launch the game (`F5` or Play button).
2. Verify the ResourceDisplay shows "Player: 1", correct AP and Currency values.
3. Trigger an AP spend action (e.g., move an entity or press any wired AP-spend button).
4. **Expected:** Marker UI updates. ResourceDisplay shows reduced AP. No crashes or errors in the Output panel.

---

## Step 4 — In-Game: Automatic Turn Switch

1. Continue spending AP until the marker reaches `max_marker_value` (default: 5).
2. **Expected:** Active player switches to Player 2 automatically. ResourceDisplay updates to show "Player: 2". Player 2 receives `base_income` currency (default: 2).

---

## Step 5 — In-Game: Manual End Turn

1. During Player 1's turn, push the marker to Player 2's side (positive value > 0).
2. Press the "End Turn" button.
3. **Expected:** Turn switches to Player 2.
4. Reset the game. Try pressing "End Turn" when the marker is at 0 or on Player 1's side.
5. **Expected:** Nothing happens — no turn switch.

---

## Checkpoints

- [ ] All `test_game_state.gd` tests fail before implementation (TDD baseline)
- [ ] All `test_game_state.gd` tests pass after implementation
- [ ] `test_signal_bus.gd` passes before and after (no regression)
- [ ] ResourceDisplay updates correctly in-game
- [ ] Automatic turn switch fires at max marker value
- [ ] Manual end turn is correctly gated by marker position
