class_name GameCardCollection
extends RefCounted

var value: Array[GameCard] = []


func _init(collection: Array[CardData] = []) -> void:
	for card_data: CardData in collection:
		value.append(GameCard.new(card_data))


func push_back(card: GameCard) -> void:
	value.push_back(card)


func push_front(card: GameCard) -> void:
	value.push_front(card)


func pop_at(index: int) -> GameCard:
	return value.pop_at(index)


func pop_back() -> GameCard:
	return value.pop_back()


func pop_front() -> GameCard:
	return value.pop_front()


func duplicate() -> GameCardCollection:
	var new_value = value.duplicate()
	var new_collection: GameCardCollection = GameCardCollection.new(new_value)
	return new_collection
