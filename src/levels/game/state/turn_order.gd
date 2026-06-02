class_name TurnOrderNetworkedState
extends Node

# --- Variables ---

var _value: Array[int] = []

var value: Array[int]:
	get:
		return _value

# --- Public Methods ---


func set_value(new_value: Array[int]) -> void:
	if not multiplayer.is_server():
		push_error("Only the server can set value directly")
		return

	_sync_value.rpc(new_value)


func push_value(new_value: int) -> void:
	if not multiplayer.is_server():
		push_error("Only the server can push value")
		return

	var new_array: Array[int] = _value.duplicate()
	new_array.append(new_value)

	_sync_value.rpc(new_array)


func get_next_player_id(current_player_id: int) -> int:
	var current_index: int = _value.find(current_player_id)
	if current_index == -1:
		push_error("Current player ID not found in turn order")
		return -1

	var next_index
	if current_index == _value.size() - 1:
		next_index = 0
	else:
		next_index = current_index + 1

	return _value[next_index]

func get_player_number(player_id: int) -> int:
	var index: int = _value.find(player_id)
	if index == -1:
		push_error("Player ID not found in turn order")
		return -1

	return index + 1


func get_player_at_number(player_number: int) -> int:
	if player_number < 1 or player_number > _value.size():
		push_error("Player number out of bounds")
		return -1

	return _value[player_number - 1]

# --- Private Methods ---


@rpc("authority", "call_local", "reliable")
func _sync_value(new_value: Array[int]) -> void:
	_value = new_value

	if not multiplayer.is_server():
		SignalBus.turn_order_synced.emit(new_value)
