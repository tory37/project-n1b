class_name NetworkedPlayer
extends Node

var _peer_id: int

@onready var _seat: SeatComponent = $SeatComponent

var peer_id: int:
	get:
		return _peer_id

var seat: SeatComponent:
	get:
		return _seat


func set_peer_id(new_peer_id: int) -> void:
	if not multiplayer.is_server():
		push_error("Only the server can set peer_id directly")
		return

	_peer_id = new_peer_id
