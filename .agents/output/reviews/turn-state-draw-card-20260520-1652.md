# Godot Best Practices Review — turn-state-draw-card
**Date:** 2026-05-20
**Scope:** All `.gd` files changed between `master` and `turn-state-draw-card` branch

## Summary

The core architecture is sound: the FSM design is clean, `RefCounted`-based data classes are used correctly, and the signal bus pattern is followed consistently. However, there are two critical issues that will cause runtime failures: a signal/handler argument count mismatch in `GameManager`, and a test suite (`test_game_state.gd`) that is entirely broken — it references an old API that no longer exists. Several warnings around file layout ordering and type precision round out the findings.

---

## Critical Findings

**[CRITICAL] [Category K] `tests/unit/test_game_state.gd` — Entire test file references a stale/nonexistent API**

The test file was written against a previous version of `GameManager` that was an Autoload singleton. The current `GameManager` is a scene node (not registered as an Autoload in `project.godot`). Every test in this file will fail for one or more of these reasons:

- `GameManager.reset()` — no `reset()` method exists on `GameManager` (line 4)
- `GameManager.PLAYER_ONE` / `GameManager.PLAYER_TWO` — these constants don't exist; they live on `PlayerSeat.Type` (lines 9, 10, 17–22, etc.)
- `GameManager.player_game_state[GameManager.PLAYER_ONE]["currency"]` — `player_game_state` values are typed `PlayerGameState` objects, not plain `Dictionary`; dictionary key access like `["currency"]` will fail (lines 19, 21)
- `GameManager._request_add_ap(3)` — method does not exist; the actual method is `_on_request_add_ap(amount: int)` (line 35)
- `GameManager._on_request_spend_ap(2)` — the actual signature is `_on_request_spend_ap(_player_id: int, amount: int)` (two params); tests call it with one (lines 93–99)
- `assert_signal_emitted(SignalBus, "resources_updated")` — no `resources_updated` signal exists in `signal_bus.gd` (lines 134, 165, 192)
- `GameManager.local_player_id = GameManager.PLAYER_TWO` — tests mutate `local_player_id` to track whose turn it is, but the implementation uses `active_player` for that purpose (line 9)

**Action required:** Either delete this file and rewrite from scratch against the current API, or update every assertion to match the live `GameManager` interface and access pattern.

---

**[CRITICAL] [Category A] `game_manager.gd:76` / `signal_bus.gd:19` — Signal argument count mismatch**

The `add_ap_requested` signal is defined with two parameters:
```gdscript
# signal_bus.gd:19
signal add_ap_requested(player_index: int, amount: int)
```

But the connected handler only accepts one:
```gdscript
# game_manager.gd:76 (connect) + line 107 (definition)
SignalBus.add_ap_requested.connect(_on_request_add_ap)

func _on_request_add_ap(amount: int) -> void:
```

In Godot 4, emitting `add_ap_requested` will pass two arguments to a function that declares only one, causing a runtime error: *"Too many arguments in function call."* This will crash any code path that emits `add_ap_requested`.

**Fix:** Either update the handler to accept both parameters:
```gdscript
func _on_request_add_ap(_player_index: int, amount: int) -> void:
    _apply_add_ap(amount)
```
...or remove `player_index` from the signal definition if it's intentionally unused.

---

## Warnings

**[WARNING] [Category A] `game_manager.gd:18,20` — `active_player` and `local_player_id` typed as `int` instead of `PlayerSeat.Type`**

```gdscript
var active_player: int = PlayerSeat.PLAYER_ONE
var local_player_id: int = PlayerSeat.PLAYER_ONE
```

These hold enum values but are declared as `int`. The correct static type is `PlayerSeat.Type`. Using `int` loses type-checker enforcement and makes the intent less clear to readers.

```gdscript
var active_player: PlayerSeat.Type = PlayerSeat.PLAYER_ONE
var local_player_id: PlayerSeat.Type = PlayerSeat.PLAYER_ONE
```

Same issue in `autoload/local_session.gd:3`.

---

**[WARNING] [Category A] `game_manager.gd:27` — `game_phase_fsm` declared but never used**

```gdscript
var game_phase_fsm: FiniteStateMachine = null  # line 27
```

`game_phase_fsm` is declared alongside `turn_phase_fsm` but is never assigned or accessed anywhere in the file. `_apply_start_game()` only initializes `turn_phase_fsm`. This is either a dead variable or an unfinished implementation of the `GameStartPhase` FSM. `game_start_phase.gd` also only has a stub `enter()` with a print — the game phase FSM appears to be scaffolded but not wired up.

---

**[WARNING] [Category L] `game_manager.gd` — Signal callbacks interleaved with private methods; public method out of position**

The Godot 4 required file order (Category L) specifies: virtual methods → signal callbacks (`_on_*`) → public methods → private methods.

Current layout violations:
- `can_spend_ap()` (public) appears at line 52, before the signal callbacks group — it should come *after* all `_on_*` callbacks.
- `_on_*` callbacks are interleaved with `_apply_*` private methods throughout the file instead of being grouped as a contiguous block (e.g., `_on_request_card_draw` at line 91, `_apply_card_draw` at 96, `_on_request_add_ap` at 107, `_apply_add_ap` at 111, etc.).

Required grouping:
```
_init / _ready          (virtuals)
_on_*                   (all signal callbacks together)
can_spend_ap            (public methods)
_is_player_1, _apply_*, _subscribe_*, _print_*   (private methods)
```

---

**[WARNING] [Category D] `deck_view.gd:6` — Autoload reference as `@export` default value**

```gdscript
@export var owner_player_id: int = LocalSession.local_player_id
```

The default value is resolved at scene instantiation time, which means it captures `LocalSession.local_player_id` at the moment the script is initialized — always `PlayerSeat.PLAYER_ONE` (the initial value). If the intent is for this value to track the actual local player dynamically, it must be set explicitly in `_ready()`:

```gdscript
@export var owner_player_id: int = 0  # set in _ready or via Inspector

func _ready() -> void:
    owner_player_id = LocalSession.local_player_id
    ...
```

Also: `owner_player_id` should be typed `PlayerSeat.Type`, not `int`.

---

**[WARNING] [Category E / L] `deck_view.gd:8-10` — Scene-tree-sourced variables should use `@onready`**

```gdscript
var _default_material: StandardMaterial3D
var _hovered_material: StandardMaterial3D
var _mesh_instance: MeshInstance3D
```

`_mesh_instance` is assigned from the scene tree in `_ready()` via `$MeshInstance3D`. It should be declared as `@onready` to make the tree-dependency explicit and idiomatic:

```gdscript
@onready var _mesh_instance: MeshInstance3D = $MeshInstance3D
```

`_default_material` and `_hovered_material` are created with `StandardMaterial3D.new()` in `_ready()`, so they don't need `@onready` — they can remain as regular `var` declarations. But `_mesh_instance` specifically is a scene-tree lookup and belongs in `@onready`.

---

**[WARNING] [Category A] `resource_display.gd:15` — `ap_tracker` parameter typed as `int` but signal carries `float`**

```gdscript
func _on_game_state_initialized(active_player: int, ap_tracker: int) -> void:
```

The `game_state_initialized` signal (signal_bus.gd:5) declares `ap_tracker: int`, but `GameManager.ap_tracker` is `float` and the emit call is:
```gdscript
SignalBus.game_state_initialized.emit(active_player, ap_tracker)  # ap_tracker: float
```

The handler parameter should be `ap_tracker: float` to match the actual emitted type. Godot 4 coerces `float` to `int` implicitly, which truncates decimal values silently. If AP tracker values are ever non-integer, this drops precision without warning.

**Fix:** Update both the signal definition and the handler to use `float`:
```gdscript
# signal_bus.gd
signal game_state_initialized(active_player: int, ap_tracker: float)

# resource_display.gd
func _on_game_state_initialized(active_player: int, ap_tracker: float) -> void:
```

---

## Suggestions

**[SUGGESTION] [Category L] `turn_phase_main.gd` — Missing explicit `_init` for consistency**

`TurnPhaseDrawCard` explicitly declares `func _init(fsm: FiniteStateMachine) -> void: super(fsm)`, but `TurnPhaseMain` relies on implicit inheritance of `FiniteState._init`. While functionally equivalent, an explicit `_init` makes the contract clear to readers and keeps the two sibling classes consistent:

```gdscript
func _init(fsm: FiniteStateMachine) -> void:
    super(fsm)
```

---

**[SUGGESTION] [Category L] `game_start_phase.gd` — Stub-only implementation; missing `_init` and `exit`**

`GameStartPhase` has only `enter()` with a print. It's missing:
- `func _init(fsm: FiniteStateMachine) -> void: super(fsm)` — required to receive the FSM reference
- `func exit() -> void` — needed if any cleanup is required when leaving this phase

If this phase is intentionally a placeholder, a comment stating that intention would be helpful.

---

**[SUGGESTION] [Category A] `player_seat.gd` — Redundant constants alongside enum**

```gdscript
const PLAYER_ONE = Type.PLAYER_ONE
const PLAYER_TWO = Type.PLAYER_TWO
```

These duplicate the enum values with untyped constants. If the goal is ergonomic shorthand, the constants should carry the enum type:
```gdscript
const PLAYER_ONE: Type = Type.PLAYER_ONE
```

Otherwise, using `PlayerSeat.Type.PLAYER_ONE` consistently throughout the codebase is cleaner and avoids two parallel representations.

---

**[SUGGESTION] [Category K] `test_signal_bus.gd` — Coverage is thin; only 4 of ~14 signals are tested**

`test_signal_bus.gd` tests only `player_switched` and `ap_tracker_moved`. The other 12 signals in `signal_bus.gd` have no presence/type checks. Consider adding `assert_has_signal` checks for at minimum the signals used by `GameManager` (`game_state_initialized`, `card_draw_requested`, `ap_spend_failed`, etc.) to catch regressions from signal renames.

---

## Positive Notes

- **`request_*` / `_apply_*` seam is correctly applied** in both `local_session.gd` and `signal_bus.gd` (the two registered Autoloads). The pattern is well-documented in `game_manager.gd`'s header comment.
- **`FiniteState` and `FiniteStateMachine` are clean** — both extend `RefCounted` correctly, are minimal, and have clear responsibilities. `TurnPhaseDrawCard` correctly connects and disconnects its signal listener in `enter()`/`exit()`, which is exactly right for FSM state lifecycle.
- **`PlayerGameState extends RefCounted`** — correct base class for a data holder. The three-array deck/hand/discard pattern is clean and `deck_to_hand()` / `use_card_from_hand()` are well-named, single-responsibility methods.
- **`HexBoard`** — good use of `@export` for all configurable properties, `push_error()` for missing scene assignment, and `PackedScene` instantiation. The axial coordinate helper delegation pattern is clean.
- **Static typing is consistently applied** across all new files — every variable and function signature carries an explicit type. This is the strongest aspect of the codebase's code quality.
- **Signal bus organization** — grouping signals by domain with section comments (`# Game State`, `# Cards`, `# Errors`, etc.) makes the bus easy to scan.

---

## Test Coverage

| File | Tests Present | Status |
|---|---|---|
| `game_manager.gd` | `test_game_state.gd` | **Broken** — stale API, will not run |
| `signal_bus.gd` | `test_signal_bus.gd` | Partial — only 2 of 14 signals checked |
| `player_game_state.gd` | None | Missing — `deck_to_hand()`, `use_card_from_hand()` edge cases (empty deck, card not in hand) should be covered |
| `finite_state_machine.gd` | None | Missing — `change_state()` transition logic (enter/exit call order) should be tested |
| `local_session.gd` | None | Low priority — trivial pass-through, acceptable to skip |
| `hex_board.gd` | None | Out of scope for this branch |

---

## Files Reviewed

- `autoload/local_session.gd`
- `autoload/signal_bus.gd`
- `src/game_manager/game_manager.gd`
- `src/game_manager/player_game_state.gd`
- `src/game_manager/player_seat.gd`
- `src/game_manager/game_phase/game_start_phase.gd`
- `src/game_manager/turn_phase/turn_phase_draw_card.gd`
- `src/game_manager/turn_phase/turn_phase_main.gd`
- `src/common/finite_state_machine/finite_state.gd`
- `src/common/finite_state_machine/finite_state_machine.gd`
- `src/deck/deck_view.gd`
- `src/levels/main/main.gd`
- `src/ui/resource_display.gd`
- `src/world/hex_board/hex_board.gd`
- `tests/unit/test_game_state.gd`
- `tests/unit/test_signal_bus.gd`
