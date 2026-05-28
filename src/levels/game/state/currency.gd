class_name CurrencyNetworkedState
extends Node

# --- Variables ---

var _value: Dictionary[int, int] = { }

var value: Dictionary[int, int]:
	get:
		return _value

# --- Public Methods ---


func get_value_for_peer(peer_id: int) -> int:
	if peer_id in _value:
		return _value[peer_id]

	return 0


func set_value(peer_id: int, new_value: int) -> void:
	if not multiplayer.is_server():
		push_error("Only the server can set value directly")
		return

	_sync_value.rpc(peer_id, new_value)


func remove_value(peer_id: int) -> void:
	if not multiplayer.is_server():
		push_error("Only the server can remove value directly")
		return

	_sync_value.rpc(peer_id, 0)

# --- Private Methods ---

# Synchronization


@rpc("authority", "call_local", "reliable")
func _sync_value(peer_id: int, new_value: int) -> void:
	_value[peer_id] = new_value

	if not multiplayer.is_server():
		SignalBus.currency_synced.emit(peer_id, new_value)