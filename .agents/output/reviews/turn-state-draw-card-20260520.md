# Godot Best Practices Review — turn-state-draw-card
**Date:** 2026-05-20
**Scope:** `git diff master...HEAD` — all `.gd` and test files on this branch

---

## Summary

The FSM architecture (FiniteState / FiniteStateMachine on RefCounted) and the request_*/\_apply_* seam pattern are solid foundations. However, there are **5 critical bugs** that will cause runtime crashes or broken game logic before any gameplay is possible: a signal parameter mismatch that corrupts AP spending, a type mismatch on `player_game_state_initialized` that will crash the UI, a signal connection leak in `TurnPhaseDrawCard` that compounds every turn, an `@export` value accessed in `_init()` that Godot hasn't populated yet, and a test suite that references an API that no longer exists.

---

## Critical Findings

**[CRITICAL] [B / Signal Seam] `game_manager.gd:67` — Signal parameter mismatch corrupts AP spending**

`SignalBus.spend_ap_requested` is defined with 3 parameters: `(player_index: int, amount: int, is_opp: bool)`.
The connected handler `_on_request_spend_ap(amount: int)` accepts only 1.
In Godot 4, surplus parameters are dropped — so the handler receives `player_index` as `amount`.
The actual spend `amount` is silently discarded. Every AP spend uses the player index (0 or 1) as the cost.

Fix: Update the handler signature to `_on_request_spend_ap(player_index: int, amount: int, is_opp: bool) -> void` and use the correct `amount` argument. Also decide whether `player_index` and `is_opp` should route the spend to the right player (currently `active_player` is hardcoded inside).

---

**[CRITICAL] [C / Signal Communication] `game_manager.gd:32` — Wrong type emitted on `player_game_state_initialized`**

`SignalBus.player_game_state_initialized` is typed: `signal player_game_state_initialized(player_game_state: PlayerGameState)`.

But in `game_manager.gd:32`:
```gdscript
SignalBus.player_game_state_initialized.emit(player_game_state)
```
`player_game_state` here is a `Dictionary[int, PlayerGameState]`, not a `PlayerGameState`.

In `resource_display.gd:21`, the receiver calls `player_game_state.currency` — which fails because a Dictionary has no `currency` property. This crashes the UI on every game start.

Fix: Either change the signal to emit a Dictionary, or emit a specific player's state (e.g., `player_game_state[active_player]`).

---

**[CRITICAL] [E / Lifecycle] `turn_phase_draw_card.gd:10` — Signal connection never disconnected; leaks and multiplies**

```gdscript
func enter() -> void:
    SignalBus.card_draw_animation_complete.connect(_on_card_draw_animation_complete)
    SignalBus.card_draw_requested.emit()

func exit() -> void:
    print("[Flow] Exiting TurnPhaseDrawCard")
    # ← no disconnect here
```

`TurnPhaseDrawCard` extends `RefCounted`. When `exit()` is called, Godot's signal system holds a Callable reference to the instance — preventing deallocation. Every turn creates a new `TurnPhaseDrawCard` and adds another connected callback. After N turns, `_on_card_draw_animation_complete` fires N times, triggering N state transitions simultaneously.

Fix: Add `SignalBus.card_draw_animation_complete.disconnect(_on_card_draw_animation_complete)` in `exit()`.

---

**[CRITICAL] [E / Lifecycle] `game_manager.gd:55-56` — @export var accessed in `_init()` before Godot populates it**

```gdscript
@export var test_deck: DeckData = DeckData.new()

func _init() -> void:
    ...
    player_game_state[PlayerSeat.PLAYER_ONE].deck = test_deck.cards.duplicate()
    player_game_state[PlayerSeat.PLAYER_TWO].deck = test_deck.cards.duplicate()
```

In Godot 4, inspector-assigned values for `@export` variables are applied **after** `_init()` completes (they are deserialized from the scene file during tree integration). At `_init()` time, `test_deck` holds only its inline default (`DeckData.new()` — empty). Both decks will always be initialized empty regardless of what is assigned in the inspector.

Fix: Move deck initialization to `_ready()`, after all properties have been set by the scene.

---

**[CRITICAL] [K / Testing] `tests/unit/test_game_state.gd` — Entire test file references a dead API**

The test file was written against an older `GameManager` design and is completely out of sync with the current implementation. It will error before any tests run:

- `GameManager.reset()` — method does not exist
- `GameManager.PLAYER_ONE` / `GameManager.PLAYER_TWO` — constants don't exist on `GameManager`; they live on `PlayerSeat`
- `GameManager._request_add_ap()` — method is named `_on_request_add_ap()` in current code
- `GameManager.player_game_state[...]["currency"]` — `player_game_state` values are `PlayerGameState` objects, not Dictionaries; bracket access won't work
- `assert_signal_emitted(SignalBus, "resources_updated")` — `resources_updated` signal does not exist on `SignalBus`
- Tests mutate `GameManager.local_player_id` directly and check it after turn switches, but `_apply_switch_turn()` changes `active_player`, not `local_player_id` — the two are semantically different and conflated throughout the test

This entire file must be rewritten against the current `GameManager` / `PlayerGameState` API.

---

## Warnings

**[WARNING] [L / File Layout] `game_manager.gd:29,37` — Public methods before lifecycle virtuals**

`start()` (line 29) and `can_spend_ap()` (line 37) appear before `_init()` (line 44) and `_ready()` (line 59). Required order: variables → `_init` → `_ready` → other virtuals → signal callbacks → public methods → private methods.

---

**[WARNING] [A / Code Standards] `resource_display.gd:24,28,32` — Missing return type annotations**

```gdscript
func _on_update_player_label(player: int):       # missing -> void
func _on_update_ap_label(ap: int):               # missing -> void
func _on_update_currency_label(currency: int):   # missing -> void
```
Static typing mandate: all function signatures must declare explicit return types.

---

**[WARNING] [A / Code Standards] `deck_view.gd:6` — @export var with underscore prefix**

```gdscript
@export var _owner_player_id: int = LocalSession.local_player_id
```
Underscore prefix (`_`) signals a private variable. `@export` variables are public (inspector-visible). This contradicts the naming convention. Should be `@export var owner_player_id: int`.

---

**[WARNING] [A / Code Standards] `game_manager.gd:96` — Orphaned method `_on_request_add_ap`**

`_on_request_add_ap(amount: int)` exists but is never connected to any signal in `_subscribe_to_game_signals()` and never called directly. Either wire it to a signal or remove it.

---

**[WARNING] [A / Code Standards] `hex_board.gd:12` — Untyped Dictionary**

```gdscript
var _tiles: Dictionary = { }
```
Should be: `var _tiles: Dictionary[Vector2i, Node] = {}` (or the most specific tile type). Static typing applies to Dictionary type parameters in GDScript 4.

---

**[WARNING] [A / Code Standards] `hex_board.gd:27-28` — Dead assignment**

```gdscript
var row_start: int = -board_height_radius      # ← immediately overwritten
row_start = -board_height_radius - 1
```
The first assignment is never read. Remove it; keep only the second.

---

**[WARNING] [A / Code Standards] `resource_display.gd:4-6` — @onready vars missing private prefix**

```gdscript
@onready var ap_label: Label = $VBoxContainer/APLabel
@onready var currency_label: Label = $VBoxContainer/CurrencyLabel
@onready var player_label: Label = $VBoxContainer/PlayerLabel
```
These are internal implementation details with no public API surface. Per convention, they should be prefixed: `_ap_label`, `_currency_label`, `_player_label`.

---

## Suggestions

**[SUGGESTION] [L / File Layout] `turn_phase_draw_card.gd:14` — `_on_*` callback between virtual methods**

`_on_card_draw_animation_complete()` sits between `enter()` and `exit()`. Per layout rules, `_on_*` signal callbacks form their own group after lifecycle virtuals and before public methods.

---

**[SUGGESTION] [D / Scene Coupling] `main.gd:6` — Missing null guard on exported dependency**

```gdscript
game_manager.start()
```
If `game_manager` is not assigned in the inspector, this silently crashes. Add:
```gdscript
if not game_manager:
    push_error("Main: game_manager not assigned")
    return
game_manager.start()
```

---

**[SUGGESTION] [A / Code Standards] `player_game_state.gd` — Verify tab indentation**

The file's indentation visually resembles 4-space indentation rather than tabs. GDScript requires tabs. Confirm (and fix if needed) in the Godot editor.

---

**[SUGGESTION] [A / Code Standards] `game_manager.gd` — Clarify `active_player` vs `local_player_id` semantics**

`active_player` (whose turn it is) and `local_player_id` (which seat this client owns) are distinct concepts but the old test suite conflated them. The current code keeps them separate, which is correct. Consider a brief doc comment on each variable to prevent future confusion, especially as networking is added.

---

## Positive Notes

- **`FiniteState` / `FiniteStateMachine` on `RefCounted`** — correct Godot practice for non-tree data structures. No unnecessary scene overhead.
- **`request_*` / `_apply_*` seam pattern** — consistently applied across all signal handlers in `GameManager` and `LocalSession`. The networking seam is architecturally sound.
- **`HexBoard._spawn_tile`** — correctly sets all properties (`position`, `rotation`, `axial_coord`) before calling `add_child()`, avoiding unnecessary setter cascades during tree integration.
- **`deck_view.gd`** — uses `StaticBody3D._input_event` for 3D click detection rather than polling `Input` in `_process`. Correct approach for physics-body interaction.
- **`PlayerSeat`** — clean namespace class (enum + constants, no behavior). Appropriate use of a class with no `extends`.
- **`SignalBus`** — well-organized with comment groupings per system domain. Easy to navigate.
- **`LocalSession`** — minimal and correct; only one exported function, follows the request/apply split.

---

## Test Coverage

| File | Coverage |
|---|---|
| `test_signal_bus.gd` | Smoke-tests 2 signals and their emission args. Adequate for a bus contract. |
| `test_game_state.gd` | **Broken** — references `GameManager.reset()`, `GameManager.PLAYER_ONE`, `GameManager._request_add_ap()`, dictionary-style `player_game_state` access, and `SignalBus.resources_updated` — none of which exist. Must be fully rewritten. |

**Missing coverage:**
- `TurnPhaseDrawCard` — no tests for `enter()`/`exit()` lifecycle, no test that verifies disconnect-on-exit
- `PlayerGameState` — no tests for `deck_to_hand()` or `use_card_from_hand()` edge cases (empty deck, card not in hand)
- `FiniteStateMachine` — no tests for `change_state()` transition: `exit()` called on old state, `enter()` called on new

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
