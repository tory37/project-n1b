class_name GameDeck
extends RefCounted

var cards: Array[GameCard] = []

func _init(deck_data: DeckData) -> void:
	cards = deck_data.cards.map(
		func(card_data: CardData) -> GameCard:
			return GameCard.new(card_data)
	)
