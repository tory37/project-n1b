extends Node

signal player_connected(peer_id: int)
signal player_disconnected(peer_id: int)
signal connection_established
signal connection_failed

const DEFAULT_PORT: int  = 7777
const MAX_PLAYERS: int = 3

var peer: ENetMultiplayerPeer = null
var connected_players: Dictionary = {} # peer_id: PlayerInfo

## True when this instance holds server authority over game state. Local-only
## (no multiplayer peer) counts as server, matching Godot's own is_server() and
## how every component gates its state writes.
var is_server: bool:
	get:
		var tree := Engine.get_main_loop() as SceneTree
		if tree == null:
			return true
		return not tree.multiplayer.has_multiplayer_peer() or tree.multiplayer.is_server()

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func host_game(port: int = DEFAULT_PORT) -> Error:
	peer = ENetMultiplayerPeer.new()
	var error: Error = peer.create_server(port, MAX_PLAYERS)

	if error != OK:
		push_error("Failed to create server: %s" % error_string(error))
		return error

	multiplayer.multiplayer_peer = peer

	# Server is also peer ID 1
	connected_players[1] = PlayerInfo.new(1, "Host")
	print("Hosting game on port %d" % port)

	return OK

func join_game(address: String, port: int = DEFAULT_PORT) -> Error:
	peer = ENetMultiplayerPeer.new()
	var error: Error = peer.create_client(address, port)

	if error != OK:
		push_error("Failed to create client: %s" % error_string(error))
		return error

	multiplayer.multiplayer_peer = peer
	print("Connecting to %s:%d" % [address, port])

	return OK


func disconnect_game() -> void:
	if peer:
		peer.close()
		peer = null

	multiplayer.multiplayer_peer = null
	connected_players.clear()
	print("Disconnected from game")


func _on_peer_connected(id: int) -> void:
	print("Peer connected: %d" % id)
	connected_players[id] = PlayerInfo.new(id, "Player %d" % id)
	player_connected.emit(id)


func _on_peer_disconnected(id: int) -> void:
	print("Peer disconnected: %d" % id)
	connected_players.erase(id)
	player_disconnected.emit(id)


func _on_connected_to_server() -> void:
	print("Connected to server.  My ID: %d" % multiplayer.get_unique_id())
	connection_established.emit()


func _on_connection_failed() -> void:
	print("Connection to server failed.")
	disconnect_game()
	connection_failed.emit()


func _on_server_disconnected() -> void:
	print("Disconnected from server.")
	disconnect_game()
