# Network & Lobby: Lobby UI

**Last Updated:** 2026-05-22
**Status:** Awaiting Feedback
**Branch:** network-and-lobby

## Summary

Building the lobby UI for this 2-player turn-based card game. The `NetworkManager` autoload handles ENet multiplayer connections (host/join). The lobby UI script existed as a skeleton but had bugs and no corresponding `.tscn` scene file. This session fixed the script and wrote the editor scene setup guide — the user still needs to build the scene in Godot.

## Implementation Complete

- Fixed `lobby_ui.gd`:
  - Inverted guard in `_on_start()` (`if not NetworkManager.is_server: return`)
  - Corrected scene change path to `res://src/levels/game/game.tscn`
  - Added `_on_connection_failed()` — re-enables host/join buttons on failure
  - Added `_update_start_button()` — disables Start until `connected_players.size() >= MAX_PLAYERS`
  - Added `StatusLabel` with status messages throughout the flow
  - Updated `@onready` paths to match the new scene hierarchy (`CenterContainer/VBoxContainer/...`)
- Wrote `design/scenes/lobby_ui.md` — step-by-step guide for building `lobby_ui.tscn` in the Godot Editor

## Pending

- **User action required:** Build `src/ui/lobby/lobby_ui.tscn` in Godot Editor following `design/scenes/lobby_ui.md`
- Set `lobby_ui.tscn` as the main scene in Project Settings > Application > Run > Main Scene
- Test the lobby flow end-to-end (host on one instance, join on another, start game)
- Nothing committed yet — this work is all uncommitted on `network-and-lobby`

## Technical Notes

- Card game does NOT need to spawn player scene nodes. Player state is initialized via `_initialize_player(peer_id)` in `game_manager.gd`, which creates a `PlayerState` resource — no physical node.
- `NetworkManager` is an autoload at `autoload/network_manager.gd`. It owns `connected_players: Dictionary` (peer_id → PlayerInfo) and emits `player_connected`, `player_disconnected`, `connection_established`, `connection_failed`.
- `PlayerInfo` is a `RefCounted` class at `src/player/player_info.gd` — holds `peer_id`, `player_name`, `is_ready`, `ping_ms`.
- `lobby_ui.gd` uses `@rpc("authority", "call_local", "reliable")` on `_start_game()` — the host calls `_start_game.rpc()` which fires on all peers including itself, triggering `change_scene_to_file`.
- `game_manager.gd` has known issues (references `player_game_state` dict that no longer exists, broken `_teardown_player` signature) — these are pre-existing and out of scope for this session.

## Next Steps

1. Open `design/scenes/lobby_ui.md` in a text editor for reference.
2. In Godot Editor, create a new scene: Scene > New Scene.
3. Follow the guide node-by-node to build `lobby_ui.tscn` and save it to `src/ui/lobby/lobby_ui.tscn`.
4. Attach `src/ui/lobby/lobby_ui.gd` as the script on the root `LobbyUI` node.
5. In Project Settings > Application > Run > Main Scene, point to `lobby_ui.tscn`.
6. Run two instances (Project > Debug > Run Multiple Instances) and test host/join/start flow.
7. Report results — then commit if all is well.
