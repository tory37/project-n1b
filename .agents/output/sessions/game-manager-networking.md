# GameManager Networking Finalization

**Last Updated:** 2026-05-22
**Status:** In Progress
**Branch:** master

## Summary

The lobby is implemented and working — host/join, player list, and scene transition via `_start_game.rpc()` in `lobby_ui.gd`. The game scene loads on all peers. The focus of this session was identifying and planning the networking finalization work in `game_manager.gd`. No code has been written yet — we identified the spots, researched the architecture, and discussed the sync pattern. Implementation is next.

## Implementation Complete

- Lobby UI (`src/ui/lobby/lobby_ui.gd`) — fully working, loads `game.tscn` on all peers via RPC
- `NetworkManager` — ENet host/join, `connected_players` dictionary, `player_connected` / `player_disconnected` signals
- `GameState` + `PlayerState` data classes — exist and are the right pattern (confirmed via research)
- `GameManager._ready()` skeleton — server iterates `connected_players` and calls `_initialize_player`
- Research doc written: `.agents/output/research/playerstate-encapsulation-20260522.html`
- Networking spots plan written: `.agents/output/features/networking-game-manager.html`

## Pending

- **Spot 1:** Fix seat/peer_id mismatch in `_initialize_player` and `GameState`
- **Spot 2:** Broadcast player init to clients via `_rpc_sync_player_init`
- **Spot 3:** Guard `_subscribe_to_game_signals` / `_apply_*` so state mutations only run on authority
- **Spot 4:** Add `@rpc("authority", "call_local")` to `_apply_start_game` so all peers enter the FSM
- **Spot 5:** Add `@rpc` to `_apply_switch_turn` and `_apply_card_draw`
- **Spot 6:** Make `_on_spend_ap_requested` / `_on_draw_card_requested` the "any peer" entrypoints
- **Sync method:** Implement `_sync_state_to_all_peers()` + `_rpc_sync_player_state` RPC (designs discussed, not written)
- **Tests:** `test_game_manager.gd` references old API (`_gm.ap_tracker`, `_gm.active_player`, `_gm.player_state[PlayerSeat.X]`) — needs updating to use `_gm._game_state.*` and the new seat-keyed player_states

## Technical Notes

- **Seat assignment:** `player_states` must be keyed by `PlayerSeat.Type` (0/1), not peer_id. `GameState` needs a `peer_to_seat: Dictionary[int, int]` reverse lookup. First connected peer = PLAYER_ONE, second = PLAYER_TWO.
- **`MultiplayerSynchronizer` cannot hide state** — it broadcasts to all peers equally. Use manual `@rpc` with `rpc_id()` for anything with per-player visibility rules (i.e. deck contents).
- **RPC sync split:** Two helpers make sense — `_sync_shared_state()` (AP tracker, active player — broadcast to all) and `_sync_player_states()` (per-recipient with `get_public_view()` for opponent). A single `_sync_state_to_all_peers()` wrapper that calls both is fine for now.
- **`get_public_view()` belongs on PlayerState** — strips deck before server sends opponent's state. Returns `{ hand_count, discard_count, currency }`.
- **Custom objects can't cross RPCs** — PlayerState must be serialized to Dictionary before being passed. `hand` cards should be serialized as `resource_path` strings and loaded back on the client.
- **Server never receives `_rpc_sync_player_state`** — it dispatches via `rpc_id()` per peer, so it never executes the function itself. No `is_server()` guard needed inside.
- The user wants to implement Spots 3–6 themselves after seeing Spots 1–2 done together.

## Next Steps

1. Update `game_state.gd`: change `player_states` comment to clarify it is keyed by `PlayerSeat.Type`, add `peer_to_seat: Dictionary[int, int] = {}`.
2. Update `_initialize_player` in `game_manager.gd`: assign seat by order (first = PLAYER_ONE if player_states is empty, else PLAYER_TWO), key player_states by seat, broadcast via `_rpc_sync_player_init.rpc(peer_id, seat)`.
3. Add `_rpc_sync_player_init` `@rpc` method: received on clients, mirrors seat + empty PlayerState (no deck on client).
4. Add `get_public_view()` to `PlayerState`.
5. Add `_sync_state_to_all_peers()` + `_rpc_sync_player_state` to GameManager.
6. Let user tackle Spots 3–6 on their own.
7. Update `test_game_manager.gd` to match the new API (access state via `_gm._game_state.*`, seed player_states with seat keys before each test).
