class_name ActivePlayerNetworkedState
extends Node

# --- Variables ---

var _value: int = 0

var value: int:
	get:
		return _value

# --- Public Methods ---


func set_value(new_value: int) -> void:
	if not multiplayer.is_server():
		push_error("Only the server can set value directly")
		return

	_apply_set(new_value)

# --- Private Methods ---

# Validation


func _validate_set(new_value: int) -> bool:
	if new_value != 1 and new_value != 2:
		push_error("Invalid active player value: %d" % new_value)
		return false

	return true

# Mutation


func _apply_set(new_value: int) -> void:
	if not multiplayer.is_server():
		push_error("Attempted to set value on a non-server peer.")
		return

	_sync_value.rpc(new_value)

# Synchronization


@rpc("authority", "call_local", "reliable")
func _sync_value(new_value: int) -> void:
	_value = new_value

	if not multiplayer.is_server():
		SignalBus.active_player_synced.emit(new_value)
