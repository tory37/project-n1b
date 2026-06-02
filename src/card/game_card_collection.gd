class_name GameCardCollection
extends RefCounted

var _value: Array[GameCard] = []

var value: Array[GameCard]:
	get:
		return _value


static func from_card_data_array(card_data_array: Array[CardData]) -> GameCardCollection:
	var collection: GameCardCollection = GameCardCollection.new()
	for card_data: CardData in card_data_array:
		collection.push_back(GameCard.new(card_data))

	return collection


static func from_game_card_array(game_card_array: Array[GameCard]) -> GameCardCollection:
	var collection: GameCardCollection = GameCardCollection.new()
	for game_card: GameCard in game_card_array:
		collection.push_back(game_card)

	return collection


func _init(collection: Array[CardData] = []) -> void:
	for card_data: CardData in collection:
		_value.append(GameCard.new(card_data))


func count() -> int:
	return _value.size()


func set_value(new_value: Array[GameCard]) -> void:
	_value = new_value


func shuffle() -> void:
	_value.shuffle()


func push_back(card: GameCard) -> void:
	_value.push_back(card)


func push_front(card: GameCard) -> void:
	_value.push_front(card)


func pop_at(index: int) -> GameCard:
	return _value.pop_at(index)


func pop_back() -> GameCard:
	return _value.pop_back()


func pop_front() -> GameCard:
	return _value.pop_front()


func duplicate() -> GameCardCollection:
	var new_value: Array[GameCard] = _value.duplicate()
	var new_collection: GameCardCollection = GameCardCollection.from_game_card_array(new_value)
	return new_collection
