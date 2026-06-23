class_name AwaitingPlayersPhase
extends GamePhase

@export var on_all_players_ready_phase: GamePhase

var ready_peers: Array[int] = []

func enter(_payload: Variant) -> void:
	if not _game_manager.multiplayer.is_server():
		return

	multiplayer.peer_connected.connect(_on_peer_connected)
	_request_ready_check.rpc()


func exit() -> void: 
	if not multiplayer.is_server():
		return

	multiplayer.peer_connected.disconnect(_on_peer_connected)


func _on_peer_connected(peer_id: int) -> void:
	if not multiplayer.is_server():
		return

	_request_ready_check.rpc_id(peer_id)

@rpc("authority", "call_remote", "reliable")
func _request_ready_check() -> void:
	notify_ready.rpc_id(1)

@rpc("any_peer", "call_remote", "reliable")
func notify_ready() -> void:
	if not multiplayer.is_server():
		return

	var sender_id = multiplayer.get_remote_sender_id()
	if not ready_peers.has(sender_id):
		ready_peers.append(sender_id)
		
	if ready_peers.size() == multiplayer.get_peers().size():
		_game_manager.transition_to_phase(on_all_players_ready_phase)