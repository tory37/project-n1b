class_name PlayerRegistry
extends Node

signal player_added(peer_id: int, player: NetworkedPlayer)
signal player_removed(peer_id: int)

var _players: Dictionary[int, NetworkedPlayer] = { }


func add_player(peer_id: int, player: NetworkedPlayer) -> void:
	Loggit.p("Registering player with peer_id %d" % peer_id, "SeatFlow")
	sync_add_player.rpc(peer_id, player)


func get_player(peer_id: int) -> NetworkedPlayer:
	if peer_id in _players:
		return _players[peer_id]

	push_error("Player with peer_id %d not found in registry" % peer_id)
	return null


func get_all_players() -> Array[NetworkedPlayer]:
	Loggit.p("Getting all players from registry. Current players: %s" % _players.keys(), "SeatFlow")
	return _players.values()


@rpc("authority", "call_local", "reliable")
func sync_add_player(peer_id: int, player: NetworkedPlayer) -> void:
	Loggit.p("Syncing added player with peer_id %d" % peer_id, "SeatFlow")
	_players[peer_id] = player
	player_added.emit(peer_id, player)