class_name PlayerInfo
extends RefCounted

var peer_id: int
var player_name: String
var is_ready: bool = false
var ping_ms: int = 0

func _init(_peer_id: int, _player_name: String) -> void:
	peer_id = _peer_id
	player_name = _player_name