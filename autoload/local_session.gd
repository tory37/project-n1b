extends Node

var local_player_id: PlayerSeat.Type = PlayerSeat.PLAYER_ONE

# In networking: called during lobby after peer IDs are assigned to slots
func request_set_local_player(player: PlayerSeat.Type) -> void:
	_apply_set_local_player(player)

func _apply_set_local_player(player: PlayerSeat.Type) -> void:
	local_player_id = player