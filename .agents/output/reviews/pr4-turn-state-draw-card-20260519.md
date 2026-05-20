# Godot Best Practices Review — PR #4 (turn-state-draw-card)
**Date:** 2026-05-19
**Scope:** All files changed on `turn-state-draw-card` vs `master`

---

## Summary

The FSM skeleton and `request_*` / `_apply_*` pattern are solid architectural foundations, and the GUT test suite is impressively thorough for the AP/currency/turn systems. However, the branch has **four critical correctness bugs** that will cause runtime crashes or completely dead state transitions before the game ever reaches `TurnPhaseMain`. These must be fixed before the branch is in a testable state. Several static typing gaps and a coroutine design concern should also be addressed.

---

## Critical Findings

**[CRITICAL] [B/D] `autoload/signal_bus.gd` — `resources_updated` signal is not defined**
The signal `resources_updated` is emitted in `game_manager.gd:122,140` and connected in `resource_display.gd:10`, but it does not exist in `signal_bus.gd`. This will crash at runtime the moment any AP is spent or currency is added. It needs to be declared:
```gdscript
signal resources_updated(player_index: int, currency: int)
```
Note: the signal should be 2-argument (`player_index`, `currency`) to match what `game_manager.gd` emits. The existing `resource_display.gd` handler and `test_signal_bus.gd` both treat it as 3-argument (adding `ap`) — those callers need to be reconciled once the source-of-truth signature is decided (see Warning below).

---

**[CRITICAL] [A/L] `src/game_manager/turn_phase/turn_phase_main.gd:4` — Wrong method name, state never enters**
`TurnPhaseMain` defines `_on_enter()` but the FSM base class defines `enter()`. The FSM calls `current_state.enter()`, which falls through to `FiniteState.enter()` (a no-op). `_on_enter()` is dead code — `TurnPhaseMain` is permanently inert.
```gdscript
# BUG: should be `enter()`, not `_on_enter()`
func _on_enter() -> void:
    print("Entering TurnPhaseMain")
```

---

**[CRITICAL] [D] `src/ui/resource_display.gd:13,18,22` — References `GameManager` as a global, but it is not an Autoload**
`GameManager` is instantiated as a scene node (`game_manager.tscn`) inside `main.tscn`. It is **not** registered as an Autoload in `project.godot`. Any reference to `GameManager.player_game_state` or `GameManager.active_player` from `resource_display.gd` will fail with "Identifier 'GameManager' not declared in current scope." Either register GameManager as an Autoload, or pass the needed state via signals (preferred — the signal bus already handles `resources_updated` and `player_switched`).

---

**[CRITICAL] [K] `tests/unit/test_game_state.gd` — Tests reference a non-existent API**
Three distinct mismatches make the entire test file non-runnable against the current `game_manager.gd`:

1. `GameManager.reset()` — the method is private (`_reset()`). Tests call the public name which does not exist.
2. `GameManager.PLAYER_ONE` / `GameManager.PLAYER_TWO` — these constants are on `PlayerSeat`, not `GameManager`. These identifiers will not resolve.
3. `GameManager.player_game_state[GameManager.PLAYER_ONE]["currency"]` — `player_game_state` stores `PlayerGameState` objects (a `RefCounted` class), not dictionaries. The `["currency"]` subscript notation will fail; it must be `.currency`.

Additionally, the switch-turn tests assert on `GameManager.local_player_id` changing, but `_apply_switch_turn()` only mutates `active_player`. `local_player_id` is never updated by the turn switch logic.

---

## Warnings

**[WARNING] [A] `autoload/local_session.gd:3` — Missing static type**
```gdscript
# Current (untyped)
var local_player_id = PlayerSeat.PLAYER_ONE
# Should be
var local_player_id: PlayerSeat.Type = PlayerSeat.PLAYER_ONE
```

---

**[WARNING] [A] `src/game_manager/game_manager.gd:16` — `local_player_id` missing type**
```gdscript
var local_player_id = PlayerSeat.PLAYER_ONE  # should be: PlayerSeat.Type
```
This is especially important since `_is_player_1()` compares `active_player` (typed `int`) to `PlayerSeat.PLAYER_ONE`. Using `PlayerSeat.Type` throughout makes comparisons unambiguous.

---

**[WARNING] [A] `src/ui/resource_display.gd:5-7` — `@onready` variables missing types**
```gdscript
@onready var ap_label = $VBoxContainer/APLabel      # should be: Label
@onready var currency_label = $VBoxContainer/CurrencyLabel  # should be: Label
@onready var player_label = $VBoxContainer/PlayerLabel      # should be: Label
```

---

**[WARNING] [A] `src/ui/resource_display.gd:26` — `_update_display` missing return type**
```gdscript
func _update_display(player: int, ap: int, currency: int):  # should end: -> void:
```

---

**[WARNING] [A] `src/game_manager/player_game_state.gd:14` — `card` variable missing type**
```gdscript
var card = deck.pop_back()   # should be: var card: CardData = deck.pop_back()
```

---

**[WARNING] [E] `src/game_manager/turn_phase/turn_phase_draw_card.gd:9` — Implicit coroutine in `enter()` creates FSM race condition**
Any function containing `await` becomes an implicit coroutine in GDScript 4. `FiniteStateMachine.change_state()` does not `await` the return of `enter()`, so the code block after `await SignalBus.card_draw_animation_complete` runs asynchronously — after the original call stack returns. This means `_fsm.change_state(TurnPhaseMain.new(_fsm))` fires at an arbitrary future point. If any external code calls `change_state()` between the `await` and the transition (e.g. a second deck click), the FSM's `current_state` will be in an inconsistent state.

Consider making the FSM aware of async states (store a pending flag, or use a coroutine-aware `change_state_async()` that the caller `await`s).

---

**[WARNING] [A/B] `src/game_manager/game_manager.gd:172` — `on_print_players_hands_requested()` is dead and improperly named**
This public function is never connected to `print_players_hands_requested` — the actual connection is to `_print_players_hands()` directly (line 58). `on_print_players_hands_requested` is unreachable dead code. If it's meant to be a signal callback it should be `_on_print_players_hands_requested()` (private, underscore prefix).

---

**[WARNING] [I/D] `src/deck/deck_view.gd:6` — Reading Autoload value as `@export` default is fragile**
```gdscript
@export var _owner_player_id: int = LocalSession.local_player_id
```
The default value of an exported variable is evaluated at parse/scene-load time. This evaluates `LocalSession.local_player_id` during the scene's initialization, before `LocalSession._ready()` has had a chance to set the value from any networking lobby logic. The scene in `main.tscn` hardcodes `_owner_player_id = 1` for Player 2's deck anyway — the runtime override works, but the default is misleading. A value of `0` (or no default with a `## set before _ready()` doc comment) is clearer.

---

**[WARNING] [H] `src/ui/resource_display.gd:13` — Signal signature inconsistency for `resources_updated`**
Regardless of where the signal is declared, `game_manager.gd` emits it with **2 args** (`player_index`, `currency`) while `resource_display.gd` receives **3 args** (`player_index`, `ap`, `currency`) and the test emits **3 args**. AP tracking is no longer stored per-player (it's a shared tracker), so the 3-arg form appears stale. Decide the canonical signature and update all three sites.

---

**[WARNING] [E] `src/game_manager/game_manager.gd:23,62` — `FiniteStateMachine` allocated twice**
```gdscript
# Line 23 — allocated but immediately discarded by _start_turn_fsm()
var turn_phase_fsm: FiniteStateMachine = FiniteStateMachine.new()

# Line 62 — overwrites the above
func _start_turn_fsm() -> void:
    turn_phase_fsm = FiniteStateMachine.new()
```
Initialize to `null` at the declaration site:
```gdscript
var turn_phase_fsm: FiniteStateMachine = null
```

---

## Suggestions

**[SUGGESTION] [A] `src/common/finite_state_machine/finite_state.gd` and `finite_state_machine.gd` — Add explicit `extends RefCounted`**
GDScript 4 implicitly extends `RefCounted` when no `extends` is present, but explicit is clearer for maintainers and eliminates any ambiguity.

**[SUGGESTION] [L] `src/game_manager/game_manager.gd` — Signal callback (`_on_card_draw_requested`) placement**
Per the file layout spec, `_on_*` callbacks should form a distinct group between lifecycle methods and public methods. Currently `_on_card_draw_requested` and `_apply_card_draw` sit between `_start_turn_fsm` and `request_add_ap`. A clean reorder would help readability as the file grows.

**[SUGGESTION] [K] `tests/unit/test_game_state.gd` — Tests for `request_switch_turn` check `local_player_id` not `active_player`**
Even after fixing the `PLAYER_ONE`/`PLAYER_TWO` constant scope issue, these tests assert on `local_player_id` but turn switching only modifies `active_player`. Consider what the intended public contract of switch_turn is and whether `active_player` should be exposed, or whether the tests need a different assertion target.

**[SUGGESTION] [A] Remove or track the `test_deck` TODO**
`game_manager.gd:14` has `# TODO: Remove - Test data`. Add this to your kanban or tracking system so it isn't forgotten when real deck selection is implemented.

---

## Positive Notes

- **`request_*` / `_apply_*` networking seam**: Perfectly applied throughout `game_manager.gd`. Every state-mutating function respects the split with zero logic in the public entrypoints beyond validation. This will make RPC wiring trivial later.
- **`PlayerGameState` extends `RefCounted`**: Correct choice. Data-only model with no scene tree needs.
- **`PlayerSeat` enum design**: Clean use of a static class with aliased constants (`PLAYER_ONE = Type.PLAYER_ONE`). Eliminates magic numbers throughout.
- **Signal Bus organization**: Well-grouped by domain with clear comments. Easy to navigate.
- **GUT test depth**: The AP/currency/turn test coverage in `test_game_state.gd` is comprehensive — happy path, boundary values, negative cases, signal assertion checks. The intent is excellent; the API mismatches need correcting but the test logic itself is sound.
- **`_apply_spend_ap` auto-switch logic**: The tug-of-war tracker auto-switching turns when it crosses zero is elegantly expressed.

---

## Test Coverage

| System | Coverage | Notes |
|---|---|---|
| `game_manager.gd` — AP economy | Good | 14 tests in `test_game_state.gd`; will not run due to API mismatches |
| `game_manager.gd` — currency | Good | 3 tests |
| `game_manager.gd` — turn switching | Good | 5+ tests |
| `game_manager.gd` — pass turn | Good | 5 tests |
| `signal_bus.gd` | Partial | `resources_updated` signal tested but not defined; other signals untested |
| `player_game_state.gd` | **Missing** | `deck_to_hand()`, `use_card_from_hand()` have no unit tests |
| `finite_state_machine.gd` | **Missing** | No tests for state transitions, exit/enter sequencing |
| `turn_phase_draw_card.gd` | **Missing** | Coroutine + FSM integration not tested |
| `deck_view.gd` | **Missing** | Click/hover logic not unit-tested |
| `local_session.gd` | **Missing** | No tests |

---

## Files Reviewed

- `autoload/local_session.gd`
- `autoload/signal_bus.gd`
- `src/common/finite_state_machine/finite_state.gd`
- `src/common/finite_state_machine/finite_state_machine.gd`
- `src/deck/deck_view.gd`
- `src/deck/deck_view.tscn`
- `src/game_manager/game_manager.gd`
- `src/game_manager/game_manager.tscn`
- `src/game_manager/player_game_state.gd`
- `src/game_manager/player_seat.gd`
- `src/game_manager/turn_phase/turn_phase_draw_card.gd`
- `src/game_manager/turn_phase/turn_phase_main.gd`
- `src/levels/main/main.tscn`
- `src/ui/resource_display.gd`
- `tests/unit/test_game_state.gd`
- `project.godot` (autoload registrations)
