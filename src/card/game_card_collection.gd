class_name GameCardCollection
extends Resource

var _cards: Array[GameCard] = []

var cards: Array[GameCard]:
	get:
		return _cards


static func from_card_data_array(card_data_array: Array[CardData]) -> GameCardCollection:
	Loggit.p("Creating GameCardCollection from CardData array with %d cards" % card_data_array.size(), "DeckDebug")
	var map = func(card_data: CardData) -> GameCard:
		var card = GameCard.new()
		card.data = card_data
		return card

	var collection: GameCardCollection = GameCardCollection.new()
	var mapped_cards: Array[GameCard] = []
	mapped_cards.assign(card_data_array.map(map))
	collection.push_back_multi(mapped_cards)

	Loggit.p("Created GameCardCollection with %d cards" % collection.cards.size(), "DeckDebug")

	return collection


static func from_game_card_array(game_card_array: Array[GameCard]) -> GameCardCollection:
	var collection: GameCardCollection = GameCardCollection.new()
	collection.push_back_multi(game_card_array)

	return collection


static func mask(to_mask: GameCardCollection) -> GameCardCollection:
	var masked_cards: GameCardCollection = GameCardCollection.new()
	for card: GameCard in to_mask.cards:
		if card.revealed:
			masked_cards.push_back(card)
		else:
			var masked_card = GameCard.new()
			masked_card.mask_card()
			masked_cards.push_back(masked_card)

	return masked_cards


static func to_dict(collection: GameCardCollection) -> Dictionary:
	Loggit.p("Serializing GameCardCollection with %d cards" % collection.cards.size())
	var dict: Dictionary = { }
	var serialized_cards: Array[Dictionary] = []
	for game_card: GameCard in collection.cards:
		serialized_cards.append(GameCard.to_dict(game_card))

	dict["cards"] = serialized_cards
	return dict


static func from_dict(dict: Dictionary) -> GameCardCollection:
	Loggit.p("Deserializing GameCardCollection from dict with cards: %s" % str(dict.get("cards", [])))
	var serialized_cards: Array[Dictionary] = []
	serialized_cards.assign(dict.get("cards", []))

	var new_cards: Array[GameCard] = []
	for serialized_card: Dictionary in serialized_cards:
		var deserialized_card = GameCard.from_dict(serialized_card)
		new_cards.append(deserialized_card)

	return GameCardCollection.from_game_card_array(new_cards)


func size() -> int:
	return _cards.size()


func set_value(new_value: Array[GameCard]) -> GameCardCollection:
	_cards = new_value
	return self


func shuffle() -> GameCardCollection:
	_cards.shuffle()
	return self


func get_card_by_uuid(uuid: String) -> GameCard:
	for card in _cards:
		if card.uuid == uuid:
			return card
	return null


func push_back(card: GameCard) -> GameCardCollection:
	_cards.push_back(card)
	return self


func push_back_multi(new_cards: Array[GameCard]) -> GameCardCollection:
	for card in new_cards:
		_cards.push_back(card)
	return self


func push_back_collection(collection: GameCardCollection) -> GameCardCollection:
	for card in collection.cards:
		_cards.push_back(card)
	return self


func push_front(card: GameCard) -> GameCardCollection:
	_cards.push_front(card)
	return self


func push_front_multi(new_cards: Array[GameCard]) -> GameCardCollection:
	for card in new_cards:
		_cards.push_front(card)
	return self


func push_front_collection(collection: GameCardCollection) -> GameCardCollection:
	for card in collection.cards:
		_cards.push_front(card)
	return self


func pop_at(index: int) -> GameCard:
	return _cards.pop_at(index)


func pop_back(count: int) -> GameCardCollection:
	var popped_cards: Array[GameCard] = []
	for i in range(count):
		popped_cards.append(_cards.pop_back())

	return GameCardCollection.from_game_card_array(popped_cards)


func pop_front(count: int) -> GameCardCollection:
	var popped_cards: Array[GameCard] = []
	for i in range(count):
		popped_cards.append(_cards.pop_front())
	return GameCardCollection.from_game_card_array(popped_cards)


func remove_cards(uuids: Array[String]) -> GameCardCollection:
	var removed_cards: Array[GameCard] = []
	_cards = _cards.filter(
		func(card: GameCard) -> bool:
			if card.uuid in uuids:
				removed_cards.append(card)
				return false
			return true
	)
	return GameCardCollection.from_game_card_array(removed_cards)


func remove_collection(collection: GameCardCollection) -> GameCardCollection:
	var uuids_to_remove: Array[String] = []
	for card in collection.cards:
		uuids_to_remove.append(card.uuid)
	return remove_cards(uuids_to_remove)


func contains_card(card_to_check: GameCard) -> bool:
	for card in _cards:
		if card.uuid == card_to_check.uuid:
			return true
	return false


func copy() -> GameCardCollection:
	var new_value: Array[GameCard] = _cards.duplicate()
	var new_collection: GameCardCollection = GameCardCollection.from_game_card_array(new_value)
	return new_collection
