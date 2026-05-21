# Godot Best Practices Review — turn-state-draw-card
**Date:** 2026-05-20 19:34
**Scope:** `git diff master...HEAD` — 10 commits, FSM implementation for draw-card turn state

---

## Summary

The FSM design for the draw-card phase is architecturally sound: `FiniteState`/`FiniteStateMachine` as `RefCounted`, signal connect/disconnect in `enter()`/`exit()`, and the deferred `call_deferred()` for the animation-complete signal all work correctly. The `request_*` / `_apply_*` seam is followed in all Autoloads.

However, there are **3 critical issues** that will cause runtime failures before the first playtest: a broken test suite (stale API references), a scene property name mismatch that silently disables Player 2's deck, and a signal type mismatch (`int` vs `float`) on `ap_tracker`. These must be addressed before testing is meaningful.

---

## Critical Findings

**[CRITICAL] [Category K] `tests/unit/test_game_state.gd` — Test suite is completely stale and will fail**

The tests reference an API that does not exist in the current `game_manager.gd`. Every test in this file is broken:

- `GameManager.reset()` — no such method exists.
- `GameManager._request_add_ap(3)` — no such method; current method is `_on_add_ap_requested(_player_id, amount)` with 2 params.
- `GameManager._on_spend_ap_requested(2)` — called with 1 arg but method requires 2: `(_player_id: int, amount: int)`.
- `GameManager.PLAYER_ONE` / `GameManager.PLAYER_TWO` — not members of GameManager; they live on `PlayerSeat`.
- `GameManager.player_game_state[key]["currency"]` — `player_game_state` values are `PlayerGameState` objects; `.currency` not `["currency"]`.
- `assert_signal_emitted(SignalBus, "resources_updated")` (lines 134, 163, 191, 193) — `resources_updated` does not exist in `signal_bus.gd`.
- Tests assert `GameManager.local_player_id` changes on turn switch, but `_apply_switch_turn()` changes `active_player`, not `local_player_id`.

The test file appears to have been written against a prior Autoload-based version of GameManager that has since been refactored into a scene-based Node.

---

**[CRITICAL] [Category D] `src/levels/main/main.tscn:30` — Player2Deck will always act as Player1**

```
# main.tscn
[node name="Player2Deck" ... instance=ExtResource("4_0it5o")]
_owner_player_id = 1
```

The scene property is `_owner_player_id` (with underscore prefix), but `deck_view.gd` exports:

```gdscript
@export var owner_player_id: int = LocalSession.local_player_id
```

The underscore name does not match the exported property name. Godot will silently discard `_owner_player_id = 1` and Player2Deck will default to `owner_player_id = 0` (PLAYER_ONE) at runtime. Clicking either deck will trigger `card_draw_requested` for Player 1. This property was likely renamed from `_owner_player_id` to `owner_player_id` but the scene file was not regenerated.

**Fix:** Either rename the export back to `_owner_player_id` (keeping the underscore) or open the scene in the Godot editor and re-set the Player2Deck's `owner_player_id` to `1` so the scene file regenerates with the correct key.

---

**[CRITICAL] [Category A] `autoload/signal_bus.gd:6` — `ap_tracker` typed as `int` but is `float`**

```gdscript
# signal_bus.gd
signal game_state_initialized(
    active_player: int,
    ap_tracker: int,  # ← wrong type
)
```

`GameManager.ap_tracker` is `float` (declared at `game_manager.gd:21`) and is emitted as a float at `game_manager.gd:117`. The signal definition and the receiver (`resource_display.gd:15`) both declare `int`. GDScript will silently truncate the float to an int, losing fractional AP values if they are ever used.

**Fix:** Change `ap_tracker: int` to `ap_tracker: float` in `signal_bus.gd` and `resource_display.gd:15`.

---

## Warnings

**[WARNING] [Category D] `src/game_manager/game_manager.gd:27` — `game_phase_fsm` is declared but never used; `GameStartPhase` is dead code**

```gdscript
var game_phase_fsm: FiniteStateMachine = null  # never initialized
```

`_apply_start_game()` only creates `turn_phase_fsm` and never assigns `game_phase_fsm`. `GameStartPhase` is never instantiated anywhere. If the game phase FSM is a planned future feature, that's fine — but the dead variable and orphaned class create false confidence that the game-phase layer is wired up.

---

**[WARNING] [Category A] `src/deck/deck_view.gd:6` — `@export` default uses Autoload runtime value**

```gdscript
@export var owner_player_id: int = LocalSession.local_player_id
```

Export default values are evaluated at parse time by the editor, not at scene instantiation. `LocalSession.local_player_id` is `0` at parse time. This export default is always `0` regardless of runtime state. Use a literal default (`= 0`) and set the correct value in the Inspector or via `@export`-driven scene properties.

---

**[WARNING] [Category A] `src/game_manager/game_manager.gd:57` — Signal callback named inconsistently**

```gdscript
func _on_request_card_draw() -> void:
```

Convention is `_on_<signal_name>`. The signal is `card_draw_requested`, so the handler should be `_on_card_draw_requested`. All other handlers in this file follow the convention correctly.

---

**[WARNING] [Category F] `src/game_manager/player_seat.gd` — No `extends`, defaults to `Object`**

`PlayerSeat` has no `extends` clause, making it implicitly extend `Object`, which requires manual `free()`. Since it's used purely as a namespace (enum + constants, never instantiated), there is no memory leak in practice. But it should extend `RefCounted` to be explicit, or the constants should be removed entirely and callers should use `PlayerSeat.Type.PLAYER_ONE` directly.

---

**[WARNING] [Category A] `autoload/local_session.gd:3`, `src/deck/deck_view.gd:6` — Player ID typed as `int` instead of `PlayerSeat.Type`**

```gdscript
# local_session.gd
var local_player_id: int = PlayerSeat.PLAYER_ONE

# deck_view.gd
@export var owner_player_id: int = LocalSession.local_player_id
```

Both should be `PlayerSeat.Type`. The rest of the codebase (e.g., `game_manager.gd`) uses `PlayerSeat.Type` correctly. Typing as `int` loses the enum safety and makes the types incompatible without implicit conversion.

---

**[WARNING] [Category A] `src/game_manager/game_manager.gd:22-40` — `player_game_state` initialized twice**

The dictionary is initialized at declaration (lines 22–25) creating two `PlayerGameState` objects, and then immediately replaced in `_init()` (lines 34–37) creating two more. The first two objects are garbage. Either remove the declaration-time initializer or remove the `_init` assignment.

---

**[WARNING] [Category A] `src/game_manager/turn_phase/turn_phase_main.gd` — Missing `[Flow]` debug prefix; no explicit `_init`**

```gdscript
func enter() -> void:
    print("Entering TurnPhaseMain")  # missing [Flow] prefix
```

Inconsistent with every other FSM state (`TurnPhaseDrawCard`, `GameStartPhase`). Also, unlike `TurnPhaseDrawCard`, this class has no explicit `_init(fsm: FiniteStateMachine) -> void: super(fsm)`. While the inherited `_init` works, the inconsistency is a reader trap — it looks like a forgotten implementation.

---

**[WARNING] [Category E] `src/deck/deck_view.gd:14` — Node path fetched in `_ready()` instead of `@onready`**

```gdscript
var _mesh_instance: MeshInstance3D

func _ready() -> void:
    _mesh_instance = $MeshInstance3D
```

Godot convention is to use `@onready`:

```gdscript
@onready var _mesh_instance: MeshInstance3D = $MeshInstance3D
```

`@onready` makes the initialization intent explicit and keeps it co-located with the declaration. The current pattern splits declaration from initialization across the file.

---

**[WARNING] [Category L] `src/game_manager/game_manager.gd` — GameManager extends `Node` but scene root is `Node3D`**

`game_manager.tscn` declares `type="Node3D"` but `game_manager.gd` declares `extends Node`. Godot allows this (Node is a parent class of Node3D), but it's misleading: the scene allocates a Node3D for a manager that has no 3D behavior. Use `type="Node"` in the scene (change the scene root type in the editor) or change the script to `extends Node3D` and document why.

---

## Suggestions

**[SUGGESTION] [Category B] `src/game_manager/game_manager.gd:62,66` — `_player_id` parameter is silently ignored in AP signal handlers**

```gdscript
func _on_add_ap_requested(_player_id: int, amount: int) -> void:
    _apply_add_ap(amount)  # always applies to active_player
```

The signal `add_ap_requested(player_index: int, amount: int)` includes a `player_index` that is never read. If AP can only be added for the active player, the signal parameter is misleading. If it's a future-proofing seam, add a comment explaining the intent. Consider either removing the parameter from the signal or asserting that `_player_id == active_player` as a guard.

---

**[SUGGESTION] [Category J] `src/game_manager/game_phase/game_start_phase.gd` — File exists but class is unused**

`GameStartPhase` is never instantiated. If the game-phase FSM is a planned feature, add a `TODO` comment. If it's been superseded by the turn-phase FSM, remove the file to avoid confusion.

---

**[SUGGESTION] [Category K] `tests/unit/test_signal_bus.gd` — Coverage is thin**

Only 4 signals are tested out of 13+ defined in `signal_bus.gd`. At minimum, signals that carry typed parameters (like `player_game_state_initialized(player_game_state: PlayerGameState)`) should be verified for correct argument types.

---

**[SUGGESTION] [Category J] `src/common/finite_state_machine/finite_state_machine.gd` — `current_state` is public but should be read-only**

`current_state: FiniteState = null` is public. External code could accidentally write to it, bypassing the `exit()`/`enter()` lifecycle. Consider making it private with a public getter, or at minimum documenting that it is read-only externally.

---

## Positive Notes

- **FSM lifecycle is correct.** `TurnPhaseDrawCard` connects `card_draw_animation_complete` in `enter()` and disconnects in `exit()` — no lingering connections after the state exits. The `call_deferred()` on the animation-complete emit correctly prevents a re-entrant FSM transition mid-frame.
- **`request_*` / `_apply_*` seam is properly implemented** in `LocalSession`. `GameManager` follows the same pattern internally even as a scene-based node.
- **`player_game_state.gd` data model is clean** — typed arrays, `pop_back()` for O(1) deck draw, `RefCounted` base class, no scene tree dependency.
- **`HexBoard._spawn_tile()` sets all properties before `add_child()`** (lines 55–60), following the correct Godot lifecycle pattern for procedural node construction.
- **Signal-based upward communication** is consistently used throughout — no `get_parent()` calls observed.
- **`FiniteState` and `FiniteStateMachine` extend `RefCounted`** — correct choice for logic objects with no scene tree presence.
- **Typed dictionaries** (`Dictionary[int, PlayerGameState]`, `Dictionary[Vector2i, Node]`) are used throughout — good GDScript 2.0 practice.

---

## Test Coverage

| File | Coverage |
|------|----------|
| `game_manager.gd` | `test_game_state.gd` exists but is **completely stale** — all tests reference a removed API and will fail |
| `signal_bus.gd` | `test_signal_bus.gd` covers 4/13+ signals; thin but functional |
| `finite_state_machine.gd` | **No tests** |
| `finite_state.gd` | **No tests** |
| `player_game_state.gd` | **No tests** — `deck_to_hand()` and `use_card_from_hand()` are untested |
| `turn_phase_draw_card.gd` | **No tests** |
| `local_session.gd` | **No tests** |

Priority order for new tests:
1. Rewrite `test_game_state.gd` against the actual `game_manager.gd` API
2. `player_game_state.gd` — deck draw and card use logic
3. `finite_state_machine.gd` — state transition lifecycle

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
- `src/game_manager/game_phase/game_start_phase.gd`
- `src/game_manager/player_game_state.gd`
- `src/game_manager/player_seat.gd`
- `src/game_manager/turn_phase/turn_phase_draw_card.gd`
- `src/game_manager/turn_phase/turn_phase_main.gd`
- `src/levels/main/main.gd`
- `src/levels/main/main.tscn`
- `src/ui/resource_display.gd`
- `src/world/hex_board/hex_board.gd`
- `tests/unit/test_game_state.gd`
- `tests/unit/test_signal_bus.gd`
- `project.godot`
