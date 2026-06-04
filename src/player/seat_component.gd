class_name SeatComponent
extends Node

signal synced(new_value: int)

# --- Variables ---

var _value: int = 0

var value: int:
	get:
		return _value

# --- Lifecycle ---


func set_value(new_value: int) -> void:
	if not multiplayer.is_server():
		push_error("Only the server can set value directly")
		return

	_sync_value.rpc(new_value)

# --- Private Methods ---


@rpc("authority", "call_local", "reliable")
func _sync_value(new_value: int) -> void:
	_value = new_value

	if not multiplayer.is_server():
		synced.emit(new_value)
