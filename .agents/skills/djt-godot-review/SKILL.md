---
name: djt-godot-review
description: "Perform a Godot 4 best-practices code review of a branch, diff, or specific files. /djt-godot-review [target]"
trigger: /djt-godot-review
---

# /djt-godot-review

Review GDScript and Godot scene/resource files against Godot's official best practices and project architectural mandates.

## Usage

```
/djt-godot-review                     # review current unstaged changes
/djt-godot-review origin/main..HEAD   # review changes between main and current branch
/djt-godot-review path/to/file.gd     # review a specific file
```

## Steps

### 1. Gather Context

Identify the scope of the review. If a diff or branch is specified, list the changed files. Read all relevant `.gd`, `.tscn`, and `.tres` files. Note whether any Autoload singletons are involved.

### 2. Analyze Against Godot Best Practices

Evaluate every file against each category below. For each violation, note the file, line number (if applicable), severity, and category label.

---

#### A — GDScript Code Standards

- **Static typing**: Every variable declaration and function signature must have explicit types (`var speed: float`, `func take_damage(amount: int) -> void`).
- **Naming conventions**: `snake_case` for variables, functions, and file names. `PascalCase` for class names (`class_name`).
- **Private prefix**: Internal variables and methods that are not part of the public API must be prefixed with `_`.
- **Export grouping**: Inspector-visible variables use `@export` and are grouped logically (related exports together).
- **No hard-coded paths**: Node paths must never be hard-coded strings. Use `@export var my_node: NodeType` or `NodePath` exported variables instead.
- **Single responsibility**: Scripts must not handle multiple unrelated systems. Flag any "God Script" where a single file controls more than one distinct domain of logic.
- **Inheritance depth**: Inheritance chains must be no deeper than 2 levels. Favor composition (component nodes) over inheritance.

---

#### B — Networking Architecture Seam

Every state-mutating function in a game manager or multiplayer-aware node must follow the `request_*` / `_apply_*` / `_rpc_sync_*` split pattern:

- `request_*` — public entrypoint, accepts inputs, performs validation, calls `_apply_*`. Must NOT directly mutate state.
- `_apply_*` — private, authority-only state mutator. This is the only place state changes happen.
- `_rpc_sync_*` — private, authority-broadcast. Sends state to clients after `_apply_*` mutates it.

Flag any function that mutates state directly without this split. This seam exists so that adding `@rpc` decorators later requires decorating existing functions — not rewriting game logic.

```gdscript
# CORRECT
func request_spend_ap(amount: int) -> void:
    _apply_spend_ap(amount)

func _apply_spend_ap(amount: int) -> void:
    player_resources[active_player]["ap"] -= amount
    _rpc_sync_ap_tracker.rpc(player_resources[active_player]["ap"])

@rpc("authority", "reliable")
func _rpc_sync_ap_tracker(value: int) -> void:
    ap_tracker = value
    SignalBus.ap_tracker_moved.emit(value)

# VIOLATION — direct mutation without split
func spend_ap(amount: int) -> void:
    player_resources[active_player]["ap"] -= amount
```

---

#### C — Signal-Based Communication

- **Downward**: Parent→child communication must use direct method calls on child nodes.
- **Upward**: Child→parent communication must use `emit_signal()` (never `get_parent()` + method call).
- **Cross-system**: Cross-scene/cross-system communication must go through a Signal Bus Autoload or dedicated manager — not via `get_node("/root/...")` traversal.

Flag any `get_parent()` call used to invoke a method (upward coupling violation). Flag any cross-system direct node reference that bypasses the signal bus.

---

#### D — Scene Organization & Coupling

- **Self-contained scenes**: Each scene must be runnable in isolation. Flag any scene whose script uses hard-coded paths to external sibling/parent nodes.
- **Dependency injection**: External dependencies must arrive via `@export` variables, signal connections, or explicit method calls — not fetched internally with `get_node()` pointing outside the scene's own subtree.
- **Parent-child test**: Parent-child relationships must pass the "elements of" test — removing the parent should logically remove all its children. If a node would survive its parent's deletion conceptually, it should be a sibling or elsewhere in the tree.
- **Autoload scope**: Autoloads must only be used for systems that (a) track data internally, (b) need global access, and (c) exist in isolation. An Autoload that modifies data belonging to another system is a violation.

---

#### E — Lifecycle & Notifications

- **`_process` vs `_physics_process`**: Use `_process(delta)` for visual/framerate-dependent logic. Use `_physics_process(delta)` for movement, physics, and anything requiring deterministic fixed-timestep behavior.
- **Input handling location**: Input checks (`Input.is_action_pressed`, etc.) must live in `_input()` or `_unhandled_input()`, not inside `_process()` or `_physics_process()`. Flag any input poll inside a frame callback.
- **Pre-tree initialization**: When constructing nodes procedurally, set all property values before calling `add_child()`. Triggering setters during tree integration causes unnecessary update cascades.
- **`_init` vs `_ready`**: Use `_init()` for setup that is independent of the scene tree (constructor-like logic). Use `_ready()` only for logic that requires children to already be initialized.

---

#### F — Node vs. Alternative Base Classes

- **RefCounted for data**: Custom data structures that do not need a scene tree presence must extend `RefCounted`, not `Node`. `RefCounted` has automatic memory management; `Node` does not.
- **Resource for serializable data**: Data that needs to be saved/loaded via Godot's resource system must extend `Resource`.
- **Object only with intent**: `Object` requires manual `free()` calls. Only use it when manual memory control is explicitly needed and documented.
- **No Node for pure data**: Flag any `Node` subclass whose sole purpose is to hold data with no scene tree behavior.

---

#### G — Scenes vs. Scripts

- **Game-specific concepts → Scenes**: Game entities, UI elements, and game-specific logic should be implemented as Scenes (`.tscn` + `.gd`), not as pure scripts. Scenes are easier to track and modify and perform better via `PackedScene` serialization.
- **Cross-project tools → Scripts**: Reusable utilities with broad applicability (math helpers, data parsers) are appropriate as standalone scripts or `class_name` definitions.
- **PackedScene instantiation**: Complex hierarchies must be instantiated from `PackedScene`, not built imperatively node-by-node in code (performance and maintainability reasons).

---

#### H — Data Structures & Algorithms

- **Dictionary for key lookup**: Use `Dictionary` when the primary access pattern is key-based lookup. Use `Array` for ordered sequences and iteration.
- **No hot-path front insertions**: Inserting at index 0 of an `Array` is O(n). In any loop or frequent callback, flag `array.insert(0, item)` or `array.push_front(item)`. Correct pattern: append to end, reverse when needed.
- **Integer enums over strings**: In performance-sensitive code (e.g., game loop state machines), use `enum` (integer) comparisons, not string comparisons. String comparison is O(n) per character.
- **Animation tool match**: Verify the animation approach suits the use case:
  - `AnimatedSprite2D` — frame-based sprite sheet animations
  - `AnimationPlayer` — complex property animations, cutout rigs
  - `AnimationTree` — blended state machines with multiple animations

---

#### I — Resource Loading

- **`preload()` for static deps**: Use `preload()` for resources that are always needed and never swapped at runtime. `preload()` runs at parse time and front-loads the cost.
- **`load()` for dynamic deps**: Use `load()` for resources that may change, be replaced by exports, or are conditionally needed.
- **No `preload()` on exported resources**: Flag any `@export var` whose default is set via `preload()` — this prevents the scene export from being overridden.
- **No `load()` in `const`**: `const MY_RES = load("res://...")` causes a runtime error. Constants must use `preload()`.

---

#### J — Composition & Folder Architecture

- **Component pattern**: Entity behavior must be broken into small, reusable component nodes (e.g., `HealthComponent`, `MovementComponent`, `AttackComponent`). Flag monolithic entity scripts that handle multiple behavioral domains.
- **Feature-based folders**: The `.gd` script and its paired `.tscn` scene must live in the same directory. Flag any script whose paired scene is in a different folder.
- **Local assets co-located**: Sprites, audio, and other assets unique to a feature must be inside that feature's folder — not in a global `assets/` dump if they are only used by one feature.

---

#### K — Testing (GUT)

- **Coverage**: All non-trivial logic must have a corresponding `tests/unit/test_<source_file>.gd`.
- **File naming**: Test files must be named `test_<source>.gd` and extend `GutTest`.
- **No scene tree in unit tests**: Unit tests must not instantiate or depend on the Godot scene tree. Any function requiring a node should be tested via integration tests instead.
- **Describe blocks**: Each public function should have a `describe_*` block. Cover: happy path, edge cases, boundary values (0, -1, max).

---

#### L — File Layout & Code Ordering

Every `.gd` file must follow the official Godot 4 declaration order. Flag any file where sections appear out of sequence.

**Required order:**
1. `@tool` / `@icon` annotations (only if needed)
2. `class_name`
3. `extends`
4. `##` doc comment
5. Signals
6. Enums
7. Constants
8. Static variables
9. `@export` variables
10. Public variables (no underscore prefix)
11. Private variables (`_` prefix)
12. `@onready` variables (`_` prefix — always last among variables)
13. Static methods / `_static_init()`
14. Built-in virtual methods in lifecycle order: `_init` → `_enter_tree` → `_ready` → `_process` → `_physics_process` → remaining virtuals
15. Signal callbacks (`_on_*`)
16. Public methods
17. Private methods (`_` prefix)
18. Inner classes

**Public/private method separation**: Public methods must be grouped together as a contiguous block. Private methods must follow as their own contiguous block. Interleaving public and private methods in the same region is a violation.

**`@onready` placement**: `@onready` variables must appear after all other variable declarations. They resolve at runtime (after `_ready()`), so placing them before regular variables is misleading about initialization order.

**Signal callbacks as a distinct group**: `_on_*` callbacks must be placed between virtual lifecycle methods and the public methods block — not scattered among private methods.

---

#### M — RPC Authority & Server/Client Guards

When any `@rpc` annotation is present, enforce the following rules. Every violation here is **Critical** — these are exploitable security and correctness bugs, not style issues.

**1. `request_*` must have a server guard.**
Every `@rpc("any_peer")` method must begin with `if not multiplayer.is_server(): return`. The `@rpc` annotation enables remote execution but does not prevent the method from being called locally. Without the guard, a bug or accidental local call on the client mutates state without server authority.

```gdscript
# CORRECT
@rpc("any_peer", "reliable")
func request_spend_ap(amount: int) -> void:
    if not multiplayer.is_server():
        return
    var player_id := multiplayer.get_remote_sender_id()
    _apply_spend_ap(player_id, amount)

# VIOLATION — no guard; accidental local call on client corrupts state
@rpc("any_peer", "reliable")
func request_spend_ap(amount: int) -> void:
    _apply_spend_ap(amount)
```

**2. Never pass `player_id` as a parameter to `request_*`.**
A client can pass any value, including another player's ID. The server must derive the caller's identity from `multiplayer.get_remote_sender_id()`, which the networking layer guarantees. Flag any `request_*` RPC that accepts a `player_id` parameter.

```gdscript
# VIOLATION — client-supplied player_id is spoofable
@rpc("any_peer", "reliable")
func request_spend_ap(player_id: int, amount: int) -> void: ...

# CORRECT
@rpc("any_peer", "reliable")
func request_spend_ap(amount: int) -> void:
    var player_id := multiplayer.get_remote_sender_id()
    ...
```

**3. `_apply_*` must have no RPC annotation.**
These methods are server-local only. They are called directly by `request_*` on the server, never remotely. An `@rpc` annotation on an `_apply_*` method is a violation.

**4. `_rpc_sync_*` must use `@rpc("authority", "reliable")`.**
Only the server may call these. `@rpc("any_peer")` on a sync method allows any client to forge a state update. Flag any sync method missing this annotation or using `"any_peer"` instead of `"authority"`.

**5. Hidden data must use `rpc_id`, not `rpc`.**
`.rpc()` broadcasts to all connected peers. Any sync RPC carrying player-private data (hand cards, secret resources, etc.) must use `.rpc_id(peer_id, ...)` to send only to the owning player. Opponents receive a public view (e.g. card count as a placeholder array) via a separate RPC.

```gdscript
# VIOLATION — sends full hand to all peers
_rpc_sync_hand.rpc(player_state.hand)

# CORRECT — full hand to owner, placeholder count to opponent
_rpc_sync_own_hand.rpc_id(player_id, player_state.hand)
_rpc_sync_opponent_hand.rpc_id(opponent_id, player_id, player_state.hand.size())
```

**6. Client signal handlers must forward via `rpc_id(1, ...)`.**
Client-side callbacks that trigger a server action must call the `request_*` method via `.rpc_id(1, ...)`. Calling the method directly on the client runs it locally — no network message is sent.

```gdscript
# VIOLATION — runs locally on client, nothing sent to server
func _on_spend_ap_requested(amount: int) -> void:
    request_spend_ap(amount)

# CORRECT
func _on_spend_ap_requested(amount: int) -> void:
    request_spend_ap.rpc_id(1, amount)
```

**7. Server/client signal subscriptions must be gated.**
`_ready()` must subscribe to server-only signals (game flow, player connected/disconnected) inside `if multiplayer.is_server():`, and client-only signals (UI input requests) inside `else:`. Subscribing both sides to all signals causes the server to forward UI events as RPCs and clients to handle authority-only events they should never see.

---

### 3. Generate Report

Write a detailed review report to `.agents/output/reviews/<target-name>-<timestamp>.html`. Use the standard HTML shell from the **HTML Output Convention** in AGENTS.md (`badge-review`, depth-1 stylesheet path `../../assets/style.css`). Bootstrap the stylesheet first if not present.

Structure the report with these sections:

**Header** — `.doc-header` with `badge-review` badge, date, and title "Godot Best Practices Review — \<target\>". Include a `.meta-block` showing scope (files or diff range).

**Summary** (`<h2>`) — High-level assessment of overall code quality and Godot best-practices adherence.

**Critical Findings** (`<h2>`) — Each finding as a `.finding-card.critical`: `.badge-critical` + category label, `.finding-title` with `filename.gd:line`, `.finding-body` with explanation.

**Warnings** (`<h2>`) — Each as `.finding-card.warning` with `.badge-warning`.

**Suggestions** (`<h2>`) — Each as `.finding-card.suggestion` with `.badge-suggestion`.

**Positive Notes** (`<h2>`) — Each as `.finding-card.positive`.

**Test Coverage** (`<h2>`) — Summary paragraph, then `.checklist` of covered and missing items.

**Files Reviewed** (`<h2>`) — File paths as `.file-chip` elements inside a `.files-list` div.

### 4. Present Summary

Output a concise terminal summary with:
- Count of Critical / Warning / Suggestion findings
- Top 3 most important findings
- Path to the full report
