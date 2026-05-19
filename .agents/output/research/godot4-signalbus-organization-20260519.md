# Godot 4 — Signal Bus Organization Patterns
**Domain:** Godot 4 Signal Bus Architecture  
**Core Conflict:** Single flat Autoload vs. composition vs. multiple Autoloads when a signal bus grows large  
**Date:** 2026-05-19

---

## The Short Answer

There is no standardized community pattern for "composing" a large signal bus from multiple files into one entry point. The community does one of three things:

1. **Keep it flat** — single Autoload, all signals in one file (most common, even at scale)
2. **Multiple Autoloads** — one per domain, each registered in project.godot
3. **Resource-based bus** — each signal is its own `.tres` resource (emerging, more complex)

The composition idea (one Autoload, split across imported files) is **not a documented community pattern.** The reason is a hard language constraint: GDScript inner classes cannot be used as signal namespaces reliably.

---

## Section I: Why Composition Doesn't Work Cleanly

### The Inner Class Dead End

The intuitive composition approach would be:

```gdscript
# signal_bus.gd (Autoload)
extends Node

class Cards:
    signal card_drawn(player_id: int)

class Player:
    signal player_switched(id: int)
```

**This doesn't work.** Signals declared in an inner class belong to *instances* of that inner class, not to the class itself. There is no static signal on `Cards` — you would need `Cards.new().card_drawn`, which creates a new instance on every call. Nobody can share the same signal through this approach.

Additionally, there is a known open bug: connecting a method from an inner class to a signal from a different script returns `OK` but the method is silently never called. [Issue #110209 — godotengine/godot](https://github.com/godotengine/godot/issues/110209)

### The RefCounted Composition Approach (Technically Valid, Not Documented)

You *can* build a composition approach using separate `RefCounted` files:

```gdscript
# autoload/signal_bus.gd
extends Node

var cards: CardSignals = CardSignals.new()
var player: PlayerSignals = PlayerSignals.new()
```

```gdscript
# autoload/card_signals.gd
class_name CardSignals
extends RefCounted

signal card_drawn(player_id: int)
signal card_draw_animation_complete()
signal deck_clicked(owner_player_id: int)
```

Access:
```gdscript
SignalBus.cards.card_drawn.connect(_on_card_drawn)
SignalBus.cards.card_drawn.emit(player_id)
```

This **works at runtime.** Signals on `RefCounted` objects are fully functional. The single `SignalBus` Autoload is the entry point; the domain objects are regular GDScript instances held as typed properties.

**Why it isn't the community standard:**
- Not documented in any official or authoritative source found
- The `.cards.` indirection is unusual in Godot codebases — developers expect to type `SignalBus.card_drawn`, not `SignalBus.cards.card_drawn`
- Godot's editor signal connection panel won't see signals on the nested RefCounted objects, making editor-based signal wiring impossible for those signals
- Zero examples found in the wild

---

## Section II: What the Community Actually Does

### Pattern A — Single Flat Autoload (Most Common)

Every project surveyed uses a single flat Autoload file for all signals. The authoritative community source on this, [GDQuest's Events Bus tutorial](https://www.gdquest.com/tutorial/godot/design-patterns/event-bus-singleton/), states:

> "We found that even with dozens of signals on a single node, it is still fairly easy to keep track of the connections."

GDQuest uses this pattern on almost every project. The file gets long; comments and blank lines organize it. That's the whole strategy.

### Pattern B — Multiple Autoloads

The only documented split pattern is registering multiple Autoloads in `project.godot`. Each domain gets its own Node:

```
Project Settings > Autoload:
  CardSignals  → autoload/card_signals.gd
  PlayerSignals → autoload/player_signals.gd
  BoardSignals  → autoload/board_signals.gd
```

Each file is a flat `extends Node` with signals. Access: `CardSignals.card_drawn.emit(...)`.

This is the pattern that exists in the community when splits do happen. It has one cost: every new domain requires a new `project.godot` entry. It has one benefit: domain signals are completely isolated — no chance of accidentally emitting a player signal from card code.

### Pattern C — Resource-Based Signal Bus (Emerging)

Each signal is its own `.tres` Resource. Nodes hold `@export` variables pointing to specific signal resources. [Resource-Based Signal Bus for Godot](https://camperotacti.co/blog/resource-based-signal-bus-for-godot/) describes this as inspired by Unity's ScriptableObject Event Channels.

```gdscript
@export var on_card_drawn: SignalBus  # points to card_drawn.tres

func _ready() -> void:
    on_card_drawn.add_connection(_handle_card_drawn)
```

Benefits: signals are assets in the filesystem, no global singleton needed, easily testable. Cost: requires either a plugin or boilerplate per signal, and no Autoload-style global access. Overkill for a project at this size.

---

## Section III: Pattern Comparison Table

| Method | Single Entry Point | Editor Wiring | File Organization | Project Size Fit |
|---|---|---|---|---|
| Single flat Autoload | Yes (`SignalBus.`) | Yes | One growing file | Small → Large (GDQuest endorses at "dozens") |
| Multiple Autoloads | No (`CardSignals.`, `PlayerSignals.`) | Yes | One file per domain | Medium → Large |
| RefCounted composition | Yes (`SignalBus.cards.`) | **No** | Multiple files, one Autoload | **Not documented in community** |
| Resource-based | No (per-node exports) | Yes | One file per signal | Large, team projects |

---

## Section V: The 5 Inviolable Laws

1. **Do not use inner classes for signal namespacing.** GDScript inner class signals are instance-owned and have a known connection bug. This path leads to silent failures. [Issue #110209](https://github.com/godotengine/godot/issues/110209)

2. **The single flat Autoload is the community default and scales further than you think.** GDQuest explicitly says "dozens of signals" is still manageable in one file. Comments and blank lines are the organization strategy. Don't split until it actually hurts.

3. **If you split, use multiple Autoloads — not composition.** The multiple-Autoload pattern is the only documented community approach for splitting. It loses the single entry point but gains full editor support and complete domain isolation.

4. **The RefCounted composition approach works but is undocumented.** It is a valid engineering choice with real trade-offs (no editor wiring). If you use it, you're pioneering it in your codebase, not following a community standard. Document the decision.

5. **Don't split prematurely.** The research found no community discussion of a signal bus becoming unmanageable at 15, 30, or even 50 signals. The cost of splitting is real (more files, more `project.godot` entries, more import paths to remember). Wait for a concrete pain point, not a line-count rule.

---

## Section VI: Sources & Bibliography

- [The Events bus singleton — GDQuest](https://www.gdquest.com/tutorial/godot/design-patterns/event-bus-singleton/) — Primary community authority on the Event Bus pattern. Explicitly endorses single flat Autoload at scale ("dozens of signals").
- [Resource-Based Signal Bus for Godot — camperotacti.co](https://camperotacti.co/blog/resource-based-signal-bus-for-godot/) — Documents the Resource/ScriptableObject approach as an alternative to Autoloads.
- [Godot's Event Bus — Nicola Dau](https://nicolaluigidau.wordpress.com/2024/05/25/sending-signals-across-your-godot-4-project-with-game-events/) — Practical single-Autoload implementation used in a shipped project. Confirms flat structure as standard.
- [Riding the Event Bus in Godot — DEV Community](https://dev.to/bajathefrog/riding-the-event-bus-in-godot-ped) — Alternative approach using event classes defined near their source. No standardized split pattern.
- [Inner class signal bug — Issue #110209, godotengine/godot](https://github.com/godotengine/godot/issues/110209) — Confirms inner class + signal connection is broken in Godot 4.4.1.
- [Best practice for managing Autoload scripts — Godot Forum](https://forum.godotengine.org/t/best-practice-for-managing-autoload-scripts-start-screen-vs-in-game/68360) — Community thread confirming "cut down on autoloads" as general advice, with no mention of composition patterns.
