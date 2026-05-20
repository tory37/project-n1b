# Research: Scene-Scoped GameManager → UI Signal Architecture

**Date:** 2026-05-20  
**Branch:** `turn-state-draw-card`  
**Question:** Now that GameManager is scene-scoped (not autoload), is the right pattern to emit a signal on every state change and have UIs subscribe in `_ready()`? Is this the Godot way?

---

## TL;DR (Read This First)

**Yes — your instinct is correct.** The pattern is: `_apply_*` functions emit via `SignalBus` on every state mutation, and UI nodes connect to `SignalBus` in their `_ready()`. Your project **already has this infrastructure in place**. The only broken piece is `resource_display.gd`, which still pulls from `GameManager` directly (stale autoload references on lines 13, 14, 19, 22, 23).

The one thing your instinct is missing: **initial state delivery**. After UI connects its signals in `_ready()`, it has no current values until the next mutation fires. You need a way to broadcast "here is the state right now" once, at startup.

---

## Section I: Why Scene-Scoped GameManager Is Correct

The official Godot documentation explicitly warns against over-using autoloads ([Autoloads vs. Internal Nodes, Godot 4.4 docs](https://docs.godotengine.org/en/4.4/tutorials/best_practices/autoloads_versus_internal_nodes.html)):

> "Global state can cause one object to be responsible for all objects' data; if the class has errors or doesn't have resources available, all nodes calling it can break."

The benefits of a scene-scoped GameManager:
- **Isolated state**: bugs are contained to the gameplay scene
- **Clean lifecycle**: GameManager is born when a match starts, dies when it ends — correct by construction
- **Efficient resources**: freed memory when returning to the start screen

**Confirmed:** The decision to move GameManager off autoload is documented Godot best practice.

---

## Section II: The Signal Architecture — What "The Godot Way" Actually Means

### The Core Rule: "Call Down, Signal Up"

From [Node Communication (the right way), KidsCanCode Godot 4 Recipes](https://kidscancode.org/godot_recipes/4.x/basics/node_communication/index.html):

> "Call down the tree for children. Signal up the tree to parents. For cross-system communication: a Signal Bus."

In practice:
- **GameManager → UI** is cross-system communication (they're not parent/child). This is exactly what `SignalBus` is for.
- You already have this. `SignalBus.ap_tracker_moved`, `SignalBus.player_currency_updated`, `SignalBus.player_switched` are all live in GameManager's `_apply_*` functions.

### The Observer Pattern (What You're Doing)

Every `_apply_*` function already emits a signal on mutation. This is the **Observer Pattern** — the correct, idiomatic Godot approach. UI is a passive observer: it reacts to announced changes rather than polling or pulling state.

```
GameManager._apply_add_ap()
  → SignalBus.ap_tracker_moved.emit(ap_tracker)   ← mutation announced

ResourceDisplay._ready()
  → SignalBus.ap_tracker_moved.connect(_on_ap_moved)  ← UI subscribed

ResourceDisplay._on_ap_moved(value)
  → updates label  ← UI reacts
```

**This is correct. Do not change the direction of this data flow.**

---

## Section III: `_ready()` vs `_init()` — Definitive Answer

**Use `_ready()`. Never `_init()` for signal connections.**

From [Godot 4 Lifecycle Order, KidsCanCode](https://kidscancode.org/godot_recipes/4.x/basics/tree_ready_order/index.html):

The execution order is:
1. `_enter_tree()` fires **top-down** (parent first, then children)
2. `_ready()` fires **bottom-up** (leaf children first, then up to root)

This means when a node's `_ready()` fires, ALL of its children are already ready. This is the guaranteed-safe moment to connect signals.

`_init()` fires before the node even enters the scene tree. Other nodes don't exist yet. `get_node()` doesn't work. `@onready` vars are null. Connecting signals in `_init()` is a bug waiting to happen.

**Rule for your project:** Connect all `SignalBus` signals in `_ready()`. This is what `resource_display.gd` already does — keep that pattern.

---

## Section IV: The Gap — Initial State Delivery

### The Problem

When `ResourceDisplay._ready()` runs, it connects to `SignalBus`. But no signals have fired yet — the UI has **no current values**. The old code patched this by pulling directly:

```gdscript
# OLD: stale autoload pull (broken now that GameManager is scene-scoped)
var ap: int = GameManager.player_game_state[GameManager.active_player]["ap"]
```

This is the core of the bug in `resource_display.gd` — not the signal subscription, but the initial state fetch.

### Three Solutions (Ranked by Fit for This Project)

#### Option A — GameManager Broadcasts an Init Signal (Recommended)

GameManager emits a dedicated "state ready" signal after `_reset()` completes, using `call_deferred()` so all UI nodes are fully ready before it fires.

```gdscript
# In SignalBus.gd — add one signal:
signal game_state_initialized(player_one_state: PlayerGameState, player_two_state: PlayerGameState, active_player: int, ap_tracker: float)

# In GameManager._ready():
func _ready() -> void:
    _reset()
    _subscribe_to_game_signals()
    _start_turn_fsm()
    # Deferred so all UI _ready() calls have completed first:
    SignalBus.game_state_initialized.emit.call_deferred(
        player_game_state[PlayerSeat.PLAYER_ONE],
        player_game_state[PlayerSeat.PLAYER_TWO],
        active_player,
        ap_tracker
    )

# In ResourceDisplay._ready():
func _ready() -> void:
    SignalBus.ap_tracker_moved.connect(_on_ap_tracker_moved)
    SignalBus.player_currency_updated.connect(_on_player_currency_updated)
    SignalBus.player_switched.connect(_on_player_switched)
    SignalBus.game_state_initialized.connect(_on_game_state_initialized)

func _on_game_state_initialized(p1: PlayerGameState, p2: PlayerGameState, active: int, ap: float) -> void:
    # Set initial display state — runs once at startup
    _update_display(active, ap, p1.currency if active == PlayerSeat.PLAYER_ONE else p2.currency)
```

**Why this wins:** no direct reference to GameManager, pure signal flow, consistent with `request_*`/`_apply_*` seam, UI is fully decoupled.

#### Option B — Scene Root Wires Initial State

The gameplay scene root (e.g., `main.gd`) can access both `$GameManager` and `$HUD` as children and pass values down after both are ready:

```gdscript
# In main.gd (the gameplay scene root):
func _ready() -> void:
    # Both children are ready by the time parent's _ready() fires (bottom-up rule)
    $HUD/ResourceDisplay.initialize($GameManager.player_game_state, $GameManager.active_player, $GameManager.ap_tracker)
```

**Tradeoff:** Clean for a small tree, but couples the scene root to the internal structure of both GameManager and UI. Breaks if you restructure the scene. Less suitable once the UI gets complex.

#### Option C — `call_deferred()` Re-Emit All State

After `_reset()`, re-emit every state signal so any connected UI gets "caught up":

```gdscript
func _reset() -> void:
    # ... existing reset logic ...
    
    # Re-emit current state so connected UIs initialize
    SignalBus.ap_tracker_moved.emit.call_deferred(ap_tracker)
    SignalBus.player_switched.emit.call_deferred(active_player)
    SignalBus.player_currency_updated.emit.call_deferred(PlayerSeat.PLAYER_ONE, player_game_state[PlayerSeat.PLAYER_ONE].currency)
    SignalBus.player_currency_updated.emit.call_deferred(PlayerSeat.PLAYER_TWO, player_game_state[PlayerSeat.PLAYER_TWO].currency)
```

**Tradeoff:** Reuses existing signals, no new signal needed. But re-emitting mid-reset is conceptually noisy — each signal has multiple meanings ("state changed" vs "initial value"). Harder to reason about.

---

## Section V: The "Ghost Connection" Problem — One Rule to Follow

From [Riding the Event Bus in Godot, DEV Community](https://dev.to/bajathefrog/riding-the-event-bus-in-godot-ped):

> "Always check for duplicate connections and disconnect in `_exit_tree()`. Ghost connections are the source of some of the hardest bugs to track down in Godot projects."

Since `SignalBus` is an autoload (it lives forever) and `ResourceDisplay` is scene-scoped (it gets freed when gameplay ends), you MUST disconnect in `_exit_tree()`:

```gdscript
func _exit_tree() -> void:
    SignalBus.ap_tracker_moved.disconnect(_on_ap_tracker_moved)
    SignalBus.player_currency_updated.disconnect(_on_player_currency_updated)
    SignalBus.player_switched.disconnect(_on_player_switched)
    SignalBus.game_state_initialized.disconnect(_on_game_state_initialized)
```

Godot 4 also provides a cleaner way using `connect()` with a lifetime object:

```gdscript
# Signal auto-disconnects when ResourceDisplay is freed:
SignalBus.ap_tracker_moved.connect(_on_ap_tracker_moved, CONNECT_ONE_SHOT)  # if one-shot
# Or store the connection and use disconnect in _exit_tree()
```

**Without this:** When the player returns to the start screen and re-enters gameplay, a second `ResourceDisplay` instance connects a second time to `SignalBus`. UI updates fire twice. Values display wrong.

---

## Section VI: Your Project's Specific Fix

The direct `GameManager.*` references in `resource_display.gd` (lines 13, 14, 19, 22, 23) must be removed. The correct replacement is **Option A** above.

Additionally, the signals `resource_display.gd` subscribes to don't match what GameManager emits:

| `resource_display.gd` expects | GameManager actually emits |
|---|---|
| `SignalBus.resources_updated` (line 10) | Does not exist in GameManager |
| `SignalBus.player_switched` (line 11) | `SignalBus.player_switched` ✓ |
| (no ap subscription) | `SignalBus.ap_tracker_moved` |
| (no currency subscription) | `SignalBus.player_currency_updated` |

The UI needs to be rewritten against the actual signals GameManager emits.

---

## Section VII: Architecture Summary — The Five Rules

1. **`_apply_*` emits, UI receives.** Every state mutation in GameManager ends with a `SignalBus.*.emit()` call. UI never pulls.

2. **Connect in `_ready()`, not `_init()`.** `_ready()` fires bottom-up — children first, then parents. It's the guaranteed-safe moment for signal wiring.

3. **Deliver initial state via a deferred broadcast signal** (`game_state_initialized`), not by pulling from GameManager. Use `call_deferred()` so all UI `_ready()` calls complete before the signal fires.

4. **Disconnect in `_exit_tree()`.** SignalBus outlives any scene-scoped node. Forgetting to disconnect creates ghost handlers that fire on re-entry.

5. **Never hold a direct reference to GameManager from UI.** If a UI node needs GameManager state, it's either missing a signal or needs the init broadcast.

---

## Sources

- [Autoloads vs. Regular Nodes — Godot 4.4 Docs](https://docs.godotengine.org/en/4.4/tutorials/best_practices/autoloads_versus_internal_nodes.html)
- [Singletons (Autoload) — Godot Stable Docs](https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html)
- [Node Communication (the right way) — KidsCanCode Godot 4 Recipes](https://kidscancode.org/godot_recipes/4.x/basics/node_communication/index.html)
- [Understanding Tree Ready Order — KidsCanCode Godot 4 Recipes](https://kidscancode.org/godot_recipes/4.x/basics/tree_ready_order/index.html)
- [The Events Bus Singleton — GDQuest](https://www.gdquest.com/tutorial/godot/design-patterns/event-bus-singleton/)
- [Smarter Godot Signals with the Event Autoload Pattern — GDQuest](https://www.gdquest.com/tutorial/godot/gdscript/events-signals-pattern/)
- [Riding the Event Bus in Godot — DEV Community](https://dev.to/bajathefrog/riding-the-event-bus-in-godot-ped)
- [Godot 4 Signals Tutorial — CodingQuests](https://codingquests.io/blog/godot-4-signals-tutorial)
- [Signals & the Observer Pattern in Godot — Slicker.me](https://slicker.me/godot/signals-observer-pattern.html)
- [Fix: Godot Signal Firing Before Child Nodes Are Ready — Bugnet Blog](https://bugnet.io/blog/fix-godot-signal-firing-before-child-nodes-ready)
