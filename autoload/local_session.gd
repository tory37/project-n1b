extends Node

var local_player_id: int = 0

# In networking: called during lobby after peer IDs are assigned to slots
func request_set_local_player(player: int) -> void:
	_apply_set_local_player(player)

func _apply_set_local_player(player: int) -> void:
	local_player_id = player