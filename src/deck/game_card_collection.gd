class_name GameCardCollection
extends RefCounted

var cards: Array[GameCard] = []


func _init(collection: Array[CardData] = []) -> void:
	cards = collection.map(
		func(card_data: CardData) -> GameCard:
			return GameCard.new(card_data)
	)


func add_card(card: GameCard) -> void:
	cards.append(card)


func remove_card(card: GameCard) -> void:
	cards.erase(card)
