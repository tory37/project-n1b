# Research: Scalable Player Architecture for Turn-Based Games
**Context:** `systems/game_state.gd` — current `enum Player { ONE, TWO }` design
**Question:** Can we replace hardcoded 2-player logic with an N-player system without locking ourselves into a corner?

---

## Section I: The Success/Failure Matrix

### Where 2-Player Hardcoding Kills Scalability

| Failure Point | Where It Appears in Your Code | Cost to Fix Later |
|---|---|---|
| **Binary enum** | `enum Player { ONE, TWO }` | Moderate — enum swap to int IDs |
| **Directional bias** | `1.0 if active_player == Player.ONE else -1.0` | **High** — tug logic is fundamentally bipolar |
| **Binary switch** | `Player.TWO if active_player == Player.ONE else Player.ONE` | Low — replace with array cycling |
| **Positional marker** | `marker_position: float` single value | **Critical** — entire mechanic assumes 2-pole axis |
| **Resource dict keys** | `player_resources[Player.ONE]` | Low — dict key is already abstract |

### The High-Fluency Delta (how shipped N-player games handle this)
- **Top-tier:** Player identity is an opaque `int` or `Resource` ID from day one. Turn order is a cyclic array. No game logic references "Player ONE" by name — only "active player" and "next player."
- **Perpetual beginners:** Start with an enum, later add `Player.THREE` to it, then add special-case `if player_count == 3` branches everywhere. The codebase rots.

---

## Section II: The Core Cognitive Load — The Marker Is the Real Problem

The binary `marker_position: float` is **not** a 2-player implementation detail. It is a **2-player game mechanic**. This is the crucial distinction.

| Question | Answer |
|---|---|
| Can a single signed float represent a 3-player tug-of-war? | **No.** A single axis has exactly 2 poles. |
| What does tug-of-war mean with 3 players? | Undefined — requires a design decision, not an engineering one. |
| Does refactoring player IDs solve this? | Partially. Player ID abstraction is safe and correct regardless. The marker mechanic needs separate design thought. |

**Conclusion:** The player ID system and the marker mechanic are two separable problems. Fix the ID system now (low risk, high payoff). Defer the multi-player marker design until the game mechanic is defined.

---

## Section III: The "Working" Stack — Proven N-Player Patterns

| Method | Theoretical Basis | Practical Implementation |
|---|---|---|
| **Integer Player ID** | Enum is just a named int — drop the name, keep the int | `var player_id: int` ranging 0..N-1. All dicts keyed on this. |
| **Cyclic Turn Array** | Turn order as a list, advance by index | `var turn_order: Array[int] = [0, 1]`. Next player = `turn_order[(current_index + 1) % turn_order.size()]` |
| **PlayerData Resource** | Composition over direct dict entries | Each player is a `PlayerData` Resource with `ap`, `coins`, `id`. Easy to serialize, easy to add fields. |

### Recommended Immediate Refactor (safe, does not break current 2P game)

```
# BEFORE
enum Player { ONE, TWO }
var active_player: Player = Player.ONE

# AFTER
var player_count: int = 2
var turn_order: Array[int] = range(player_count)   # [0, 1]
var active_player_index: int = 0
var active_player: int:
    get: return turn_order[active_player_index]
```

The `marker_position` direction logic becomes:
```
# BEFORE — hardcoded
var move_direction = 1.0 if active_player == Player.ONE else -1.0

# AFTER — player 0 pushes positive, all others push negative (same 2P behavior)
# For N-player, this needs a design decision first — placeholder:
var move_direction = 1.0 if active_player == 0 else -1.0
```
This is an **honest placeholder**: it preserves current behavior and clearly marks the design boundary.

---

## Section IV: Engagement Theater vs. Active ROI

| Engagement Theater (avoid) | Active ROI (do this) |
|---|---|
| Adding `Player.THREE` to the enum now "just in case" | Abstract player ID to `int` and cycle turn order array |
| Designing a 3-player marker mechanic today | Write a clear `# DESIGN TODO: multi-player marker` comment and move on |
| Refactoring all of `game_state.gd` as prep work | Scoped change: player ID + turn cycling only. Marker logic untouched. |
| Pretending the tug-of-war axis will "just work" with 3 players | Acknowledge it requires a game design session, not a code session |

---

## Section V: The 5 Inviolable Laws

1. **Player identity must be an opaque ID from now on.** Never reference `Player.ONE` or `Player.TWO` by name in logic. Only `active_player` (the current ID) and `next_player` (derived from the cycle).

2. **Turn order is data, not code.** `[0, 1]` in an array beats a binary `if/else` every time. Adding player 2 is appending to an array, not writing a new branch.

3. **The tug-of-war marker is a 2-player mechanic. Do not abstract it until you design what it means for 3+ players.** A premature abstraction here creates a broken mechanic, not a flexible one.

4. **`PlayerData` should be a Resource, not a raw dict.** `{"ap": 1, "coins": 0}` has no schema enforcement. A `PlayerData` class gives you static types, defaults, and easy extensibility.

5. **The refactor boundary is clear: player ID + turn cycling = do it now. Marker direction = design decision first.** Do not conflate the two. Ship the ID refactor independently.

---

## Recommended Next Steps (Prioritized)

| Priority | Task | Risk | Payoff |
|---|---|---|---|
| **1** | Replace `enum Player` with integer IDs and cyclic turn array | Low — 2P behavior identical | Unblocks future N-player |
| **2** | Extract `PlayerData` as a typed inner class or Resource | Low — internal refactor | Cleaner, extensible player state |
| **3** | Add `# DESIGN TODO` comment on marker direction logic | Zero — comment only | Honest marker for future designer |
| **4** | Design session: what does tug-of-war mean with 3 players? | Design risk, not code risk | Unlocks 3P marker implementation |

---

*Research basis: Godot 4 GDScript docs, standard turn-based game architecture patterns (Sid Meier's Civilization, Dominion digital — all use integer player indices with cyclic arrays), GDScript type system constraints.*
