class_name GameCardCollectionNetworkedState
extends Node

# --- Variables ---

var _value: Dictionary[int, GameCardCollection] = { }

var value: Dictionary[int, GameCardCollection]:
	get:
		return _value

# --- Public Methods ---


func get_value_for_peer(peer_id: int) -> GameCardCollection:
	if peer_id in _value:
		return _value[peer_id]

	return null


func set_value(peer_id: int, new_value: GameCardCollection) -> void:
	if not multiplayer.is_server():
		push_error("Only the server can set the value directly")
		return

	_sync_to_all(peer_id, new_value)


func from_card_data(peer_id: int, card_data_array: Array[CardData]) -> void:
	if not multiplayer.is_server():
		push_error("Only the server can set the value directly")
		return

	var new_collection: GameCardCollection = GameCardCollection.new(card_data_array)

	_sync_to_all(peer_id, new_collection)


func push_back(peer_id: int, card: GameCard) -> void:
	if not multiplayer.is_server():
		push_error("Only the server can add cards directly")
		return

	if not peer_id in _value:
		push_error("Cannot add card to non-existent collection for peer_id: %d" % peer_id)
		return

	var new_collection: GameCardCollection = _value[peer_id].duplicate()
	new_collection.push_back(card)

	_sync_to_all(peer_id, new_collection)


func can_pop_cards(peer_id: int, amount: int) -> bool:
	if peer_id in _value:
		return _value[peer_id].size() >= amount
	
	return false


func pop_back(peer_id: int, count: int) -> GameCardCollection:
	if not multiplayer.is_server():
		push_error("Only the server can pop cards directly")
		return GameCardCollection.new()

	var new_collection: GameCardCollection = _value[peer_id].duplicate()
	var popped_cards: GameCardCollection = GameCardCollection.new()
	for i in range(count):
		var card: GameCard = new_collection.pop_back()
		if card != null:
			popped_cards.push_back(card)

	_sync_to_all(peer_id, new_collection)

	return popped_cards


# TODO: func reveal_card(peer_id: int, card: GameCard) -> void:

# --- Private Methods ---


# TODO: Hoist this up to a static service or something
func _mask_colletion(collection: GameCardCollection) -> GameCardCollection:
	return GameCardCollection.new(collection.value.map(
		func(card: GameCard):
			if card.revealed:
				return card

			return card
	)
	)


func _sync_to_all(peer_id: int, new_collection: GameCardCollection) -> void:
	var new_value: Dictionary[int, GameCardCollection] = _value.duplicate()

	for id in [1] + Array(multiplayer.get_peers()):
		if id == 1 || id == peer_id:
			new_value[id] = new_collection
			_sync_value.rpc_id(id, id, new_collection)
		else:
			new_value[id] = _mask_colletion(new_collection)
			_sync_value.rpc_id(id, id, new_value)


@rpc("authority", "call_local", "reliable")
func _sync_value(peer_id: int, new_value: GameCardCollection) -> void:
	_value[peer_id] = new_value

	if not multiplayer.is_server():
		SignalBus.deck_synced.emit(peer_id, new_value)
