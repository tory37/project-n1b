# feat/main-scene: Build Minimal Playable Main Scene

**Last Updated:** 2026-05-15
**Status:** Not Started
**Branch:** (create from master)
**PR:** N/A

## Summary

The game has no playable scene. All Autoloads (`GameState`, `SignalBus`) are wired up and fully tested, but there is no `main.tscn` to launch. The next session builds a minimal main scene sufficient to visually exercise the Turn Economy: a ResourceDisplay showing AP/Currency for the active player, a Marker UI (horizontal slider) showing the Tug-of-War track, and a manual "End Turn" button. No hex grid or entities needed yet — just enough to make the game launchable and the core economy visible.

## Implementation Complete

- `systems/game_state.gd` — fully refactored with authority seam (`request_*` / `_apply_*`), int player IDs, `reset()` for tests
- `autoload/signal_bus.gd` — signals: `player_switched(int)`, `marker_moved(float)`, `resources_updated(int, int, int)`
- `ui/resource_display.gd` — displays active player AP and Currency, already connected to SignalBus
- `tests/unit/test_game_state.gd` — 42 passing GUT tests
- `AGENTS.md` / `README.md` — networking architecture mandate documented

## Pending

- No `main.tscn` exists — the project has no launchable scene
- `ui/resource_display.gd` has a scene file counterpart to create or wire up
- Marker UI (slider or progress bar showing `marker_position`) does not exist
- "End Turn" button calling `GameState.request_end_turn_manual()` does not exist
- `project.godot` has no `run/main_scene` set

## Technical Notes

- All GameState mutations go through `request_*` — the main scene should never call `_apply_*` directly
- `marker_position` is a signed float: positive = Player 1 has pushed toward Player 2's side; negative = Player 2 pushing back. The slider should visually represent this (center = 0, right = Player 1 advancing)
- `max_marker_value` defaults to `5.0` — slider range should be `-5` to `+5`
- Turn switches automatically when `abs(marker_position) >= max_marker_value` — no button needed for that path
- "End Turn" button should only be enabled when marker is on the opponent's side (the validation lives in `request_end_turn_manual`, so the button can always be visible — wrong presses are just silently ignored)
- There is no way to spend AP from the UI yet — consider adding a debug "Spend 1 AP" button for testing purposes
- `ui/resource_display.gd` already exists and connects to SignalBus in `_ready()` — it just needs a matching `.tscn`

## Next Steps

1. Checkout master, pull, create branch `feat/main-scene`
2. Read `ui/resource_display.gd` and `systems/game_state.gd` to confirm current API before touching any scene
3. Plan the scene tree for `main.tscn`:
   - `Node2D` (root)
     - `MarginContainer` → `VBoxContainer`
       - `ResourceDisplay` (instance of `ui/resource_display.tscn`)
       - `HSlider` (marker — range -5 to +5, read-only, updated via `SignalBus.marker_moved`)
       - `Button` ("End Turn" — calls `GameState.request_end_turn_manual()`)
       - `Button` ("Spend 1 AP" — debug only, calls `GameState.request_spend_ap(1)`)
4. Present plan, await approval
5. Write tests first (GUT) — verify marker slider updates on `marker_moved` signal, verify End Turn button is wired correctly
6. Build the scene and scripts
7. Set `main.tscn` as the main scene in `project.godot`
8. Have user run GUT, then launch and manually verify per Doer Test Plan
