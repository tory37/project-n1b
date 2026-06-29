@tool
class_name AwaitingPlayersPhase
extends GamePhase

@export var on_all_players_ready_phase: FiniteState

func _on_enter() -> void:
	if not _game_manager.multiplayer.is_server():
		return

	NetworkManager.all_peers_readied.connect(_on_all_peers_ready)
	_game_manager.multiplayer.peer_connected.connect(_on_peer_connected)

	for peer_id in _game_manager.multiplayer.get_peers():
		NetworkManager.request_ready_check.rpc_id(peer_id)


func _on_exit() -> void:
	if not _game_manager.multiplayer.is_server():
		return

	_game_manager.multiplayer.peer_connected.disconnect(_on_peer_connected)
	NetworkManager.all_peers_readied.disconnect(_on_all_peers_ready)


func _on_peer_connected(peer_id: int) -> void:
	if not _game_manager.multiplayer.is_server():
		return

	NetworkManager.request_ready_check.rpc_id(peer_id)


func _on_all_peers_ready() -> void:
	if not _game_manager.multiplayer.is_server():
		return

	state_change_requested.emit(on_all_players_ready_phase)
