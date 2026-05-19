# FSM State Communication in Godot 4 — Research Strategy
**Domain:** Godot 4 FSM Architecture for Turn-Based Games  
**Target:** `project-n1b` — `GameManager` Autoload + `FiniteStateMachine` (RefCounted) + `SignalBus`  
**Core Conflict:** How does a FSM state trigger game state mutations and coordinate async animations without coupling to `GameManager`?  
**Date:** 2026-05-19

---

## Section I: The Three Options — Success/Failure Matrix

The user identified three candidate patterns. This section evaluates each.

### Option A — Dependency Injection (pass GameManager into state init)

```gdscript
func enter(game_manager: GameManager) -> void:
    game_manager.request_draw_card()
```

| Factor | Assessment |
|---|---|
| Coupling | **High.** State directly references `GameManager`. Every state must accept it. |
| Testability | **Low.** Unit testing a state requires constructing or mocking `GameManager`. |
| Encapsulation | **Broken.** The state knows far more than it needs to. |
| Animation await | **Possible** (GameManager can return a signal), but messy. |

**Verdict: Rejected.** The user's instinct is correct — this is wrong. States should not know who owns them.

---

### Option B — Direct State Signals (GameManager subscribes to each state)

```gdscript
# In GameManager
func _ready() -> void:
    var phase = PhaseADrawCard.new()
    phase.card_draw_requested.connect(_on_draw_card)
    turn_phase_fsm.change_state(phase)
```

| Factor | Assessment |
|---|---|
| Coupling | **Medium.** GameManager must connect to each state's unique signals. |
| Lifecycle problem | **Hard.** States are instantiated and discarded; connections must be rewired every `change_state`. `RefCounted` objects don't emit `tree_exited`-style cleanup signals. |
| Scalability | **Poor.** Adding a new state means new connection logic in `GameManager`. |

**Verdict: Rejected.** This is the right *idea* (signals) but the wrong *target*. Routing signals through the `GameManager` directly creates the same coupling — just via signals instead of method calls.

---

### Option C — SignalBus (Correct Direction)

States emit to `SignalBus`. `GameManager` listens on `SignalBus`. States never reference `GameManager`.

| Factor | Assessment |
|---|---|
| Coupling | **None.** States and GameManager share only the signal contract, not references. |
| Lifecycle | **Clean.** `SignalBus` is an Autoload that outlives both parties. Connections stay valid. |
| Scalability | **High.** New states just emit new (or existing) bus signals. |
| Animation await | **Solvable** — see Section III. |

**Verdict: Correct pattern for this codebase.**

---

## Section II: The Animation-Await Problem (Core Cognitive Load)

This is the user's sharpest question: *"we don't want to move to the next state until after the animation finishes — but the state can't await that flow, right?"*

**It can.** This is the key insight.

### Why `await` Works in `RefCounted`-based States

`FiniteState extends RefCounted`. GDScript's `await` keyword does not require a `Node` — it suspends the *coroutine* (the function frame), not a node's process. The state object stays alive as long as the `FiniteStateMachine` holds a reference via `current_state`. That reference is kept until `change_state` replaces it. So the `await` is safe *as long as the state is current*.

```gdscript
# This works. `enter()` is a coroutine when it contains `await`.
func enter() -> void:
    SignalBus.draw_card_requested.emit(GameManager.active_player)
    await SignalBus.card_draw_animation_complete  # suspends here
    SignalBus.phase_transition_requested.emit(PhaseBMainPhase.new())
```

### The Stale Awaiter Problem

There is **one real danger**: if `change_state` is called externally before `enter()` finishes awaiting (e.g., a forfeit button, a timeout), the state is replaced in the FSM but the coroutine is still live. When the signal fires, the old state's code resumes and emits `phase_transition_requested` — causing a double transition.

**Fix: Active Guard**

```gdscript
class_name PhaseADrawCard
extends FiniteState

var _is_active: bool = false

func enter() -> void:
    _is_active = true
    SignalBus.draw_card_requested.emit(GameManager.active_player)
    await SignalBus.card_draw_animation_complete
    if not _is_active:
        return
    SignalBus.phase_transition_requested.emit(PhaseBMainPhase.new())

func exit() -> void:
    _is_active = false
```

This is a standard coroutine guard. The `exit()` hook in `FiniteState` already exists — use it.

---

## Section III: The Recommended Stack for This Codebase

Three evidence-based patterns for Godot 4 FSMs, ranked by fit for `project-n1b`.

| Method | Theoretical Basis | Practical Implementation |
|---|---|---|
| **Async State with SignalBus** (Recommended) | Observer pattern + coroutines. State owns its own exit condition. | State `enter()` emits action signal, `await`s completion signal, emits transition signal. Guard via `_is_active`. |
| **Manager-Driven Transitions** (Fallback) | Command pattern. Manager is the explicit traffic controller. | State emits action signal. GameManager handles it, then calls `change_state` directly. No await in state. |
| **Async FSM** (Future/Advanced) | Cooperative multitasking. FSM `change_state` awaits enter(). | FSM calls `await current_state.enter()`. State returns when ready to transition. Requires FSM rework. |

### Why "Async State with SignalBus" fits `project-n1b`

- **Preserves the `request_*`/`_apply_*` seam.** `GameManager._apply_draw_card()` still owns the mutation. The state never touches data directly.
- **Preserves networking readiness.** The state emits a *request*; the authority (`GameManager`) fulfills it. When multiplayer arrives, only `_apply_draw_card` gets decorated — nothing else changes.
- **States are self-documenting.** Reading `PhaseADrawCard.enter()` tells you the *full lifecycle* of that phase: what it requests, what it waits for, and where it goes next.

---

## Section IV: Full Concrete Implementation

This shows exactly how to wire `PhaseADrawCard` using the recommended pattern against the existing codebase.

### Step 1 — Add signals to `SignalBus`

```gdscript
# In SignalBus.gd (add these)
signal draw_card_requested(player_id: int)
signal card_draw_animation_complete()
signal phase_transition_requested(next_state: FiniteState)
```

### Step 2 — Implement `PhaseADrawCard`

```gdscript
class_name PhaseADrawCard
extends FiniteState

var _is_active: bool = false

func enter() -> void:
    _is_active = true
    SignalBus.draw_card_requested.emit(GameManager.active_player)
    await SignalBus.card_draw_animation_complete
    if not _is_active:
        return
    SignalBus.phase_transition_requested.emit(PhaseBMainPhase.new())

func exit() -> void:
    _is_active = false
```

### Step 3 — Handle in `GameManager`

```gdscript
# In GameManager._ready() (add connections)
func _ready() -> void:
    SignalBus.draw_card_requested.connect(_on_draw_card_requested)
    SignalBus.phase_transition_requested.connect(_on_phase_transition_requested)
    reset()

func _on_draw_card_requested(player_id: int) -> void:
    _apply_draw_card(player_id)

func _apply_draw_card(player_id: int) -> void:
    player_game_state[player_id].deck_to_hand()
    SignalBus.card_drawn.emit(player_id, player_game_state[player_id].hand.back())

func _on_phase_transition_requested(next_state: FiniteState) -> void:
    turn_phase_fsm.change_state(next_state)
```

### Step 4 — UI/Animation Layer emits the completion signal

```gdscript
# In whatever Node drives card draw animation (e.g., HandView or CardAnimator)
func _on_card_drawn(player_id: int, card: CardData) -> void:
    # play animation...
    await animation_player.animation_finished
    SignalBus.card_draw_animation_complete.emit()
```

**Right now (no animation yet)**, you can emit `card_draw_animation_complete` immediately from `_apply_draw_card`:

```gdscript
func _apply_draw_card(player_id: int) -> void:
    player_game_state[player_id].deck_to_hand()
    var drawn_card: CardData = player_game_state[player_id].hand.back()
    SignalBus.card_drawn.emit(player_id, drawn_card)
    SignalBus.card_draw_animation_complete.emit()  # immediate until UI is built
```

When the UI is ready, remove the direct emit from `GameManager` and let the animation node emit it instead. **No other code changes.**

---

## Section V: The 5 Inviolable Laws for FSM-SignalBus in This Project

1. **States are requests, not commands.** A state emits `draw_card_requested`, never calls `GameManager.deck_to_hand()` directly. All mutations flow through `GameManager._apply_*`.

2. **States own their exit condition.** Each state's `enter()` knows what signal to `await` before requesting the next transition. The GameManager does not hardcode "after draw phase, go to phase B."

3. **Always guard awaiting coroutines.** Every `await` inside a state's `enter()` must be preceded by a check on `_is_active` after the await. Set `_is_active = false` in `exit()`.

4. **`card_draw_animation_complete` is the seam between logic and presentation.** Today it's emitted immediately by `GameManager`. Tomorrow it's emitted by a `CardAnimator` node. The game logic doesn't care which.

5. **`phase_transition_requested` carries the next state instance.** The state constructs `PhaseBMainPhase.new()` itself. This keeps the phase sequence readable inside each state file, not scattered across `GameManager`.

---

## Section VI: Sources & Bibliography

- [Godot 4 — GDScript Signals](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html#signals) — Official docs on signal declaration and connection lifecycle.
- [Godot 4 — Coroutines with `await`](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html#awaiting-signals-or-coroutines) — Documents that `await` suspends a function frame, not a Node, and works in any GDScript context.
- [Godot 4 — RefCounted](https://docs.godotengine.org/en/stable/classes/class_refcounted.html) — Confirms RefCounted objects live as long as a reference is held; relevant to state object lifetime during `await`.
- [Game Programming Patterns — State](https://gameprogrammingpatterns.com/state.html) — Robert Nystrom's canonical treatment of FSMs. Specifically the "self-owned transition" vs "manager-driven transition" tradeoff (Chapter 7).
- [Game Programming Patterns — Observer](https://gameprogrammingpatterns.com/observer.html) — Foundation for why SignalBus (a global event queue) decouples senders from receivers.
- [Godot 4 — Autoloads as Singletons](https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html) — Confirms Autoload lifetime and the pattern for global event buses.

**Unverified Hypothesis (not backed by a primary source):** Some community patterns suggest giving each `FiniteState` a reference to the FSM itself (so states can call `fsm.change_state(...)` directly). This avoids the `phase_transition_requested` bus signal. It is viable but creates a circular reference pattern (`FSM` holds `state`, `state` holds `FSM`). GDScript's reference counting handles this safely, but it tightens coupling between states and their host FSM. For this project's networking seam requirements, keeping transitions through the bus is preferable.
