class_name DeckData
extends Resource

@export var cards: Array[CardData] = []

func _init() -> void:
	cards = []

func add_card(card: CardData) -> void:
	cards.append(card)

func remove_card(card: CardData) -> void:
	if card in cards:
		cards.erase(card)