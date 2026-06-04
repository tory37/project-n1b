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

	if !new_value:
		Loggit.p("Setting value to null", "CARD_STATE")
	else:
		Loggit.p("Setting value to new collection: " + str(new_value.size()), "CARD_STATE")

	var serialized_value = GameCardCollection.to_dict(new_value)

	if not serialized_value:
		push_error("Failed to serialize GameCardCollection for syncing")
		return
	else:
		Loggit.p("Serialized GameCardCollection successfully", "CARD_STATE")

	_sync_value.rpc_id(1, serialized_value)
	_sync_value.rpc_id(_peer_id, serialized_value)

	var masked_value: GameCardCollection = GameCardCollection.mask(new_value)

	for peer: int in multiplayer.get_peers():
		if peer != 1 and peer != _peer_id:
			_sync_value.rpc_id(peer, GameCardCollection.to_dict(masked_value))

# --- Private Methods ---

@rpc("authority", "call_local", "reliable")
func _sync_value(new_value: Dictionary) -> void:
	Loggit.p("Received new value for GameCardCollection: %s" % [new_value], "CARD_STATE")
	_value = GameCardCollection.from_dict(new_value)
	Loggit.p("Deserialized GameCardCollection successfully. %s" % [_value], "CARD_STATE")


	if not _value:
		Loggit.p("Synced new value: null", "CARD_STATE")
	else:
		Loggit.p("Synced new value: new collection. Size: %d" % _value.cards.size(), "CARD_STATE")


	if not multiplayer.is_server():
		Loggit.p("Emitting synced signal with new collection", "CARD_STATE")
		synced.emit(_value)
