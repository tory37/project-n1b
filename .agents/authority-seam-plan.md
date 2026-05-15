# Plan: Authority-Seam Refactor + Architecture Documentation
**Branch:** `refactor/authority-seam`
**Scope:** Refactor `game_state.gd` to use integer player IDs and a request/apply mutation pattern. Document the rule in `AGENTS.md` and `README.md`.

---

## Why This Change

`game_state.gd` currently mutates state directly from any call site and uses a named `enum Player { ONE, TWO }`. When we wire up Godot 4 multiplayer, every state-mutating function will need to become an RPC that only executes on the authoritative peer (the host). The `request_*` / `_apply_*` split creates that seam now, so adding `@rpc` decorators later requires no game logic changes — only the transport layer changes.

This is NOT adding networking. This is writing code that does not resist networking.

---

## What Is In Scope

- [ ] Remove `enum Player { ONE, TWO }` from `game_state.gd`; replace with plain `int` IDs (`0` = player one, `1` = player two)
- [ ] Rename `active_player: Player` → `active_player: int`
- [ ] Split every state-mutating public function into `request_*` (entrypoint, will become RPC) and `_apply_*` (authority-only execution)
- [ ] Write `tests/unit/test_game_state.gd` with full coverage of the new public API
- [ ] Add a **Networking Architecture** section to `AGENTS.md`
- [ ] Add a brief **Networking Architecture** note to `README.md`

## What Is Out of Scope

- Actual `@rpc` decorators or any network transport (deferred)
- Changing `resource_display.gd` — it reads state only, no mutations, already uses `int`
- Multi-player marker design (explicitly deferred — see `.agents/research-multiplayer-first-vs-later.md`)

---

## Tests First

**File:** `tests/unit/test_game_state.gd`

GUT tests for the new public API. State must be reset in `before_each()` by calling `GameState.reset()` (a new test-helper method we'll add to GameState).

### Functions to test

| Function | Test Cases |
|---|---|
| `request_spend_ap(amount)` | Reduces active player AP; moves marker by amount; emits `marker_moved`; triggers `_apply_switch_turn` when marker >= max_marker_value |
| `request_add_currency(player, amount)` | Increases target player currency; emits `resources_updated` |
| `request_switch_turn()` | Active player changes; new player receives base_income currency; new player AP set from marker; emits `player_switched` |
| `request_end_turn_manual()` | Does nothing when marker is on own side; calls `_apply_switch_turn` when marker is on opponent's side |
| `reset()` | Restores all state to defaults (test helper) |

---

## Implementation Steps

### Step 1 — Refactor `game_state.gd`

**Remove the enum. Replace with int constants for readability:**

```gdscript
const PLAYER_ONE: int = 0
const PLAYER_TWO: int = 1
```

**Replace binary flip with modular arithmetic:**
```gdscript
# Before
active_player = Player.TWO if active_player == Player.ONE else Player.ONE
# After
active_player = (active_player + 1) % 2
```

**Replace hardcoded direction with int-based check + DESIGN TODO:**
```gdscript
# DESIGN TODO: marker direction is a 2-player mechanic — revisit if N-player is ever designed
var move_direction: float = 1.0 if active_player == PLAYER_ONE else -1.0
```

**Introduce request/apply split for all mutating functions:**

| Current function | Becomes (request) | Becomes (apply, private) |
|---|---|---|
| `spend_ap(amount)` | `request_spend_ap(amount)` | `_apply_spend_ap(amount)` |
| `add_currency(player, amount)` | `request_add_currency(player, amount)` | `_apply_add_currency(player, amount)` |
| `switch_turn()` | `request_switch_turn()` | `_apply_switch_turn()` |
| `end_turn_manual()` | `request_end_turn_manual()` | *(validates, then calls `_apply_switch_turn`)* |

`request_*` in the local prototype simply calls `_apply_*` directly. The future networking layer will intercept `request_*` and route to the host via RPC.

**Add `reset()` for testability:**
```gdscript
func reset() -> void:
    active_player = PLAYER_ONE
    marker_position = 0.0
    player_resources = {
        PLAYER_ONE: {"ap": 1, "currency": 0},
        PLAYER_TWO: {"ap": 0, "currency": 0}
    }
```

### Step 2 — Write `tests/unit/test_game_state.gd`

Full GUT coverage per the test table above. Tests reset state in `before_each`.

### Step 3 — Update `AGENTS.md`

Add a **Networking Architecture** section with the request/apply rule explicitly stated as a project mandate.

### Step 4 — Update `README.md`

Add a brief **Networking Architecture** note directing readers to the rule in `AGENTS.md`.

---

## Key Decisions & Rationale

| Decision | Rationale |
|---|---|
| `int` constants instead of enum | Enum values are just named ints. Removing the enum eliminates a layer of implicit 2-player assumption with zero runtime cost. |
| `(active_player + 1) % 2` for turn flip | Same behavior as the binary flip, but generalizes to N if the turn_order array is ever introduced. No behavior change for 2P. |
| `request_*` calls `_apply_*` directly in local prototype | Zero overhead, zero behavior change. When networking is added, `request_*` becomes `@rpc("any_peer")` and `_apply_*` becomes `@rpc("authority")`. Game logic is untouched. |
| `reset()` added to GameState | GUT tests against a singleton need state isolation. `reset()` is a test seam, not game logic. |

---

## Verification Gate (before Step 7)

User must:
1. Run GUT tests: all `test_game_state.gd` tests pass.
2. Launch game, verify ResourceDisplay updates correctly on turn switch.
3. Verify AP spend moves the marker and triggers turn switch at max value.
4. Confirm no regressions in existing `test_signal_bus.gd` tests.
