# Godot Best Practices Review — turn-state-draw-card (rev 2)
**Date:** 2026-05-20 16:38
**Scope:** All `.gd` files on `turn-state-draw-card` branch, post "Code Review" commits

---

## Summary

Three of the five previous criticals were cleanly fixed: the signal disconnect leak in `TurnPhaseDrawCard`, the `@export` timing bug in `GameManager._init()`, and the `@onready`/return-type annotation warnings in `resource_display.gd`. The foundation (FSM on `RefCounted`, request/apply seam) remains sound.

However, the "Code Review" commits introduced **six new critical bugs** that make the game unlaunchable: a missing `start()` method that main.gd calls directly, two missing signals wired in `_subscribe_to_game_signals()`, still-swapped argument order on `spend_ap_requested`, an undefined variable reference in `deck_view.gd`, and an unreachable `_apply_start_game()` method. The test file also remains fully out of sync.

---

## Critical Findings

**[CRITICAL] [D / Scene Coupling] `main.gd:8` → `game_manager.gd` — `start()` method does not exist**

`main.gd` calls `game_manager.start()` unconditionally. `GameManager` has no `start()` method. The game will crash with `Invalid call. Nonexistent function 'start' in base 'GameManager'` on every launch.

The method that initializes the turn FSM is `_on_start_game_requested()` (line 57 of `game_manager.gd`), which is a private signal callback, not a public entrypoint. Either:
- Rename it to `start()` and make it the public entrypoint that `main.gd` calls, or
- Keep it as a signal callback and emit `start_game_requested` from `main.gd` (requires adding that signal to `SignalBus`).

---

**[CRITICAL] [C / Signal Communication] `game_manager.gd:75` — `add_ap_requested` signal does not exist on `SignalBus`**

```gdscript
SignalBus.add_ap_requested.connect(_on_request_add_ap)
```

`SignalBus` has no `add_ap_requested` signal (only `spend_ap_requested`). This line will throw `Invalid get index 'add_ap_requested' on base 'Node'` and crash `_subscribe_to_game_signals()` at startup — meaning all other signal connections below it are also never made.

Fix: Either add `signal add_ap_requested(amount: int)` to `SignalBus`, or remove this line if AP is only added via turn/pass-turn logic (it's currently never called externally anyway).

---

**[CRITICAL] [C / Signal Communication] `game_manager.gd:60` — `game_state_updated` signal does not exist on `SignalBus`**

```gdscript
SignalBus.game_state_updated.emit(active_player, ap_tracker)
```

`SignalBus` defines `game_state_initialized` but not `game_state_updated`. This emit will crash the moment the game starts.

Fix: Either add `signal game_state_updated(active_player: int, ap_tracker: float)` to `SignalBus`, or change this to emit `game_state_initialized` (whichever matches the intended semantic).

---

**[CRITICAL] [B / Signal Seam] `game_manager.gd:117` — `spend_ap_requested` argument order still swapped**

`SignalBus` defines: `signal spend_ap_requested(player_index: int, amount: int)`

The handler is:
```gdscript
func _on_request_spend_ap(amount: int, _player_id: int, ) -> void:
```

Godot passes signal arguments positionally. The handler receives `player_index` (0 or 1) as `amount`, and the actual spend amount as `_player_id` (which is immediately discarded). Every AP spend uses the seat index (0 or 1) as its cost — the actual amount is silently thrown away.

Fix: Flip the parameter order:
```gdscript
func _on_request_spend_ap(player_index: int, amount: int) -> void:
```
Then decide whether `player_index` should route the spend (currently `active_player` is hardcoded in `_apply_spend_ap`).

---

**[CRITICAL] [C / Signal Communication] `deck_view.gd:40` — undefined variable `_owner_player_id`**

```gdscript
SignalBus.deck_clicked.emit(_owner_player_id)
```

The `@export` variable was correctly renamed from `_owner_player_id` to `owner_player_id` (line 6) as part of the prior review fix. But the `_input_event` handler still references `_owner_player_id` (with the underscore). This is an undefined variable reference — clicking the deck will crash.

Fix: Change line 40 to `SignalBus.deck_clicked.emit(owner_player_id)`.

---

**[CRITICAL] [B / Signal Seam] `game_manager.gd:65-68` — `_apply_start_game()` is dead code; `player_game_state_initialized` never emitted correctly**

```gdscript
func _apply_start_game() -> void:
    print("[Flow] GameManager applying start game")
    SignalBus.player_game_state_initialized.emit(active_player)  # emits int, not PlayerGameState
```

This method is never called from anywhere in the codebase. The signal it emits is also typed incorrectly: `signal player_game_state_initialized(player_game_state: PlayerGameState)` expects a `PlayerGameState`, but `active_player` is an `int`. The receiver (`resource_display.gd:21`) calls `player_game_state.currency` which would crash on an int.

Fix: Either call `_apply_start_game()` from `_on_start_game_requested()`, or remove it and emit the signal with the correct type. The emit should be something like:
```gdscript
SignalBus.player_game_state_initialized.emit(player_game_state[active_player])
```

---

**[CRITICAL] [K / Testing] `tests/unit/test_game_state.gd` — Entire file references a dead API (unchanged from last review)**

The test file is fully out of sync with the current `GameManager` implementation and cannot run:

- `GameManager.reset()` — method does not exist
- `GameManager.PLAYER_ONE` / `GameManager.PLAYER_TWO` — constants live on `PlayerSeat`, not `GameManager`
- `GameManager._request_add_ap()` — doesn't exist; current method is `_on_request_add_ap`
- `GameManager.player_game_state[...]["currency"]` — `player_game_state` values are `PlayerGameState` objects, not Dictionaries
- `SignalBus.resources_updated` — signal does not exist on `SignalBus`
- Tests set `GameManager.local_player_id` to switch turns, but `_apply_switch_turn()` changes `active_player` — these are different variables

This must be fully rewritten against the current API.

---

## Warnings

**[WARNING] [L / File Layout] `game_manager.gd:29` — `can_spend_ap()` (public method) appears before `_init()` and `_ready()`**

Required order: constants → exports → variables → `_init` → `_ready` → signal callbacks → public methods → private methods. `can_spend_ap` sits at line 29 before the lifecycle methods at lines 36/48.

---

**[WARNING] [A / Code Standards] `game_manager.gd` — trailing comma on signal handler signature**

```gdscript
func _on_request_spend_ap(amount: int, _player_id: int, ) -> void:
```

Trailing comma after the last parameter is unusual and may confuse readers. Remove it.

---

**[WARNING] [A / Code Standards] `turn_phase_main.gd` — `enter()` missing `exit()` override**

`TurnPhaseMain` overrides `enter()` but not `exit()`. While the base class no-ops `exit()`, explicitly overriding both makes the lifecycle intent clear and prevents signal connection leaks if signals are ever added here. Compare with `TurnPhaseDrawCard` which connects/disconnects in both.

---

**[WARNING] [A / Code Standards] `game_start_phase.gd` — `enter()` missing `exit()` override (same as above)**

---

## Suggestions

**[SUGGESTION] [A / Code Standards] `game_manager.gd` — clarify `active_player` vs `local_player_id` semantics**

`active_player` (whose turn it is) and `local_player_id` (which seat this client owns) are distinct concepts. The dead test file conflated them throughout. Consider a brief doc comment on each to prevent future confusion:

```gdscript
## Whose turn it is currently; changes on switch_turn.
var active_player: int = PlayerSeat.PLAYER_ONE
## The seat this client controls; fixed after lobby assignment.
var local_player_id: int = PlayerSeat.PLAYER_ONE
```

---

**[SUGGESTION] [K / Testing] Missing test coverage**

- `PlayerGameState.deck_to_hand()` — no test for empty deck (already guards, but worth asserting no crash)
- `PlayerGameState.use_card_from_hand()` — no test for card-not-in-hand guard
- `FiniteStateMachine.change_state()` — no test that `exit()` is called on the old state before `enter()` is called on the new one

---

## What Was Fixed Since Last Review

| Finding | Status |
|---|---|
| `TurnPhaseDrawCard` signal connection leak (no disconnect on `exit()`) | ✅ Fixed |
| `@export var test_deck` accessed in `_init()` before Godot populates it | ✅ Fixed — moved to `_ready()` |
| `resource_display.gd` missing return type annotations | ✅ Fixed |
| `resource_display.gd` `@onready` vars missing `_` prefix | ✅ Fixed |
| `deck_view.gd` `@export var` with `_` prefix | ✅ Fixed (but left a dangling `_owner_player_id` reference — see Critical above) |
| `hex_board.gd` untyped Dictionary | ✅ Fixed |
| `hex_board.gd` dead assignment | ✅ Fixed |
| `main.gd` missing null guard on exported dependency | ✅ Fixed |

---

## Positive Notes

- **`FiniteState` / `FiniteStateMachine` on `RefCounted`** — correct Godot practice; no scene overhead.
- **`request_*` / `_apply_*` seam pattern** — still consistently applied wherever wired up.
- **`TurnPhaseDrawCard`** — signal connect/disconnect lifecycle is now correct.
- **`HexBoard._spawn_tile`** — properties set before `add_child()`, correct pattern.
- **`PlayerGameState`** — clean `RefCounted` data class; `deck_to_hand()` and `use_card_from_hand()` guard correctly.
- **`SignalBus`** — well-organized with comment groupings per domain.

---

## Test Coverage

| File | Status |
|---|---|
| `test_signal_bus.gd` | Adequate smoke-test for bus signal contracts |
| `test_game_state.gd` | **Broken** — must be fully rewritten (see Critical above) |

**Missing:**
- `TurnPhaseDrawCard` — enter/exit lifecycle, signal connect/disconnect
- `PlayerGameState` — empty-deck guard, card-not-in-hand guard
- `FiniteStateMachine` — state transition ordering

---

## Files Reviewed

- `autoload/local_session.gd`
- `autoload/signal_bus.gd`
- `src/common/finite_state_machine/finite_state.gd`
- `src/common/finite_state_machine/finite_state_machine.gd`
- `src/deck/deck_view.gd`
- `src/game_manager/game_manager.gd`
- `src/game_manager/game_phase/game_start_phase.gd`
- `src/game_manager/player_game_state.gd`
- `src/game_manager/player_seat.gd`
- `src/game_manager/turn_phase/turn_phase_draw_card.gd`
- `src/game_manager/turn_phase/turn_phase_main.gd`
- `src/levels/main/main.gd`
- `src/ui/resource_display.gd`
- `src/world/hex_board/hex_board.gd`
- `tests/unit/test_game_state.gd`
- `tests/unit/test_signal_bus.gd`
