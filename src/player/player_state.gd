class_name PlayerState
extends RefCounted

# Public State
var currency: int = 0
var hand: Array[GameCard] = []
var deck: Array[GameCard] = []
var discard: Array[GameCard] = []


func get_public_view() -> Dictionary:
	return {
		"hand_count": hand.size(),
		"deck_count": deck.size(),
		"discard_count": discard.size(),
		"currency": currency,
	}


func deck_to_hand(count: int) -> void:
	if deck.size() == 0:
		return

	for i in range(count):
		if deck.size() == 0:
			return

		var card: GameCard = deck.pop_back()
		hand.append(card)


func use_card_from_hand(card: GameCard) -> void:
	if not hand.has(card):
		return

	hand.erase(card)
	discard.append(card)
