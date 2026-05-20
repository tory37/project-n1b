class_name PlayerGameState
extends RefCounted

var currency: int = 0
var deck: Array[CardData] = []
var hand: Array[CardData] = []
var discard: Array[CardData] = []


func deck_to_hand() -> void:
	if deck.size() == 0:
		return

	var card: CardData = deck.pop_back()
	hand.append(card)


func use_card_from_hand(card: CardData) -> void:
	if not hand.has(card):
		return

	hand.erase(card)
	discard.append(card)
