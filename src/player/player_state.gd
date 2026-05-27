class_name PlayerState
extends RefCounted

# Public State
var currency: int = 0
var hand: GameCardCollection = GameCardCollection.new()
var deck: GameCardCollection = GameCardCollection.new()
var discard: GameCardCollection = GameCardCollection.new()


func get_public_view() -> Dictionary:
	return {
		"hand_count": hand.cards.size(),
		"deck_count": deck.cards.size(),
		"discard_count": discard.cards.size(),
		"currency": currency,
	}


func deck_to_hand(count: int) -> void:
	if deck.cards.size() == 0:
		return

	for i in range(count):
		if deck.cards.size() == 0:
			return

		var card: GameCard = deck.cards.pop_back()
		hand.cards.append(card)


func use_card_from_hand(card: GameCard) -> void:
	if not hand.cards.has(card):
		return

	hand.cards.erase(card)
	discard.cards.append(card)
