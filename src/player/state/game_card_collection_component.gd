# TODO: It would be even more efficent to only ever rpc the uuid and the coming "id"
# of the the card data itself.  Client could easily just grab raw card data
# from upcoming "card store" singleton, and then construct the card locally without 
# needing to serialize the whole thing
class_name GameCardCollectionComponent
extends Node

signal set_synced(new_value: GameCardCollection)
signal cards_added_synced(added_cards: GameCardCollection)
signal cards_removed_synced(uuids: Array[String])

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
	var old_value = _value

	var added_cards = GameCardCollection.new()
	var removed_cards = GameCardCollection.new()

	for card in new_value.cards:
		if not old_value.contains_card(card):
			added_cards.push_back(card)

	for card in old_value.cards:
		if not new_value.contains_card(card):
			removed_cards.push_back(card)

	if not multiplayer.is_server():
		push_error("Only the server can set value directly")
		return

	if added_cards.size() > 0:
		var serialized_added_cards: Dictionary = GameCardCollection.to_dict(added_cards)
		_sync_cards_added.rpc_id(1, serialized_added_cards, true)
		_sync_cards_added.rpc_id(_peer_id, serialized_added_cards, true)

	if removed_cards.size() > 0:
		var removed_uuids: Array[String] = []
		for card in removed_cards.cards:
			removed_uuids.append(card.uuid)

		_sync_cards_removed.rpc_id(1, removed_uuids)
		_sync_cards_removed.rpc_id(_peer_id, removed_uuids)

	# Since cards will often be masked for opponents, there's no good
	# way to only send the diffs.  So we just sync the whole collection
	# specifically to them on modification
	for peer: int in multiplayer.get_peers():
		if peer != 1 and peer != _peer_id:
			var masked_value: GameCardCollection = GameCardCollection.mask(new_value)
			_sync_value.rpc_id(peer, GameCardCollection.to_dict(masked_value))

# --- Private Methods ---


@rpc("any_peer", "call_remote", "reliable")
func _sync_value(new_value: Dictionary) -> void:
	Loggit.p("Syncing full collection: %s" % new_value)
	_value = GameCardCollection.from_dict(new_value)

	if not multiplayer.is_server():
		set_synced.emit(_value)


@rpc("authority", "call_local", "reliable")
func _sync_cards_added(added_cards: Dictionary, push_back: bool = true) -> void:
	Loggit.p("Syncing added cards: %s" % added_cards)
	var added_cards_collection = GameCardCollection.from_dict(added_cards)
	if push_back:
		_value.push_back_collection(added_cards_collection)
	else:
		_value.push_front_collection(added_cards_collection)
	cards_added_synced.emit(added_cards_collection)


@rpc("authority", "call_local", "reliable")
func _sync_cards_removed(uuids: Array[String]) -> void:
	Loggit.p("Syncing removed cards: %s" % uuids)
	_value.remove_cards(uuids)
	cards_removed_synced.emit(uuids)
