class_name TurnNumberNetworkedState
extends Node

# --- Variables ---

var _value: int = 1

var value: int:
	get:
		return _value

# --- Lifecycle ---


func _ready() -> void:
	SignalBus.increment_turn_requested.connect(_on_increment_turn_requested)


func _exit_tree() -> void:
	SignalBus.increment_turn_requested.disconnect(_on_increment_turn_requested)

# --- Signal Callbacks ---


func _on_increment_turn_requested() -> void:
	request_increment.rpc_id(1)

# --- Public Methods ---


func set_value(new_value: int) -> void:
	if not multiplayer.is_server():
		push_error("Only the server can set value directly")
		return

	_apply_set(new_value)

# Requests


@rpc("any_peer", "reliable")
func request_increment() -> void:
	if not multiplayer.is_server():
		push_error("Only the server can increment turn number")
		return

	var new_value: int = _value + 1

	if not _validate_set(new_value):
		_sync_increment_turn_requested_failed.rpc()
		return

	_apply_set(new_value)

# --- Private Methods ---

# Validation


func _validate_set(_new_value: int) -> bool:
	# Add validation logic here if needed
	return true

# Mutation


func _apply_set(new_value: int) -> void:
	if not multiplayer.is_server():
		push_error("Attempted to set turn number on a non-server peer.")
		return

	_sync_value.rpc(new_value)

# Synchronization


@rpc("authority", "call_local", "reliable")
func _sync_value(new_value: int) -> void:
	_value = new_value

	if not multiplayer.is_server():
		SignalBus.turn_number_synced.emit(new_value)


@rpc("authority", "call_remote", "reliable")
func _sync_increment_turn_requested_failed() -> void:
	SignalBus.increment_turn_requested_failed.emit()
