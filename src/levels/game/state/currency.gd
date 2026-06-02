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


func add(peer_id: int, amount: int) -> void:
	if not multiplayer.is_server():
		push_error("Only the server can add value directly")
		return

	var new_value: int = get_value_for_peer(peer_id) + amount

	_sync_value.rpc(peer_id, new_value)


func spend(peer_id: int, amount: int) -> void:
	if not multiplayer.is_server():
		push_error("Only the server can spend value directly")
		return

	var new_value: int = get_value_for_peer(peer_id) - amount

	_sync_value.rpc(peer_id, new_value)

# --- Private Methods ---

# Synchronization


@rpc("authority", "call_local", "reliable")
func _sync_value(peer_id: int, new_value: int) -> void:
	Loggit.p("Syncing currency for peer %d: %d" % [peer_id, new_value], "CurrencyNetworkedState")
	_value[peer_id] = new_value

	if not multiplayer.is_server():
		Loggit.p(
			"Calling synced signal for peer %d: %d" % [peer_id, new_value], 
			"CurrencyNetworkedState"
		)
		SignalBus.currency_synced.emit(peer_id, new_value)
