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

#### B — Networking Architecture Seam (Autoloads)

Every state-mutating function in an Autoload singleton must follow the `request_*` / `_apply_*` split pattern:

- `request_*` — public entrypoint, accepts inputs, performs validation, calls `_apply_*`. Must NOT directly mutate state.
- `_apply_*` — private, authority-only state mutator. This is the only place state changes happen.

Flag any Autoload function that mutates state directly without this split. This seam exists so that adding `@rpc("any_peer")` / `@rpc("authority")` decorators later requires zero logic rewrites.

```gdscript
# CORRECT
func request_spend_ap(amount: int) -> void:
    _apply_spend_ap(amount)

func _apply_spend_ap(amount: int) -> void:
    player_resources[active_player]["ap"] -= amount

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

### 3. Generate Report

Write a detailed review report to `.agents/output/reviews/<target-name>-<timestamp>.md`.

The report must follow this structure:

```markdown
# Godot Best Practices Review — <target>
**Date:** <timestamp>
**Scope:** <files or diff range reviewed>

## Summary
High-level assessment of overall code quality and Godot best-practices adherence.

## Critical Findings
Bugs, architectural violations, or patterns that will cause correctness or maintainability problems.
Each finding: `[CRITICAL] [Category X] filename.gd:line — explanation`

## Warnings
Violations of best practices that are not immediately harmful but should be addressed.
Each finding: `[WARNING] [Category X] filename.gd:line — explanation`

## Suggestions
Non-blocking improvements or optimizations.
Each finding: `[SUGGESTION] [Category X] filename.gd:line — explanation`

## Positive Notes
What was done well. Be specific.

## Test Coverage
Summary of GUT test coverage. List what's covered and what's missing.

## Files Reviewed
- path/to/file.gd
```

### 4. Present Summary

Output a concise terminal summary with:
- Count of Critical / Warning / Suggestion findings
- Top 3 most important findings
- Path to the full report
