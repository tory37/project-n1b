class_name GameCardCollectionComponent
extends Node

signal synced(new_value: GameCardCollection)

# --- Variables ---

var _value: GameCardCollection = GameCardCollection.new()
var _peer_id: int

var value: GameCardCollection:
	get:
		return _value

	
# --- Lifecycle ---

func setup(peer_id: int) -> void:
	_peer_id = peer_id

func set_value(new_value: GameCardCollection) -> void:
	if not multiplayer.is_server():
		push_error("Only the server can set value directly")
		return

	var serialized_value = GameCardCollection.to_dict(new_value)

	if not serialized_value:
		push_error("Failed to serialize GameCardCollection for syncing")
		return

	_sync_value.rpc_id(1, serialized_value)
	_sync_value.rpc_id(_peer_id, serialized_value)

	var masked_value: GameCardCollection = GameCardCollection.mask(new_value)

	for peer: int in multiplayer.get_peers():
		if peer != 1 and peer != _peer_id:
			_sync_value.rpc_id(peer, GameCardCollection.to_dict(masked_value))

# --- Private Methods ---

@rpc("authority", "call_local", "reliable")
func _sync_value(new_value: Dictionary) -> void:
	_value = GameCardCollection.from_dict(new_value)

	if not multiplayer.is_server():
		synced.emit(_value)
