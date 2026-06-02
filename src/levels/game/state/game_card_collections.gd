# ------------------------------------------------------------------------
# This is an abstract base class for networked game card collections. 
# It provides the basic functionality for synchronizing a collection of 
# cards across the network, but does not implement any specific behavior 
# for a particular type of collection (e.g., hand, deck, discard pile). 
# Subclasses should override the `_call_synced_signal` method to emit the 
# appropriate signal for their specific collection type.
# ------------------------------------------------------------------------

class_name GameCardCollectionsNetworkedState
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

	var new_collection: GameCardCollection = GameCardCollection.from_card_data_array(
		card_data_array
	)

	_sync_to_all(peer_id, new_collection)


func shuffle(peer_id: int) -> void:
	if not multiplayer.is_server():
		push_error("Only the server can shuffle the collection directly")
		return

	if not peer_id in _value:
		push_error("Cannot shuffle non-existent collection for peer_id: %d" % peer_id)
		return

	var new_collection: GameCardCollection = _value[peer_id].duplicate()
	new_collection.shuffle()

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
		return _value[peer_id].count() >= amount

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
	var mask_card = func(card: GameCard):
		if card.revealed:
			return card
		return null

	var new_collection: GameCardCollection = GameCardCollection.new()
	var new_value: Array[GameCard] = []
	new_value.assign(collection.value.map(mask_card))

	new_collection.set_value(new_value)
	return new_collection


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
		_call_synced_signal(peer_id, new_value)

func _call_synced_signal(_peer_id: int, _new_value: GameCardCollection) -> void:
	push_error(
		"This method should be overridden in subclasses to emit the appropriate signal" +
		" for the specific collection type."
	)		
