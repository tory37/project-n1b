class_name RoundNumberComponent
extends Node

var _value: int = 0

var value: int:
	get:
		return _value

func increment() -> void:
	if not multiplayer.is_server():
		push_error("Only the server can increment the round number")
		return

	_sync_value.rpc(_value + 1)


func decrement() -> void:
	if not multiplayer.is_server():
		push_error("Only the server can decrement the round number")
		return

	_sync_value.rpc(_value - 1)


@rpc("authority", "call_local", "reliable")
func _sync_value(new_value: int) -> void:
	_value = new_value
	if not multiplayer.is_server():
		SignalBus.round_number_synced.emit(new_value)