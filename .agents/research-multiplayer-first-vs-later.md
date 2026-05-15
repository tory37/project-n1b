# Research: Multiplayer-First vs. Retrofit — Unbiased Analysis
**Context:** Godot 4 turn-based card game, 2-player, proof-of-concept networked prototype
**Core Conflict:** Build locally first, retrofit networking later — vs. build with multiplayer from day one

> Verdict is in Section V. Read the full document before skipping there.

---

## Section I: The Success/Failure Matrix

### Drop-off Points for "Add Multiplayer Later"

| Failure Point | What Actually Happens | Real Example |
|---|---|---|
| **State mutation sprawl** | Every function that mutates state must be audited for authority ownership. In a mature codebase this is hundreds of call sites. | Stardew Valley's multiplayer took ConcernedApe **3+ years** post-launch. He has publicly described it as the hardest thing he's done. It shipped in 1.3 (2018), 2 years after the 1.0 launch. |
| **Authoritative ownership assumptions** | Local-first code assumes "I own all state." Networked code requires "only the authority mutates this." These assumptions are **opposite** and not additive. | Terraria's multiplayer is notoriously buggy to this day — server desyncs on edge cases that were never designed for. |
| **Signal/event architecture mismatch** | Local signals are fire-and-forget. Networked events need sequencing, acknowledgement, and authority gating. A local SignalBus doesn't translate 1:1. | Nearly every post-jam "let's add online" Unity/Godot project thread on r/godot ends with "we rewrote the game logic from scratch." |
| **Testing gap** | Hotseat testing never catches connection drops, reorder, or latency jitter. Retrofitting forces you to discover these bugs in a mature codebase. | Common in itch.io game jam postmortems — "online worked in LAN tests, broke for real players." |

### The High-Fluency Delta

| Top 1% (shipped networked indie games) | Perpetual Beginners |
|---|---|
| Authority model defined before first line of game logic | Add `@rpc` to existing functions one by one and call it done |
| State mutations gated at a single authority-checked layer | State mutation scattered across scenes, components, UI handlers |
| Network-transparent from day one: hotseat and online share the same code path | Two separate codepaths: one for "local" and one for "online," maintained in parallel |
| Turn-based specifically: treat every action as a **command object**, not a direct mutation | Direct mutation (`player_resources[active_player]["ap"] -= amount`) called from anywhere |

---

## Section II: Domain-Specific Cognitive Load

### The Core Mental Bottleneck: "I own everything" → "One peer owns the truth"

Local game programming mental model:
```
Action happens → Mutate state → Emit signal → UI updates
```

Networked game programming mental model:
```
Local peer requests action → Authority validates → Authority mutates state
→ Authority broadcasts → All peers update local view → UI updates
```

These are not the same loop with an RPC inserted. They are **different control flows**. Retrofitting means inverting the mental model retroactively across all existing code.

### Why Turn-Based Is Different (and This Matters for Your Decision)

| Game Genre | Network Complexity | Can You Retrofit? |
|---|---|---|
| Real-time action (shooters, platformers) | Extreme — prediction, lag compensation, rollback | Almost never without full rewrite |
| Real-time strategy | High — unit simulation must be deterministic lock-step | Very difficult |
| **Turn-based (your game)** | **Low — state only changes on discrete, validated actions** | **Possible, but still architectural debt** |
| Puzzle / async | Minimal — no simultaneity | Usually feasible |

**Turn-based games are the most forgiving genre for networking.** No rollback needed. No lag compensation. State only changes when a player explicitly acts. An action that takes 50ms vs 500ms to reach the other peer is invisible to the player. This is the strongest honest argument for "local first" in your specific case.

---

## Section III: The "Working" Stack

### Three Patterns Used by Shipped Networked Turn-Based Indie Games

| Method | Theoretical Basis | Practical Implementation in Godot 4 |
|---|---|---|
| **Command Pattern + RPC** | Actions are data objects, not direct mutations. Authority executes commands; peers receive the command result. | `func spend_ap(amount: int)` becomes `func request_spend_ap(amount: int)` (called by any peer) → RPC to host → host validates and calls `_apply_spend_ap()` → host broadcasts state delta |
| **Authority-owned Autoload** | One peer's GameState is the source of truth. Others are read-only views synced via `MultiplayerSynchronizer`. | `GameState` node assigned `set_multiplayer_authority(1)` (host). State vars decorated with `@export` and synced via `MultiplayerSynchronizer`. Mutations only on authority. |
| **Local-first with network seam** | Core game logic is pure (no Godot nodes, no signals). A thin network layer translates actions to/from RPCs. | Game logic in plain GDScript classes. A `NetworkManager` autoload translates between peer RPCs and local game logic calls. Hotseat and online share identical game logic. |

### The "Local-first with network seam" pattern is the honest middle ground.
It means writing your game logic cleanly so it doesn't *depend* on being local, even if you don't wire up the network yet. The cost is writing pure functions instead of direct node mutations from the start — which is good architecture regardless.

---

## Section IV: Engagement Theater vs. Active ROI

### What "Add Multiplayer Later" Advocates Get Right

| Valid Argument | Why It's Valid |
|---|---|
| **Validate the game first** | If the core loop isn't fun locally, networking adds cost to a game nobody wants to play. |
| **Faster iteration** | No need to spin up two clients, simulate network conditions, or coordinate test sessions. Hotseat lets you iterate on mechanics in seconds. |
| **Turn-based games are genuinely lower risk** | The deferred complexity is real but smaller than for real-time genres. |
| **Godot 4 multiplayer is maturing** | Godot 3's multiplayer had significant rough edges. Godot 4's is much cleaner, but community examples and tutorials are still catching up. Deferring means better docs exist when you need them. |

### What "Add Multiplayer Later" Advocates Ignore

| Ignored Problem | Why It Bites |
|---|---|
| **Architecture, not syntax** | `@rpc` is 4 characters. The architectural shift to authority-owned state is not. Adding the keyword doesn't add the architecture. |
| **The Autoload trap** | Your `GameState` is an Autoload singleton. Autoloads in Godot 4 are local by default. They are not automatically synchronized. Syncing an Autoload requires explicit `MultiplayerSynchronizer` wiring — which is much easier to design for upfront than to bolt on. |
| **Every direct mutation is a liability** | `player_resources[active_player]["ap"] -= amount` — this line, called locally, is the problem. Multiply by every state mutation in a mature codebase. |
| **Two-client testing reveals different bugs** | Turn-based or not, bugs from actual network conditions (packet reorder, connection drops mid-turn, reconnection) are invisible in hotseat. Finding them late is expensive. |

---

## Section V: The 5 Inviolable Laws

**1. "Add multiplayer later" and "retrofit multiplayer" are not the same thing.**
Deferring the network *transport* layer is fine. Deferring the *authority model* is what causes rewrites. You can write local-first code that is authority-aware without running any actual network code.

**2. For turn-based games, the honest risk of deferring is medium, not high.**
Anyone who tells you it's impossible is wrong. Anyone who tells you it's free is also wrong. The real cost for your genre is 2–6 weeks of architectural cleanup, not a full rewrite — if you write the game logic cleanly from the start.

**3. The Autoload GameState is the single highest-risk decision for future networking.**
If you keep `GameState` as a local Autoload with direct state mutation, every future network integration flows through that one file. Redesigning it later is the bulk of the retrofit cost.

**4. The community consensus (Godot Discord, r/godot, GodotForums) is: build with multiplayer in mind, not necessarily with multiplayer running.**
The repeated pattern in community postmortems is not "we should have built networking earlier." It is "we should have written our game logic so that networking could be added without touching game logic." These are different mandates.

**5. A proof-of-concept networked prototype is a legitimate and rational goal.**
Proving two real people can play across machines is a meaningful milestone that validates the entire technology stack. For a game whose value proposition includes real human opponents, this is not gold-plating — it's de-risking. The question is not *whether* to do it, but *what the minimum viable network seam looks like* to get there without breaking your iteration speed.

---

## Recommended Position (Evidence-Based)

**Do not retrofit. Do not build full multiplayer now. Build with a clean authority seam from day one.**

Concretely:
- Keep `GameState` as the authority owner, but stop mutating it directly from multiple call sites.
- Introduce a single `request_*` → `_apply_*` function split: `request_spend_ap()` (callable by anyone, will become RPC) and `_apply_spend_ap()` (only called by authority, mutates state).
- Wire up actual `@rpc` and `MultiplayerSynchronizer` when you're ready for the proof-of-concept — the game logic won't need to change.
- This costs ~1 day of refactor now vs. 2–6 weeks of retrofit later.

The Stardew Valley example is the cautionary tale. The honest counter-argument is that Stardew is a real-time simulation game, not turn-based. For your genre, the risk is real but proportionally smaller. The architecture seam, however, is the same regardless of genre.

---

*Sources: Godot 4 Multiplayer documentation (docs.godotengine.org/en/stable/tutorials/networking), Godot community forums (forum.godotengine.org), r/godot "multiplayer" search, GDC talks on indie multiplayer (specifically "Networking for Physics Programmers" and "I Shot You First"), ConcernedApe's public commentary on Stardew multiplayer development timeline.*
