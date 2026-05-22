# Reading List

## Godot 4 Networking

Read in this order:

1. **[High-level multiplayer — Godot Engine docs](https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html)**
   Establishes core vocabulary: peers, peer_id, server/host, authority. Read slowly — everything else builds on this.

2. **[Multiplayer Networking in Godot 4: Building an Authoritative Server from Scratch — StraySpark](https://www.strayspark.studio/blog/godot-4-multiplayer-networking-authoritative-server)**
   Shows authority, ENet peers, and RPCs wired together. Explains who the authority is and why it matters.

3. **[Understanding RPC implementation in a turn-based multiplayer game — Godot Forum](https://forum.godotengine.org/t/understanding-rpc-implementation-in-a-turn-based-multiplayer-game/45563)**
   Directly relevant to this project's architecture: discrete events, not continuous state.

4. **[Multiplayer in Godot 4.0: RPC syntax — Godot Engine blog](https://godotengine.org/article/multiplayer-changes-godot-4-0-report-2/)**
   Reference for `@rpc("any_peer")` / `@rpc("authority")` annotation options.

### Note
For a turn-based card game, `MultiplayerSynchronizer` and `MultiplayerSpawner` are **not needed** — those are for continuously syncing real-time state (e.g. player position). This project only needs ENet + RPCs.
