class_name ActionPointsNetworkedState
extends Node

# --- Variables ---

var _value: int = 0

var value: int:
	get:
		return _value

# --- Lifecycle ---


func _ready() -> void:
	SignalBus.spend_action_points_requested.connect(_on_spend_requested)
	SignalBus.gain_action_points_requested.connect(_on_gain_requested)


func _exit_tree() -> void:
	SignalBus.spend_action_points_requested.disconnect(_on_spend_requested)
	SignalBus.gain_action_points_requested.disconnect(_on_gain_requested)

# --- Signal Callbacks ---


func _on_spend_requested(amount: int) -> void:
	request_spend.rpc_id(1, amount)


func _on_gain_requested(amount: int) -> void:
	request_gain.rpc_id(1, amount)

# --- Public Methods ---


func set_value(new_value: int) -> void:
	if not multiplayer.is_server():
		push_error("Only the server can set value directly")
		return

	_sync_value.rpc(new_value)


func can_request_spend(amount: int) -> bool:
	return _validate_spend(amount)

# Requests


@rpc("any_peer", "reliable")
func request_spend(amount: int) -> void:
	if not multiplayer.is_server():
		push_error("Only the server can spend action points")
		return

	var new_value: int = _value - amount

	if not _validate_spend(amount):
		_sync_spend_requested_failed.rpc()
		return

	_sync_value.rpc(new_value)


func request_gain(amount: int) -> void:
	if not multiplayer.is_server():
		push_error("Only the server can gain action points")
		return

	# TODO: Update the '10' to the value in whatever config we setup
	var new_value: int = clamp(_value + amount, 0, 10)

	if not _validate_gain(amount):
		_sync_gain_requested_failed.rpc()
		return

	_sync_value.rpc(new_value)

# --- Private Methods ---


func _validate_spend(amount: int) -> bool:
	# TODO: Update the '10' to the value in whatever config we setup
	if amount > _value + 10:
		push_error("Cannot spend more AP than available: %d" % amount)
		return false

	return true


func _validate_gain(amount: int) -> bool:
	return amount >= 0


@rpc("authority", "call_local", "reliable")
func _sync_value(new_value: int) -> void:
	_value = new_value

	if not multiplayer.is_server():
		SignalBus.action_points_synced.emit(new_value)


@rpc("authority", "call_remote", "reliable")
func _sync_spend_requested_failed() -> void:
	SignalBus.spend_action_points_requested_failed.emit()


@rpc("authority", "call_remote", "reliable")
func _sync_gain_requested_failed() -> void:
	SignalBus.gain_action_points_requested_failed.emit()
