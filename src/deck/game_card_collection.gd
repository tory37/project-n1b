class_name GameCardCollection
extends RefCounted

var cards: Array[GameCard] = []


func _init(collection: Array[CardData] = []) -> void:
	for card_data: CardData in collection:
		cards.append(GameCard.new(card_data))


func add_card(card: GameCard) -> void:
	cards.append(card)


func remove_card(card: GameCard) -> void:
	cards.erase(card)
